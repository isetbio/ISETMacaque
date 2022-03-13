function fittedModel(fittedModelFileName)
% Visualize a fitted RGCSTF model 
%
% Syntax:
%   simulator.visualize.fittedModel(fittedModelFileName)
%
% Description:
%   Visualize a fitted RGCSTF model 
%
% Inputs:
%    fittedModelFileName  
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    none

    load(fittedModelFileName)
    STFdataToFit
    keys(fittedModels)
end