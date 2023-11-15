
%% Check sequence timing
[ok, error_report] = seq.checkTiming;
if (ok)
    fprintf('Timing check passed successfully\n');
else
    fprintf('Timing check failed! Error listing follows:\n');
    fprintf([error_report{:}]);
    fprintf('\n');
end

%% Output for execution and plot
seq.setDefinition('FOV', [fov fov sliceThickness]);
seq.setDefinition('Name', 'gre2d');
seq.write('gre2d.seq')       % Write to pulseq file

seq.plot('timeRange', [0 3]*TR);

%% Optional slow step, but useful for testing during development,
%% e.g., for the real TE, TR or for staying within slewrate limits  
%rep = seq.testReport;
%fprintf([rep{:}]);
