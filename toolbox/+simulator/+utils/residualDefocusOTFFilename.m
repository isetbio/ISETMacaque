function filename = residualDefocusOTFFilename(residualDefocusDiopters)
    p = getpref('ISETMacaque');
    filename = fullfile(p.generatedDataDir, 'components', ...
        sprintf('residualDefocusOTF_%2.4fD.mat', residualDefocusDiopters));
end
