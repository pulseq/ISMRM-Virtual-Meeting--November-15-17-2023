setsys;

% create trapezoid figure (trap.png)
trap;
event2txt({gx}, {'gx'}, 'trap.txt');
plottrap;

% create extended trapezoid figure (exttrap.png)
exttrap;
event2txt({gx}, {'gx'}, 'exttrap.txt');
plotexttrap;

% create arbitrary gradient figure (arbgrad.png)
arbgrad;
event2txt({gx}, {'gx'}, 'arbgrad.txt');
plotarbgrad;

% first and last
firstlast;
event2txt({gx}, {'gx'}, 'firstlast.txt');

% sinc rf figure
sincrf;
event2txt({rf,gx}, {'rf','gx'}, 'sincrf.txt');
plotsincrf;

% arbitrary rf figure
arbrf;
event2txt({rf,gx}, {'rf','gx'}, 'arbrf.txt');
plotarbrf;

% adc
makeadc;
event2txt({adc}, {'adc'}, 'adc.txt');

% delay
makedelay;
event2txt({del}, {'delay'}, 'delay.txt');

% dummy sequence example
makeblocks;
print -dpng blocks.png
b = seq.getBlock(1);
event2txt({b}, {'seq.getBlock(1)'}, 'block1.txt');

close all;
