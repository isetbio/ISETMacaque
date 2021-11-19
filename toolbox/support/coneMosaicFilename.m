function filename = coneMosaicFilename(monkeyID)
    rootDirName = ISETmacaqueRootPath();
    filename = fullfile(rootDirName, sprintf('dataResources/coneMosaic%s.mat', monkeyID));
end
