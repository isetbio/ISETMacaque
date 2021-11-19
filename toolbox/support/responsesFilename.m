function filename = responsesFilename(monkeyID, apertureParams, coneCouplingLambda, opticalDefocusDiopters, ...
    PolansSubject, visualStimulus)

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
                sprintf('simulations/generatedData/%s_coneMosaic%s_%sApertureSigma%2.3f_ConeCouplingLambda%2.2f_OpticalDefocusDiopters%2.3f.mat', ...
                stimPrefix, monkeyID, apertureParams.shape, apertureParams.sigma, coneCouplingLambda, opticalDefocusDiopters));
        else
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/%s_coneMosaic%s_%sApertureSigma%2.3f_ConeCouplingLambda%2.2f_OpticalDefocusDiopters%2.3f_PolansSubject_%d.mat', ...
                stimPrefix, monkeyID, apertureParams.shape, apertureParams.sigma, coneCouplingLambda, opticalDefocusDiopters, PolansSubject));
        end
        
    else
        if (isempty(PolansSubject))
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/%s_coneMosaic%s_%sApertureSigma%2.3f_OpticalDefocusDiopters%2.3f.mat', ...
                stimPrefix,monkeyID, apertureParams.shape, apertureParams.sigma, opticalDefocusDiopters));
        else
            filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/%s_coneMosaic%s_%sApertureSigma%2.3f_OpticalDefocusDiopters%2.3f_PolansSubject_%d.mat', ...
                stimPrefix, monkeyID, apertureParams.shape, apertureParams.sigma, opticalDefocusDiopters, PolansSubject));
        end
    end
end