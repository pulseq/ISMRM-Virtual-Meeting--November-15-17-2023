# Basic Pulseq tutorial
## 1. Prerequisites
### 1.1 Programming Tools
Matlab software (https://mathworks.com/products/matlab.html) needs to be installed in your computer.   
Basic familiarity with Matlab programming is required.   
### 1.2 Pulseq Software
Please download the Pulseq software from https://github.com/pulseq/pulseq. Install Pulseq software in Matlab by adding its directory and subdirectories to Matlab's path.   
### 1.3 mapVBVD Software
The mapVBVD software is required to read raw data in Siemens TWIX format. The software can be downloaded from https://github.com/pehses/mapVBVD and installed by adding its directory to Matlab's path.

## 2. sequence folder
### 2.1 Basic MR spectroscopy
s01_FID: the simplest free induction decay sequence   
s02_SE: spin-echo sequence without gradients   
s03_SE_crushers: spin-echo sequence with a pair of crushers to eliminate spurious signals arising from the notoriously imperfect 180 deg RF pulse   
### 2.2 Basic MR imaging
s11_GRE2D: basic 2D gradient echo (GRE) sequence   
s12_GRE2D_optimizedSpoiler: 2D GRE with optimized spoiler timing   
s13_GRE2D_acceleratedComputation: 2D GRE with optimized spoiler timing and accelerated computation   

## 3. data folder
work-in-progress   

## 4. recon folder
work-in-progress   

## 5. A more detailed Pulseq tutorial
This Pulseq tutorial only covers very basic sequence design concepts. For more detailed tutorials, please go to https://github.com/pulseq/tutorials.    
