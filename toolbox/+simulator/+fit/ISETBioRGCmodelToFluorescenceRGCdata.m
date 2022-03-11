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



end
