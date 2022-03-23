function pdfFilename = populationKsKcPlots(coneMosaicSTFresponsesFileName, opticsString)

    tmp = strrep(coneMosaicSTFresponsesFileName, 'responses', 'exports/populationPDFs');
    pdfFilename  = sprintf('%s_%s_SummaryKsKc.pdf', tmp,  opticsString);
    
end
