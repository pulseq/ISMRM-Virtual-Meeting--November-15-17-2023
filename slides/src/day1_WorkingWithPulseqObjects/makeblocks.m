seq = mr.Sequence();

% slice-select pulse
sincrf;                                      % create rf and gz
seq.addBlock(rf, gz, mr.makeDelay(2e-3));    % what is effect of the delay event here??

% slice rephaser gradient
gzrep = mr.makeTrapezoid('z', 'Area', -gz.area/2, 'system', sys);
seq.addBlock(gzrep);

% spiral readout 
spiral;                     % create gx
seq.addBlock(gx, adc);

close all; seq.plot('showBlocks', true);
