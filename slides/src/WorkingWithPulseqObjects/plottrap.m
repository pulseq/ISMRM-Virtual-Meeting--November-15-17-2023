tt = gx.delay + [0 gx.riseTime gx.riseTime+gx.flatTime gx.riseTime+gx.flatTime+gx.fallTime];
tt = 1e3*tt;  % ms
g = gx.amplitude/sys.gamma*1e3 * [0 1 1 0];
l = plot(tt, g, 'black-');
axis([0 1.1*tt(end) 0 1.1*max(g)]);
set(l, 'MarkerSize', 12, 'MarkerFaceColor', 'black', 'LineWidth', 1);
xlabel('time (ms)');
ylabel('mT/m');
print -dpng trap.png


return

seq = mr.Sequence();
seq.addBlock(gx);
seq.plot();
h = subplot(3,2,2);  % gx subplot
f = figure;
h2 = copyobj(h,f);
close(1);
set(h2, 'Position', get(0, 'DefaultAxesPosition'));
