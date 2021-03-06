# ISETMacaque
Code to use ISETBio to characterize the eye of the macaque monkey



Under: /Volumes/SSDdisk/MATLAB/projects/ISETMacaque/manuscripts/M838/publicationReadyFigures
- plotRawSTFs()
% Plot the STF or RF profile of different fitted modeling scenarios for all the cells

- plotFittedSTFs()
% Plot the STF or RF profile of different fitted modeling scenarios for all the cells 

- plotSynthesizedSTFs()
% Compute synthesized STFs for different optics and visual stimulation scenarios (AO, monochromatic vs CRT, achromatic, physiological optics)


- runBatchComputeSyntheticRGCPhysiologicalOpticsSTFs()
% Batch generate STFs by applying synthetic RGC cone pooling models (derived 
%   by fitting center/surround pooled  weighted cone mosaic responses to 
%   diffraction-limited DF/F STF measurements - see runBatchFit()) to cone 
%   mosaic responses obtained under physiological optics. 
%   Then fit the generated STFs using a DoG model and generate figures with 
%   key parameters of the DoG model (Figs 10 and 11 of the paper).
