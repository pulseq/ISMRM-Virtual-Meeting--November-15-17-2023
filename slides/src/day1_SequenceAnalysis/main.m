
%
% 2D GRE sequence analysis
%

% Create seq object
write2DGRE__;

% Plot sequence
seq.plot();
print -dpng 2DGRE.png
seq.plot('blockRange', [1 6], 'showBlocks', true);
print -dpng 2DGREzoom.png

% Check timing
checktiming__;

% report
testreport__;
fprintf('Remove the degree superscript in tmp.txt and rename file testreport.txt\n');

% waveformsandtimes 
clear gx gy gz
waveformsandtimes__;
close all;
l = plot(gx.tt, gx.waveform, 'ro-');
set(l, 'linewidth', 1, 'MarkerSize', 4, 'MarkerFaceColor', 'black' );
hold on;
l = plot(gy.tt, gy.waveform, 'go-');
set(l, 'linewidth', 1, 'MarkerSize', 4, 'MarkerFaceColor', 'black' );
l = plot(gz.tt, gz.waveform, 'bo-');
set(l, 'linewidth', 1, 'MarkerSize', 4, 'MarkerFaceColor', 'black' );
legend('gx', 'gy', 'gz');
hold off;
print -dpng waveformsandtimes.png
axis([0 0.02 -7e5 20e5]);
print -dpng waveformsandtimes_zoom.png

% combined gradients
rotateandplot__;

% oblique scan


% kspace. Do this last since we create a version w/o spoilers
kspace__;
print -dpng kspace_full.png
write2DGRE__nospoil;
kspace__;
print -dpng kspace.png

%event2txt({gx}, {'gx'}, 'trap.txt');

% Oblique scan analysis
%close all; writeEpiRS__;
%figure(2); print -dpng epi_seq.png
%figure(5); print -dpng epi_kspace.png
%epirotateandplot__;

% slice profile
rfsim__;
print -dpng slice.png

% PNS
pnsdemo__;
print -dpng pns.png

close all
