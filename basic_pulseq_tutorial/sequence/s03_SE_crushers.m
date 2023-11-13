%% Pulseq tutorial for ISMRM virtual meeting 15.11.2023. Qingping Chen
% Build a spin echo sequence with a pair of crushers
clear ; close all; clc ;
%% Define system properties
system = mr.opts('MaxGrad',32,'GradUnit','mT/m',...
    'MaxSlew',130,'SlewUnit','T/m/s',...
    'rfRingdownTime', 20e-6, 'rfDeadtime', 100e-6,...
    'adcDeadTime', 20e-6, 'B0', 2.89 ... % this is Siemens' 3T
);
%% Create a new sequence object
seq = mr.Sequence(system) ;

%% Set sequence parameters
Nrep = 1 ;% number of repetitions
Nx = 6400 ; % number of samples
adcDur = 128e-3 ; % ADC duration
rfDur = 1000e-6 ; % RF duration
TR = 500e-3 ; % unit: s
TE = 200e-3 ; % unit: s
spA = 1000; % spoiler area in 1/m (=Hz/m*s)
%% Create a non-selective and refocusing pulse 
rf_ex = mr.makeBlockPulse(pi/2, 'Duration', rfDur, 'system', system) ;
rf_ref = mr.makeBlockPulse(pi,'Duration',rfDur, 'system', system, 'use', 'refocusing') ;
%% calculate spoiler gradient
g_sp = mr.makeTrapezoid('z','Area',spA,'system',system) ;
rf_ref.delay = max(mr.calcDuration(g_sp), rf_ref.delay) ;
%% Define delays and ADC events
delayTE1 = TE/2 - rf_ex.shape_dur/2 - rf_ex.ringdownTime - rf_ref.delay...
    - rf_ref.shape_dur/2 ;
delayTE2 = TE/2 - rf_ref.shape_dur/2 - rf_ref.ringdownTime - adcDur / 2 ;
adc = mr.makeAdc(Nx,'Duration',adcDur, 'system', system, 'delay', delayTE2) ;
delayTR = TR - mr.calcDuration(rf_ex) - delayTE1 - mr.calcDuration(rf_ref) - mr.calcDuration(adc) ;
assert(delayTE1 >= 0) ;
assert(delayTE2 >= 0) ;
assert(delayTR >= 0) ;
assert(delayTE2 > mr.calcDuration(g_sp)) ; %% ADC delay > g_sp

%% Loop over repetitions and define sequence blocks
for i = 1:Nrep
    seq.addBlock(rf_ex) ;
    seq.addBlock(mr.makeDelay(delayTE1) ) ;
    seq.addBlock(rf_ref, g_sp) ;
    seq.addBlock(adc, g_sp) ;
    seq.addBlock(mr.makeDelay(delayTR) ) ;
end

%% Check whether the timing of the sequence is compatible with the scanner
[ok, error_report]=seq.checkTiming;

if (ok)
    fprintf('Timing check passed successfully\n');
else
    fprintf('Timing check failed! Error listing follows:\n');
    fprintf([error_report{:}]);
    fprintf('\n');
end

seq.write('secrush.seq')       % Write to pulseq file

%% Plot sequence diagram
seq.plot() ;

[ktraj_adc, t_adc, ktraj, t_ktraj, t_excitation, t_refocusing] = seq.calculateKspacePP();

%% plot k-spaces
figure; plot(ktraj(1,:),ktraj(2,:),'b'); % a 2D plot
axis('equal'); % enforce aspect ratio for the correct trajectory display
hold;plot(ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % plot the sampling points

