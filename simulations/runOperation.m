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
    %operation = 'generateConeMosaic';
    %options.recompute = ~true;
    
    % --------------------------------------
    % 2. Compute cone mosaic responses
    % --------------------------------------
    operation = 'computeConeMosaicSTFresponses';

    % Monochromatic (AOSLO) stimulus params
    options.stimulusParams = simulator.params.AOSLOStimulus();
    
    % Achromatic (LCD) stimulus params
    % options.stimulusParams = simulator.params.LCDachromaticStimulus();
    
    [~,options.stimulusParams.STFspatialFrequencySupport] = simulator.load.fluorescenceSTFdata(monkeyID);
    
    % Optics params
    options.opticsParams = struct(...
        'type', simulator.opticsTypes.diffractionLimited, ...
        'residualDefocusDiopters', 0.067, ...
        'pupilSizeMM', WilliamsLabData.constants.pupilDiameterMM, ...
        'wavelengthSupport', options.stimulusParams.wavelengthSupport);

%     options.opticsParams = struct(...
%         'type', simulator.opticsTypes.M838, ...
%         'pupilSizeMM', 2.5, ...
%         'wavelengthSupport', options.stimulusParams.wavelengthSupport);

   % Cone mosaic params
    options.cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204, ...
        'integrationTimeSeconds', options.stimulusParams.frameDurationSeconds, ...
        'wavelengthSupport', options.stimulusParams.wavelengthSupport);


    % --------------------------------------
    % 3. Something else
    % --------------------------------------


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

        case simulator.operations.computeConeMosaicSTFresponses
            
            % Synthesize responses filename
            coneMosaicResponsesFileName = simulator.filename.coneMosaicSTFresponses(monkeyID, options)
            pause

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