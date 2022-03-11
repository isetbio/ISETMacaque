function runOperation(operation, operationOptions, monkeyID)
% Configure the selected operation and run it
%
% Syntax:
%   runOperation(operation, operationOptions, monkeyID)
%
% Description:
%   Configure the selected operation and run it
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None

    % Assert that we have a valid operation
    assert(ismember(operation, enumeration('simulator.operations')), ...
        sprintf('''%s'' is not a valid operation.\nValid options are:\n %s', ...
        operation, sprintf('\t%s\n',(enumeration('simulator.operations')))));

    % Set stimulus params based on selected stimulusType enumeration
    switch (operationOptions.stimulusType)
        case simulator.stimTypes.monochromaticAO
            options.stimulusParams = simulator.params.AOSLOStimulus();

        case simulator.stimTypes.achromaticLCD
            % Achromatic (LCD) stimulus params
            options.stimulusParams = simulator.params.LCDAchromaticStimulus();

        otherwise
            error('Unknown stimulus type: ''%s''.', operationOptions.stimulusType)
    end

    % Set optics params based on selected opticsScenario enumeration
    switch (operationOptions.opticsScenario)
        case simulator.opticsScenarios.diffrLimitedOptics_residualDefocus

            % Diffraction-limited optics
            options.opticsParams = struct(...
                'type', simulator.opticsTypes.diffractionLimited, ...
                'residualDefocusDiopters', operationOptions.residualDefocusDiopters, ...
                'pupilSizeMM', WilliamsLabData.constants.pupilDiameterMM, ...
                'wavelengthSupport', options.stimulusParams.wavelengthSupport);

        case simulator.opticsScenarios.M838Optics
            % M838 optics
            options.opticsParams = struct(...
                'type', simulator.opticsTypes.M838, ...
                'pupilSizeMM', operationOptions.M838PupilSizeMM, ...
                'wavelengthSupport', options.stimulusParams.wavelengthSupport);

    end

    
    % Set spatial frequency support for the STF measurements
    [~,options.stimulusParams.STFspatialFrequencySupport] = simulator.load.fluorescenceSTFdata(monkeyID);
    
    
    % Set the cone mosaic params
    options.cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204, ...
        'integrationTimeSeconds', options.stimulusParams.frameDurationSeconds, ...
        'wavelengthSupport', options.stimulusParams.wavelengthSupport);



    % Switch
    switch (operation)
        
        case simulator.operations.fitFluorescenceSTFresponses
            % Synthesize cone mosaic responses filename
            coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(monkeyID, options);

            simulator.fit.ISETBioRGCmodelToFluorescenceRGCdata(monkeyID, ...
                coneMosaicResponsesFileName, ...
                operationOptions.STFdataToFit);
            

        case simulator.operations.visualizeConeMosaicSTFresponses
            % Synthesize cone mosaic responses filename
            coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(monkeyID, options);

            % Visualize responses
            visualizedDomainRangeMicrons = 60;
            d = simulator.visualize.coneMosaicSTFresponses(coneMosaicResponsesFileName, ...
                'visualizedDomainRangeMicrons', visualizedDomainRangeMicrons, ...
                'framesToVisualize', [1]);

            % Co-visualize the cone mosaic with the PSF
            % Generate optics using the desired optics params
            [~, thePSFdata] = simulator.optics.generate(monkeyID, options.opticsParams);

            % Import the cone mosaic
            load(coneMosaicResponsesFileName, 'theConeMosaic');

            simulator.visualize.mosaicAndPSF(theConeMosaic, thePSFdata, visualizedDomainRangeMicrons, ...
                WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                'figureHandle', d.hFig, ...
                'axesHandle', d.axPSF);

        case simulator.operations.computeConeMosaicSTFresponses
            % Synthesize cone mosaic responses filename
            coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(monkeyID, options);

            % Modify the default cone mosaic with the examined cone mosaic params
            theConeMosaic = simulator.coneMosaic.modify(monkeyID, options.cMosaicParams);
            
            % Generate optics using the desired optics params
            [theOI, thePSFdata] = simulator.optics.generate(monkeyID, options.opticsParams);
    
            % Visualize mosaic and PSF
            visualizedDomainRangeMicrons = 40;
            simulator.visualize.mosaicAndPSF(theConeMosaic, thePSFdata, visualizedDomainRangeMicrons, ...
                WilliamsLabData.constants.imagingPeakWavelengthNM);
        
            % Compute cone mosaic responses for the stimuli used to measure
            % the RGC spatial transfer functions (STFs)
            simulator.responses.coneMosaicSTF(options.stimulusParams, ...
                theOI, theConeMosaic, coneMosaicResponsesFileName);

       case simulator.operations.generateConeMosaic
            simulator.coneMosaic.generate(monkeyID, operationOptions.recomputeMosaic);

    end

end