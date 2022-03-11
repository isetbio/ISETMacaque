function ISETBioRGCmodelToFluorescenceRGCdata(monkeyID, ...
    coneMosaicResponsesFileName, STFdataToFit, varargin)
    

    % Import the cone mosaic STF response data (cone excitations)
    load(coneMosaicResponsesFileName, 'theConeMosaic', 'coneMosaicBackgroundActivation', ...
        'coneMosaicSpatiotemporalActivation', 'temporalSupportSeconds', ...
        'spatialFrequenciesExamined');

    % Convert to cone modulations
    b = coneMosaicBackgroundActivation;
    coneMosaicSpatiotemporalActivation = ...
        bsxfun(@times, bsxfun(@minus, coneMosaicSpatiotemporalActivation, b), 1./b);

    figure(1); clf;
    
    plot(STFdataToFit.spatialFrequencySupport, STFdataToFit.responses, 'ko-', ...
        'LineWidth', 1.5, 'MarkerSize', 12);
    set(gca, 'XLim', [4 60], 'XScale', 'log', 'XTick', [5 10 20 40 60]);
    
end
