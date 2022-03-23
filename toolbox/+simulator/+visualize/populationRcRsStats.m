function populationRcRsStats(dataOut)

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
    
    % Load the cone mosaic
    iRGCindex = 1;
    load(dataOut{iRGCindex}.coneMosaicResponsesFileName, 'theConeMosaic');
    
    %  Plot the Rc of all cones in the model mosaic
    allMosaicConesEcc = sqrt(sum(theConeMosaic.coneRFpositionsDegs.^2,2));
    allMosaicConesRc = theConeMosaic.coneRFspacingsDegs * 0.204 * sqrt(2.0);
    idx = find(allMosaicConesEcc< 0.6);
    allMosaicConesEcc = allMosaicConesEcc(idx);
    allMosaicConesRc = allMosaicConesRc(idx);
    
    % Add the curcio mosaic data
    obj = WatsonRGCModel();
    CurcioModelConesEcc = logspace(log10(0.003), log10(40), 100);
    coneSpacingDegs = obj.coneRFSpacingAndDensityAlongMeridian(CurcioModelConesEcc, 'temporal meridian', 'deg', 'deg^2');
    CurcioModelConesRc  = coneSpacingDegs * 0.204 * sqrt(2.0);
    
   
    % AOSLO-optics figure
    [~,~,~, axesHandles1] = CronerKaplanData.RcRsVersusEccentricity(...
        'generateFigure', true, ...
        'comboOptics', false, ...
        'extraRcDegsData', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', RcDegsRetinalSingleConeRFcenterAllCells, ...
            'legend', 'Rc (M3 - AOSLO optics)'), ...
         'extraRsDegsData', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', RcDegsRetinalSingleConeRFcenterAllCells .* RsToCenterConeRcAOSLOOpticsAllCells, ...
            'legend', 'Rs (M3 - AOSLO optics)'), ...
         'extraData1', struct(...
            'eccDegs', allMosaicConesEcc, ...
            'values', allMosaicConesRc, ...
            'legend', 'model mosaic cone Rc'), ...
          'extraData2', struct(...
            'eccDegs', CurcioModelConesEcc, ...
            'values', CurcioModelConesRc, ...
            'legend', 'Curcio model Rc (temporal meridian)') ...
        );
    
    pdfFileName = simulator.filename.populationRcRsPlots(dataOut{1}.coneMosaicResponsesFileName, 'AOSLOoptics');
    NicePlot.exportFigToPDF(pdfFileName, axesHandles1.hFig, 300);
    
    
    % Physiological-optics figure
    [~,~,~, axesHandles2] = CronerKaplanData.RcRsVersusEccentricity(...
        'generateFigure', true, ...
        'comboOptics', false, ...
        'extraRcDegsData', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', RcDegsPhysiologicalOpticsAllCells, ...
            'legend', 'Rc (M3 - physiological optics)'), ...
         'extraRsDegsData', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', RcDegsPhysiologicalOpticsAllCells .* RsToCenterConeRcPhysiologicalOpticsAllCells, ...
            'legend', 'Rs (M3 - physiological optics)'), ...
         'extraData1', struct(...
            'eccDegs', allMosaicConesEcc, ...
            'values', allMosaicConesRc, ...
            'legend', 'model mosaic cone Rc'), ...
          'extraData2', struct(...
            'eccDegs', CurcioModelConesEcc, ...
            'values', CurcioModelConesRc, ...
            'legend', 'Curcio model Rc (temporal meridian)') ...
        );
    pdfFileName = simulator.filename.populationRcRsPlots(dataOut{1}.coneMosaicResponsesFileName, 'PhysiologicalOptics');
    NicePlot.exportFigToPDF(pdfFileName, axesHandles2.hFig, 300);
    
    
    % Physiological vs AOSLO optics Rc/Rs ratio
    [~,~,~, axesHandles3] = CronerKaplanData.RcRsVersusEccentricity(...
        'generateFigure', true, ...
        'comboOptics', true, ...
        'extraData1', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', 1./RsToCenterConeRcAOSLOOpticsAllCells, ...
            'legend', 'M3 - AOSLO optics'), ...
        'extraData2', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', 1./RsToCenterConeRcPhysiologicalOpticsAllCells, ...
            'legend', 'M3 - physiological optics') ...
    );
    
    pdfFileName = simulator.filename.populationRcRsPlots(dataOut{1}.coneMosaicResponsesFileName, 'PhysiologicalOptics');
    pdfFileName = strrep(pdfFileName, 'PhysiologicalOptics', 'AOSLO_vs_PhysiologicalOptics');
    NicePlot.exportFigToPDF(pdfFileName, axesHandles3.hFig, 300);
    
    
end

