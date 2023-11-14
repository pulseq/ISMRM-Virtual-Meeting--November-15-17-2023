%% Pulseq tutorial for ISMRM virtual meeting 15.11.2023
% Build a simplest free induction decay (FID) sequence
clear ; close all; clc ;
%% Define system properties
system = mr.opts('rfRingdownTime', 20e-6, 'rfDeadTime', 100e-6, ...
                 'adcDeadTime', 20e-6) ;

%% Create a new sequence object
seq = mr.Sequence(system) ;

%% Set sequence parameters
Nrep = 1 ;% number of repetitions
Nx = 6400 ; % number of samples
adcDur = 256e-3 ; % ADC duration
rfDur = 500e-6 ; % RF duration
TR = 500e-3 ; % unit: s
TE = 30e-3 ; % unit: s

%% Create a non-selective pulse 
rf_ex = mr.makeBlockPulse(pi/2, 'Duration', rfDur, 'system', system) ;
    
%% Define delays and ADC events
adc = mr.makeAdc(Nx,'Duration',adcDur, 'system', system) ;

delayTE = TE - rf_ex.shape_dur/2 - rf_ex.ringdownTime - adc.delay ;
delayTR = TR - mr.calcDuration(rf_ex) - delayTE - mr.calcDuration(adc) ;
assert(delayTE >= 0) ;
assert(delayTR >= 0) ;

%% Loop over repetitions and define sequence blocks
for i = 1:Nrep
    seq.addBlock(rf_ex) ;
    seq.addBlock(mr.makeDelay(delayTE)) ;
    seq.addBlock(adc) ;
    seq.addBlock(mr.makeDelay(delayTR)) ;
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

seq.write('fid.seq')       % Write to pulseq file

%% Plot sequence diagram
seq.plot() ;

%% plot k-spaces
% k-space trajectory calculation
[ktraj_adc, t_adc, ktraj, t_ktraj, t_excitation, t_refocusing] = seq.calculateKspacePP();
figure; plot(ktraj(1,:),ktraj(2,:),'b'); % a 2D plot
axis('equal'); % enforce aspect ratio for the correct trajectory display
hold;plot(ktraj_adc(1,:),ktraj_adc(2,:),'r.'); % plot the sampling points

