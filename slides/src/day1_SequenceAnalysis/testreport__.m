rep = seq.testReport;
s = sprintf([rep{:}]);
fid = fopen('tmp.txt', 'w');  % remove superscript (degree symbol) by hand, then copy to testreport.txt
fprintf(fid, s);
fclose(fid);
