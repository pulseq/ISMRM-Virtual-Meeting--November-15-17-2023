Nx = 256; 
fov = 240e-3;     % m
dwell = 4e-6;     % sec
deltak = 1/fov;
gx = mr.makeTrapezoid('x', 'FlatArea', Nx*deltak, 'FlatTime', Nx*dwell, ...
                      'delay', 200e-6, 'system', sys);
