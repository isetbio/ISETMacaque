function generate2022Video

    presentationDisplay = generateCustomDisplay(...
        'dotsPerInch', 220, ...
        'viewingDistanceMeters', 1.00, ...
        'gammaTable', repmat((linspace(0,1,1024)').^2, [1 3]), ...
        'plotCharacteristics', true);
    
    %% Select stimulus chromaticity specification
    chromaSpecificationType = 'RGBsettings';  % choose between {'RGBsettings', 'chromaLumaLMScontrasts'}
    
    % gamma uncorrected values
    switch (chromaSpecificationType)
        case 'RGBsettings'
        % Specify both background and stimulus in terms of RGB settings
        % values on presentation display
        chromaSpecification = struct(...
                'type', chromaSpecificationType, ...
                'backgroundRGB', [0.5 0.5 0.5], ...
                'foregroundRGB',  [1 1 1]);
                    
        case 'chromaLumaLMScontrasts'
        % Specify background in terms of cie-31 (x,y) and luminance (cd/m2)
        % and stimulus in terms of nominal LMS cone contrasts
        chromaSpecification = struct(...
               'type', chromaSpecificationType, ...
               'backgroundChromaLuma', [0.31 0.32 40], ...
               'foregroundLMSConeContrasts', [-0.5 -0.5 0.0]); 
    end
    
    % Stimulus params
    textSceneParams = struct(...
        'textString1', 'MM.', ...                   % Text to display
        'textString2', ' XX.', ... 
        'textString3', '  II.', ... 
        'textRotation', 0, ...                         % Rotation (0,90,180,270 only)
        'rowsNum', 30, ...                             % Pixels along the vertical (y) dimension
        'colsNum', 125, ...                            % Pixels along the horizontal (x) dimension
        'targetRow', 1, ...                           % Stimulus Y-pixel offset 
        'targetCol', 20, ...                           % Stimulus X-pixel offset 
        'chromaSpecification', chromaSpecification ... % Background and stimulus chromaticity
    );
            
    % Generate the scene
    visualizeScene = ~true;
    theScene = rotatedTextSceneRealizedOnDisplay(presentationDisplay, textSceneParams, visualizeScene);
    theScene = sceneSet(theScene, 'fov', 1.7);

    load('/Volumes/SSDdisk/MATLAB/projects/ISETMacaque/toolbox/dataResources/coneMosaicM838.mat', 'cm');
    cm.integrationTime = 2/1000;
    
    % Generate 1 eye movement sequence lasting for 100 msec
    eyeMovementDurationSeconds = 200/1000;
    cm.emGenSequence(eyeMovementDurationSeconds, ...
        'microsaccadeType', 'stats based', ...
        'microsaccadeMeanIntervalSeconds', 0.05, ...
        'nTrials', 1, ...
        'randomSeed', 12234);
    
    % Visualize cone mosaic and eye movement path
    cm.visualize('displayedEyeMovementData', struct('trial', 1, 'timePoints', 1:100));
    


    wavelengthSupport = WilliamsLabData.constants.imagingPeakWavelengthNM + (-160:10:140);
    opticalDefocusDiopters = 0.0;

    noLCA = false;
    [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength] = diffractionLimitedOptics(...
            WilliamsLabData.constants.pupilDiameterMM, wavelengthSupport, ...
            WilliamsLabData.constants.imagingPeakWavelengthNM, ...
            WilliamsLabData.constants.micronsPerDegreeRetinalConversion, ...
            opticalDefocusDiopters, 'noLCA', noLCA);

    % Visualize the PSF
    [sfSupportCyclesPerDeg, visualizedOTFslice] = visualizeDiffractionLimitedPSF(thePSF, psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength, ...
            theOI, WilliamsLabData.constants.imagingPeakWavelengthNM);
 
    % Compute the optical image of the background stimulus
    theOI = oiCompute(theScene, theOI);
    
    % Compute the cone mosaic response time series
    [coneExcitationsNoiseFree, coneExcitations] = ...
        cm.compute(theOI, 'withFixationalEyeMovements', true);
    
    videoOBJ = VideoWriter('2022', 'MPEG-4');
        videoOBJ.FrameRate = 10;
        videoOBJ.Quality = 100;
        videoOBJ.open();

    hFig = figure();
    set(hFig, 'Position', [10 10 1024 1024], 'Color', [0 0 0]);
    greens = zeros(1024,3);
    greens(:,2) = linspace(0,1,1024);
    ax = subplot('Position', [0.05 0.05 0.90 0.94]);
    for tBin = 1:size(coneExcitationsNoiseFree,2)
        cm.visualize('figureHandle', hFig, 'axesHandle', ax, ...
            'activation', squeeze(coneExcitations(1,tBin,:)), ...
            'activationColorMap', greens, ...
            'backgroundColor', [0 0 0], ...
            'activationRange', [0 150], ...
            'verticalActivationColorBarInside', true, ...
            'crossHairsOnMosaicCenter', true, ...
            'crossHairsColor', [1 0 0], ...
            'plotTitle', ' ');
        
     hFig.Color = [0 0 0];
     drawnow;
     videoOBJ.writeVideo(getframe(hFig));
    end
videoOBJ.close();

end