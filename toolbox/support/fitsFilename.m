function filename = fitsFilename(modelVariant, startingPointsNum, ...
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
            modelValidationString = 'CrossValidatedTraining';
        elseif (crossValidateModelAgainstAllSessions)
            modelValidationString = CrossValidatedMultipleSessionsTesting;
        else
            modelValidationString = 'CrossValidatedSingleSessionTesting';
        end
    else
        modelValidationString = 'NotCrossValidated';
    end
   
    if (isfield(modelVariant, 'transducerFunctionAccountsForResponseOffset')) && ...
       (isfield(modelVariant, 'transducerFunctionAccountsForResponseSign'))
            
            if (modelVariant.transducerFunctionAccountsForResponseOffset)
                transducerDCoffsetString = 'YES';
            else
                transducerDCoffsetString = 'NO';
            end

            if (modelVariant.transducerFunctionAccountsForResponseSign)
                tranducerSignString = 'YES';
            else
                tranducerSignString = 'NO';
            end

            modelTransducerString = sprintf('tranducerSign%stransducerDCoffset%s', tranducerSignString, transducerDCoffsetString);
    else
        modelTransducerString = '';
    end

    % Assemble fits filename
    if (isempty(modelTransducerString))
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBio%sFits_%sCenterConeNum_coneCouplingLambda_%2.3f_%2.3fD_startingPointsNum%d_%s.mat', ...
                modelValidationString, ...
                modelVariant.centerConesSchema, ...
                modelVariant.coneCouplingLambda, ...
                modelVariant.residualDefocusDiopters, ...
                startingPointsNum, cellsStrings));
    else
        filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBio%sFits_%sCenterConeNum_coneCouplingLambda_%2.3f_%2.3fD_%s_startingPointsNum%d_%s.mat', ...
                modelValidationString, ...
                modelVariant.centerConesSchema, ...
                modelVariant.coneCouplingLambda, ...
                modelVariant.residualDefocusDiopters, ...
                modelTransducerString, ...
                startingPointsNum, cellsStrings));
    end
    
end