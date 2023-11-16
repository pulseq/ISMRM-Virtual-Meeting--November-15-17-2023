% writeB0.m
%
% 3D GRE B0 mapping sequence. Uses parameters defined in 'main.m',
% except increases FOV.

% RF/gradient delay (sec). 
% Conservative choice that should work across all GE scanners.
psd_rf_wait = 200e-6;  

% System/design parameters.
% Here we extend rfRingdownTime by psd_rf_wait to ensure that 
% the subsequent wait pulse (delay block) doesn't overlap with
% the 'true' RF ringdown time (54 us).
sys = mr.opts('maxGrad', 40, 'gradUnit','mT/m', ...
              'maxSlew', 150, 'slewUnit', 'T/m/s', ...
              'rfDeadTime', 100e-6, ...
              'rfRingdownTime', 60e-6 + psd_rf_wait, ...
              'adcDeadTime', 40e-6, ...
              'adcRasterTime', 2e-6, ...
              'blockDurationRaster', 10e-6, ...
              'B0', 3.0);

% Acquisition parameters
nx = 100; ny = nx; nz = 100;    % Matrix size. Make large enough to avoid foldover
fov = voxelSize.*[nx ny nz];
dwell = 10e-6;                  % ADC sample time (s)
alpha = 4;                      % flip angle (degrees)
fatChemShift = 3.5e-6;          % 3.5 ppm
fatOffresFreq = sys.gamma*sys.B0*fatChemShift;  % Hz
TE = 1/fatOffresFreq*[1 2];     % fat and water in phase for both echoes
TR = 6e-3*[1 1];                % constant TR

% Sequence parameters
alphaPulseDuration = 0.2e-3;
rfSpoilingInc = 117;            % RF spoiling increment
nCyclesSpoil = 2;               % number of spoiler cycles
Tpre = 1.0e-3;                  % prephasing trapezoid duration

% Acquisition parameters

% Create a new sequence object
seq = mr.Sequence(sys);           

% Create non-selective pulse
[rf] = mr.makeBlockPulse(alpha/180*pi, sys, 'Duration', alphaPulseDuration);

% Define other gradients and ADC events
% Cut the redaout gradient into two parts for optimal spoiler timing
deltak = 1./fov;
Tread = nx*dwell;

commonRasterTime = 20e-6;   

gyPre = trap4ge(mr.makeTrapezoid('y', sys, ...
    'Area', ny*deltak(2)/2, ...   % PE1 gradient, max positive amplitude
    'Duration', Tpre), ...
    commonRasterTime, sys);
gzPre = trap4ge(mr.makeTrapezoid('z', sys, ...
    'Area', nz/2*deltak(3), ...   % PE2 gradient, max amplitude
    'Duration', Tpre), ...
    commonRasterTime, sys);

gxtmp = mr.makeTrapezoid('x', sys, ...  % readout trapezoid, temporary object
    'Amplitude', nx*deltak(1)/Tread, ...
    'FlatTime', Tread);
gxPre = trap4ge(mr.makeTrapezoid('x', sys, ...
    'Area', -gxtmp.area/2, ...
    'Duration', Tpre), ...
    commonRasterTime, sys);

adc = mr.makeAdc(nx, sys, ...
    'Duration', Tread,...
    'Delay', gxtmp.riseTime);

% extend flat time so we can split at end of ADC dead time
gxtmp2 = trap4ge(mr.makeTrapezoid('x', sys, ...  % temporary object
    'Amplitude', nx*deltak(1)/Tread, ...
    'FlatTime', Tread + adc.deadTime), ...
    commonRasterTime, sys);
[gx, ~] = mr.splitGradientAt(gxtmp2, gxtmp2.riseTime + gxtmp2.flatTime);
%gx = gxtmp;

gzSpoil = mr.makeTrapezoid('z', sys, ...
    'Area', nx*deltak(1)*nCyclesSpoil);
gxSpoil = mr.makeExtendedTrapezoidArea('x', gxtmp.amplitude, 0, gzSpoil.area, sys);
%gxSpoil = mr.makeTrapezoid('x', sys, ...
%    'Area', nx*deltak(1)*nCyclesSpoil);

%% y/z PE steps
pe1Steps = ((0:ny-1)-ny/2)/ny*2;
pe2Steps = ((0:nz-1)-nz/2)/nz*2;

%% Calculate timing
TEmin = rf.shape_dur/2 + rf.ringdownTime + mr.calcDuration(gxPre) ...
      + adc.delay + nx/2*dwell;
delayTE = ceil((TE-TEmin)/seq.gradRasterTime)*seq.gradRasterTime;
TRmin = mr.calcDuration(rf) + delayTE + mr.calcDuration(gxPre) ...
      + mr.calcDuration(gx) + mr.calcDuration(gxSpoil);
delayTR = ceil((TR-TRmin)/seq.gradRasterTime)*seq.gradRasterTime;

%% Loop over phase encodes and define sequence blocks
% iZ < 0: Dummy shots to reach steady state
% iZ = 0: ADC is turned on and used for receive gain calibration on GE scanners
% iZ > 0: Image acquisition

nDummyZLoops = 1;
rf_phase = 0;
rf_inc = 0;

lastmsg = [];
for iZ = -nDummyZLoops:nz
    isDummyTR = iZ < 0;

    for ii = 1:length(lastmsg)
        fprintf('\b');
    end
    msg = sprintf('z encode %d of %d   ', iZ, nz);
    fprintf(msg);
    lastmsg = msg;

    for iY = 1:ny
        % Turn on y and z prephasing lobes, except during dummy scans and
        % receive gain calibration (auto prescan)
        yStep = (iZ > 0) * pe1Steps(iY);
        zStep = (iZ > 0) * pe2Steps(max(1,iZ));

        for c = 1:length(TE)

            % RF spoiling
            rf.phaseOffset = rf_phase/180*pi;
            adc.phaseOffset = rf_phase/180*pi;
            rf_inc = mod(rf_inc+rfSpoilingInc, 360.0);
            rf_phase = mod(rf_phase+rf_inc, 360.0);
            
            % Excitation
            % Mark start of segment (block group) by adding label.
            % Subsequent blocks in block group are NOT labelled.
            seq.addBlock(rf, mr.makeLabel('SET', 'LIN', 2-isDummyTR));
            
            % Encoding
            seq.addBlock(mr.makeDelay(delayTE(c)));
            seq.addBlock(gxPre, ...
                mr.scaleGrad(gyPre, yStep), ...
                mr.scaleGrad(gzPre, zStep));
            if isDummyTR
                seq.addBlock(gx);
            else
                seq.addBlock(gx, adc);
            end

            % rephasing/spoiling
            seq.addBlock(gxSpoil, ...
                mr.scaleGrad(gyPre, -yStep), ...
                mr.scaleGrad(gzPre, -zStep));
            seq.addBlock(mr.makeDelay(delayTR(c)));
        end
    end
end
fprintf('Sequence ready\n');

%% Check sequence timing
[ok, error_report]=seq.checkTiming;
if (ok)
    fprintf('Timing check passed successfully\n');
else
    fprintf('Timing check failed! Error listing follows:\n');
    fprintf([error_report{:}]);
    fprintf('\n');
end

%% Output for execution
seq.setDefinition('FOV', fov);
seq.setDefinition('Name', 'b0');
seq.write('b0.seq');

%% Plot sequence
Noffset = length(TE)*ny*(nDummyZLoops+1);
seq.plot('timerange',[Noffset Noffset+4]*TR(1), 'timedisp', 'ms');


%% Convert to .tar file for GE

sysGE = toppe.systemspecs('maxGrad', 5, ...   % G/cm
    'maxSlew', 20, ...               % G/cm/ms
    'maxRF', 0.125, ...               % Gauss. Must be >= peak RF in sequence.
    'maxView', ny, ...               % Determines slice/view index in data file
    'rfDeadTime', 100, ...           % us
    'rfRingdownTime', 60, ...        % us
    'adcDeadTime', 40, ...           % us
    'psd_rf_wait', 148, ...          % RF/gradient delay (us)
    'psd_grd_wait', 156);            % ADC/gradient delay (us)

seq2ge('b0.seq', sysGE, 'b0.tar');
