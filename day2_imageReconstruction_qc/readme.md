# Image Reconstruction Based on the Pulseq Framework

For interfacing with ICE/Gadgetron, every ADC event in the Pulseq 
sequence must be labeled, and additional necessary information is given using the sequence 
definitions option (*seq.setDefinition*).

The *s21_GRE2D_GRAPPA* is built by implementing GRAPPA acceleration to the 2D GRE sequence with optimized spoiler and accelerated 
computation (*s13_GRE2D_acceleratedComputation* in day 1).
s21_GRE2D_GRAPPA produces raw data reconstructable by Siemens ICE and online/offline Gadgetron.
