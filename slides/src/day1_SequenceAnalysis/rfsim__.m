% rfsim__.m

% Design RF and z gradient events
[rfe, gze] = mr.makeSincPulse(20/180*pi, 'Duration', 2e-3, 'SliceThickness', 5e-3, ...
   'apodization', 0.42, 'timeBwProduct', 4, 'system', sys);

% Interpolate waveforms to a common raster period
dt = 4e-6;    % sec
rf = interp1([0 rfe.delay+rfe.t], [0 rfe.signal], dt/2:dt:rfe.t(end));
gz = interp1([0 gze.riseTime gze.riseTime+gze.flatTime ...
              gze.riseTime+gze.flatTime+gze.fallTime], ...
              gze.amplitude*[0 1 1 0], dt/2:dt:mr.calcDuration(gze));

% pad to same length and simulate
l = length(gz); rf = [rf zeros(1,l-length(rf))];
rf = rf/sys.gamma*1e4;              % Gauss
gz = gz/sys.gamma*1e2;              % Gauss/cm
m0 = [0 0 1];                       % initial magnetization along mz
Z = linspace(-1,1,100);             % cm
T1 = 1000; T2 = 100;                % ms
toppe.utils.rf.slicesim(m0, rf, gz, dt*1e3, Z, T1, T2);
