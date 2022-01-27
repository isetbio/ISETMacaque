function visStruct = initializeISETBioFitVisualization(iRGCindex, centerConeType, startingPointsNum, crossValidationRun, ...
            residualDefocusDiopters)

    % Generate pdf and video filenames
    [pdfFilename, videoFileName] = fitsPDFFilename(...
        residualDefocusDiopters, sprintf('%s%d',centerConeType, iRGCindex), startingPointsNum, crossValidationRun);
    visStruct.pdfFilename = pdfFilename;

    % Set up figure and axes
    visStruct.hFig = figure(iRGCindex); clf;
    set(visStruct.hFig, 'Position', [10 10 1680 450], 'Color', [1 1 1]);
    visStruct.axRF = subplot('Position', [0.525 0.12 0.22 0.8]);
    visStruct.axConeWeights = subplot('Position', [0.78 0.12 0.22 0.8]);
    visStruct.axFit  = subplot('Position', [0.28 0.12 0.22 0.8]);
    visStruct.axMap  = subplot('Position', [0.02 0.12 0.22 0.8]);

    % Video showing all cones
    visStruct.videoOBJ = VideoWriter(videoFileName, 'MPEG-4');
    visStruct.videoOBJ.FrameRate = 30;
    visStruct.videoOBJ.Quality = 100;
    visStruct.videoOBJ.open();
end