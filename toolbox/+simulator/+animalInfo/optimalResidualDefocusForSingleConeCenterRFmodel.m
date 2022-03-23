function residualDefocusForDerivingSyntheticRGCModel = ...
    optimalResidualDefocusForSingleConeCenterRFmodel(monkeyID, RGCIDString)
% Select the optimal residual defocus for a given RGCID in a given monkey
%
% Syntax:
%   residualDefocus = simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(...
%            monkeyID, RGCIDstring)
%
% Description:
%   Select the optimal residual defocus for a given RGCID in a given monkey
%
% Inputs:
%    monkeyID
%    RGCIDstring
%
% Outputs:
%    residualDefocusForDerivingSyntheticRGCModel

    switch (monkeyID)
        case 'M838'
        switch (RGCIDString)
                case 'L1'
                    residualDefocusForDerivingSyntheticRGCModel = 0.0;
                 case 'L2'
                    residualDefocusForDerivingSyntheticRGCModel = 0.057;
                case 'L3'
                    residualDefocusForDerivingSyntheticRGCModel = 0.077;
                case 'L4'
                    residualDefocusForDerivingSyntheticRGCModel = 0.077;
                case 'L5'
                    residualDefocusForDerivingSyntheticRGCModel = 0.067; %FLAT b/ 0.062-0.072
                case 'L6'
                    residualDefocusForDerivingSyntheticRGCModel = 0.082;
                case 'L7'
                    residualDefocusForDerivingSyntheticRGCModel = 0.0;
                case 'L8'
                    residualDefocusForDerivingSyntheticRGCModel = 0.0;   %FLAT n/n 0 - 0.057
                case 'L9'
                    residualDefocusForDerivingSyntheticRGCModel = 0.077; 
                case 'L10'
                    residualDefocusForDerivingSyntheticRGCModel = 0.077; % FLAT b/n 0.067-.0.077
                case 'L11'
                    residualDefocusForDerivingSyntheticRGCModel = 0.062; % FLAT b/n 0.057-0.067
                case 'M1'
                    residualDefocusForDerivingSyntheticRGCModel = 0.067; % FLAT between 0.057-0.077
                case 'M2'
                    residualDefocusForDerivingSyntheticRGCModel = 0.0;
                case 'M3'
                   residualDefocusForDerivingSyntheticRGCModel = 0.067;  % FLAT from 0 - 0.072
                case 'M4'
                   residualDefocusForDerivingSyntheticRGCModel = 0.0;  % FLAT from 0 to 0.062
                otherwise
                    error('Must be a residual defocus for cell %s', RGCIDString);
        end % RGCIDString
            
        otherwise
            error('No data for monkey ''%s''.', monkeyID);
    end  % monnkeyID
            
        
end
