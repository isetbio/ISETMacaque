function filename = coneMosaicSTFresponses(monkeyID, options)
% Generate filename for the cone mosaic STF responses
%
% Syntax:
%   filename = simulator.filename.coneMosaic((monkeyID);
%
% Description: Generate filename for the cone mosaic STF responses
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021

    p = getpref('ISETMacaque');

    % Add monkeyID
    responseFilename = sprintf('%s', monkeyID);

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
    responseFilename = strcat(responseFilename, stimDescriptor);

    % Add optics descriptor
    switch (options.opticsParams.type)
        case simulator.opticsTypes.diffractionLimited
            opticsDescriptor = sprintf('_%sOptics_ResidualDefocus_%2.3fD',...
                options.opticsParams.type, options.opticsParams.residualDefocusDiopters);

        case simulator.opticsTypes.Polans
            opticsDescriptor = sprintf('_%sSubj%dOptics_PupilDiam_%2.2fMM', ...
                options.opticsParams.type, options.opticsParams.subjectID, options.opticsParams.pupilSizeMM);

        case simulator.opticsTypes.Artal
            error('Artal optics not implemented yet')

        case simulator.opticsTypes.Thibos
            error('Thibos optics not implemented yet')

        case simulator.opticsTypes.M838
            opticsDescriptor = sprintf('_%sOptics_PupilDiam_%2.2fMM', ...
                options.opticsParams.type, options.opticsParams.pupilSizeMM);
    end
    responseFilename = strcat(responseFilename, opticsDescriptor);

    % Add cone mosaic descriptor
    coneMosaicDescriptor = sprintf('_ConeCouplingLambda%2.2f', ...
        options.cMosaicParams.coneCouplingLambda);
    responseFilename = strcat(responseFilename, coneMosaicDescriptor);

    % Finalize responses full filename
    filename = fullfile(p.generatedDataDir, 'responses', sprintf('%s.mat',responseFilename));


end
