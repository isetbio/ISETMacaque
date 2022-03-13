function fluorescenceSTFData(STFdataToFit, fitParams, ...)
    coneMosaicSamplingParams, rfCenterConePoolingScenariosExamined, ...
    coneMosaicResponsesFileName, fitResultsFileName)
% Fit the mesured fluorescence STF data
%
% Syntax:
%   simulator.fit.fluorescenceSTFData(STFdataToFit, fitParams, ...
%            coneMosaicSamplingParams, rfCenterConePoolingScenariosExamined, ...
%            coneMosaicResponsesFileName)
%
%
% Description: Fit the measured fluorescence STF data using variants
%              the DoG model operating on ISETBIO model coneMosaicResponses
%              to the same stimuli used to measure the fluorescence STF
%

    % Import the cone mosaic STF excitations response data
    load(coneMosaicResponsesFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'spatialFrequenciesExamined');

    % Convert cone excitation responses to cone modulations
    b = coneMosaicBackgroundActivation;
    coneMosaicSpatiotemporalActivation = ...
        bsxfun(@times, bsxfun(@minus, coneMosaicSpatiotemporalActivation, b), 1./b);

   
    % Select the positions of the cones driving the center of the model RGCs
    rfCenterConeIndices = simulator.coneMosaic.indicesOfConesOfSpecificTypeWithinEccRange(...
        theConeMosaic, STFdataToFit.whichCenterConeType, coneMosaicSamplingParams);

    % Only allow L/M cones in the surround
    allowableSurroundConeTypes = [ ...
        theConeMosaic.LCONE_ID ...
        theConeMosaic.MCONE_ID ];


    % Fit the DoG cone pooling model for the different cone pooling scenarios examined
    fittedModels = containers.Map();

    % Start the parallel pool
    poolobj = gcp('nocreate');
    if isempty(poolobj)
        parpool('local')
    end

    % Turn off the nearlySingularMatrix warning
    pctRunOnAll warning('off','MATLAB:nearlySingularMatrix');

    for iCenterConePoolingScenarioIdx = 1:numel(rfCenterConePoolingScenariosExamined)
        % Cone pooling scenario
        rfCenterConePoolingScenario = rfCenterConePoolingScenariosExamined{iCenterConePoolingScenarioIdx};

        % Fit the DoG cone pooling model for a number of assumed RF center 
        % cone positions within the model cone mosaic
        fitsAtExaminedMosaicPositions = cell(1,numel(rfCenterConeIndices));

        for iCenterConeIdx = 1:numel(rfCenterConeIndices)
            tic
            fprintf('\nFitting ''%s'' RF center scenario to cone position %d of %d ...', ...
                rfCenterConePoolingScenario, iCenterConeIdx, numel(rfCenterConeIndices));
            % Fit the DoG model for this RF center cone and RF center cone pooling scenario
            fitsAtExaminedMosaicPositions{iCenterConeIdx} = simulator.fit.conePoolingDoGModelToSTF(...
                    STFdataToFit, fitParams, ...
                    theConeMosaic, ...
                    rfCenterConeIndices(iCenterConeIdx), ...
                    rfCenterConePoolingScenario, ...
                    allowableSurroundConeTypes, ...
                    coneMosaicSpatiotemporalActivation, ...
                    temporalSupportSeconds);  
            fprintf('Performed %d multi-starts within %2.2f minutes\n', fitParams.multiStartsNum , toc/60);
        end

        % Choose the model with best performance across all center cone positions
        % Or return fits for all examined positions
        fittedModels(rfCenterConePoolingScenario) = fitsAtExaminedMosaicPositions;
    end

    % Restore standard warnings on all workers
    pctRunOnAll warning('on','MATLAB:nearlySingularMatrix');

    % Save fitted models
    save(fitResultsFileName, ...
        'STFdataToFit', ...
        'theConeMosaic', ...
        'fittedModels', ...
        '-v7.3');
end
