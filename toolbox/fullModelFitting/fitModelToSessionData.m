function [fittedParams, fittedSTFs, rmsErrors, rmsErrorsTrain, ...
    centerConeCharacteristicRadiusDegs, centerConesFractionalNum, centroidPosition, ...
    centerConeIndices, centerConeWeights, surroundConeIndices, surroundConeWeights] = fitModelToSessionData(...
                theTrainedModel, modelSTFrunData, ...
                indicesOfModelConesDrivingTheRGCcenters, ...
                d, crossValidationRun, startingPointsNum, ...
                centerConeType, modelVariant, targetRGCindices, varargin)

   
    assert( ((isempty(d.test)) == isempty(theTrainedModel)), ...
        sprintf('Incosistent d.test and theTrainedModel params'));

    % Fit each of RGC STF with a DoG cone pooling model in which
    % the center cone is one of the cones within the maxRecordedRGCeccArcMin
    switch (centerConeType)
        case 'L'
            if (isempty(d.test))
                theMeasuredSTFdata = d.train.dFresponsesLcenterRGCs;
                theMeasuredSTFerrorData = d.train.dFresponseStdLcenterRGCs;
            else
               if (iscell(d.test))
                    % multi-session responses 
                    for iSession = 1:numel(d.test)
                        theMeasuredSTFdata(iSession,:,:) = d.test{iSession}.dFresponsesLcenterRGCs;
                        theMeasuredSTFerrorData(iSession,:,:) = d.test{iSession}.dFresponseStdLcenterRGCs;
                    end
                else
                    % single-session responses
                    theMeasuredSTFdata = d.test.dFresponsesLcenterRGCs;
                    theMeasuredSTFerrorData = d.test.dFresponseStdLcenterRGCs;
               end

               theTrainingSTFdata = d.train.dFresponsesLcenterRGCs;
               theTrainingSTFerrorData = d.train.dFresponseStdLcenterRGCs;
            end
                
        case 'M'
            if (isempty(d.test))
                theMeasuredSTFdata = d.train.dFresponsesMcenterRGCs;
                theMeasuredSTFerrorData = d.train.dFresponseStdMcenterRGCs;
            else
                if (iscell(d.test))
                    % multi-session responses 
                    for iSession = 1:numel(d.test)
                        theMeasuredSTFdata(iSession,:,:) = d.test{iSession}.dFresponsesMcenterRGCs;
                        theMeasuredSTFerrorData(iSession,:,:) = d.test{iSession}.dFresponseStdMcenterRGCs;
                    end
                else
                    % single-session responses
                    theMeasuredSTFdata = d.test.dFresponsesMcenterRGCs;
                    theMeasuredSTFerrorData = d.test.dFresponseStdMcenterRGCs;
                end

                theTrainingSTFdata = d.train.dFresponsesMcenterRGCs;
                theTrainingSTFerrorData = d.train.dFresponseStdMcenterRGCs;
            end
    end


    % Reshape data if needed
    if (ndims(theMeasuredSTFdata) == 2)
        % single session responses
        theMeasuredSTFdata = reshape(theMeasuredSTFdata, [1 size(theMeasuredSTFdata,1) size(theMeasuredSTFdata,2)]);
        theMeasuredSTFerrorData = reshape(theMeasuredSTFerrorData, [1 size(theMeasuredSTFerrorData,1) size(theMeasuredSTFerrorData,2)]);
    end

    sessionsNum = size(theMeasuredSTFdata,1);
    rgcCellsNum = size(theMeasuredSTFdata,2);
    sfsNum = size(theMeasuredSTFdata,3);

    if ((isempty(d.test)) && (sessionsNum > 1))
        error('Expected a single session for training the model. Data have %d sessions', sessionsNum);
    end

    % Initialize
    examinedCenterConesNum = numel(indicesOfModelConesDrivingTheRGCcenters);
    rmsErrors = nan(sessionsNum, rgcCellsNum, examinedCenterConesNum);
    rmsErrorsTrain = [];
    if (strcmp(modelVariant.centerConesSchema, 'single'))
        fittedParams = zeros(sessionsNum, rgcCellsNum, examinedCenterConesNum,4);
    else
        fittedParams = zeros(sessionsNum, rgcCellsNum, examinedCenterConesNum,5);
    end
    fittedSTFs = zeros(sessionsNum, rgcCellsNum, examinedCenterConesNum,sfsNum);

    for iRGCindex = 1:rgcCellsNum
        
        if (~ismember(iRGCindex, targetRGCindices))
            fprintf('Skipping RGC %d.\n', iRGCindex);
            continue;
        end
            
        if (sessionsNum == 1)
            % Initialize the visualization
            visStruct = initializeISETBioFitVisualization(...
                isempty(theTrainedModel), iRGCindex, centerConeType, ...
                startingPointsNum, crossValidationRun, ...
                modelVariant);
        else
            visStruct = initializeISETBioMultiSessionFitVisualization(...
                isempty(theTrainedModel), iRGCindex, centerConeType, ...
                startingPointsNum, crossValidationRun, ...
                modelVariant);
        end

        fprintf('Fitting RGC data (%d/%d).\n', iRGCindex, rgcCellsNum);

        % Fit the model for each of the assumed RFcenter driving cones
        for iCone = 1:numel(indicesOfModelConesDrivingTheRGCcenters)  

            if (isempty(d.test))
                % Fit the model to the training data
                fprintf(2,'\tTraining the model (best of %d different paths) using %s-cone %d/%d.\n', ...
                    startingPointsNum, centerConeType, iCone, numel(indicesOfModelConesDrivingTheRGCcenters));

                tStart = clock;
                fitResults = fitConePoolingDoGModelToSTF(...
                    squeeze(theMeasuredSTFdata(1,iRGCindex,:)), ...
                    squeeze(theMeasuredSTFerrorData(1,iRGCindex,:)), ...
                    modelSTFrunData, indicesOfModelConesDrivingTheRGCcenters(iCone), ...
                    modelVariant, ...
                    startingPointsNum, []);

                tEnd = clock;
                fprintf(2,'\tModel training for %s-cone %d/%d took %2.2f minutes.\n', ...
                     centerConeType, iCone, numel(indicesOfModelConesDrivingTheRGCcenters), etime(tEnd, tStart)/60);
                
                % Keep fit results for each RGC and each RF center driving cone
                fittedParams(1,iRGCindex, iCone,:) = fitResults.fittedParams;

                rmsErrors(1,iRGCindex, iCone) = fitResults.rmsErrors;
                fittedSTFs(1,iRGCindex, iCone,:) =  fitResults.theFittedSTFs;

                theTrainingFittedSTFs(1,iRGCindex, iCone,:) = fittedSTFs(1,iRGCindex, iCone,:);

            else
                % Cross-validate the fitted model to the test data
                dTrainSession = str2num(strrep(d.dataSets{1}, 's', ''));

                if (iscell(d.dataSets{2}))
                    % Cross-validate against multiple sessions
                    sessionStrings = d.dataSets{2};
                    dTestSession = [];
                    for iSession = 1:sessionsNum
                        dTestSession(iSession) = str2num(strrep(sessionStrings{iSession}, 's', ''));
                    end
                    fprintf('\tCross-validating the trained model (run %d) using %s-cone %d/%d to testing data (train session: %d, multiple test sessions)\n', ...
                        crossValidationRun, centerConeType, iCone, numel(indicesOfModelConesDrivingTheRGCcenters), ...
                        dTrainSession);
                else
                    % Cross-validate against a single session
                    dTestSession = str2num(strrep(d.dataSets{2}, 's', ''));
                    fprintf('\tCross-validating the trained model (run %d) using %s-cone %d/%d to testing data (train session: %d, test session: %d)\n', ...
                        crossValidationRun, centerConeType, iCone, numel(indicesOfModelConesDrivingTheRGCcenters), ...
                        dTrainSession , dTestSession);
                end

                % Retrieve the trained model and the training RMSerrors
                switch (centerConeType)
                    case 'L'
                        trainedModelFitParams = theTrainedModel.fittedParamsLcenterRGCs{dTrainSession}(1,iRGCindex, iCone,:);
                        rmsErrorsTrain(iRGCindex, iCone) = theTrainedModel.rmsErrorsLcenterRGCs{dTrainSession}(1,iRGCindex, iCone);
                    case 'M'
                        trainedModelFitParams = theTrainedModel.fittedParamsMcenterRGCs{dTrainSession}(1,iRGCindex, iCone,:);
                        rmsErrorsTrain(iRGCindex, iCone) = theTrainedModel.rmsErrorsMcenterRGCs{dTrainSession}(1,iRGCindex, iCone);
                end

                % Fit the test data using the trained model (just scaling)
                for iSession = 1:sessionsNum
                    fitResults = fitConePoolingDoGModelToSTF(...
                        squeeze(theMeasuredSTFdata(iSession,iRGCindex,:)), ...
                        squeeze(theMeasuredSTFerrorData(iSession,iRGCindex,:)), ...
                        modelSTFrunData, indicesOfModelConesDrivingTheRGCcenters(iCone), ...
                        modelVariant, ...
                        startingPointsNum, trainedModelFitParams);

                    fittedParams(iSession,iRGCindex, iCone,:) = fitResults.fittedParams;
                    theTrainingFittedSTFs(iSession,iRGCindex, iCone,:) = fitResults.fittedParamsSTF;

                    rmsErrors(iSession,iRGCindex, iCone) = fitResults.rmsErrors;
                    fittedSTFs(iSession,iRGCindex, iCone,:) =  fitResults.theFittedSTFs;
                    fittedCenterSTFs(iSession,iRGCindex, iCone,:) =  fitResults.theFittedCenterSTFs;
                end
            end

            % Keep fit results for each RF center driving cone
            centerConeCharacteristicRadiusDegs(iCone) = fitResults.centerConeCharacteristicRadiusDegs;
            surroundConeIndices{iCone} = fitResults.surroundConeIndices;
            surroundConeWeights{iCone} = fitResults.surroundConeWeights;
            centerConeIndices{iCone} = fitResults.centerConeIndices;
            centerConeWeights{iCone} = fitResults.centerConeWeights;
            centerConesFractionalNum{iCone} = fitResults.centerConesFractionalNum;
            centroidPosition{iCone} = fitResults.centroidPosition;
            
            if (isempty(d.test))
                % Display the training model params
                for iParam = 1:numel(fitResults.paramNames)
                    fprintf('\t ''%20s'': %2.4f [%2.4f - %2.2f]\n', ...
                        fitResults.paramNames{iParam}, ...
                        fittedParams(1,iRGCindex, iCone,iParam), ...
                        fitResults.paramsLowerBound(iParam), ...
                        fitResults.paramsUpperBound(iParam));
                end
                fitTitle = sprintf('RMSE: %2.2f', rmsErrors(1,iRGCindex, iCone));
            else
                if (sessionsNum == 1)
                    fitTitle = sprintf('RMSE: %2.2f (train:%s), RMSE: %2.2f (test: %s)', ...
                        rmsErrorsTrain(iRGCindex, iCone), d.dataSets{1}, rmsErrors(1,iRGCindex, iCone), d.dataSets{2});
                else
                    fitTitle = sprintf('RMSE: %2.2f (train:%s), RMSE: %2.2f (mean %d sessions)', ...
                        rmsErrorsTrain(iRGCindex, iCone), d.dataSets{1}, mean(rmsErrors(:,iRGCindex, iCone),1, 'omitnan'), sessionsNum);
                end
            end


            if (sessionsNum == 1)
                % Single session. visualize fits
                % Update visualization for this assumed RFcenter cone
                updateISETBioFitVisualization(visStruct, iRGCindex, iCone, ...
                    indicesOfModelConesDrivingTheRGCcenters, ...
                    modelSTFrunData.theConeMosaic, ...
                    centerConeCharacteristicRadiusDegs, ...
                    centerConeIndices, centerConeWeights, centroidPosition, centerConesFractionalNum, ...
                    surroundConeIndices, surroundConeWeights, ...
                    squeeze(fittedParams(1,:,:,:)), squeeze(rmsErrors(1,:,:)), rmsErrorsTrain, ...
                    modelSTFrunData.examinedSpatialFrequencies, fittedSTFs, ...
                    squeeze(theMeasuredSTFdata(1,iRGCindex,:)), ...
                    squeeze(theMeasuredSTFerrorData(1,iRGCindex,:)), ...
                    fitTitle);
            else
                % Multiple sessions. visualize the rmsErrors only
                updateISETBioMultiSessionFitVisualization(visStruct, iRGCindex, iCone, ...
                    indicesOfModelConesDrivingTheRGCcenters, ...
                    modelSTFrunData.theConeMosaic, ...
                    centerConeCharacteristicRadiusDegs, ...
                    centerConeIndices, centerConeWeights, centroidPosition, centerConesFractionalNum, ...
                    surroundConeIndices, surroundConeWeights, ...
                    squeeze(fittedParams(1,:,:,:)), rmsErrors, rmsErrorsTrain, ...
                    modelSTFrunData.examinedSpatialFrequencies, ...
                    squeeze(fittedSTFs(1:sessionsNum,iRGCindex, :,:)), ...
                    squeeze(theMeasuredSTFdata(1:sessionsNum,iRGCindex,:)), ...
                    squeeze(theMeasuredSTFerrorData(1:sessionsNum,iRGCindex,:)), ...
                    squeeze(theTrainingFittedSTFs(1,iRGCindex, :,:)), ...
                    squeeze(theTrainingSTFdata(iRGCindex,:)), ...
                    squeeze(theTrainingSTFerrorData(iRGCindex,:)), ...
                    fitTitle, dTrainSession, dTestSession);
            end
        end % iCone

        % End visualization for this RGC
        closeISETBioFitVisualization(visStruct);
    end % iRGCindex
end


function fitResults = fitConePoolingDoGModelToSTF(theSTF, theSTFstdErr, ...
                     modelSTFrunData, centerModelConeIndex, ...
                     modelVariant, ...
                     startingPointsNum, ...
                     trainedModelFitParams)


    allowableSurroundConeTypes = [ ...
        modelSTFrunData.theConeMosaic.LCONE_ID ...
        modelSTFrunData.theConeMosaic.MCONE_ID ];

    constants.allowableSurroundConeTypes = allowableSurroundConeTypes;
    constants.centerConeIndex = centerModelConeIndex;
    constants.centerConesSchema = modelVariant.centerConesSchema;
    constants.modelTransducerFunctionAccountsForResponseOffset = modelVariant.transducerFunctionAccountsForResponseOffset;
    constants.modelTransducerFunctionAccountsForResponseSign = modelVariant.transducerFunctionAccountsForResponseSign;

    constants.allConePositions = modelSTFrunData.theConeMosaic.coneRFpositionsDegs;
    constants.allConeTypes = modelSTFrunData.theConeMosaic.coneTypes;
    constants.coneMosaicSpatiotemporalActivation = modelSTFrunData.coneMosaicSpatiotemporalActivation;
    constants.temporalSupportSeconds = modelSTFrunData.temporalSupportSeconds;
    
    centerConeCharacteristicRadiusDegs = sqrt(2) * 0.204 * modelSTFrunData.theConeMosaic.coneRFspacingsDegs(centerModelConeIndex);
    constants.centerConeCharacteristicRadiusDegs = centerConeCharacteristicRadiusDegs;


    weights = 1./theSTFstdErr;
    fitAbsoluteValueOfResponses = true;
    visualizeCenterWeights = false;
    if (fitAbsoluteValueOfResponses)
        objective = @(p) sum(weights' .* (abs(ISETBioComputedSTF(p, constants, visualizeCenterWeights)) - abs(theSTF')).^2);
    else
        objective = @(p) sum(weights' .* (ISETBioComputedSTF(p, constants, visualizeCenterWeights) - theSTF').^2);
    end

    options = optimset(...
        'Display', 'off', ...
        'Algorithm', 'interior-point',... % 'sqp', ... % 'interior-point',...
        'GradObj', 'off', ...
        'DerivativeCheck', 'off', ...
        'MaxFunEvals', 10^5, ...
        'MaxIter', 10^3);
%     , ...
%         'TolX', 10^(-32), ...
%         'TolFun', 10^(-32));

    kc = struct(...
        'low', 1e-4, ...
        'high', 1e5, ...
        'initial', 1);

    KsToKc = struct(...
        'low', 1e-3, ...
        'high', 1, ...
        'initial', 0.1);

    RsToCenterConeRc = struct(...
        'low', 1.2, ...
        'high', 40, ...
        'initial', 5);

    %                Kc            kS/kC              RsToCenterConeRc          
    paramsInitial = [kc.initial    KsToKc.initial     RsToCenterConeRc.initial  ];
    lowerBound    = [kc.low        KsToKc.low         RsToCenterConeRc.low      ];
    upperBound    = [kc.high       KsToKc.high        RsToCenterConeRc.high     ];
    paramNames    = {'Kc', 'kS/kC',  'RsToCenterConeRc'};
    
    if (strcmp(constants.centerConesSchema, 'variable'))
        % Add 4-th parameter, the number of center cones
        RcToCenterConeRc = struct(...
            'low', 1.0, ...
            'high', 3.0, ...
            'initial', 1.1);
        paramNames{numel(paramNames)+1} = 'RcToCenterConeRc';
        paramsInitial(numel(paramsInitial)+1) = RcToCenterConeRc.initial;
        lowerBound(numel(lowerBound)+1) = RcToCenterConeRc.low;
        upperBound(numel(upperBound)+1) = RcToCenterConeRc.high;
    end

    if (modelTransducerFunctionAccountsForResponseOffset)
        % Add Dc Term
        dcTerm = struct(...
                'low', -0.3, ...
                'high', 0.3, ...
                'initial', 0.0);
    
        paramNames{numel(paramNames)+1} = 'dcTerm';
        paramsInitial(numel(paramsInitial)+1) = dcTerm.initial;
        lowerBound(numel(lowerBound)+1) = dcTerm.low;
        upperBound(numel(upperBound)+1) = dcTerm.high;
    end



    if (isempty(trainedModelFitParams))
        % Fit model to data
        if (startingPointsNum <= 1)
            % Just one attempt
            trainedModelFitParams = fmincon(objective,paramsInitial,[],[],[],[],lowerBound,upperBound,[],options);
        else
            % Multi-start
            problem = createOptimProblem('fmincon',...
                            'x0', paramsInitial, ...
                            'objective', objective, ...
                            'lb', lowerBound, ...
                            'ub', upperBound, ...
                            'options', options...
                            );
        
            displayProgress = 'off';
            useParallel = true;
            ms = MultiStart(...
                           'Display', displayProgress, ... %'FunctionTolerance', 2e-4, ...
                           'StartPointsToRun','bounds-ineqs', ...  % run only initial points that are feasible with respect to bounds and inequality constraints.
                           'UseParallel', useParallel);
        
            % Run the multi-start
            [trainedModelFitParams,errormulti] = run(ms, problem, startingPointsNum);
        end

        % Compute the fitted STF
        visualizeCenterWeights = true;
        [theFittedSTF, theFittedCenterSTF, theFittedSurroundSTF, ...
         centerConeIndices, centerConeWeights, centroidPosition, centerConesFractionalNum, ...
         surroundConeIndices, surroundConeWeights] = ISETBioComputedSTF(trainedModelFitParams, constants, visualizeCenterWeights);

        % Return dublicate of the fittedSTF
        trainedModelFittedSTF = theFittedSTF;
    else

        % Compute the fittedSTF using the trained model
        [theFittedSTF, theFittedCenterSTF, theFittedSurroundSTF, ...
         centerConeIndices, centerConeWeights, centroidPosition, centerConesFractionalNum, ...
         surroundConeIndices, surroundConeWeights] = ISETBioComputedSTF(trainedModelFitParams, constants);

        % Keep a copy so we can return it in the struct fitResults.fittedParamsSTF
        % separately from fitResults.theFittedSTFs
        trainedModelFittedSTF = theFittedSTF;

        % Determine the optical scaling factor for the fittedSTF to match the test data which may have a different overal
        % scale factor
    
        % Objective function with a single parameter: thescalingFactor
        if (modelTransducerFunctionAccountsForResponseOffset)
            dcTerm = trainedModelFitParams(end);
        else
            dcTerm = 0;
        end
        scalingObjective = @(scalingFactor) sum(weights' .* (dcTerm+(theFittedSTF-dcTerm)*scalingFactor - theSTF').^2);

        % Initial params and bounds for the scalingFactor
        scalingFactorInitial = [1];
        scalingFactorLowerBound = [0.1]; 
        scalingFactorUpperBound = [10];

         % Find the optimal scaling factor
        scalingFactor = fmincon(scalingObjective, scalingFactorInitial,[],[],[],[],scalingFactorLowerBound,scalingFactorUpperBound,[],options);

        % Apply the optimal scaling factor to theFittedSTF
        theFittedSTF = dcTerm + (theFittedSTF-dcTerm) * scalingFactor;
        theFittedCenterSTF = theFittedCenterSTF * scalingFactor;
        theFittedSurroundSTF = theFittedSurroundSTF * scalingFactor;
    end


    % RMSerror
    N = numel(theSTF);        
    residuals = theSTF(:)-theFittedSTF(:);
    dataRange = prctile(theSTF(:),75) - prctile(theSTF(:),25);

    % Normalize residuals with respect to the measured data range to make the 
    % RMS error scale-independent
    residuals = residuals / dataRange;
    theRMSerror = 100*sqrt(1/N*sum(residuals.^2,1));
    fitResults.rmsErrors = theRMSerror;

    % Form return struct
    fitResults.theFittedSTFs = theFittedSTF;
    fitResults.theFittedCenterSTFs = theFittedCenterSTF;
    fitResults.theFittedSurroundSTFs = theFittedSurroundSTF;

    fitResults.centerConeCharacteristicRadiusDegs = centerConeCharacteristicRadiusDegs;

    fitResults.fittedParams = trainedModelFitParams;
    fitResults.fittedParamsSTF = trainedModelFittedSTF;

    fitResults.surroundConeIndices = surroundConeIndices;
    fitResults.surroundConeWeights = surroundConeWeights;
    fitResults.centerConeIndices = centerConeIndices;
    fitResults.centerConeWeights = centerConeWeights;

    fitResults.centerConesFractionalNum = centerConesFractionalNum;
    fitResults.centroidPosition = centroidPosition;
    fitResults.paramNames = paramNames;
    fitResults.paramsLowerBound = lowerBound;
    fitResults.paramsUpperBound = upperBound;
end

function  [centerConeIndices, centerConeWeights, ...
    centerConesFractionalNum, centroidPosition] = centerConeIndicesAndWeights(RcDegs, constants)

    if (isnan(RcDegs))
        centerConeWeights = 1;
        centerConeIndices = constants.centerConeIndex;
        centerConesFractionalNum = 1;
        centroidPosition = constants.allConePositions(constants.centerConeIndex,:);
    else
        % Determine how many cones are feeding into the center as (Rc/coneRc)^2
        centerConesFractionalNum = (RcDegs/constants.centerConeCharacteristicRadiusDegs)^2;
        
        if (centerConesFractionalNum <= 1.01)
            centerConeWeights = 1;
            centerConeIndices = constants.centerConeIndex;
            centerConesFractionalNum = 1;
            centroidPosition = constants.allConePositions(constants.centerConeIndex,:);
            return;
        end

        % Find the distances from the centerCone to all other cones
        d = sqrt(sum((bsxfun(@minus, constants.allConePositions, constants.allConePositions(constants.centerConeIndex,:))).^2,2));

        % Sort the distances from lowest to highest
        [~, sortedConeIndices] = sort(d, 'ascend');

        % centerConeIndices is the first ceil(centerConesFractionalNum)
        sortedConeIndices = sortedConeIndices(1:ceil(centerConesFractionalNum));

        % Find the weights for the weighted centroid
        centroidWeights(1:floor(centerConesFractionalNum)) = 1;
        centroidWeights(ceil(centerConesFractionalNum)) = ceil(centerConesFractionalNum)-centerConesFractionalNum;

        % Compute weighted centroid position
        for k = 1:numel(centroidWeights)
            weightedPos = constants.allConePositions(sortedConeIndices(k),:) * centroidWeights(k);
            if (k == 1)
                centroidPosition = weightedPos;
            else
                centroidPosition = centroidPosition + weightedPos;
            end
        end
        centroidPosition = centroidPosition / sum(centroidWeights);

        % Gaussian weights with cone distance from centroid
        d = sqrt(sum((bsxfun(@minus, constants.allConePositions(sortedConeIndices,:), centroidPosition)).^2,2));
        centerConeWeights = exp(-(d/RcDegs).^2);

        minSensitivity = 1/100;
        idx = find(centerConeWeights >= minSensitivity);

        % Return indices and connection weights of the center cones
        centerConeIndices = sortedConeIndices(idx);
        centerConeWeights = centerConeWeights(idx);
        centerConeIndices = reshape(centerConeIndices, [1 numel(centerConeIndices)]);
        centerConeWeights = reshape(centerConeWeights, [1 numel(centerConeIndices)]);

    end

end


function [surroundConeIndices, surroundConeWeights] = surroundConeIndicesAndWeights(RsDegs, constants, centerPosition)

    % Gaussian weights for the surround cones    
    d = sqrt(sum((bsxfun(@minus, constants.allConePositions, centerPosition)).^2,2));
    surroundWeights = exp(-(d/RsDegs).^2);

    % Threshold sensitivity for inclusion to the surround summation mechanism
    minSensitivity = 1/100;
    surroundConeIndices = find(surroundWeights >= minSensitivity);
    surroundConeWeights = surroundWeights(surroundConeIndices);

    % Only include cones of the allowable cone types
    idx = [];
    for iConeType = 1:numel(constants.allowableSurroundConeTypes)
        idx2 = find(constants.allConeTypes(surroundConeIndices) == constants.allowableSurroundConeTypes(iConeType));
        idx = cat(1, idx, idx2);
    end

    % Return indices and connection weights of the surround cones
    surroundConeIndices = surroundConeIndices(idx);
    surroundConeWeights = surroundConeWeights(idx);
    surroundConeIndices = reshape(surroundConeIndices, [1 numel(surroundConeIndices)]);
    surroundConeWeights = reshape(surroundConeWeights, [1 numel(surroundConeIndices)]);
end


function [theModelSTF, theModelCenterSTF, theModelSurroundSTF, ...
              centerConeIndices, centerConeWeights, centroidPosition, centerConesFractionalNum, ...
              surroundConeIndices, surroundConeWeights] = ISETBioComputedSTF(...
              DoGparams, constants, visualizeCenterWeights)

    modelTransducerFunctionAccountsForResponseOffset = constants.modelTransducerFunctionAccountsForResponseOffset;
    modelTransducerFunctionAccountsForResponseSign = constants.modelTransducerFunctionAccountsForResponseSign;

    Kc = DoGparams(1);
    if (strcmp(constants.centerConesSchema, 'single'))
        RcDegs = nan;
        if (modelTransducerFunctionAccountsForResponseOffset)
            dcTerm = DoGparams(4);
        else
            dxTerm = 0;
        end
    else
        RcDegs = DoGparams(4)*constants.centerConeCharacteristicRadiusDegs;
        if (modelTransducerFunctionAccountsForResponseOffset)
            dcTerm = DoGparams(5);
        else
            dcTerm = 0;
        end
    end

    KsToKc = DoGparams(2);
    Ks = Kc * KsToKc;
    RsDegs = DoGparams(3)*constants.centerConeCharacteristicRadiusDegs;

   
    % Determine center cone indices and weights
    [centerConeIndices, centerConeWeights, centerConesFractionalNum, centroidPosition] = ...
        centerConeIndicesAndWeights(RcDegs, constants);

     % Determine surround cone indices and weights
    [surroundConeIndices, surroundConeWeights] = ...
        surroundConeIndicesAndWeights(RsDegs, constants, centroidPosition);

    if (visualizeCenterWeights)
        figure(111); clf;
        hold on
        for k = 1:numel(centerConeIndices)
            theConeIndex = centerConeIndices(k);
            theConePos = constants.allConePositions(theConeIndex,:);
            theConeWeight = centerConeWeights(k);
            theMarkerSize = max([1, theConeWeight*100]);
            if (theConeIndex == constants.centerConeIndex)
                theConeColor = [1 0 0];
            else
                theConeColor = [0 0 0];
            end
            plot(theConePos(1), theConePos(2), 'o', 'MarkerSize', theMarkerSize, 'Color', theConeColor);
            plot(centroidPosition(1), centroidPosition(2), 'bx', 'MarkerSize', 14);
        end
        xRange(1) = min(constants.allConePositions(centerConeIndices,1))-3/60;
        xRange(2) = max(constants.allConePositions(centerConeIndices,1))+3/60;
        yRange(1) = min(constants.allConePositions(centerConeIndices,2))-3/60;
        yRange(2) = max(constants.allConePositions(centerConeIndices,2))+3/60;

        set(gca, 'XLim', xRange, 'YLim', yRange);
        set(gca, 'FontSize', 18);
        title(sprintf('centerConesFractionalNum = %2.3f', centerConesFractionalNum));
        drawnow;
    end

    %sfsNum = size(constants.coneMosaicSpatiotemporalActivation,1);
    %tBinsNum = size(constants.coneMosaicSpatiotemporalActivation,2);
    %conesNum = size(constants.coneMosaicSpatiotemporalActivation,3);

    % Center model cone responses
    centerMechanismInputModulations = constants.coneMosaicSpatiotemporalActivation(:,:,centerConeIndices);
    
    % Weighted pooling of center model cone responses
    weightedCenterModulations = bsxfun(@times, centerMechanismInputModulations, reshape(centerConeWeights, [1 1 numel(centerConeWeights)]));

    % Sum weighted center cone responses
    totalCenterResponse = sum(weightedCenterModulations,3);

    % Apply center gain
    centerMechanismModulations = Kc * totalCenterResponse;


    % Surround model cone responses
    surroundMechanismInputModulations = constants.coneMosaicSpatiotemporalActivation(:,:,surroundConeIndices);

    % Weighted pooling of surround model cone responses
    weightedSurroundModulations = bsxfun(@times, surroundMechanismInputModulations, reshape(surroundConeWeights, [1 1 numel(surroundConeWeights)]));
    
    % Sum weighted surround cone responses
    totalSurroundResponse = sum(weightedSurroundModulations,3);

    % Apply surround gain 
    surroundMechanismModulations = Ks * totalSurroundResponse;
    


    % Composite center-surround responses
    modelRGCmodulations = centerMechanismModulations - surroundMechanismModulations;
    
    % Fit a sinusoid to the time series responses for each spatial frequency
    % The amplitude of the sinusoid is the STFmagnitude at that spatial frequency
    sfsNum = size(modelRGCmodulations,1);
    theModelSTF = zeros(1, sfsNum);
    theModelCenterSTF = zeros(1, sfsNum);
    theModelSurroundSTF = zeros(1, sfsNum);
    %timeHR = linspace(constants.temporalSupportSeconds(1), constants.temporalSupportSeconds(end), 100);
    
    for iSF = 1:sfsNum

        if (modelTransducerFunctionAccountsForResponseSign) 
            % Fit a sinusoid to the center modulation
            [~, fittedParams] = fitSinusoidToResponseTimeSeries(...
                constants.temporalSupportSeconds, ...
                centerMechanismModulations(iSF,:), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
            % The centerSTF is the amplitude of the sinusoid
            theModelCenterSTF(iSF) = fittedParams(1);
     
            % Fit a sinusoid to the center modulation
            [~, fittedParams] = fitSinusoidToResponseTimeSeries(...
                constants.temporalSupportSeconds, ...
                surroundMechanismModulations(iSF,:), ...
                WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
                []);
            % The centerSTF is the amplitude of the sinusoid
            theModelSurroundSTF(iSF) = fittedParams(1);
        end


        % Fit sinusoid to the compund center-surround responses.
        % This forces the STF amplitude to be non-negative, which can lead to
        % issues with the fluorescene STF data which for some cells go
        % negative at low spatial frequencies. So we assign a positive sign
        % if (theModelCenterSTF(iSF) > theModelSurroundSTF(iSF)), 
        % and a negative sign otherwise

        [~, fittedParams] = ...
            fitSinusoidToResponseTimeSeries(...
            constants.temporalSupportSeconds, ...
            modelRGCmodulations(iSF,:), ...
            WilliamsLabData.constants.temporalStimulationFrequencyHz, ...
            []);

        if (modelTransducerFunctionAccountsForResponseSign) 
            if (theModelCenterSTF(iSF) > theModelSurroundSTF(iSF))
                % Center response dominates, keep sign
                sign = 1;  
            else
                % Surround response dominates, revert sign
                sign = -1;
            end
        else
            % no sign
            sign = 1;
        end

        % The STF is the dc (if enabled) + signed (if enabled) amplitude of the sinusoid
        theModelSTF(iSF) = dcTerm + sign * fittedParams(1);
    end
end