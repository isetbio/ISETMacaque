function filename = fittedRGCmodel(monkeyID, options, ...
    coneMosaicSamplingParams, fitParams, STFdataToFit)
% Generate filename for the fitted RGC model
%
% Syntax:
%   filename = simulator.filename.fittedRGCmode(monkeyID, options, ...
%               coneMosaicSamplingParams, fitParams, STFdataToFit)
%
% Description: Generate filename for the fitted 
%              (to the fluorescence STF data)RGC model
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021

    p = getpref('ISETMacaque');

    % Add monkeyID
    modelFilename = sprintf('%s', monkeyID);

    % Add stimulus descriptor
    switch (options.stimulusParams.type)
        
        case simulator.stimTypes.monochromaticAO
            stimDescriptor = '_AOMonoChromatic';

        case simulator.stimTypes.achromaticLCD
            stimDescriptor = sprintf('_CRTLMS_%2.2f_%2.2f_%2.2f', ...
                options.stimulusParams.lmsConeContrasts(1), ...
                options.stimulusParams.lmsConeContrasts(2), ...
                options.stimulusParams.lmsConeContrasts(3));
        otherwise
            error('Unknown stimulus type: ''%s''.', options.stimulusParams.type);
    end
    modelFilename = strcat(modelFilename, stimDescriptor);

    % Add optics descriptor
    switch (options.opticsParams.type)
        case simulator.opticsTypes.diffractionLimited
            opticsDescriptor = sprintf('_%sOptics_ResidualDefocus_%2.3fD',...
                options.opticsParams.type, options.opticsParams.residualDefocusDiopters);

        case simulator.opticsTypes.Polans
            opticsDescriptor = sprintf('_%sSubj%dOptics_PupilDiam_%2.2fMM', ...
                options.opticsParams.type, opticsParams.PolansSubject, options.opticsParams.pupilSizeMM);

        case simulator.opticsTypes.Artal
            error('Artal optics not implemented yet')

        case simulator.opticsTypes.Thibos
            error('Thibos optics not implemented yet')

        case simulator.opticsTypes.M838
            opticsDescriptor = sprintf('_%sOptics_PupilDiam_%2.2fMM', ...
                options.opticsParams.type, options.opticsParams.pupilSizeMM);
    end
    modelFilename = strcat(modelFilename, opticsDescriptor);

    % Add cone mosaic descriptor
    coneMosaicDescriptor = sprintf('_ConeCouplingLambda%2.2f', ...
        options.cMosaicParams.coneCouplingLambda);
    modelFilename = strcat(modelFilename, coneMosaicDescriptor);

    fitDescriptor = sprintf('_%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
    if (fitParams.accountForNegativeSTFdata)
        fitDescriptor = strcat(fitDescriptor, '_accountForNegSTF');
    else
        fitDescriptor = strcat(fitDescriptor, '_noaccountForNegSTF');
    end
    fitDescriptor = strcat(fitDescriptor, sprintf('_%sSFbias', fitParams.spatialFrequencyBias));
    fitDescriptor = strcat(fitDescriptor, sprintf('_%dconePositionsTested', coneMosaicSamplingParams.positionsExamined));
    modelFilename = strcat(modelFilename, fitDescriptor);

    % Finalize responses full filename
    filename = fullfile(p.generatedDataDir, 'fittedRGCModels', sprintf('%s_fittedRGCmodel.mat',modelFilename));
    
end
