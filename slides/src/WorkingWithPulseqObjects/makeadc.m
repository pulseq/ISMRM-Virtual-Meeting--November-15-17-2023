
Nx = 256;
dwell = 4e-6;   % sec
adc = mr.makeAdc(Nx, 'Duration', Nx*dwell, 'Delay', 0.2e-3, 'system', sys);
