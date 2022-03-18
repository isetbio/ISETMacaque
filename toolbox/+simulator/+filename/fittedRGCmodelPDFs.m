function [allPositionsPDFfilename, bestPositionPDFfilename] = ...
    fittedRGCmodelPDFs(monkeyID, options, ...
    coneMosaicSamplingParams, fitParams, STFdataToFit)
% Generate filename for the fitted RGC model PDFs
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
    fittedModelFileName = simulator.filename.fittedRGCmodel(monkeyID, options, ...
                coneMosaicSamplingParams, fitParams, STFdataToFit);

    tmp = strrep(fittedModelFileName, 'fittedRGCModels', 'exports/fittedRGCModelPDFs');
    allPositionsPDFfilename = strrep(tmp, '.mat', '_WhichModel_AllPositions.pdf');
    bestPositionPDFfilename = strrep(tmp, '.mat', '_WhichModel_BestPosition.pdf');
end
