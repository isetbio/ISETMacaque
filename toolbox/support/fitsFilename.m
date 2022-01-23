function filename = fitsFilename(opticalDefocusDiopters)
    % Generate data filename
    rootDirName = ISETmacaqueRootPath();

    filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/fitResults/ISETBioFits%2.3fD.mat', ...
                opticalDefocusDiopters));
   
end