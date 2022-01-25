function filename = fitsFilename(opticalDefocusDiopters, startingPointsNum, crossValidateModel)
    % Generate data filename
    rootDirName = ISETmacaqueRootPath();

    if (crossValidateModel)
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioCrossValidatedFits%2.3fD_startingPointsNum%d.mat', ...
                opticalDefocusDiopters, startingPointsNum));
    else
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioFits%2.3fD_startingPointsNum%d.mat', ...
                opticalDefocusDiopters, startingPointsNum));
    end
   
end