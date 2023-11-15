% plot with Pulseq plotter
seq = mr.Sequence();
seq.addBlock(rf,gz);
seq.plot();
print -dpng sincrf.png
return

h_rf = subplot(3,2,3);  % gx subplot
h_gz = subplot(3,2,6);  % gx subplot
f = figure;
h2_rf = subplot(1,2,1);
h2 = copyobj(h_rf,h2_rf);
h2_gz = subplot(1,2,2);
h2 = copyobj(h_gz,h2_gz);
set(h2, 'Position', get(0, 'DefaultAxesPosition'));
%print -dpng arbgrad_pulseq.png
