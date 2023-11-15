% plot with Pulseq plotter
seq = mr.Sequence();
seq.addBlock(rf,gz);
seq.plot();
print -dpng arbrf.png
return

