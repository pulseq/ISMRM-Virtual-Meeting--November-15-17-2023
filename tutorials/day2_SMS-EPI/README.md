# Create SMS-EPI Pulseq file, convert to GE format, and plot in MATLAB

To create the scan files and plot, in MATLAB do:
```
>> main;
```

## Requirements

Script assumes
1. Linux (tested on Ubuntu)
2. git installed
3. python installed

## Python troubleshooting

writeEPI.m calls Python to create the CAIPI sampling pattern.
I'm no Python expert, but found that to be able to call Python from MATLAB, 
the following can help (assuming Linux):

1. On the Linux command line:
```
sudo apt-get install matlab-support
```
2. That may make the Python call from within MATLABwork, but now figures may not show in Matlab. 
To fix that, do:
```
>> opengl('save','software');
```
and restart Matlab


