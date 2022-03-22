function runBatchComputePhysiologicalOpticsSTF()
% Batch generate all physiological optics STFs
%
% Syntax:
%   runBatchComputePhysiologicalOpticsSTF()
%
% Description:
%   Batch generate all physiological optics STFs
%
% Inputs:
%    none
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    None
%         

    % Monkey to analyze
    monkeyID = 'M838';


    % Choose which optics scenario to run.
    % To list the available options, type:
    %    enumeration simulator.opticsScenarios
    operationOptions.opticsScenario = simulator.opticsScenarios.diffrLimitedOptics_residualDefocus;
    operationOptions.residualDefocusDiopters = 0.067;
    operationOptions.residualDefocusDiopters = 0.000;

    % M838 optics scenario
    operationOptions.opticsScenario = simulator.opticsScenarios.M838Optics;
    operationOptions.pupilSizeMM = 2.5;

    % Polans subject optics scenario
    %operationOptions.opticsScenario = simulator.opticsScenarios.PolansOptics;
    %operationOptions.subjectID = 8; % [2 8 9]
    %operationOptions.pupilSizeMM = 3.0;
    

    % Choose which stimulus type to use.
    % To list the available options, type:
    %    enumeration simulator.stimTypes
    operationOptions.stimulusType = simulator.stimTypes.achromaticLCD;

    % Choose what operation to run.


    % RF center pooling scenarios to examine
    operationOptions.rfCenterConePoolingScenariosExamined = ...
        {'single-cone', 'multi-cone'};


 
    % Select the spatial sampling within the cone mosaic
    % From 2022 ARVO abstract: "RGCs whose centers were driven by cones in
    % the central 6 arcmin of the fovea"
    operationOptions.coneMosaicSamplingParams = struct(...
        'maxEccArcMin', 6, ...
        'positionsExamined', 7 ... % select 7 cone positions within the maxEcc region
        );

    % Fit options
    operationOptions.fitParams = struct(...
        'multiStartsNum', 512, ...
        'accountForNegativeSTFdata', true, ...
        'spatialFrequencyBias', simulator.spatialFrequencyWeightings.boostHighEnd ...
        );
    

    operation = simulator.operations.computeSynthesizedRGCSTFresponses;
   
    
    % Examined RGCs (all 11 L-center and 4 M-center)
    LconeRGCsNum  = 11;
    MconeRGCsNum = 4;
    coneTypes(1:LconeRGCsNum) = {'L'};
    coneTypes(LconeRGCsNum+(1:MconeRGCsNum)) = {'M'};
    coneRGCindices(1:LconeRGCsNum) = 1:LconeRGCsNum;
    coneRGCindices(LconeRGCsNum+(1:MconeRGCsNum)) = 1:MconeRGCsNum;

    for iRGCindex = 1:numel(coneRGCindices)
        
         % Select which recording session and which RGC to fit. 
        operationOptions.STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
        'whichSession', 'meanOverSessions', ...
        'whichCenterConeType', coneTypes{iRGCindex}, ...
        'whichRGCindex', coneRGCindices(iRGCindex));
    
        theSyntheticRGCIDstring = sprintf('%s%d', operationOptions.STFdataToFit.whichCenterConeType,  operationOptions.STFdataToFit.whichRGCindex);
        switch (theSyntheticRGCIDstring)
            case 'L1'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.0;
             case 'L2'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.057;
            case 'L3'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.077;
            case 'L4'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.077;
            case 'L5'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.067; %FLAT b/ 0.062-0.072
            case 'L6'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.082;
            case 'L7'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.0;
            case 'L8'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.0;   %FLAT n/n 0 - 0.057
            case 'L9'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.077; 
            case 'L10'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.077; % FLAT b/n 0.067-.0.077
            case 'L11'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.062; % FLAT b/n 0.057-0.067
            case 'M1'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.067; % FLAT between 0.057-0.077
            case 'M2'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.0;
            case 'M3'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.067;  % FLAT from 0 - 0.072
            case 'M4'
                residualDefocusUsedToDerivedOpticmalSyntheticRGCModel = 0.0;  % FLAT from 0 to 0.062
            otherwise
                error('Must be a residual defocus for cell %s', theSyntheticRGCIDstring)
        end
    
        % Params used to derive the RGC model
        operationOptions.syntheticRGCmodelParams = struct(...
            'opticsParams', struct(...
                'type', simulator.opticsTypes.diffractionLimited, ...
                'residualDefocusDiopters', residualDefocusUsedToDerivedOpticmalSyntheticRGCModel), ...
            'stimulusParams', struct(...
                'type', simulator.stimTypes.monochromaticAO), ...
            'cMosaicParams', struct(...
                'coneCouplingLambda', 0.0), ...
            'rfCenterConePoolingScenario', 'single-cone', ...
            'rmsSelector', 'unweighted'...
          );
    

        % Go !
        dataOut{iRGCindex} = simulator.performOperation(operation, operationOptions, monkeyID);
    end
    
    % Collect the stats
    for iRGCindex = 1:numel(coneRGCindices)
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
    
    % Add the variation in coneRc for the M838 mosaic
    % Load the cone mosaic
    load(dataOut{iRGCindex}.coneMosaicResponsesFileName, 'theConeMosaic');
    
    %  Plot the Rc of all cones in the model mosaic
    allMosaicConesEcc = sqrt(sum(theConeMosaic.coneRFpositionsDegs.^2,2));
    allMosaicConesRc = theConeMosaic.coneRFspacingsDegs * 0.204 * sqrt(2.0);
    idx = find(allMosaicConesEcc< 0.6);
    allMosaicConesEcc = allMosaicConesEcc(idx);
    allMosaicConesRc = allMosaicConesRc(idx);
    
    % Add the curcio mosaic data
    obj = WatsonRGCModel();
    CurcioModelConesEcc = logspace(log10(0.01), log10(100), 100);
    coneSpacingDegs = obj.coneRFSpacingAndDensityAlongMeridian(CurcioModelConesEcc, 'temporal meridian', 'deg', 'deg^2');
    CurcioModelConesRc  = coneSpacingDegs * 0.204 * sqrt(2.0);

    
   
    % AOSLO-optics figure
    [~,~,~, axesHandles1] = CronerKaplanData.RcRsVersusEccentricity(...
        'generateFigure', true, ...
        'extraRcRsRatioData', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', 1./RsToCenterConeRcAOSLOOpticsAllCells, ...
            'legend', 'M3 - AOSLO optics'), ...
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
            'eccDegs', CurcioModelConesREcc, ...
            'values', CurcioModelConesRc, ...
            'legend', 'Curcio model Rc') ...
        );
    NicePlot.exportFigToPDF('AOSLOopticsRcRsSummary.pdf', axesHandles1.hFig, 300);
    
    
    % Physiological-optics figure
    [~,~,~, axesHandles2] = CronerKaplanData.RcRsVersusEccentricity(...
        'generateFigure', true, ...
        'extraRcRsRatioData', struct(...
            'eccDegs', eccDegsAllCells, ...
            'values', 1./RsToCenterConeRcPhysiologicalOpticsAllCells, ...
            'legend', 'M3 - physiological optics'), ...
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
            'eccDegs', CurcioModelConesREcc, ...
            'values', CurcioModelConesRc, ...
            'legend', 'Curcio model Rc') ...
        );
        NicePlot.exportFigToPDF('PhysiologicalOpticsRcRsSummary.pdf', axesHandles2.hFig, 300);
   
end

