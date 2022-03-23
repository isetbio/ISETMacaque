function pdfFilename = populationIntegratedSensitivityPlots(coneMosaicSTFresponsesFileName, opticsString)

    tmp = strrep(coneMosaicSTFresponsesFileName, 'responses', 'exports/populationPDFs');
    pdfFilename  = sprintf('%s_%s_IntegratedSensitivity.pdf', tmp,  opticsString);
    
end
