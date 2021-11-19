function filename = videoFilename(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, ...
    PolansSubject, visualStimulus, conePostFix)

    % Generate data filename
    rootDirName = ISETmacaqueRootPath();
    
    switch (visualStimulus.type)
        case 'WilliamsLabStimulus'
            stimPrefix = 'AOstimulus';
        case 'CRT'
            stimPrefix = sprintf('CRT_lmsContrasts_%2.2f_%2.2f_%2.2f', ...
                visualStimulus.lmsConeContrasts(1), visualStimulus.lmsConeContrasts(2), visualStimulus.lmsConeContrasts(3));
        otherwise
            error('Unknown stimulus type: ''%s''.', visualStimulus.type);
    end
    
    
    % Load responses
    if (~isempty(coneCouplingLambda))
        if (isempty(PolansSubject))
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/%s_coneMosaic%s_%sApertureSigma%2.3f_ConeCouplingLambda%2.2f_OpticalDefocusDiopters%2.3f_%s', ...
                stimPrefix, monkeyID, apertureParams.shape, apertureParams.sigma, coneCouplingLambda, opticalDefocusDiopters, conePostFix));
        else
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/%s_coneMosaic%s_%sApertureSigma%2.3f_ConeCouplingLambda%2.2f_OpticalDefocusDiopters%2.3f_PolansSubject_%d_%s', ...
                stimPrefix, monkeyID, apertureParams.shape, apertureParams.sigma, coneCouplingLambda, opticalDefocusDiopters, PolansSubject, conePostFix));
        end
        
    else
        if (isempty(PolansSubject))
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/%s_coneMosaic%s_%sApertureSigma%2.3f_OpticalDefocusDiopters%2.3f_%s.mat', ...
                stimPrefix,monkeyID, apertureParams.shape, apertureParams.sigma, opticalDefocusDiopters,conePostFix));
        else
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/exports/%s_coneMosaic%s_%sApertureSigma%2.3f_OpticalDefocusDiopters%2.3f_PolansSubject_%d_%s.mat', ...
                stimPrefix_monkeyID, apertureParams.shape, apertureParams.sigma, opticalDefocusDiopters, PolansSubject, conePostFix));
        end
    end
end