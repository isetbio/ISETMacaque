function closeISETBioFitVisualization(visStruct)
    % Close video
    visStruct.videoOBJ.close();

    % Export PDF
    NicePlot.exportFigToPDF(visStruct.pdfFilename, visStruct.hFig, 300);
end
