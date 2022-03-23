function pdfFilename = syntheticSTFPDF(monkeyID, options, STFdataToFit, residualDefocusDiopters)
% Generate filename for the synthetic STF PDF
%
% Syntax:
%   [allPositionsPDFfilename, bestPositionPDFfilename] = ...
%       simulator.filename.fittedRGCmodelPDFs(monkeyID, options, ...
%               coneMosaicSamplingParams, fitParams, STFdataToFit)
%
% Description: Generate filenames for the PDFs of the fitted 
%              (to the fluorescence STF data)RGC model
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021

    % Synthesize filename for the fitted RGCmodel  
    fittedModelFileName = ...
        simulator.filename.coneMosaicSTFresponses(monkeyID, options);

    tmp = strrep(fittedModelFileName, 'responses', 'exports/syntheticSTFPDFs');
    pdfFilename  = sprintf('%s_%2.3fDresidualDefocusModelBased_%s%dsyntheticSTF.pdf', ...
        tmp,  residualDefocusDiopters, ...
        STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
    
end
