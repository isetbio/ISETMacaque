function [pdfFilename, videoFileName] = fitsPDFFilename(opticalDefocusDiopters, centerConeType, startingPointsNum)
    % Generate data filename
    rootDirName = ISETmacaqueRootPath();

    filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/ISETBioFits%2.3fD_%s_startingPoints%d', ...
                opticalDefocusDiopters, centerConeType, startingPointsNum));
   
    pdfFilename = sprintf('%s.pdf', filename);
    videoFileName = sprintf('%s.mp4', filename);
end