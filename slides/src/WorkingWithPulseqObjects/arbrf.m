load arbrf.mat;    % rfwav (T) and gzwav (mT/m)

flip = pi;   % dummy value, will rescale anyhow 
rf = mr.makeArbitraryRf(rfwav, flip, 'delay', sys.rfDeadTime, 'system', sys);
rf.signal = rf.signal/max(abs(rf.signal))*max(abs(rfwav)*sys.gamma); % Hz

gzwav_Hzm = gzwav*sys.gamma/1e3;
gz = mr.makeArbitraryGrad('z', gzwav_Hzm, sys, 'delay', 10e-6);
    
