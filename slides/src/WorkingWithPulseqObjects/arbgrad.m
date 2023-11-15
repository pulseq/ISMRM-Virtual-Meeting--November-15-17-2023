spiral;   % creates 'wav' vector, mT/m
gx = mr.makeArbitraryGrad('x', wav*sys.gamma/1e3, 'delay', 200e-6);
