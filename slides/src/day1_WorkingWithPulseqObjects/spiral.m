gamp = 12;                        % mT/m
raster = 10e-6;                   % gradient raster time, sec
n = 104;                          % gradient samples
ncyc = 2;                        % number of spiral turns
tt = raster/2:raster:n*raster;
dur = n*raster;
lam = n/ncyc;
wav = gamp*[(0.5:n)/n].*sin(2*pi*tt/raster/lam);
plot(tt,wav,'-o');
