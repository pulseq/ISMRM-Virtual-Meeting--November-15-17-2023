%% ISMRM virtual meeting 15.11.2023
% Build a 2D GRE sequence with optimized spoiler
clear all; close all; clc ;

%% set system limits and parameters
sys = mr.opts('MaxGrad', 22, 'GradUnit', 'mT/m', ...
    'MaxSlew', 120, 'SlewUnit', 'T/m/s', ...
    'rfRingdownTime', 20e-6, 'rfDeadTime', 100e-6, 'adcDeadTime', 20e-6) ;

seq = mr.Sequence(sys) ;           % Create a new sequence object
fov = 256e-3 ; Nx = 256 ; Ny = 256 ;     % Define FOV and resolution
alpha = 10 ;                       % flip angle
sliceThickness = 3e-3 ;            % slice
TR = 20e-3 ;                       % repetition time TR
TE = 6e-3 ;                        % echo time TE
roDuration = 5.12e-3 ;              % ADC duration

%% Create alpha-degree slice selection pulse and gradient
[rf, gz] = mr.makeSincPulse(alpha*pi/180,'Duration',3e-3,...
    'SliceThickness',sliceThickness,'apodization',0.42,'timeBwProduct',4,'system',sys);

%% Define other gradients and ADC events
deltak = 1/fov ;
gx = mr.makeTrapezoid('x','FlatArea',Nx*deltak,'FlatTime',roDuration,'system',sys) ;
adc = mr.makeAdc(Nx,'Duration',gx.flatTime,'Delay',gx.riseTime,'system',sys) ;
gxPre = mr.makeTrapezoid('x','Area',-gx.amplitude*(adc.dwell*(adc.numSamples/2+0.5)+0.5*gx.riseTime),...
    'Duration',1e-3,'system',sys) ;
gzReph = mr.makeTrapezoid('z','Area',-gz.area/2,'Duration',1e-3,'system',sys) ;
phaseAreas = ((0:Ny-1) - Ny/2) * deltak ;
gy = mr.makeTrapezoid('y','Area',max(abs(phaseAreas)),'Duration',mr.calcDuration(gxPre),'system',sys) ;
peScales = phaseAreas/gy.area ;
clear gyPre gyReph ;
for iY = 1:Ny
    gyPre(iY) = mr.scaleGrad(gy, peScales(iY)) ;
    gyReph(iY) = mr.scaleGrad(gy, -peScales(iY)) ;
end
%% gradient spoiling
% we cut the RO gradient into two parts for the optimal spoiler timing
[gx1, ~] = mr.splitGradientAt(gx, gx.riseTime + gx.flatTime) ;
% gradient spoiling
gxSpoil = mr.makeExtendedTrapezoidArea(gx.channel, gx.amplitude, 0, 2*Nx*deltak, sys) ;
gxSpoil.delay = mr.calcDuration(gx1) ;
gx_add = mr.addGradients({gx1, gxSpoil},'system',sys) ;

gzSpoil = mr.makeTrapezoid('z','Area',4/sliceThickness,'system',sys) ;
gzSpoil.delay = max(mr.calcDuration(gx1), gzSpoil.delay) ;

for iY = 1:Ny
    gyReph(iY).delay = max(mr.calcDuration(gx1), gyReph(iY).delay) ;
end

%% Calculate timing
delayTE = ceil((TE - mr.calcDuration(gxPre) - gz.fallTime - gz.flatTime/2 ...
    - mr.calcDuration(gx)/2)/seq.gradRasterTime) * seq.gradRasterTime ;
delayTR = ceil((TR - mr.calcDuration(gz) - mr.calcDuration(gxPre) ...
    - mr.calcDuration(gx_add, gzSpoil, gyReph) - delayTE)/seq.gradRasterTime)*seq.gradRasterTime ;
assert(delayTE >= 0 ) ;
assert(delayTR >= 0 ) ;

%% Loop over phase encodes and define sequence blocks
tic ;
for i=1:Ny
    % RF spoiling (vary RF phase pseudo-randomly)
    rand_phase = mod(117*(i^2 + i + 2), 360) * pi/180 ;
    rf.phaseOffset = rand_phase ;
    adc.phaseOffset = rand_phase ;
    %
    seq.addBlock(rf, gz) ;
    seq.addBlock(gxPre, gyPre(i), gzReph) ;
    seq.addBlock(mr.makeDelay(delayTE)) ;
    seq.addBlock(gx_add, adc, gzSpoil, gyReph(i) ) ;
    seq.addBlock(mr.makeDelay(delayTR) ) ;
end
toc ;

%% check whether the timing of the sequence is correct
[ok, error_report]=seq.checkTiming;

if (ok)
    fprintf('Timing check passed successfully\n');
else
    fprintf('Timing check failed! Error listing follows:\n');
    fprintf([error_report{:}]);
    fprintf('\n');
end

%% prepare sequence export
seq.setDefinition('FOV', [fov fov sliceThickness]);
seq.setDefinition('Name', 'gresp');

seq.write('gresp.seq')       % Write to pulseq file

%% plot sequence and k-space diagrams

seq.plot('timeRange', [0 5]*TR);

% k-space trajectory calculation
[ktraj_adc, t_adc, ktraj, t_ktraj, t_excitation, t_refocusing] = seq.calculateKspacePP();

% plot k-spaces
figure; plot(ktraj(1,:),ktraj(2,:),'b'); % a 2D plot
axis('equal'); % enforce aspect ratio for the correct trajectory display
hold;plot(ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % plot the sampling points



