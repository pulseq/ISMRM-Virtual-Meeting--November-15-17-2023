% write2DGRE__short.m

rf_phase = 0;
rf_inc = 0;
rfSpoilingInc = 117;        % RF spoiling increment (degrees)

for iY = 1:Ny
    % RF spoiling
    rf.phaseOffset = rf_phase/180*pi;
    adc.phaseOffset = rf_phase/180*pi;
    rf_inc = mod(rf_inc+rfSpoilingInc, 360.0);
    rf_phase = mod(rf_phase+rf_inc, 360.0);
    
    % Excitation block
    seq.addBlock(rf, gz);

    % Slice-select refocus and readout prephasing
    pesc = peScales(iY,1);  % phase-encode gradient scaling (pre-computed outside loop)
    seq.addBlock(gxPre, mr.scaleGrad(gyPre, pesc), gzReph);

    % delay to achieve desired TE
    seq.addBlock(mr.makeDelay(delayTE));

    % ADC
    seq.addBlock(gx, adc);

    % Spoil and PE rephasing, and TR delay
    seq.addBlock(gxSpoil, mr.scaleGrad(gyPre, -pesc), gzSpoil);
    seq.addBlock(mr.makeDelay(delayTR));
end
