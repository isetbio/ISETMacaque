function runOperation
% Main gateway to all operations
%
% Syntax:
%   runOperation()
%
% Description:
%   Run some operation (e.g., generate cone mosaic responses, fit etc)
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         

    % Monkey to analyze
    monkeyID = 'M838';

    % Choose operation
    % --------------------------------------
    % 1. Generate cone mosaic
    % --------------------------------------
    %operation = simulator.operations.generateConeMosaic;
    %options.recompute = ~true;
    
    % --------------------------------------
    % 2. Compute cone mosaic responses
    % --------------------------------------
    operation = simulator.operations.computeConeMosaicSTFresponses;

    % --------------------------------------
    % 3. Visualize cone mosaic responses
    % --------------------------------------
    operation = simulator.operations.visualizeConeMosaicSTFresponses;

    
    simulateCronerKaplan = true;
    simulateWilliams = ~simulateCronerKaplan;
    
    if (simulateWilliams) 
        % Monochromatic (AOSLO) stimulus params
        options.stimulusParams = simulator.params.AOSLOStimulus();
    
        % Diffraction-limited optics
        options.opticsParams = struct(...
            'type', simulator.opticsTypes.diffractionLimited, ...
            'residualDefocusDiopters', 0.067, ...
            'pupilSizeMM', WilliamsLabData.constants.pupilDiameterMM, ...
            'wavelengthSupport', options.stimulusParams.wavelengthSupport);

    else
        
        % Achromatic (LCD) stimulus params
        options.stimulusParams = simulator.params.LCDAchromaticStimulus();
    
        % Physiological optics
        options.opticsParams = struct(...
            'type', simulator.opticsTypes.M838, ...
            'pupilSizeMM', 2.5, ...
            'wavelengthSupport', options.stimulusParams.wavelengthSupport);
    end
    
    % SF support
    [~,options.stimulusParams.STFspatialFrequencySupport] = simulator.load.fluorescenceSTFdata(monkeyID);
   
    
    % Cone mosaic params
    options.cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204, ...
        'integrationTimeSeconds', options.stimulusParams.frameDurationSeconds, ...
        'wavelengthSupport', options.stimulusParams.wavelengthSupport);


    


    % Go !
    performOperation(operation, options, monkeyID);
end

function performOperation(operation, options, monkeyID)

    % Assert that we have a valid operation
    assert(ismember(operation, enumeration('simulator.operations')), ...
        sprintf('''%s'' is not a valid operation name.\nValid options are:\n %s', ...
        operation, sprintf('\t%s\n',(enumeration('simulator.operations')))));

    % Switch
    switch (operation)
        case simulator.operations.generateConeMosaic
            simulator.coneMosaic.generate(monkeyID, options.recompute);

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
    end

end