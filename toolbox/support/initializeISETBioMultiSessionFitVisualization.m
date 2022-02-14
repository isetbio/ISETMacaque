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
       'colsNum', 4, ...
       'heightMargin',  0.12, ...
       'widthMargin',    0.04, ...
       'leftMargin',     0.04, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.065, ...
       'topMargin',      0.00);

    subplotPosVectors = subplotPosVectors(:);

    visStruct.hFig = figure(999); clf;
    set(visStruct.hFig, 'Position', [100 100 1500 850], 'Color', [1 1 1]);
    % The STF fits
    for iPos = 1:8
        visStruct.axSTFfits{iPos} = subplot('Position', subplotPosVectors(iPos).v);
    end

    % Video showing all cones
    visStruct.videoOBJ = VideoWriter(videoFileName, 'MPEG-4');
    visStruct.videoOBJ.FrameRate = 30;
    visStruct.videoOBJ.Quality = 100;
    visStruct.videoOBJ.open();
    
end
