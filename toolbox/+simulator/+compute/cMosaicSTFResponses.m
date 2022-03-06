function cMosaicSTFResponses(monkeyID, stimulusParams, ...
                opticsParams, coneMosaicParams)
% Compute cone mosaic responses to stimuli of different SFs
%
% Syntax:
%   simulator.compute.cMosaicSTFResponses(monkeyID, stimulusType)
%
% Description:
%   Compute cone mosaic responses to stimuli of different SFs
%
% Inputs:
%    monkeyID           String, denoting which monkey data to use, e.g., 'M838'
%    stimulusParams     Struct with stimulus params
%    opticsParams       Struct with optics params 
%    coneMosaicParams   Struct with cone mosaic params
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         

    % Assert that we have a valid stimulusType
    assert(ismember(stimulusParams.type, enumeration('simulator.stimTypes')), ...
                sprintf('''%s'' is not a valid stimulus type.\nValid options are:\n %s', ...
                stimulusParams.type, sprintf('\t%s\n',(enumeration('simulator.stimTypes')))));

    % Assert that we have valid optics system
    assert(ismember(opticsParams.type, enumeration('simulator.opticsTypes')), ...
                sprintf('''%s'' is not a valid optics type.\nValid options are:\n %s', ...
                opticsParams.type, sprintf('\t%s\n',(enumeration('simulator.opticsTypes')))));

    % Select wavelength support
    switch (stimulusParams.type)
        case simulator.stimTypes.monochromaticAO
            wavelengthSupport = WilliamsLabData.constants.imagingPeakWavelengthNM + (-20:2:20);
        case simulator.stimTypes.achromaticLCD
            wavelengthSupport = WilliamsLabData.constants.imagingPeakWavelengthNM + (-500:5:500);
            % Only doing L/M cone simulation, so skip short wavelengths
            idx = find((wavelengthSupport >= 465)&&(wavelengthSupport<=750));
            wavelengthSupport = wavelengthSupport(idx);
    end

    % Load cone mosaic model
    load(simulator.utils.cMosaicFilename(monkeyID), 'cm');
    theConeMosaic = cm;
    clear 'cm';

    % Cone mosaic modifications
    % 1. Spectral support
    theConeMosaic.wave = wavelengthSupport;

    % 2. Aperture modifiers
    newConeApertureModifiers = theConeMosaic.coneApertureModifiers;
    newConeApertureModifiers.smoothLocalVariations = true;
    newConeApertureModifiers.shape = coneMosaicParams.apertureShape;
    if (strcmp(coneMosaicParams.apertureShape, 'Gaussian'))
        newConeApertureModifiers.sigma = coneMosaicParams.apertureSigmaToDiameterRatio;
    end
    theConeMosaic.coneApertureModifiers = newConeApertureModifiers;

    % 3. Cone coupling
    theConeMosaic.coneCouplingLambda = coneMosaicParams.coneCouplingLambda;


    % 4. Optics
    switch (opticsParams.type)
        case simulator.opticsTypes.diffractionLimited
            [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, ...
             psfSupportWavelength] = diffractionLimitedOptics(...
                opticsParams.pupilSizeMM, wavelengthSupport, ...
                WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                opticsParams.residualDefocusDiopters, 'noLCA', false);

            % Export the OTF of the residual blur AOSLO system. This will be used for
            % de-convonlving the DF/F responses before fitting them with the DoG model
            if (abs(opticsParams.residualDefocusDiopters) > 0)
                exportResidualDefocusOTF(theOI, psfSupportWavelength, opticsParams.residualDefocusDiopters);
            end

        case simulator.opticsTypes.Polans
             [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, ...
                 psfSupportWavelength] = PolansOptics.oiForSubjectAtEccentricity(...
                 opticsParams.PolansSubject, 'right eye', [0 0], ...
                 opticsParams.pupilSizeMM, wavelengthSupport, ...
                 WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                'zeroCenterPSF', true, ...
                'inFocusWavelength', WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                'subtractCentralRefraction', PolansOptics.constants.subjectRequiresCentralRefractionCorrection(opticsParams.PolansSubject));
   

        case simulator.opticsTypes.Artal
            error('Artal optics not implemented yet')

        case simulator.opticsTypes.Thibos
            error('Thibos optics not implemented yet')

        case simulator.opticsTypes.M838
            % Load the Zernikes for the animal
            ZernikesFileName = sprintf('%s_Polychromatic_PSF.mat', monkeyID);
            load(ZernikesFileName, 'Z_coeff_M838', 'd_pupil');
            Zcoeffs = Z_coeff_M838;

            measPupilDiamMM = d_pupil*1000;
            measWavelength = 550; 
            [~,idx] = min(abs(wavelengthSupport-measWavelength));
            measWavelength = wavelengthSupport(idx);
            psfSupportWavelength = wavelengthSupport;
            [thePSF, ~, ~,~, psfSupportMinutesX, psfSupportMinutesY, theWVF] = ...
               computePSFandOTF(Zcoeffs, ...
                                psfSupportWavelength , 701, ...
                                measPupilDiamMM, opticsParams.pupilSizeMM, measWavelength, false, ...
                                'doNotZeroCenterPSF', false, ...
                                'micronsPerDegree', WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                                'upsampleFactor', 1, ...
                                'flipPSFUpsideDown', ~true, ...
                                'noLCA', false, ...
                                'name', sprintf('%s optics', monkeyID));
         
             % Generate the OI from the wavefront map
            theOI = wvf2oiSpecial(theWVF,  WilliamsLabData.constants.micronsPerDegreeRetinalConversion, opticsParams.pupilSizeMM);
   
    end


    % Visualize mosaic and PSF
    visualizedDomainRangeMicrons = 40;
    simulator.visualize.mosaicAndPSF(theConeMosaic, visualizedDomainRangeMicrons, thePSF, ...
            psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength, ...
            WilliamsLabData.constants.imagingPeakWavelengthNM, opticsParams);
    
    fprintf('Computing responses of %s cone mosaic to %s stimuli varying in SF using %s optics.\n', ...
        monkeyID, stimulusParams.type, opticsParams.type);

end

function exportResidualDefocusOTF(theOI, psfSupportWavelength, residualDefocusDiopters)
    % Extract OTF at the in-focus wavelength
    theOptics = oiGet(theOI, 'optics');
    theOTF = opticsGet(theOptics, 'otf data');
    [~,idx] = min(abs(psfSupportWavelength-WilliamsLabData.constants.imagingPeakWavelengthNM));
    visualizedOTF = squeeze(theOTF(:,:,idx));
    visualizedOTF = fftshift(abs(visualizedOTF));
    r = (size(visualizedOTF,1)-1)/2+1;
    residualDefocusOTFmag = squeeze(visualizedOTF(r,:)); 

    % Extract spatial frequency support
    sfSupportCyclesPerMM = opticsGet(theOptics, 'otf fx');
    sfSupportCyclesPerDeg = sfSupportCyclesPerMM/1e3*WilliamsLabData.constants.micronsPerDegreeRetinalConversion;
   
    % Export
    save(simulator.utils.residualDefocusOTFFilename(residualDefocusDiopters), ...
        'sfSupportCyclesPerDeg', 'residualDefocusOTFmag');

    fprintf('Residual defocus OTF saved to %s\n', simulator.utils.residualDefocusOTFFilename(residualDefocusDiopters));
end
