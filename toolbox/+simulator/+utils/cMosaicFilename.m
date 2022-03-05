function filename = cMosaicFilename(monkeyID)
    p = getpref('ISETMacaque');
    filename = fullfile(p.generatedDataDir, 'components', sprintf('cMosaic%s.mat', monkeyID));
end