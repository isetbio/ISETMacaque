function filename = customDefocusOTFFilename(opticalDefocusDiopters)

    % Generate data filename
    rootDirName = ISETmacaqueRootPath();
    
    filename = fullfile(strrep(rootDirName, 'toolbox', ''), ...
                sprintf('simulations/generatedData/OTF_%2.3fDiopters.mat', opticalDefocusDiopters));
            
end

