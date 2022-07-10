function backedOutConeRc = backOutAnatomicalConeRcThroughEccVaryingOptics(...
                anatomicalConeEcc, anatomicalRadiusDegs, opticsParamsForBackingOutConeRc)

    switch (opticsParamsForBackingOutConeRc.eccVaryingMeridian)
        case 'ArtalTemporalMeridian'
            xFormer = RetinaToVisualFieldTransformer('ZernikeDataBase', 'Artal2012');
            analyzedRetinalQuadrant = RetinaToVisualFieldTransformer.temporalRetinaQuadrant;
   
             % Only the first 30
            examinedSubjectRankOrders = 1:38;
            % Remove some subjects which increase the
            examinedSubjectRankOrders = setdiff(examinedSubjectRankOrders, [5 16 20 23 31 34 36 37]);

        case 'ArtalNasalMeridian'
            xFormer = RetinaToVisualFieldTransformer('ZernikeDataBase', 'Artal2012');
            analyzedRetinalQuadrant = RetinaToVisualFieldTransformer.nasalRetinaQuadrant;
   
            % Only the first 30
            examinedSubjectRankOrders = 1:38;
            % Remove some subjects which increase the
            examinedSubjectRankOrders = setdiff(examinedSubjectRankOrders, [5 16 20 23 31 34 36 37]);



        otherwise
            error('Unknown opticsParamsForBackingOutConeRc: ''%s''.', opticsParamsForBackingOutConeRc);
    end


    % Use the right eye PSFs
    analyzedEye = RetinaToVisualFieldTransformer.rightEye;

    % For a 3 MM pupil
    pupilDiameterMM = 3.0;

    % Retrieve the eccentricities
    maxEccDegs = 30;
    [horizontalEccDegs, verticalEccDegs, eccDegsForPlotting] = ...
         RetinaToVisualFieldTransformer.eccentricitiesForQuadrant(...
                analyzedRetinalQuadrant, analyzedEye, maxEccDegs);

    % Use the right eye subject ranking
    subjectRankingEye = RetinaToVisualFieldTransformer.rightEye;
    

    % Analyze all examined subjects
    backedOutConeRcAllSubjects = nan(numel(examinedSubjectRankOrders), numel(anatomicalConeEcc));

    for iSubj = 1:numel(examinedSubjectRankOrders)
        
        % Get the subject ID
        subjectRankOrder = examinedSubjectRankOrders(iSubj);
        subjID = xFormer.subjectWithRankInEye(subjectRankOrder, subjectRankingEye);

        parfor iEcc = 1:numel(anatomicalConeEcc)
            [~,idx] = min(abs(anatomicalConeEcc(iEcc)-eccDegsForPlotting));

            % Analyze effect of optics at this eccentricity
            eccDegs = [horizontalEccDegs(idx) verticalEccDegs(idx)];
            dStruct = xFormer.estimateConeCharacteristicRadiusInVisualSpace(...
                analyzedEye, eccDegs, subjID, pupilDiameterMM, '', ...
                'anatomicalConeCharacteristicRadiusDegs', anatomicalRadiusDegs(iEcc));

            backedOutConeRcAllSubjects(iSubj, iEcc) = dStruct.visualConeCharacteristicRadiusDegs;

        end % iEcc
    end % iSubj

    % Mean over all subjects
    backedOutConeRc = mean(backedOutConeRcAllSubjects,1, 'omitnan');


end

