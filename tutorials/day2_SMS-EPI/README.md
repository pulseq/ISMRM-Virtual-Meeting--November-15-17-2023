# Create SMS-EPI (or 3D EPI) fMRI Pulseq file, convert to GE format, and plot in MATLAB

To create the scan files and plot, in MATLAB do:
```
>> main;
```

To create the corresponding 3D EPI file (3d-epi.seq), change 'SMS' to '3D' in the writeEPI call.

This is a real fMRI sequence -- not just a demo! If you'd like to try it out for fMRI, 
I'd love to hear from you (Jon, jfnielse@umich.edu)


## Requirements

Script assumes
1. Linux (tested on Ubuntu)
2. git installed
3. python3 installed (tested with Python 3.10.12)


## Python troubleshooting

writeEPI.m calls Python to create the CAIPI sampling pattern.
I'm no Python expert, but found that to be able to call Python from MATLAB, 
the following can help (assuming Linux):

1. On the Linux command line:
    ```
    sudo apt-get install matlab-support
    ```
2. That may make the Python call from within MATLAB work, but now figures may not show in MATLAB. 
    To fix that, do:
    ```
    >> opengl('save','software');
    ```
    and restart Matlab


