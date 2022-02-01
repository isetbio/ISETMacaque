function [pdfFilename, videoFileName] = fitsPDFFilename(opticalDefocusDiopters, ...
    centerConeType, startingPointsNum, crossValidationRun, runType)
    % Generate data filename
    rootDirName = ISETmacaqueRootPath();

    if (crossValidationRun > 0)
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/ISETBioFits%2.3fD_%s_CrossValidated%sRun%d_startingPoints%d', ...
                opticalDefocusDiopters, centerConeType, runType, crossValidationRun, startingPointsNum));
    else
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/ISETBioFits%2.3fD_%s_startingPoints%d', ...
                opticalDefocusDiopters, centerConeType, startingPointsNum));
    end

   
    pdfFilename = sprintf('%s.pdf', filename);
    videoFileName = sprintf('%s.mp4', filename);
end