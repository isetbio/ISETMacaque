function filename = fitsFilename(opticalDefocusDiopters, startingPointsNum, ...
    crossValidatedModel, crossValidateModelAgainstAllSessions, trainModel, ...
    targetLcenterRGCindices, targetMcenterRGCindices)
    % Generate data filename
    rootDirName = ISETmacaqueRootPath();

    cellsStrings = '';
    if (~isempty(targetLcenterRGCindices))
        for k = 1:numel(targetLcenterRGCindices)
            cellsStrings = strcat(cellsStrings, sprintf('_L%d',targetLcenterRGCindices(k)));
        end
    end
    if (~isempty(targetMcenterRGCindices))
        for k = 1:numel(targetMcenterRGCindices)
            cellsStrings = strcat(cellsStrings, sprintf('_M%d',targetMcenterRGCindices(k)));
        end
    end
    
    if (crossValidatedModel)
        if (trainModel)
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioCrossValidatedTrainingFits%2.3fD_startingPointsNum%d_%s.mat', ...
                opticalDefocusDiopters, startingPointsNum, cellsStrings));
        elseif (crossValidateModelAgainstAllSessions)
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioCrossValidatedMultipleSessionsTestingFits%2.3fD_startingPointsNum%d_%s.mat', ...
                opticalDefocusDiopters, startingPointsNum, cellsStrings));
        else
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioCrossValidatedSingleSessionTestingFits%2.3fD_startingPointsNum%d_%s.mat', ...
                opticalDefocusDiopters, startingPointsNum, cellsStrings));
        end

    else
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioFits%2.3fD_startingPointsNum%d_%s.mat', ...
                opticalDefocusDiopters, startingPointsNum, cellsStrings));
    end
   
end