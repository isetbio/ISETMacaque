% Generate optics 
%
% Syntax:
%   theOI = simulator.optics.generate(monkeyID, opticsParams)
%
% Description: Generate optics
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021


function [theOI, thePSFdata] = generate(monkeyID, opticsParams)

    % Assert that we have valid optics system
    assert(ismember(opticsParams.type, enumeration('simulator.opticsTypes')), ...
                sprintf('''%s'' is not a valid optics type.\nValid options are:\n %s', ...
                opticsParams.type, sprintf('\t%s\n',(enumeration('simulator.opticsTypes')))));
            
    % Generate the optics
    switch (opticsParams.type)
        case simulator.opticsTypes.diffractionLimited
            [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, ...
             psfWavelengthSupport] = diffractionLimitedOptics(...
                opticsParams.pupilSizeMM, opticsParams.wavelengthSupport, ...
                WilliamsLabData.constants.imagingPeakWavelengthNM, ...
                WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
                opticsParams.residualDefocusDiopters, 'noLCA', false);

            % Export the OTF of the residual blur AOSLO system. This will be used for
            % de-convonlving the DF/F responses before fitting them with the DoG model
            if (abs(opticsParams.residualDefocusDiopters) > 0)
                exportResidualDefocusOTF(theOI, psfWavelengthSupport, opticsParams.residualDefocusDiopters);
            end

        case simulator.opticsTypes.Polans
             [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, ...
                 psfWavelengthSupport] = PolansOptics.oiForSubjectAtEccentricity(...
                 opticsParams.PolansSubject, 'right eye', [0 0], ...
                 opticsParams.pupilSizeMM, opticsParams.wavelengthSupport, ...
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
            psfWavelengthSupport = opticsParams.wavelengthSupport;
            [~,idx] = min(abs(psfWavelengthSupport-measWavelength));
            measWavelength = wpsfWavelengthSupport(idx);
            [thePSF, ~, ~,~, psfSupportMinutesX, psfSupportMinutesY, theWVF] = ...
               computePSFandOTF(Zcoeffs, ...
                                psfWavelengthSupport , 701, ...
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
    
    thePSFdata =  struct(...
        'psf', thePSF, ...
        'supportMinutesX', psfSupportMinutesX, ...
        'supportMinutesY', psfSupportMinutesY, ...
        'supportWavelengthNM', psfWavelengthSupport);
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