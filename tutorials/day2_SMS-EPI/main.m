%% Get MATLAB toolboxes

% Pulseq
system('git clone git@github.com:pulseq/pulseq.git');
addpath pulseq/matlab

% PulCeq (seq2ge.m)
system('git clone git@github.com:HarmonizedMRI/PulCeq.git');
addpath PulCeq/matlab

% toppe (needed by seq2ge.m, and we'll use toppe.plotseq() function)
system('git clone git@github.com:toppeMRI/toppe.git');
addpath toppe

% function for creating SMS RF event
system('git clone --branch develop git@github.com:HarmonizedMRI/SMS-EPI.git');
addpath SMS-EPI/sequence/Pulseq/   % getsmspulse.m, rf2pulseq.m

% path to skippedcaipi_sampling.py, for defining the ky-kz CAIPI sampling pattern
system('git clone git@github.com:HarmonizedMRI/3DEPI.git');
caipiPythonPath = './3DEPI/caipi/';


%% create multiband 6 SMS-EPI sequence files

% acquisition parameters
voxelSize = [2.4 2.4 2.4]*1e-3;   % m
nx = 90; ny = nx; nz = 60;
TE = 30e-3;                       % sec
alpha = 52;
pf_ky = (nx-3*6)/nx;

% Design sub-sequence containing 4 frames, to ensure that RF phase cycling (spoiling) 
% is not interrupted across runs (for rf_inc = 117).
mb = 6; Ry = 1; Rz = mb; caipiShiftZ = 2;
TR = 0.8;                      % volume TR (sec)
nDummyFrames = 0;
nFrames = 4;
writeEPI(voxelSize, [nx ny nz], TE, TR, alpha, mb, pf_ky, Ry, Rz, caipiShiftZ, nFrames, nDummyFrames, 'SMS', ...
    'caipiPythonPath', caipiPythonPath, ...
    'doRefScan', false);


%% Convert to .tar file and plot
np = nz/mb;                                   % number of partitions (shots per volume)
etl = 2*ceil(pf_ky*ny/Ry/2);                  % echo train length
sysGE = toppe.systemspecs('maxGrad', 5, ...   % G/cm
    'maxSlew', 20, ...                        % G/cm/ms
    'maxView', np*etl, ...           % Determines slice/view index in data file
    'adcDeadTime', 20);              % us. Half of 40us since applied both before + after ADC window.

fnStem = 'sms-epi';
ofn = [fnStem '.tar'];
seq2ge([fnStem '.seq'], sysGE, [fnStem '.tar']);

% add caipi.mat to the .tar file (needed in reconstruction)
system(sprintf('tar --append --file=%s caipi.mat', ofn));

% Untar file so that toppe.plotseq() can 'see' the scan files, then plot.
system(sprintf('tar xf %s', ofn));
nBlocksPerTR = 79;
toppe.plotseq(sysGE, 'blockRange', [1 nBlocksPerTR]);  % Should match Pulse View

return;
