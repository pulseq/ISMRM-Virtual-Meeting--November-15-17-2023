waveformsandtimes__;  % get waveforms ax gx, gy, gz for entire sequence

% interpolate to regular raster
raster = 10e-6;
T = [gx.tt(1):raster:gx.tt(end)];  gx.waveform = interp1(gx.tt, gx.waveform, T); gx.tt = T;
T = [gy.tt(1):raster:gy.tt(end)];  gy.waveform = interp1(gy.tt, gy.waveform, T); gy.tt = T;
T = [gz.tt(1):raster:gz.tt(end)];  gz.waveform = interp1(gz.tt, gz.waveform, T); gz.tt = T;

return

lims = [0.05 0.087];
mask = gx.tt > lims(1) & gx.tt < lims(2);
gx.tt = gx.tt(mask);
gx.waveform = gx.waveform(mask);
mask = gy.tt > lims(1) & gy.tt < lims(2);
gy.tt = gy.tt(mask);
gy.waveform = gy.waveform(mask);
mask = gz.tt > lims(1) & gz.tt < lims(2);
gz.tt = gz.tt(mask);
gz.waveform = gz.waveform(mask);

g = [gx.waveform; gy.waveform; gz.waveform]/sys.gamma;   % T/m
gnorm = sqrt(sum(g.^2,1));

gslew = [zeros(3,1) diff(g,1,2)/raster];   % T/m/s
gnormslew = [0 diff(gnorm)/raster];   % T/m/s

T = gx.tt;
close all;
figure(1); title('Gradient amplitude, no rotation');
plot(T, g(1,:), 'r-'); hold on;
plot(T, g(2,:), 'g-');
plot(T, g(3,:), 'b-');
l = plot(T, gnorm, 'm-');
%set(l, 'linewidth', 1);
legend('gx', 'gy', 'gz');
xlabel('time (s)');
ylabel('mT/m');
print -dpng epi_amp_norot.png

% sagittal scan, in-plane rotation
R1 = [0 0 1; 0 1 0; 1 0 0];   % swap x a z
gr = R1*g;


