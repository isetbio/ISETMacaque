function pdfFilename = populationRcRsPlots(coneMosaicSTFresponsesFileName, opticsString)

    tmp = strrep(coneMosaicSTFresponsesFileName, 'responses', 'exports/populationPDFs');
    pdfFilename  = sprintf('%s_%s_SummaryRcRs.pdf', tmp,  opticsString);
    
end
