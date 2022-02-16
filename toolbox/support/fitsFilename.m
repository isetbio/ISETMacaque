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
            modelValidationString = 'CrossValidatedMultipleSessionsTesting';
        else
            modelValidationString = 'CrossValidatedSingleSessionTesting';
        end
    else
        modelValidationString = 'NotCrossValidated';
    end
   
    transducerOptionsString = sprintf('transducerDC_%d_transducerSign_%d', ...
        modelVariant.transducerFunctionAccountsForResponseOffset, ...
        modelVariant.transducerFunctionAccountsForResponseSign);

    fitBiasString = sprintf('%sFitBias', modelVariant.fitBias);
    

    % Assemble fits filename
    filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBio%s_%s_%s_%sCenterCone_coneCouplingLambda_%2.3f_%2.3fD_%s_multiStart%d.mat', ...
                modelValidationString, ...
                cellsStrings, ...
                fitBiasString, ...
                modelVariant.centerConesSchema, ...
                modelVariant.coneCouplingLambda, ...
                modelVariant.residualDefocusDiopters, ...
                transducerOptionsString, ...
                startingPointsNum));
    
end