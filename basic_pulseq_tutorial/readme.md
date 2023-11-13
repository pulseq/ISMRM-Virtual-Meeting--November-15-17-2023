# Basic Pulseq tutorial
## 1. Prerequisites
### 1.1 Programming Tools
Matlab software (https://mathworks.com/products/matlab.html) needs to be installed in your computer.   
Basic familiarity with Matlab programming is required.   
### 1.2 Pulseq Software
Please download the Pulseq software from https://github.com/pulseq/pulseq. Install Pulseq software in Matlab by adding its directory and subdirectories to Matlab's path.   
### 1.3 mapVBVD Software
The mapVBVD software is required to read raw data in Siemens TWIX format. The software can be downloaded from https://github.com/pehses/mapVBVD and installed by adding its directory to Matlab's path.
### 1.4 Text Compare Tool
We recommend using a text comparison tool to compare the sequences within the subsequent steps to visualize the changes that occur at each
step. *Meld* software can be used for text comparison and can be downloaded from <https://meldmerge.org/>. By using Meld or other comparable software packages, it is possible to very quickly make the relevant changes easily visible, as in the example below.

![meld](https://github.com/pulseq/ISMRM-Virtual-Meeting--November-15-17-2023/assets/26165904/306150db-68d7-4a8b-8eb3-13b8fccfc3a2)


## 2. Sequence Folder
### 2.1 Basic MR Spectroscopy
s01_FID: the simplest free induction decay (FID) sequence   
s02_SE: spin-echo (SE) sequence without gradients   
s03_SE_crushers: SE sequence with a pair of crushers to eliminate spurious signals arising from the notoriously imperfect 180 deg RF pulse   
### 2.2 Basic MR Imaging
s11_GRE2D: basic 2D gradient echo (GRE) sequence   
s12_GRE2D_optimizedSpoiler: 2D GRE with optimized spoiler timing   
s13_GRE2D_acceleratedComputation: 2D GRE with optimized spoiler timing and accelerated computation   

## 3. Data Folder
work-in-progress   

## 4. Recon Folder
work-in-progress   

## 5. A More Detailed Pulseq Tutorial
This Pulseq tutorial only covers very basic sequence design concepts. For more detailed tutorials, please go to https://github.com/pulseq/tutorials.    
