tt = 1e3*[gx.delay gx.delay+gx.tt];
g = [0 gx.waveform/sys.gamma*1e3];
l = plot(tt, g, 'black-o');
axis([0 1.1*tt(end) 0 1.1*max(g)]);
set(l, 'MarkerSize', 12, 'MarkerFaceColor', 'black', 'LineWidth', 1);
xlabel('time (ms)');
ylabel('mT/m');
print -dpng exttrap.png


return

seq = mr.Sequence();
seq.addBlock(gx);
seq.plot();
h = subplot(3,2,2);  % gx subplot
f = figure;
h2 = copyobj(h,f);
close(1);
set(h2, 'Position', get(0, 'DefaultAxesPosition'));
