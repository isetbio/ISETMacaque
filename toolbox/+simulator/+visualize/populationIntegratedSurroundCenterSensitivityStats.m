function populationIntegratedSurroundCenterSensitivityStats(dataOut)

    % Collect the stats across all cells
    RGCsNum = numel(dataOut);
    
    weightsSurroundToCenterRatioAllCells = zeros(1, RGCsNum);
    
    RsToCenterConeRcPhysiologicalOpticsAllCells = zeros(1, RGCsNum);
    KsToKcPhysiologicalOpticsAllCells = zeros(1, RGCsNum);
    RcDegsPhysiologicalOpticsAllCells = zeros(1, RGCsNum);
    
    RsToCenterConeRcAOSLOOpticsAllCells = zeros(1, RGCsNum);
    KsToKcAOSLOOpticsAllCells = zeros(1, RGCsNum);
    RcDegsRetinalSingleConeRFcenterAllCells = zeros(1, RGCsNum);
    
    eccDegsAllCells = zeros(1, RGCsNum);
    
    for iRGCindex = 1:RGCsNum
        d = dataOut{iRGCindex};
        weightsSurroundToCenterRatioAllCells(iRGCindex) = d.weightsSurroundToCenterRatio;
        
        for iParam = 1:numel(d.physiologicalOpticsDoGParams.names)
            if (strcmp(d.physiologicalOpticsDoGParams.names{iParam}, 'RsToCenterConeRc'))
                RsToCenterConeRcPhysiologicalOpticsAllCells(iRGCindex) = d.physiologicalOpticsDoGParams.bestFitValues(iParam);
            end
            
            if (strcmp(d.physiologicalOpticsDoGParams.names{iParam}, 'kS/kC'))
                KsToKcPhysiologicalOpticsAllCells(iRGCindex) = d.physiologicalOpticsDoGParams.bestFitValues(iParam);
            end
            
            if (strcmp(d.physiologicalOpticsDoGParams.names{iParam}, 'RcDegs'))
                RcDegsPhysiologicalOpticsAllCells(iRGCindex) = d.physiologicalOpticsDoGParams.bestFitValues(iParam);
            end
        end
        
        
        for iParam = 1:numel(d.AOSLOOpticsDoGparams.names)
            if (strcmp(d.AOSLOOpticsDoGparams.names{iParam}, 'RsToCenterConeRc'))
                RsToCenterConeRcAOSLOOpticsAllCells(iRGCindex) = d.AOSLOOpticsDoGparams.bestFitValues(iParam);
            end
            
            if (strcmp(d.AOSLOOpticsDoGparams.names{iParam}, 'kS/kC'))
                KsToKcAOSLOOpticsAllCells(iRGCindex) = d.AOSLOOpticsDoGparams.bestFitValues(iParam);
            end
            
            RcDegsRetinalSingleConeRFcenterAllCells(iRGCindex) = d.centerConeCharacteristicRadiusDegs;
            eccDegsAllCells(iRGCindex) = d.centerConeEccDegs;
        end
    end
    
    
    % Integrated surround/center sensitivity ratios - physiological optics
    intSurroundCenterSensitivityRatiosPhysiologicalOpticsAllCells = KsToKcPhysiologicalOpticsAllCells .* (RsToCenterConeRcPhysiologicalOpticsAllCells.^2);
       
    % Integrated surround/center sensitivity ratios - AOSLO optics
    intSurroundCenterSensitivityRatiosAOSLOOpticsAllCells = KsToKcAOSLOOpticsAllCells .* (RsToCenterConeRcAOSLOOpticsAllCells.^2);   
    
    
    % Generate figure
    [~, axesHandles] = CronerKaplanData.integratedSurroundCenterSensitivityVersusEccentricity(...
            'generateFigure', true, ...
            'extraData1', struct(...
                'eccDegs',  eccDegsAllCells, ...
                'values', intSurroundCenterSensitivityRatiosPhysiologicalOpticsAllCells, ...
                'legend', 'M3 - Physiological optics'), ...
             'extraData2', struct(...
                'eccDegs',  eccDegsAllCells, ...
                'values', intSurroundCenterSensitivityRatiosAOSLOOpticsAllCells, ...
                'legend', 'M3 - AOSLO optics'));
        
    pdfFileName = simulator.filename.populationIntegratedSensitivityPlots(dataOut{1}.coneMosaicResponsesFileName, 'AOSLO_vs_PhysiologicalOptics');
    NicePlot.exportFigToPDF(pdfFileName, axesHandles.hFig, 300);
    
 end