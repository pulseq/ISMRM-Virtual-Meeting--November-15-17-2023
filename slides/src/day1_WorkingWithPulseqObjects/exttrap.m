gxtmp = mr.makeTrapezoid('x', 'FlatArea', Nx*deltak, 'FlatTime', Nx*dwell, ...
                      'delay', 200e-6, 'system', sys);
[gx,~] = mr.splitGradientAt(gxtmp, gxtmp.riseTime + gxtmp.flatTime);

% Or:
gx = mr.makeExtendedTrapezoid('x', 'times', gx.tt, 'amplitudes', gx.waveform);
gx.delay = 200e-6;
