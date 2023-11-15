setsys;

% create arbitrary gradient event 'gx'
gamp = 1;                        % mT/m
raster = 10e-6;                   % gradient raster time, sec
n = 20;                          % gradient samples
ncyc = 1;                        % number of spiral turns
tt = raster/2:raster:n*raster;
dur = n*raster;
lam = n/ncyc;
wav = gamp*[(0.5:n)/n].*sin(2*pi*tt/raster/lam);
gx = mr.makeArbitraryGrad('x', wav*sys.gamma/1e3, 'delay', 200e-6);
gx.first = 0;
gx.last = 0;

tt = gx.delay + gx.tt;
wav = gx.waveform;
n = length(tt);

% plot samples
hold off
h = plot(gx.delay + gx.tt, gx.waveform, 'o');
hold on
set(h, 'MarkerSize', 8, 'MarkerFaceColor', 'black');
axis([tt(1)-sys.gradRasterTime tt(end)+sys.gradRasterTime 1.1*min(wav) 0.5e5]);
xlabel('time (s)');
ylabel('gradient amplitude (Hz/m)');

% plot first and last
l = plot(tt(1) - sys.gradRasterTime/2, gx.first, 'o');
set(l, 'MarkerSize', 8, 'MarkerFaceColor', 'red');
f = plot(tt(end) + sys.gradRasterTime/2, gx.last, 'rx');
set(f, 'MarkerSize', 10, 'MarkerFaceColor', 'red', 'linewidth', 4);

% plot continuous curve as plotted by seq.plot()
c = plot([gx.delay gx.delay+gx.tt gx.delay+gx.tt(end)+sys.gradRasterTime/2], ...
         [gx.first gx.waveform gx.last], 'b-');
set(c, 'linewidth', 1);

clr = [0.7 0.7 0.7];
xline(tt(1)-sys.gradRasterTime/2, '--', 'Color', clr);
for ii = 1:length(tt)
    xline(tt+sys.gradRasterTime/2, '--', 'Color', clr);
end

hold off

legend('gx.waveform', 'g.first', 'g.last', 'seq.plot()', 'raster period boundary', 'Location', 'northwest');

print -dpng firstlast.png

