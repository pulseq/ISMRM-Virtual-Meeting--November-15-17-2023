function event2txt(E, Labels, fn)
% function event2txt(E, Labels, fn)
%
% Print event struct info to .txt file
%
% E         [1 n]   cell array containing Pulseq events
% Labels    [1 n]   cell array containing event labels/names
% fn        string  output file name

fid = fopen(fn, 'w');  % Open for writing. Overwrite if already existing.
for ii = 1:length(E)
    s = formattedDisplayText(E{ii});
    fprintf(fid, '%s =\n%s', Labels{ii}, s);
end
fclose(fid);
