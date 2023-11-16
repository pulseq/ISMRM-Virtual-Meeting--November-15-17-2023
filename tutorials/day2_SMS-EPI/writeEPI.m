function [gro, adc] = writeEPI(voxelSize, N, TE, TR, alpha, mb, pf_ky, Ry, Rz, caipiShiftZ, nFrames, nDummyFrames, type, varargin)
% function [gro, adc] = writeSMSEPI(voxelSize, N, TE, TR, alpha, mb, pf_ky, Ry, Rz, caipiShiftZ, nFrames, nDummyFrames, varargin)
%
% Create .seq file for SMS-EPI or 3D EPI fMRI.
%
% The recommended use of this function to define a few frames, 
% then use the 'runs' (repeat) feature on the scanner to repeat this .seq file.
% 
% Uses skippedcaipi_sampling.py (R. Stirnberg) to define the ky-kz CAIPI sampling pattern.
%
% Inputs:
%   voxelSize    [1 3]    m
%   N            [1 3]    image matrix size 
%   TE           [1]      s
%   alpha        [1]      flip angle (degrees)
%   mb           [1]      multiband/SMS factor
%   pf_ky        [1]      partial Fourier factor
%   Ry           [1]      ky undersampling factor
%   Rz           [1]      kz undersampling factor
%   caipiShiftZ  [1]      caipi shift along z for every ky blip
%   nFrames      [1]      number of time frames (image volumes)
%   nDummyFrames [1]      number of frames w/o data acquisition to reach steady state
%   type         string   'SMS' or '3D'
%
% Keyword-argument input options:
%   gro          struct   readout gradient struct. Default: create a new one and return from this function
%   adc          struct   acquisition struct. Default: create a new one and return from this function
%
% Outputs:
%   gro 
%   adc

[nx ny nz] = deal(N(1), N(2), N(3));

np = nz/mb;   % number of excitations/partiations (sets of SMS slices)

if strcmp(type, '3D') 
    mb = 1;
end
    

% parse input options
arg.gro = [];
arg.adc = [];
arg.fatsatOn = true;  
arg.simulateSliceProfile = false;    % simulate SMS profile and display
arg.gzPreOn = true;                 % prephase along kz by -mb/2*deltak
arg.plot = false;
arg.segmentRingdownTime = 120e-6;   % segment ringdown time for Pulseq on GE
arg.doRefScan = true;               % do EPI ghost reference scan in frame 1
arg.caipiPythonPath = '~/github/HarmonizedMRI/3DEPI/caipi/';

arg = toppe.utils.vararg_pair(arg, varargin);

warning('OFF', 'mr:restoreShape');

%% Define experimental parameters
sys = mr.opts('maxGrad', 40, 'gradUnit','mT/m', ...
              'maxSlew', 110, 'slewUnit', 'T/m/s', ...
              'rfDeadTime', 100e-6, ...
              'rfRingdownTime', 60e-6, ...
              'adcDeadTime', 20e-6, ...
              'adcRasterTime', 2e-6, ...
              'gradRasterTime', 10e-6, ...
              'blockDurationRaster', 10e-6, ...
              'B0', 3.0);

% reduced slew for spoilers
sys2 = mr.opts('maxGrad', 40, 'gradUnit','mT/m', ...
              'maxSlew', 60, 'slewUnit', 'T/m/s', ...
              'rfDeadTime', sys.rfDeadTime, ...
              'rfRingdownTime', sys.rfRingdownTime, ...
              'adcDeadTime', sys.adcDeadTime, ...
              'gradRasterTime', sys.gradRasterTime, ...
              'blockDurationRaster', sys.blockDurationRaster, ...
              'B0', sys.B0);

fov = voxelSize .* [nx ny nz];       % FOV (m)

if strcmp(type, 'SMS')
    slThick = fov(3)/nz;
else
    slThick = 0.85*fov(3);
end

dwell = 4e-6;                    % ADC sample time (s). For GE, must be multiple of 2us.

etl = 2*ceil(pf_ky*ny/Ry/2);   % echo train length. even

nCyclesSpoil = 2;    % number of spoiler cycles, along x and z
rfSpoilingInc = 117;                % RF spoiling increment (degrees)

if strcmp(type, 'SMS')
    rfTB  = 6;          % RF pulse time-bandwidth product
    rfDur = 8e-3;       % RF pulse duration (s)
else
    rfTB  = 8;          % RF pulse time-bandwidth product
    rfDur = 2e-3;       % RF pulse duration (s)
end

fatChemShift = 3.5*1e-6;                        % 3.5 ppm
fatOffresFreq = sys.gamma*sys.B0*fatChemShift;  % Hz


%% Create fat sat pulse 

fatsat.flip    = 90;      % degrees
fatsat.slThick = 1e5;     % dummy value (determines slice-select gradient, but we won't use it; just needs to be large to reduce dead time before+after rf pulse)
fatsat.tbw     = 3.5;     % time-bandwidth product
fatsat.dur     = 8.0;     % pulse duration (ms)

% RF waveform in Gauss
wav = toppe.utils.rf.makeslr(fatsat.flip, fatsat.slThick, fatsat.tbw, fatsat.dur, 1e-6, toppe.systemspecs(), ...
    'type', 'ex', ...    % fatsat pulse is a 90 so is of type 'ex', not 'st' (small-tip)
    'ftype', 'min', ...
    'writeModFile', false);

% Convert from Gauss to Hz, and interpolate to sys.rfRasterTime
rfp = rf2pulseq(wav, 4e-6, sys.rfRasterTime);

% Create pulseq object
% Try to account for the fact that makeArbitraryRf scales the pulse as follows:
% signal = signal./abs(sum(signal.*opt.dwell))*flip/(2*pi);
flip = fatsat.flip/180*pi;
flipAssumed = abs(sum(rfp));
rfsat = mr.makeArbitraryRf(rfp, ...
    flip*abs(sum(rfp*sys.rfRasterTime))*(2*pi), ...
    'system', sys);
rfsat.signal = rfsat.signal/max(abs(rfsat.signal))*max(abs(rfp)); % ensure correct amplitude (Hz)
rfsat.freqOffset = -440;  % Hz


%% Create excitation pulse
sysGE = toppe.systemspecs('maxGrad', sys.maxGrad/sys.gamma*100, ...   % G/cm
    'maxSlew', 0.7*sys.maxSlew/sys.gamma/10, ...           % G/cm/ms
    'maxRF', 0.25);
sliceSep = fov(3)/mb;   % center-to-center separation between SMS slices (m)
% freq = frequency offset (Hz) corresponding to a sliceSep
if strcmp(type, 'SMS')
    ftype = 'ls';
else
    ftype = 'min';
end
[rf, gzRF, freq] = getsmspulse(alpha, slThick, rfTB, rfDur, ...
    mb, sliceSep, sysGE, sys, ...
    'doSim', arg.simulateSliceProfile, ...    % Plot simulated SMS slice profile
    'type', 'st', ...     % SLR choice. 'ex' = 90 excitation; 'st' = small-tip
    'ftype', ftype);      % filter design. 'ls' = least squares

freq = freq/sliceSep*voxelSize(3); % frequency offset for z shift of voxelSize(3)



%% Get CAIPI sampling pattern (for one shot/echo train)

% create caipi.mat, and load it
pyFile = [arg.caipiPythonPath 'skippedcaipi_sampling.py'];
pyCmd = sprintf('python3 %s %d %d %d %d %d %d', ...
    pyFile, ny, nz, Ry, Rz, caipiShiftZ, 1);

if system(pyCmd) ~= 0
    fprintf('Open a terminal and run the following python command:\n\t%s\n', pyCmd);
    input('\tWhen done, press Enter to continue');
end

load caipi

% kz and ky indeces (multiples of deltak)
kyInds = double(indices((end-etl+1):end, 2));
kzInds = double(indices((end-etl+1):end, 1));

% ky/kz encoding blip amplitude along echo train (multiples of deltak)
kyStep = diff(kyInds);
kzStep = diff(kzInds);

kyStepMax = max(abs(kyStep));
kzStepMax = max(abs(kzStep));

%% Define readout gradients and ADC event
% The Pulseq toolbox really shines here!

deltak = 1./fov;

% Start with the blips
% Wrap in trap4ge.m so all times are on 20us boundary for accurate interpolation to 4us for GE
commonRasterTime = 20e-6;   
gyBlip = trap4ge(mr.makeTrapezoid('y', sys, 'Area', kyStepMax*deltak(2)), commonRasterTime, sys);
gzBlip = trap4ge(mr.makeTrapezoid('z', sys, 'Area', kzStepMax*deltak(3)), commonRasterTime, sys);

blipDuration = max(mr.calcDuration(gyBlip), mr.calcDuration(gzBlip));
maxBlipArea = max(gyBlip.area, gzBlip.area);

% Readout trapezoid
if isempty(arg.gro) 
    systmp = sys;
    systmp.maxGrad = deltak(1)/dwell;  % to ensure >= Nyquist sampling
    gro = trap4ge(mr.makeTrapezoid('x', systmp, 'Area', nx*deltak(1) + maxBlipArea), commonRasterTime, systmp);
else
    gro = arg.gro;
end

% ADC event
% Number of readout samples must be multiple of 4 (TODO: check if this is actually needed)
if isempty(arg.adc) 
    TreadTmp = mr.calcDuration(gro) - blipDuration;
    numSamplesTmp = ceil(TreadTmp/dwell);
    numSamples = ceil(numSamplesTmp/4)*4;
    Tread = numSamples*dwell;
    adc = mr.makeAdc(numSamples, sys, ...
        'Duration', Tread, ...
        'Delay', blipDuration/2);  % + dwell/2? TODO
else
    adc = arg.adc;
end

% Split blips at block boundary
[gyBlipUp, gyBlipDown] = mr.splitGradientAt(gyBlip, mr.calcDuration(gyBlip)/2);
gyBlipUp.delay = mr.calcDuration(gro) - mr.calcDuration(gyBlipUp);
gyBlipDown.delay = 0;

[gzBlipUp, gzBlipDown] = mr.splitGradientAt(gzBlip, mr.calcDuration(gzBlip)/2);
gzBlipUp.delay = mr.calcDuration(gro) - mr.calcDuration(gzBlipUp);
gzBlipDown.delay = 0;

% prephasers and spoilers
gxPre = trap4ge(mr.makeTrapezoid('x', sys, ...
    'Area', -gro.area/2), ...
    commonRasterTime, sys);
Tpre = mr.calcDuration(gxPre) + 4*commonRasterTime;
gyPre = trap4ge(mr.makeTrapezoid('y', sys, ...
    'Area', (kyInds(1)-ny/2)*deltak(2), ... 
    'Duration', Tpre-4*commonRasterTime), ...  % make a bit shorter than Tpre to ensure duration doesn't exceed Tpre after trap4ge
    commonRasterTime, sys);
if strcmp(type, 'SMS')
    area = -floor(mb/2)*deltak(3);
else
    area = nz/2*deltak(3);
end
gzPre = trap4ge(mr.makeTrapezoid('z', sys, ...
    'Area', area, ...
    'Duration', Tpre-commonRasterTime), ...   % make < Tpre to ensure duration doesn't exceed Tpre
    commonRasterTime, sys);
gxSpoil = mr.makeTrapezoid('x', sys2, ...
    'Area', -nx*deltak(1)*nCyclesSpoil);
gzSpoil = mr.makeTrapezoid('z', sys2, ...
    'Area', nx*deltak(1)*nCyclesSpoil);


%% Calculate delays to achieve desired TE and TR
kyIndAtTE = find(kyInds-ny/2 == min(abs(kyInds-ny/2)));
minTE = mr.calcDuration(gzRF) - mr.calcDuration(rf)/2 - rf.delay + mr.calcDuration(gxPre) + ...
        (kyIndAtTE-0.5) * mr.calcDuration(gro);
if TE < minTE
    error(sprintf('Requested TE < minimum TE (%d)', minTE));
end
TEdelay = floor((TE-minTE)/sys.blockDurationRaster) * sys.blockDurationRaster;

minTR = arg.fatsatOn*(mr.calcDuration(rfsat) + mr.calcDuration(gxSpoil)) + ...
    mr.calcDuration(gzRF) + TEdelay + mr.calcDuration(gxPre) + ...
    etl*mr.calcDuration(gro) + mr.calcDuration(gxSpoil);
if TR < np*minTR
    error(sprintf('Requested TR < minimum TR (%d)', np*minTR));
end
TRdelay = round((TR/np-minTR-arg.segmentRingdownTime)/sys.blockDurationRaster) * sys.blockDurationRaster;


%% Interleaved slice ordering for SMS
if strcmp(type, 'SMS')
    % if even number of shots, swap last two to reduce slice cross-talk
    IP = [1:2:np 2:2:np];
    if ~mod(np,2)
        % for np = even, change order of last two partitions/shots
        l = length(IP);
        IP = IP([1:(l-2) l l-1]);
    end
else
    IP = -nz/2:Rz:nz/2-1;
end

%% Assemble sequence
seq = mr.Sequence(sys);           

% temporal frame loop
rf_phase = 0;
rf_inc = 0;
msg = [];
for ifr = (1-nDummyFrames):nFrames

    for ii = 1:length(msg)
        fprintf('\b');
    end
    msg = sprintf('Frame %d of %d     ', ifr, nFrames);
    fprintf(msg);

    % dummy shots before turning on ADC, to reach steady state 
    isDummyShot = ifr < 1;

    % First frame is EPI calibration/reference scan (blips off)
    isRefShot = ifr == 1 & arg.doRefScan;

    % Segment ID (see 'Pulseq on GE' manual)
    segmentID = 3;
    if isDummyShot
        segmentID = 1;
    end
    if isRefShot
        segmentID = 2;
    end

    blipsOn = ~isDummyShot & ~isRefShot;

    % slice offset (partition/SMS group) loop
    for p = IP
        if strcmp(type, 'SMS')
            rf.freqOffset = round((p-np/2-1)*freq);  % frequency offset (Hz) for slice shift
        else
            rf.freqOffset = 0;
        end

        % Must label the first block in segment with segment ID. See Pulseq on GE manual.
        if arg.fatsatOn
            % fat sat
            rfsat.phaseOffset = rf_phase/180*pi;
            seq.addBlock(rfsat, mr.makeLabel('SET', 'LIN', segmentID));
            seq.addBlock(gxSpoil, gzSpoil);
            rf_inc = mod(rf_inc+rfSpoilingInc, 360.0);
            rf_phase = mod(rf_phase+rf_inc, 360.0);

            % excitation pulse
            rf.phaseOffset = rf_phase/180*pi;
            adc.phaseOffset = rf_phase/180*pi;
            seq.addBlock(rf, gzRF);
            rf_inc = mod(rf_inc+rfSpoilingInc, 360.0);
            rf_phase = mod(rf_phase+rf_inc, 360.0);
        else
            % excitation pulse
            rf.phaseOffset = rf_phase/180*pi;
            adc.phaseOffset = rf_phase/180*pi;
            seq.addBlock(rf, gzRF, mr.makeLabel('SET', 'LIN', segmentID));
            rf_inc = mod(rf_inc+rfSpoilingInc, 360.0);
            rf_phase = mod(rf_phase+rf_inc, 360.0);
        end

        % TE delay
        seq.addBlock(mr.makeDelay(TEdelay));

        % Readout
        %seq.addBlock(gxPre, gyPre, mr.scaleGrad(gzPre, 1 - 2/nz*(shot-1)));
        if strcmp(type, 'SMS')
            if caipiShiftZ > 0 & arg.gzPreOn
                seq.addBlock(gxPre, mr.scaleGrad(gyPre, blipsOn), mr.scaleGrad(gzPre, blipsOn));
            else
                seq.addBlock(gxPre, mr.scaleGrad(gyPre, blipsOn));
            end
        else
            seq.addBlock(gxPre, mr.scaleGrad(gyPre, blipsOn), mr.scaleGrad(gzPre, p/(nz/2)*blipsOn));
        end

        if isDummyShot
            seq.addBlock(gro, ...
                         mr.scaleGrad(gyBlipUp, blipsOn*kyStep(1)/max(kyStepMax,1)), ...
                         mr.scaleGrad(gzBlipUp, blipsOn*kzStep(1)/max(kzStepMax,1)));
        else
            seq.addBlock(gro, adc, ...
                         mr.scaleGrad(gyBlipUp, blipsOn*kyStep(1)/max(kyStepMax,1)), ...
                         mr.scaleGrad(gzBlipUp, blipsOn*kzStep(1)/max(kzStepMax,1)));
        end

        for ie = 2:(etl-1)
            % Example: 'gybdu' = Gy blip down up
            gybd = mr.scaleGrad(gyBlipDown, blipsOn*kyStep(ie-1)/max(kyStepMax,1));
            gybu = mr.scaleGrad(gyBlipUp,   blipsOn*kyStep(ie)/max(kyStepMax,1));
            gybdu = mr.addGradients({gybd, gybu}, sys);
            gzbd = mr.scaleGrad(gzBlipDown, blipsOn*kzStep(ie-1)/max(kzStepMax,1));
            gzbu = mr.scaleGrad(gzBlipUp,   blipsOn*kzStep(ie)/max(kzStepMax,1));
            gzbdu = mr.addGradients({gzbd, gzbu}, sys);
            if isDummyShot
                seq.addBlock(mr.scaleGrad(gro, (-1)^(ie-1)), gybdu, gzbdu);
            else
                seq.addBlock(adc, mr.scaleGrad(gro, (-1)^(ie-1)), gybdu, gzbdu);
            end
        end

        if isDummyShot
            seq.addBlock(mr.scaleGrad(gro, (-1)^(ie)), ...
                         mr.scaleGrad(gyBlipDown, blipsOn*kyStep(ie)/max(kyStepMax,1)), ...
                         mr.scaleGrad(gzBlipDown, blipsOn*kzStep(ie)/max(kzStepMax,1)));
        else
            seq.addBlock(adc, ...
                         mr.scaleGrad(gro, (-1)^(ie)), ...
                         mr.scaleGrad(gyBlipDown, blipsOn*kyStep(ie)/max(kyStepMax,1)), ...
                         mr.scaleGrad(gzBlipDown, blipsOn*kzStep(ie)/max(kzStepMax,1)));
        end

        % spoil. Disabling makes the k-space plot neater
        seq.addBlock(gxSpoil, gzSpoil);

        % TR delay
        seq.addBlock(mr.makeDelay(TRdelay));
    end
end
fprintf('\n');

%% Check sequence timing
[ok, error_report]=seq.checkTiming;
if (ok)
    fprintf('Timing check passed successfully\n');
else
    fprintf('Timing check failed! Error listing follows:\n');
    fprintf([error_report{:}]);
    fprintf('\n');
end

%% Write .seq file
if strcmp(type, 'SMS')
    fnStem = 'sms-epi';
else
    fnStem = '3d-epi';
end
seq.setDefinition('FOV', fov);
seq.setDefinition('Name', 'epi');
ofn = [fnStem '.seq'];
seq.write(ofn);       % Write to pulseq file

return

%% k-space trajectory calculation and plot
[ktraj_adc, t_adc, ktraj, t_ktraj, t_excitation, t_refocusing] = seq.calculateKspacePP();
figure; plot(ktraj(1,:),ktraj(2,:),'b'); % a 2D k-space plot
axis('equal'); % enforce aspect ratio for the correct trajectory display
hold;plot(ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % plot the sampling points
title('sms EPI, full k-space trajectory (k_x x k_y)');

% seq.plot('timeRange', [0 0.06]);

return

%% Optional slow step, but useful for testing during development,
%% e.g., for the real TE, TR or for staying within slewrate limits
% rep = seq.testReport;
% fprintf([rep{:}]);
