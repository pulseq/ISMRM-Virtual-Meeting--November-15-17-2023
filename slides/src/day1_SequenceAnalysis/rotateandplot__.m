waveformsandtimes__;  % get waveforms ax gx, gy, gz for entire sequence

% interpolate to regular raster
raster = 10e-6;
T = [gx.tt(1):raster:gx.tt(end)];  
gx.waveform = interp1(gx.tt, gx.waveform, T); gx.tt = T;
gy.waveform = interp1(gy.tt, gy.waveform, T); gy.tt = T;
gz.waveform = interp1(gz.tt, gz.waveform, T); gz.tt = T;

lims = [0.019 0.029];  % time window to plot
mask = gx.tt > lims(1) & gx.tt < lims(2);
gx.tt = gx.tt(mask);
gx.waveform = gx.waveform(mask);
mask = gy.tt > lims(1) & gy.tt < lims(2);
gy.tt = gy.tt(mask);
gy.waveform = gy.waveform(mask);
mask = gz.tt > lims(1) & gz.tt < lims(2);
gz.tt = gz.tt(mask);
gz.waveform = gz.waveform(mask);

g = [gx.waveform; gy.waveform; gz.waveform]/sys.gamma*1e3;   % mT/m
gnorm = sqrt(sum(g.^2,1));

T = gx.tt;
close all;
figure(1); title('Gradient amplitude, no rotation');
plot(T, g(1,:), 'm-'); hold on;
plot(T, g(2,:), 'g-');
plot(T, g(3,:), 'b-');
xlabel('time (s)');
ylabel('mT/m');
legend('gx', 'gy', 'gz');
axis([T(1) T(end) 1.2*min(g(:)) 1.1*max(gnorm(:))]);
legend('gx', 'gy', 'gz', 'Location', 'northwest');
print -dpng amp_norot.png

l = plot(T, gnorm, 'r-');
set(l, 'linewidth', 2);
legend('gx', 'gy', 'gz', 'combined (norm)', 'Location', 'northwest');
print -dpng amp_norot_norm.png
hold off

% do the same thing for slew
close all
gslew = [zeros(3,1) diff(g*1e-3,1,2)/raster];   % T/m/s
gslewnorm = [0 diff(gnorm*1e-3)/raster];   % T/m/s
plot(T, gslew(1,:), 'm-'); hold on;
plot(T, gslew(2,:), 'g-');
plot(T, gslew(3,:), 'b-');
xlabel('time (s)');
ylabel('T/m/s');
legend('gx', 'gy', 'gz');
axis([T(1) T(end) 1.2*min(gslew(:)) 1.1*max(gslewnorm(:))]);
legend('gx', 'gy', 'gz', 'Location', 'northwest');
print -dpng slew_norot.png

l = plot(T, gslewnorm, 'r-');
set(l, 'linewidth', 2);
legend('gx', 'gy', 'gz', 'combined (norm)', 'Location', 'northwest');
print -dpng slew_norot_norm.png
hold off

return
% ran out of time here

% sagittal scan with in-plane rotation
R1 = [0 0 1; 0 1 0; 1 0 0];   % swap x and z
th = 45/180*pi;  % in plane rotation angle
R2 = [cos(th) -sin(th) 0; sin(th) cos(th) 0; 0 0 1];
grot = R2*R1*g;
title('Gradient amplitude, with rotation');
plot(T, grot(1,:), 'm-'); hold on;
plot(T, grot(2,:), 'g-');
plot(T, grot(3,:), 'b-');
xlabel('time (s)');
ylabel('mT/m');
legend('gx', 'gy', 'gz');
axis([T(1) T(end) 1.2*min(g(:)) 1.1*max(gnorm(:))]);
legend('gx', 'gy', 'gz', 'Location', 'northwest');
print -dpng amp_rot.png
return

grotnorm = sqrt(sum(grot.^2,1));
l = plot(T, gnorm, 'r-');
set(l, 'linewidth', 1);
legend('gx', 'gy', 'gz', 'combined (norm)', 'Location', 'northwest');
print -dpng amp_rot_norm.png
