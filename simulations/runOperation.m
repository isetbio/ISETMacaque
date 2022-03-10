function runOperation(operation, operationOptions, monkeyID)

    % Assert that we have a valid operation
    assert(ismember(operation, enumeration('simulator.operations')), ...
        sprintf('''%s'' is not a valid operation.\nValid options are:\n %s', ...
        operation, sprintf('\t%s\n',(enumeration('simulator.operations')))));

    
    % Assert that we have a valid model scenario
    assert(ismember(operationOptions.modelScenario, enumeration('simulator.modelScenarios')), ...
        sprintf('''%s'' is not a valid model scenario.\nValid options are:\n %s', ...
        operationOptions.modelScenario, sprintf('\t%s\n',(enumeration('simulator.modelScenarios')))));
    

    switch (operationOptions.modelScenario)
        case simulator.modelScenarios.diffrLimitedOptics_0067DResidualDefocus_MonochromaticGrating
            % Monochromatic (AOSLO) stimulus params
            options.stimulusParams = simulator.params.AOSLOStimulus();
        
            % Diffraction-limited optics
            options.opticsParams = struct(...
                'type', simulator.opticsTypes.diffractionLimited, ...
                'residualDefocusDiopters', 0.067, ...
                'pupilSizeMM', WilliamsLabData.constants.pupilDiameterMM, ...
                'wavelengthSupport', options.stimulusParams.wavelengthSupport);

        case simulator.modelScenarios.M838Optics_AchromaticGrating
            % Achromatic (LCD) stimulus params
            options.stimulusParams = simulator.params.LCDAchromaticStimulus();
    
            % M838 optics
            options.opticsParams = struct(...
                'type', simulator.opticsTypes.M838, ...
                'pupilSizeMM', operationOptioncs.M838PupilSizeMM, ...
                'wavelengthSupport', options.stimulusParams.wavelengthSupport);

        otherwise
            error('Unknown model scenario: ''%s''.', modelScenario)
    end

    
    % Set spatial frequency support for the STF measurements
    [~,options.stimulusParams.STFspatialFrequencySupport] = simulator.load.fluorescenceSTFdata(monkeyID);
    
    % Cone mosaic params
    options.cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204, ...
        'integrationTimeSeconds', options.stimulusParams.frameDurationSeconds, ...
        'wavelengthSupport', options.stimulusParams.wavelengthSupport);


    % Switch
    switch (operation)
        
        case simulator.operations.fitMeasuredSTFresponsesForSpecificModelScenario
            disp('here')
            pause

        case simulator.operations.visualizeConeMosaicSTFresponses
            % Synthesize responses filename
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

            simulator.visualize.mosaicAndPSF(theConeMosaic,  thePSFdata, visualizedDomainRangeMicrons, ...
                WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                'figureHandle', d.hFig, ...
                'axesHandle', d.axPSF);

        case simulator.operations.computeConeMosaicSTFresponses
            % Synthesize responses filename
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
            simulator.coneMosaic.generate(monkeyID, operationOptions.recompute);

    end

end