sysGE = toppe.systemspecs('maxGrad', 5, 'maxSlew', 20);

% Convert .seq file to GE scan files
seq2ge('gre2d.seq', sysGE, 'gre2d.tar');  

% Untar scan files to current working directory
system('tar xf gre2d.tar');  

% Simulate and plot PNS waveform
p = toppe.calcsequencepns(sysGE, 'timeRange', [0 0.03]);
