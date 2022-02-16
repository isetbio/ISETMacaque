function [pdfFilename, videoFileName] = fitsPDFFilename(modelVariant, ...
    centerConeType, startingPointsNum, crossValidationRun, runType)
    % Generate data filename
    rootDirName = ISETmacaqueRootPath();

    if (crossValidationRun > 0)
        modelValidationString = sprintf('CrossValidated%sSession%d', runType, crossValidationRun);
    else
        modelValidationString = '';
    end

    transducerOptionsString = sprintf('transducerDC_%d_transducerSign_%d', ...
        modelVariant.transducerFunctionAccountsForResponseOffset, ...
        modelVariant.transducerFunctionAccountsForResponseSign);

    fitBiasString = sprintf('%sFitBias', modelVariant.fitBias);

    filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/ISETBio%s_%s_%s_%sCenterCone_coneCouplingLambda_%2.3f_%2.3fD_%s_multiStart%d', ...
                modelValidationString, ...
                centerConeType, ...
                fitBiasString, ...
                modelVariant.centerConesSchema, ...
                modelVariant.coneCouplingLambda, ...
                modelVariant.residualDefocusDiopters, ...
                transducerOptionsString, ...
                startingPointsNum));

    pdfFilename = sprintf('%s.pdf', filename);
    videoFileName = sprintf('%s.mp4', filename);
end