function populationRcRsStats(dataOut, opticsParamsForBackingOutConeRc)

    % Collect the stats across all cells
    RGCsNum = numel(dataOut);
    
    
    RsToCenterConeRcPhysiologicalOpticsAllCells = zeros(1, RGCsNum);
    RcDegsPhysiologicalOpticsAllCells = zeros(1, RGCsNum);
    RsToCenterConeRcAOSLOOpticsAllCells = zeros(1, RGCsNum);
    RcDegsRetinalSingleConeRFcenterAllCells = zeros(1, RGCsNum);
    eccDegsAllCells = zeros(1, RGCsNum);
    
    for iRGCindex = 1:RGCsNum
        d = dataOut{iRGCindex};

        for iParam = 1:numel(d.physiologicalOpticsDoGParams.names)
            if (strcmp(d.physiologicalOpticsDoGParams.names{iParam}, 'RsToRc'))
                RsToCenterConeRcPhysiologicalOpticsAllCells(iRGCindex) = d.physiologicalOpticsDoGParams.bestFitValues(iParam);
            end
            
            if (strcmp(d.physiologicalOpticsDoGParams.names{iParam}, 'RcDegs'))
                RcDegsPhysiologicalOpticsAllCells(iRGCindex) = d.physiologicalOpticsDoGParams.bestFitValues(iParam);
            end
        end
        
        for iParam = 1:numel(d.AOSLOOpticsDoGparams.names)
            if (strcmp(d.AOSLOOpticsDoGparams.names{iParam}, 'RsToCenterConeRc'))
                RsToCenterConeRcAOSLOOpticsAllCells(iRGCindex) = d.AOSLOOpticsDoGparams.bestFitValues(iParam);
            end
            
            RcDegsRetinalSingleConeRFcenterAllCells(iRGCindex) = d.centerConeCharacteristicRadiusDegs;
            eccDegsAllCells(iRGCindex) = d.centerConeEccDegs;
        end
    end
    
    % Load the cone mosaic
    iRGCindex = 1;
    load(dataOut{iRGCindex}.coneMosaicResponsesFileName, 'theConeMosaic');
    
    %  Retrieve the Rc of all cones in the model mosaic
    allMosaicConesEcc = sqrt(sum(theConeMosaic.coneRFpositionsDegs.^2,2));
    allMosaicConesRc = theConeMosaic.coneRFspacingsDegs * 0.204 * sqrt(2.0);
    idx = find(allMosaicConesEcc< 0.6);
    allMosaicConesEcc = allMosaicConesEcc(idx);
    allMosaicConesRc = allMosaicConesRc(idx);
    
    anatomicalConeStudy = 'Curcio';
    anatomicalConeStudy = 'Packer ''89';

    switch (anatomicalConeStudy)
        case 'Curcio'
            % Retrieve the Rc based on the Curcio cone density data (human)
            obj = WatsonRGCModel();
            anatomicalConeEcc = logspace(log10(0.003), log10(40), 32);
            coneSpacingDegs = obj.coneRFSpacingAndDensityAlongMeridian(anatomicalConeEcc, ...
                'temporal meridian', 'deg', 'deg^2');
            anatomicalConeRc  = coneSpacingDegs * 0.204 * sqrt(2.0);
    
        case 'Packer ''89'
            % Retrieve the Rc based on the Packer cone density data (monkey)
            d = simulator.load.PackerConeRc(32);
            anatomicalConeEcc = d.eccDegs;
            anatomicalConeRc = d.temporalConeRcDegs;
    end % switch


    backOutConeRc = false;
    if (backOutConeRc)
        anatomicalConeStudyBackedOut = sprintf('%s (backed out to visual space)', anatomicalConeStudy);
        % Backout (to the visual space) the cone mosaic Rc using the current optics
        backedOutConeRc = simulator.optics.backOutAnatomicalConeRcThroughOptics(...
            anatomicalConeEcc, anatomicalConeRc, opticsParamsForBackingOutConeRc);
    else
        anatomicalConeStudyBackedOut = anatomicalConeStudy;
        backedOutConeRc = anatomicalConeRc;
    end

    


    % AOSLO-optics figure
    % Data identifiers
    anatomicalRcVector   = [1 0 0 0 0 0];
    modelMosaicRcVector  = [0 1 0 0 0 0];
    fittedSTFRcVector    = [0 0 1 0 0 0];
    fittedSTFRsVector    = [0 0 0 1 0 0];
    CronerKaplanRcVector = [0 0 0 0 1 0];
    CronerKaplanRsVector = [0 0 0 0 0 1];

    % Build up
    plotsToShow(1,:) = modelMosaicRcVector;
    plotsToShow(end+1,:) = plotsToShow(end,:) + fittedSTFRcVector;
    plotsToShow(end+1,:) = plotsToShow(end,:) + CronerKaplanRcVector;
    plotsToShow(end+1,:) = plotsToShow(end,:) + anatomicalRcVector - modelMosaicRcVector;
    plotsToShow(end+1,:) = plotsToShow(end,:) + fittedSTFRsVector + CronerKaplanRsVector;


    % One-shot bulding up
    %plotsToShow = [1 1 1 1 1 1];

    for gradualFigureBuildUpStep = 1:size(plotsToShow,1)
    
        % No optics case
        [~,~,~, axesHandles] = CronerKaplanData.RcRsVersusEccentricity(...
            squeeze(plotsToShow(gradualFigureBuildUpStep,:)), ...
            'generateFigure', true, ...
            'comboOptics', false, ...
            'extraRcDegsData', struct(...
                'eccDegs', eccDegsAllCells, ...
                'values', RcDegsRetinalSingleConeRFcenterAllCells, ...
                'legend', 'Rc (M3 - no optics)'), ...
             'extraRsDegsData', struct(...
                'eccDegs', eccDegsAllCells, ...
                'values', RcDegsRetinalSingleConeRFcenterAllCells .* RsToCenterConeRcAOSLOOpticsAllCells, ...
                'legend', 'Rs (M3 - no optics)'), ...
             'extraData2', struct(...
                'eccDegs', allMosaicConesEcc, ...
                'values', allMosaicConesRc, ...
                'legend', 'model mosaic cone Rc'), ...
              'extraData1', struct(...
                'eccDegs', anatomicalConeEcc, ...
                'values', anatomicalConeRc, ...
                'legend', anatomicalConeStudy) ...
            );
    
%         pdfFileName = simulator.filename.populationRcRsPlots(dataOut{1}.coneMosaicResponsesFileName, sprintf('AOSLOoptics_BuildingUpStep%d',gradualFigureBuildUpStep));
%         NicePlot.exportFigToPDF(pdfFileName, axesHandles.hFig, 300);

        % Physiological-optics case
        switch (opticsParamsForBackingOutConeRc.opticsType)
            case simulator.opticsTypes.diffractionLimited
                physioOpticsString = sprintf('diffr-limited, defocus:%2.3fD', opticsParamsForBackingOutConeRc.residualDefocusDiopters);
            case simulator.opticsTypes.M838
                physioOpticsString = sprintf('M3, pupil:%2.1fMM', opticsParamsForBackingOutConeRc.pupilSizeMM);
            case simulator.opticsTypes.Polans
                physioOpticsString = sprintf('Polans #%d, pupil:%2.1fMM', opticsParamsForBackingOutConeRc.PolansSubjectID, opticsParamsForBackingOutConeRc.pupilSizeMM);
        end

        [~,~,~, axesHandles] = CronerKaplanData.RcRsVersusEccentricity(...
            squeeze(plotsToShow(gradualFigureBuildUpStep,:)), ...
            'generateFigure', true, ...
            'axesHandles', axesHandles, ...
            'comboOptics', false, ...
            'extraRcDegsData', struct(...
                'eccDegs', eccDegsAllCells, ...
                'values', RcDegsPhysiologicalOpticsAllCells, ...
                'legend', sprintf('Rc (%s)',physioOpticsString)), ...
             'extraRsDegsData', struct(...
                'eccDegs', eccDegsAllCells, ...
                'values', RcDegsPhysiologicalOpticsAllCells .* RsToCenterConeRcPhysiologicalOpticsAllCells, ...
                'legend', sprintf('Rs (%s)',physioOpticsString)), ...
             'extraData2', struct(...
                'eccDegs', allMosaicConesEcc, ...
                'values', allMosaicConesRc, ...
                'legend', 'model mosaic cone Rc'), ...
             'extraData1', struct(...
                'eccDegs', anatomicalConeEcc, ...
                'values', backedOutConeRc, ...
                'legend', anatomicalConeStudyBackedOut) ...
            );
        %pdfFileName = simulator.filename.populationRcRsPlots(dataOut{1}.coneMosaicResponsesFileName, sprintf('BuildUpStep%d', gradualFigureBuildUpStep));
        %NicePlot.exportFigToPDF(pdfFileName, axesHandles.hFig, 300);
    end

    

    
    % Physiological vs AOSLO optics Rc/Rs ratio
    [~,~,~, axesHandles] = CronerKaplanData.RcRsVersusEccentricity(...
        plotsToShow, ...
        'generateFigure', true, ...
        'comboOptics', true, ...
        'extraData1', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', 1./RsToCenterConeRcPhysiologicalOpticsAllCells, ...
            'legend', 'M3 - physiological optics'), ...
        'extraData2', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', 1./RsToCenterConeRcAOSLOOpticsAllCells, ...
        'legend', 'M3 - AOSLO optics') ...
    );
    
    pdfFileName = simulator.filename.populationRcRsPlots(dataOut{1}.coneMosaicResponsesFileName, 'AOSLO_vs_PhysiologicalOptics');
    NicePlot.exportFigToPDF(pdfFileName, axesHandles.hFig, 300);
end

