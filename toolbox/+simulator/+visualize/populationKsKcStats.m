function populationKsKcStats(dataOut)

    % Collect the stats across all cells
    RGCsNum = numel(dataOut);
    
    KsToKcPhysiologicalOpticsAllCells = zeros(1, RGCsNum);
    KsToKcAOSLOOpticsAllCells = zeros(1, RGCsNum);
    eccDegsAllCells = zeros(1, RGCsNum);
    
    for iRGCindex = 1:RGCsNum
        d = dataOut{iRGCindex};
        for iParam = 1:numel(d.physiologicalOpticsDoGParams.names)
            if (strcmp(d.physiologicalOpticsDoGParams.names{iParam}, 'kS/kC'))
                KsToKcPhysiologicalOpticsAllCells(iRGCindex) = d.physiologicalOpticsDoGParams.bestFitValues(iParam);
            end
        end
        
        for iParam = 1:numel(d.AOSLOOpticsDoGparams.names)  
            if (strcmp(d.AOSLOOpticsDoGparams.names{iParam}, 'kS/kC'))
                KsToKcAOSLOOpticsAllCells(iRGCindex) = d.AOSLOOpticsDoGparams.bestFitValues(iParam);
            end
            eccDegsAllCells(iRGCindex) = d.centerConeEccDegs;
        end
    end
    
    % Generate figure
    [~, axesHandles] = CronerKaplanData.KsKcVersusEccentricity(...
            'generateFigure', true, ...
            'extraData1', struct(...
                'eccDegs',  eccDegsAllCells, ...
                'values', KsToKcPhysiologicalOpticsAllCells, ...
                'legend', 'M3 - Physiological optics'), ...
             'extraData2', struct(...
                'eccDegs',  eccDegsAllCells, ...
                'values', KsToKcAOSLOOpticsAllCells, ...
                'legend', 'M3 - AOSLO optics'));
        
    pdfFileName = simulator.filename.populationKsKcPlots(dataOut{1}.coneMosaicResponsesFileName, 'AOSLO_vs_PhysiologicalOptics');
    NicePlot.exportFigToPDF(pdfFileName, axesHandles.hFig, 300);
end

