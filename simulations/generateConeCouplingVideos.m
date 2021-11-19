function generateConeCouplingVideos


    % Initialize
    ieInit;
    clear;
    close all;

    % Generate a small cMosaic at ecc = (0,0)
    theConeMosaic = cMosaic(...
            'eccentricityDegs', [0 0], ...
            'sizeDegs', [0.2 0.2], ...
            'tritanopicRadiusDegs', 0, ...
            'eccVaryingConeBlur', true);
        
    % Find the cone nearest to (0,0);
    foveolaROI = struct(...
        'units', 'microns', ...
        'shape', 'rect', ...
        'center', [0 0], ...
        'width',  3, ...       % ROI width: 3 microns
        'height', 3, ...       % ROI height: 3 microns
        'rotation', 0);
    coneIndicesWithinROI = theConeMosaic.indicesOfConesWithinROI(foveolaROI);
    centerMostConePositionMicrons = theConeMosaic.coneRFpositionsMicrons(coneIndicesWithinROI(1),:);

    
    centerMostConePositionMicrons = [0 0];
    % Specify the desired stimulus
    stimParams = struct(...
        'spotXoMicrons', centerMostConePositionMicrons(1), ...   % place the spot on the targeted-cone
        'spotYoMicrons', centerMostConePositionMicrons(2), ...   % place the spot on the targeted-cone
        'spotDiameterMicrons', 0.2, ...
        'micronsPerDegree', theConeMosaic.micronsPerDegree, ...
        'wavelengthSupport', 550:2:570, ...
        'beamPeakWavelengthNM', 560, ...
        'beamFullWidthHalfMaxBandwidthNM', 3, ...
        'peakRadiance', 100 ...
        );
     
     % Generate the corresponding scene
     theScene = generateDeltaFunctionScene(stimParams);
     
     % Best possible optics: diffraction-limited with a large pupil
     opticalDefocusDiopters = 0.0;
     pupilDiameterMM = 6.7;
     wavelengthsListToCompute = theConeMosaic.wave;
     inFocusWavelength = stimParams.beamPeakWavelengthNM;
     [theOI, thePSF, psfSupportMinutesX, psfSupportMinutesY, psfSupportWavelength] = ...
       diffractionLimitedOptics(pupilDiameterMM, wavelengthsListToCompute, inFocusWavelength, ...
       theConeMosaic.micronsPerDegree, opticalDefocusDiopters, 'noLCA', ~true);
   
     % PSF at visualized wavelength
     [~,idx] = min(abs(psfSupportWavelength-stimParams.beamPeakWavelengthNM));
     thePSF = squeeze(thePSF(:,:,idx));
     theVisualizedPSF = struct(...
        'data', thePSF  / max(thePSF (:)), ...
        'spatialSupportMicronsX', psfSupportMinutesX/60*theConeMosaic.micronsPerDegree, ...
        'spatialSupportMicronsY', psfSupportMinutesY/60*theConeMosaic.micronsPerDegree);
     
     % Compute the optical image of the scene
     theOI = oiCompute(theScene, theOI);
     
     % Compute the spatial support of the oi
     spatialSupport = oiGet(theOI, 'spatial support', 'microns');
     oiResMicrons = spatialSupport(1,2,1) - spatialSupport(1,1,1);
     oiSpatialSupportXmicrons = squeeze(spatialSupport(1,:,1));
   
     
     % Compute the cone mosaic response (noise-free)
     noiseFreePhotopigmentsExcitationResponse = theConeMosaic.compute(theOI);
     
     % Visualize it
     figNo = 1;
     visualizeResults(figNo, sceneGet(theScene, 'rgbImage'), oiGet(theOI, 'rgbimage'), oiSpatialSupportXmicrons, ...
         theConeMosaic, theVisualizedPSF, ...
         noiseFreePhotopigmentsExcitationResponse, ...
         theConeMosaic.coneApertureModifiers, 0,[]);
     
     % Visualize the aperture shapes
     %visualizeApertureShapes(theConeMosaic, oiResMicrons, 101);
    
     % Change aperture to Gaussian with sigma = 0.204 x cone diameter
     % The 0.204 factor is from 'Serial Spatial Filters in Vision', by Chen, Makous and Williams, 1993
     apertureModifiers = theConeMosaic.coneApertureModifiers;
     apertureModifiers.shape = 'Gaussian';
     apertureModifiers.sigma = 0.204;
     theConeMosaic.coneApertureModifiers = apertureModifiers;

     % Compute the cone mosaic response (noise-free)
     noiseFreePhotopigmentsExcitationGaussianAperture = theConeMosaic.compute(theOI);
     
     % Visualize it
     figNo = 2;
     visualizeResults(figNo, sceneGet(theScene, 'rgbImage'), oiGet(theOI, 'rgbimage'), oiSpatialSupportXmicrons, ...
         theConeMosaic, theVisualizedPSF, ...
         noiseFreePhotopigmentsExcitationGaussianAperture, ...
         theConeMosaic.coneApertureModifiers, 0,[]);

     % Visualize the aperture shapes
     % visualizeApertureShapes(theConeMosaic, oiResMicrons, 102);
     
     % CONE COUPLING: 0.4 X INNER SEGMENT DIAMETER
     theConeMosaic.coneCouplingLambda = 0; % -0.4;

     % Compute the cone mosaic response (noise-free)
     noiseFreePhotopigmentsExcitationGaussianApertureCoupledCones = theConeMosaic.compute(theOI);

     % Visualize it
     figNo = 4;
     visualizeResults(figNo, sceneGet(theScene, 'rgbImage'), oiGet(theOI, 'rgbimage'), oiSpatialSupportXmicrons, ...
         theConeMosaic, theVisualizedPSF, ...
         noiseFreePhotopigmentsExcitationGaussianApertureCoupledCones, ...
         theConeMosaic.coneApertureModifiers, theConeMosaic.coneCouplingLambda, []);

     
     % Video with moving spot
     activationRange = [50 1200]; %[0 6000];
     
     coneCouplings = [-0.5];
     thetas = 0:10:(360*3);
     
     for k = 1:numel(coneCouplings)
         theConeMosaic.coneCouplingLambda = coneCouplings(k);
         
         for iTheta = 1:numel(thetas)
             fprintf('Computing responses for cone coupling: %f (frame:%d/%d)\n', coneCouplings(k), iTheta, numel(thetas));
             theta = -thetas(iTheta);
             radius = 1+12*(iTheta-1)/numel(thetas);
             stimParams.spotXoMicrons = radius * cosd(theta);
             stimParams.spotYoMicrons = radius * sind(theta);
             
             % Generate the corresponding scene
             theScene = generateDeltaFunctionScene(stimParams);
             theSceneRGBimages(iTheta, k,:,:,:) = sceneGet(theScene, 'rgbimage');
             if (numel(coneCouplings) == 1)
                 theSceneRGBimages(iTheta, 2,:,:,:) = theSceneRGBimages(iTheta, k,:,:,:);
                 theSceneRGBimages(iTheta, 3,:,:,:) = theSceneRGBimages(iTheta, k,:,:,:);
             end
             
             % Compute the optical image of the scene
             theOI = oiCompute(theScene, theOI);
             
             theOIRGBimages(iTheta, k,:,:,:) = oiGet(theOI, 'rgbimage');
             if (numel(coneCouplings) == 1)
                 theOIRGBimages(iTheta, 2,:,:,:) = theOIRGBimages(iTheta, k,:,:,:);
                 theOIRGBimages(iTheta, 3,:,:,:) = theOIRGBimages(iTheta, k,:,:,:);
             end
             
             % Compute the cone mosaic response (noise-free)
             noiseFreePhotopigmentsExcitations(iTheta,k,:,:) = theConeMosaic.compute(theOI);
             if (numel(coneCouplings) == 1)
                 noiseFreePhotopigmentsExcitations(iTheta,2,:,:) = noiseFreePhotopigmentsExcitations(iTheta,k,:,:);
                 noiseFreePhotopigmentsExcitations(iTheta,3,:,:) = noiseFreePhotopigmentsExcitations(iTheta,k,:,:);
             end
             
         end
     end
     
              
     videoFileName = sprintf('movingDotConeCoupling');
     videoOBJ = VideoWriter(videoFileName, 'MPEG-4');
     videoOBJ.FrameRate = 10;
     videoOBJ.Quality = 100;
     videoOBJ.open();   
     
     for iTheta = 1:numel(thetas)
           figNo = 5;
           hFig = visualizeResults(figNo, squeeze(theSceneRGBimages(iTheta,:,:,:,:)), ...
                    squeeze(theOIRGBimages(iTheta,:,:,:,:)), oiSpatialSupportXmicrons, ...
                    theConeMosaic, theVisualizedPSF, ...
                    squeeze(noiseFreePhotopigmentsExcitations(iTheta,:,:,:)), ...
                    theConeMosaic.coneApertureModifiers, coneCouplings, ...
                    activationRange);
           % Write video frame
           videoOBJ.writeVideo(getframe(hFig));
     end
         
     videoOBJ.close();
    
     
end

function visualizeApertureShapes(obj, oiResMicrons, figNo)
    lineROI = struct(...
        'units', 'microns', ...
        'shape', 'rect', ...
        'center', [0 0], ...
        'width',  30, ...
        'height', 30, ...
        'rotation', 0);
    
    coneIndicesWithinROI = obj.indicesOfConesWithinROI(lineROI);
    conePositionsMicrons = obj.coneRFpositionsMicrons(coneIndicesWithinROI,:);
    maxXY = max(conePositionsMicrons, [], 1);
    minXY = min(conePositionsMicrons, [], 1);
    nx = (minXY(1)-10*oiResMicrons) :oiResMicrons : (maxXY(1)+10*oiResMicrons);
    ny = (minXY(2)-10*oiResMicrons) :oiResMicrons : (maxXY(2)+10*oiResMicrons);
    
    zonesNum = numel(obj.blurApertureDiameterMicronsZones);
    coneAperturesImage = zeros(zonesNum,numel(ny),numel(nx));

    apertureKernelAllZones = cell(1, zonesNum);
    for zoneIndex = 1:zonesNum
        blurApertureDiameterMicrons = obj.blurApertureDiameterMicronsZones(zoneIndex);
        apertureKernel = obj.generateApertureKernel(blurApertureDiameterMicrons, oiResMicrons);
        apertureKernelAllZones{zoneIndex} = apertureKernel / max(apertureKernel(:));
    end
    
    for iCone = 1:numel(coneIndicesWithinROI)
        % Find cone index
        theConeIndex = coneIndicesWithinROI(iCone);
        
        % Find which zblur zone the cone is assigned to
        blurApertureZoneIndex = [];
        for zoneIndex = 1:zonesNum
            coneIDsInZone = obj.coneIndicesInZones{zoneIndex};
            if (ismember(theConeIndex, coneIDsInZone))
                blurApertureZoneIndex = zoneIndex;
            end
        end

        if (isempty(blurApertureZoneIndex))
            error('Could not find blur  zone for cone %d\n', theConeIndex);
        else
            theConePos = conePositionsMicrons(iCone,:);
            [~,xIndex] = min(abs(theConePos(1)-nx));
            [~,yIndex] = min(abs(theConePos(2)-ny));
            coneAperturesImage(blurApertureZoneIndex,yIndex,xIndex) = 1;
        end
    end
    
    
    for zoneIndex = 1:zonesNum
        coneAperturesImage(zoneIndex,:,:) = conv2(...
           squeeze(coneAperturesImage(zoneIndex,:,:)), apertureKernelAllZones{zoneIndex}, 'same');
    end
    
    
    
    figure(figNo); clf;
    for zoneIndex = 1:zonesNum
        subplot(2,zonesNum, zoneIndex);
        kernel = apertureKernelAllZones{zoneIndex};
        max(kernel(:))
        kernel = kernel/max(kernel(:));
        m = round(size(kernel,1)/2)+1;
        spatialSupport = 1:size(kernel,2);
        spatialSupport = (spatialSupport - mean(spatialSupport))* oiResMicrons;
        plot(spatialSupport , kernel(m,:), 'r-', 'LineWidth', 1.5);
        set(gca, 'XLim', [-3 3], 'XTick', -5:1:5, 'YLim', [0 1], 'YTick', 0:0.2:1);
        grid on
        xlabel('space (microns)');
        axis 'square';
        subplot(2,zonesNum, zonesNum+zoneIndex);
        imagesc(nx,ny, squeeze(coneAperturesImage(zoneIndex,:,:)));
        set(gca, 'CLim', [0 1]);
        axis 'image'
        title(sprintf('apertures at zone %d', zoneIndex))
    end
    colormap(gray(1024));
    drawnow;
end


function hFig = visualizeResults(figNo, theSceneRGBimages, theOIRGBimages, spatialSupportXmicrons, theConeMosaic, theVisualizedPSF, theConeMosaicResponses, ...
    coneApertureModifiers, coneCouplingLambdas, activationRange)

     if (~isfield(coneApertureModifiers, 'shape'))
         mosaicTitle = sprintf('cone mosaic (aperture: Pillbox-default)');
     else
         switch (coneApertureModifiers.shape)
             case 'Gaussian'
                 mosaicTitle = sprintf('cone mosaic\n(aperture: %s, s: %2.3f x diameter)', ...
                     coneApertureModifiers.shape, coneApertureModifiers.sigma);
             otherwise
                 mosaicTitle = sprintf('cone mosaic (aperture: %s)', ...
                     coneApertureModifiers.shape);
         end
     end
     
     
     visualizedRangeMirons = 16;
     
     rowsNum = 2;
     colsNum = 3;
     sv = NicePlot.getSubPlotPosVectors(...
           'colsNum', colsNum, ...
           'rowsNum', rowsNum, ...
           'heightMargin',  0.08, ...
           'widthMargin',    0.04, ...
           'leftMargin',     0.03, ...
           'rightMargin',    0.00, ...
           'bottomMargin',   0.05, ...
           'topMargin',      0.04);
       
     hFig = figure(figNo); 
     clf;
     set(hFig, 'Position', [10 10 1620 1100]);
     
     if (isfield(coneApertureModifiers ,'shape') && strcmp(coneApertureModifiers.shape, 'Gaussian'))
         visualizedConeAperture = 'lightCollectingArea4sigma';
     else
         visualizedConeAperture = 'geometricArea';
     end
                 
     ax = subplot('Position', sv(1,3).v);
     theConeMosaic.visualize('figureHandle', hFig, 'axesHandle', ax, ...
         'domain', 'microns', ...
         'domainVisualizationLimits', visualizedRangeMirons*[-1 1 -1 1], ...
         'domainVisualizationTicks', struct('x', [], 'y', []), ...
         'visualizedConeAperture', visualizedConeAperture, ...
         'crossHairsOnMosaicCenter', true, ...
         'crossHairsColor', [1 1 1], ...
         'backgroundColor', [0 0 0], ...
         'noXLabel', true, ...
         'noYLabel', true, ...
         'fontSize', 16, ...
         'plotTitle', mosaicTitle ...
         );
     
     % Superimpose the PSF
     hold(ax, 'on');
     cmap = brewermap(1024,'greys');
     alpha = 0.5;
     contourLineColor = [0.0 0.0 0.0];
     cMosaic.semiTransparentContourPlot(ax, ...
            theVisualizedPSF.spatialSupportMicronsY, theVisualizedPSF.spatialSupportMicronsY, theVisualizedPSF.data, [0.03:0.15:0.95], cmap, alpha, contourLineColor);

     
     if (isempty(activationRange))
         activationRange = [50 max(theConeMosaicResponses(:))];
     end
     cmap = brewermap(1024, '*greys');
     
     
     
     for k = 1:size(theConeMosaicResponses,1)
         
         ax = subplot('Position', sv(1,1).v);
         if (ndims(theSceneRGBimages) == 4)
            rgbImage = squeeze(theSceneRGBimages(k,:,:,:)); 
         else
             rgbImage = theSceneRGBimages;
         end
         
         x = 1:size(rgbImage,1);
         x = x - mean(x);
         y = x;
         image(ax,x,y,rgbImage);
         hold(ax, 'on');
         plot(ax, [0 0], [y(1), y(end)], '-', 'Color', [1 1 1], 'LineWidth', 1.0);
         plot(ax, [x(1), x(end)], [0 0], '-', 'Color', [1 1 1], 'LineWidth', 1.0);
         set(ax, 'XTick', [], 'YTick', [], 'FontSize', 16);
         title(ax,'stimulus scene');
         axis(ax,'image')

         ax = subplot('Position', sv(1,2).v);
         if (ndims(theSceneRGBimages) == 4)
            rgbImage = squeeze(theOIRGBimages(k,:,:,:)); 
         else
            rgbImage = theOIRGBimages;
         end
         
         image(ax,spatialSupportXmicrons, spatialSupportXmicrons, rgbImage);
         hold(ax, 'on');
         plot(ax, [0 0], [spatialSupportXmicrons(1), spatialSupportXmicrons(end)], '-', 'Color', [1 1 1], 'LineWidth', 1.0);
         plot(ax, [spatialSupportXmicrons(1), spatialSupportXmicrons(end)], [0 0], '-', 'Color', [1 1 1], 'LineWidth', 1.0);
         axis(ax,'image');
         set(ax, 'XLim', visualizedRangeMirons*[-1 1], 'YLim', visualizedRangeMirons*[-1 1]);
         set(ax, 'XTick', [], 'YTick', [], 'FontSize', 16);
         title(ax,'retinal image');

     
     
         ax = subplot('Position', sv(2,k).v);
         if (numel(coneCouplingLambdas) == 1)
             plotTitle = sprintf('cone coupling: %2.2f', coneCouplingLambdas(1));
         else
             plotTitle = sprintf('cone coupling: %2.2f', coneCouplingLambdas(k));
         end
         
         theConeMosaic.visualize('figureHandle', hFig, 'axesHandle', ax, ...
             'domain', 'microns', ...
             'domainVisualizationLimits', visualizedRangeMirons*[-1 1 -1 1], ...
             'domainVisualizationTicks', struct('x', -15:5:15, 'y', -15:5:15), ...
             'visualizedConeAperture', visualizedConeAperture, ...
             'crossHairsOnMosaicCenter', true, ...
             'crossHairsColor', [1 1 1], ...
             'activation', squeeze(theConeMosaicResponses(k,:)), ...
             'verticalActivationColorBarInside', true, ...
             'activationColorMap', cmap, ...
             'activationRange', activationRange, ... 
             'backgroundColor', [0 0 0], ...
             'fontSize', 16, ...
             'plotTitle', plotTitle ...
             );
     end
     drawnow;
end


function theScene = generateDeltaFunctionScene(stimParams)

    pixelSizeMicrons = 0.05;
    pixelSizeDegs = pixelSizeMicrons / stimParams.micronsPerDegree;
    pixelsNum = ceil(stimParams.spotDiameterMicrons/pixelSizeMicrons) * 130 + 1;
    fovDegs = pixelsNum *  pixelSizeDegs;
    
    % Compute spatial support
    spatialSupportMicrons = (1:pixelsNum)*pixelSizeMicrons;
    spatialSupportMicrons = spatialSupportMicrons - mean(spatialSupportMicrons);
    [X,Y] = meshgrid(spatialSupportMicrons, spatialSupportMicrons);
    
    % Generate spatial modulation pattern
    R = sqrt((X-stimParams.spotXoMicrons).^2+(Y-stimParams.spotYoMicrons).^2);
    spatialModulationPattern = R*0;
    spatialModulationPattern(R<=0.5*stimParams.spotDiameterMicrons) = 1;
    
    % Create an empty scene.  Put it 20 meters away so it
    % is basically in focus for an emmetropic eye accommodated to infinity.
    theScene = sceneCreate('empty');
    theScene = sceneSet(theScene,'wavelength',stimParams.wavelengthSupport);
    theScene = sceneSet(theScene,'distance', 20);
    
    % The spectral profile of the imaging beam
    gratingSpdRadianceProfile = exp(-0.5*((stimParams.wavelengthSupport-stimParams.beamPeakWavelengthNM)/FWHMToStd(stimParams.beamFullWidthHalfMaxBandwidthNM)).^2);
    
    % Compute the stimulus spatial-spectral radiance
    stimulusRadiance = zeros(pixelsNum, pixelsNum, numel(stimParams.wavelengthSupport));
    for iWave = 1:numel(stimParams.wavelengthSupport)
        stimulusRadiance(:,:,iWave) = stimParams.peakRadiance * spatialModulationPattern * gratingSpdRadianceProfile(iWave);
    end
    
     % Set the scene radiance
    theScene = sceneSet(theScene, 'energy', stimulusRadiance, stimParams.wavelengthSupport);
    
    % Set the desired FOV
    theScene = sceneSet(theScene, 'h fov', fovDegs);
end
