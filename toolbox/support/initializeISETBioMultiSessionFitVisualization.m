function visStruct = initializeISETBioMultiSessionFitVisualization(...
            isATrainingRun, ...
            iRGCindex, centerConeType, startingPointsNum, crossValidationRun, ...
            modelVariant)


    if (isATrainingRun)
        error('Cannot be a training run with multiple sessions');
    end

    [pdfFilename, videoFileName] = fitsPDFFilename(...
            modelVariant, sprintf('%s%d',centerConeType, iRGCindex), startingPointsNum, ...
            crossValidationRun, 'MultiSessionTest');
    visStruct.pdfFilename = pdfFilename;

    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'rowsNum', 2, ...
       'colsNum', 3, ...
       'heightMargin',  0.12, ...
       'widthMargin',    0.04, ...
       'leftMargin',     0.04, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.065, ...
       'topMargin',      0.00);

    % Set up figure and axes
    visStruct.hFig = figure(iRGCindex + crossValidationRun*100); clf;
    set(visStruct.hFig, 'Position', [10 10 1250 850], 'Color', [1 1 1]);

    % Left-most plot, 2D error map
    visStruct.axMap  = subplot('Position', subplotPosVectors(1,3).v);

    % Second plot. The relationhip between rms errors for the different
    % test sessions
    visStruct.axSessionsRMSE = subplot('Position', subplotPosVectors(1,2).v);

   % The best STF fits
    visStruct.axSTFfits = subplot('Position', subplotPosVectors(1,1).v);

   
    

     % Third plot. The RF profile
    visStruct.axRF = subplot('Position', subplotPosVectors(2,1).v);

    % The cone weights
    visStruct.axConeWeights = subplot('Position', subplotPosVectors(2,2).v);

     % The cone mosaic
    visStruct.axConeMosaic = subplot('Position', subplotPosVectors(2,3).v);


    % Video showing all cones
    visStruct.videoOBJ = VideoWriter(videoFileName, 'MPEG-4');
    visStruct.videoOBJ.FrameRate = 30;
    visStruct.videoOBJ.Quality = 100;
    visStruct.videoOBJ.open();
    
end
