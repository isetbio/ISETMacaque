function filename = fitsFilename(opticalDefocusDiopters, startingPointsNum, crossValidateModel, ...
    fitLcenterCells, fitMcenterCells, targetLcenterRGCindices, targetMcenterRGCindices)
    % Generate data filename
    rootDirName = ISETmacaqueRootPath();

    cellsStrings = '';
    if (fitLcenterCells)
        for k = 1:numel(targetLcenterRGCindices)
            cellsStrings = strcat(cellsStrings, sprintf('_L%d',targetLcenterRGCindices(k)));
        end
    end
    if (fitMcenterCells)
        for k = 1:numel(targetMcenterRGCindices)
            cellsStrings = strcat(cellsStrings, sprintf('_M%d',targetLcenterRGCindices(k)));
        end
    end
    
    if (crossValidateModel)
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioCrossValidatedFits%2.3fD_startingPointsNum%d_%s.mat', ...
                opticalDefocusDiopters, startingPointsNum, cellsStrings));
    else
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioFits%2.3fD_startingPointsNum%d_%s.mat', ...
                opticalDefocusDiopters, startingPointsNum, cellsStrings));
    end
   
end