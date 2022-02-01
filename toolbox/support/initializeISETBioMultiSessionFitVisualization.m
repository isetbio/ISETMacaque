function visStruct = initializeISETBioMultiSessionFitVisualization(...
            isATrainingRun, ...
            iRGCindex, centerConeType, startingPointsNum, crossValidationRun, ...
            residualDefocusDiopters)


    if (isATrainingRun)
        error('Cannot be a training run with multiple sessions');
    end

    [pdfFilename, videoFileName] = fitsPDFFilename(...
            residualDefocusDiopters, sprintf('%s%d',centerConeType, iRGCindex), startingPointsNum, ...
            crossValidationRun, 'MultiSessionTest');
    visStruct.pdfFilename = pdfFilename;

    % Set up figure and axes
    visStruct.hFig = figure(iRGCindex); clf;
    set(visStruct.hFig, 'Position', [10 10 1680 450], 'Color', [1 1 1]);

    % Left-most plot, 2D error map
    visStruct.axMap  = subplot('Position', [0.02 0.12 0.22 0.8]);

    % Second plot. The relationhip between rms errors for the different
    % test sessions
    visStruct.axSessionsRMSE = subplot('Position', [0.28 0.12 0.22 0.8]);

    % Third plot. The RF profile
    visStruct.axRF = subplot('Position', [0.525 0.12 0.22 0.8]);

    % Fourth plot. The cone weights
    visStruct.axConeWeights = subplot('Position', [0.78 0.12 0.22 0.8]);

    % Video showing all cones
    visStruct.videoOBJ = VideoWriter(videoFileName, 'MPEG-4');
    visStruct.videoOBJ.FrameRate = 30;
    visStruct.videoOBJ.Quality = 100;
    visStruct.videoOBJ.open();
    
end
