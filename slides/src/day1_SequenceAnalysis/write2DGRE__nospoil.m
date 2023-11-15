% write2DGRE__nospoil.m
% Remove spoilers to get cleaner k-space plot
%
% 2D spoiled GRE demo sequence from Pulseq on GE User Guide.
% Similar to writeGradientEcho.m from Pulseq demoSeq folder.

% System/design parameters.
% Reduce gradients by 1/sqrt(3) to allow for oblique scans.
% Reduce slew a bit further to reduce PNS.
sys = mr.opts('maxGrad', 50/sqrt(3), 'gradUnit','mT/m', ...
              'maxSlew', 120/sqrt(3), 'slewUnit', 'T/m/s', ...
              'rfDeadTime', 100e-6, ...
              'rfRingdownTime', 60e-6, ...
              'adcDeadTime', 40e-6, ...
              'adcRasterTime', 2e-6, ...
              'blockDurationRaster', 10e-6, ...
              'B0', 3.0);

% Create a new sequence object
seq = mr.Sequence(sys);             

% Acquisition parameters
fov = 180e-3; Nx = 32; Ny = 32;     % FOV and resolution
sliceThickness = 5e-3;              % slice thickness (m)
alpha = 6;                          % flip angle (degrees)
TR = 10e-3;                         % repetition time TR (s)
TE = 5e-3;                          % echo time TE (s) 
dwell = 10e-6;                      % ADC sample time (s)
rfSpoilingInc = 117;                % RF spoiling increment

% Create alpha-degree slice selection pulse and gradient
[rf, gz] = mr.makeSincPulse(alpha*pi/180, 'Duration', 3e-3, ...
    'SliceThickness', sliceThickness, 'apodization', 0.42, ...
    'timeBwProduct', 4, 'system', sys);

% Define other gradients and ADC events
deltak = 1/fov;
gx = mr.makeTrapezoid('x', 'FlatArea', Nx*deltak, 'FlatTime', Nx*dwell, 'system', sys);
adc = mr.makeAdc(Nx, 'Duration', gx.flatTime, 'Delay', gx.riseTime, 'system', sys);
gxPre = mr.makeTrapezoid('x', 'Area', -gx.area/2, 'Duration', 1e-3, 'system',sys);
gzReph = mr.makeTrapezoid('z', 'Area', -gz.area/2, 'Duration', 1e-3, 'system', sys);
phaseAreas = ((0:Ny-1)-Ny/2)*deltak;
gyPre = mr.makeTrapezoid('y', 'Area', max(abs(phaseAreas)), ...
    'Duration', mr.calcDuration(gxPre), 'system', sys);
peScales = phaseAreas/gyPre.area;
gxSpoil = mr.makeTrapezoid('x', 'Area', 2*Nx*deltak, 'system', sys);
gzSpoil = mr.makeTrapezoid('z', 'Area', 4/sliceThickness, 'system', sys);

% Calculate timing
delayTE = ceil((TE - mr.calcDuration(gx)/2 - mr.calcDuration(gxPre) - ...
    gz.fallTime - gz.flatTime/2)/seq.gradRasterTime)*seq.gradRasterTime;
delayTR = ceil((TR - mr.calcDuration(gxSpoil, gzSpoil) ...
    - mr.calcDuration(gx)/2 - TE ...
    - gz.flatTime/2 - gz.riseTime)/seq.gradRasterTime)*seq.gradRasterTime;
assert(all(delayTE >= 0));
assert(all(delayTR >= mr.calcDuration(gxSpoil, gzSpoil)));

% Loop over phase encodes and define sequence blocks
% iY < 1        Dummy shots to reach steady state
% iY > 0        Image acquisition

nDummyShots = 0;  % dummy shots to reach steady state

rf_phase = 0;
rf_inc = 0;

for iY = (-nDummyShots+1):Ny
    isDummyTR = iY < 1;

    % RF spoiling
    rf.phaseOffset = rf_phase/180*pi;
    adc.phaseOffset = rf_phase/180*pi;
    rf_inc = mod(rf_inc+rfSpoilingInc, 360.0);
    rf_phase = mod(rf_phase+rf_inc, 360.0);
    
    % Excitation block
    % Mark start of segment (block group) by adding label.
    % Subsequent blocks in block group are NOT labelled.
    seq.addBlock(rf, gz, mr.makeLabel('SET', 'LIN', 2-isDummyTR));

    % Slice-select refocus and readout prephasing
    % Set phase-encode gradients to zero while iY < 1
    pesc = (iY>0) * peScales(max(iY,1));  % phase-encode gradient scaling
    seq.addBlock(gxPre, mr.scaleGrad(gyPre, pesc), gzReph);
    seq.addBlock(mr.makeDelay(delayTE));

    % ADC
    if isDummyTR
        seq.addBlock(gx);
    else
        seq.addBlock(gx, adc);
    end

    % Spoil and PE rephasing, and TR delay
    seq.addBlock(mr.scaleGrad(gyPre, -pesc));
    seq.addBlock(mr.makeDelay(delayTR));
end

%% Check sequence timing
[ok, error_report] = seq.checkTiming;
if (ok)
    fprintf('Timing check passed successfully\n');
else
    fprintf('Timing check failed! Error listing follows:\n');
    fprintf([error_report{:}]);
    fprintf('\n');
end

%% Output for execution and plot
seq.setDefinition('FOV', [fov fov sliceThickness]);
seq.setDefinition('Name', 'gre2d');
seq.write('gre2d.seq')       % Write to pulseq file

%% Optional slow step, but useful for testing during development,
%% e.g., for the real TE, TR or for staying within slewrate limits  
%rep = seq.testReport;
%fprintf([rep{:}]);
