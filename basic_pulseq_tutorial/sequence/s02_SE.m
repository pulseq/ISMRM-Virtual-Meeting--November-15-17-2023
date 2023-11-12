%% Pulseq tutorial for ISMRM virtual meeting 15.11.2023. Qingping Chen
% Build a spin echo sequence
clear ; close all; clc ;
%% Define system properties
system = mr.opts('rfRingdownTime', 20e-6, 'rfDeadTime', 100e-6, ...
                 'adcDeadTime', 20e-6) ;

%% Create a new sequence object
seq = mr.Sequence(system) ;

%% Set sequence parameters
Nrep = 1 ;% number of repetitions
Nx = 6400 ; % number of samples
adcDur = 128e-3 ; % ADC duration
rfDur = 1000e-6 ; % RF duration
TR = 500e-3 ; % unit: s
TE = 200e-3 ; % unit: s

%% Create a non-selective and refocusing pulse 
rf_ex = mr.makeBlockPulse(pi/2, 'Duration', rfDur, 'system', system) ;
rf_ref = mr.makeBlockPulse(pi,'Duration',rfDur, 'system', system, 'use', 'refocusing') ;
%% Define delays and ADC events
delayTE1 = TE/2 - rf_ex.shape_dur/2 - rf_ex.ringdownTime - rf_ref.delay...
    - rf_ref.shape_dur/2 ;
delayTE2 = TE/2 - rf_ref.shape_dur/2 - rf_ref.ringdownTime - adcDur / 2 ;
adc = mr.makeAdc(Nx,'Duration',adcDur, 'system', system, 'delay', delayTE2);
delayTR = TR - mr.calcDuration(rf_ex) - delayTE1 - mr.calcDuration(rf_ref) - mr.calcDuration(adc) ;
assert(delayTE1 >= 0) ;
assert(delayTE2 >= 0) ;
assert(delayTR >= 0) ;

%% Loop over repetitions and define sequence blocks
for i = 1:Nrep
    seq.addBlock(rf_ex) ;
    seq.addBlock(mr.makeDelay(delayTE1) ) ;
    seq.addBlock(rf_ref) ;
    seq.addBlock(adc) ;
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

seq.write('se.seq')       % Write to pulseq file

%% Plot sequence diagram
seq.plot() ;

%% plot k-spaces
figure; plot(ktraj(1,:),ktraj(2,:),'b'); % a 2D plot
axis('equal'); % enforce aspect ratio for the correct trajectory display
hold;plot(ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % plot the sampling points