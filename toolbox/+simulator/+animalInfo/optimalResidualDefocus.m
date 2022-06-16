function optimalResidualDefocus = ...
    optimalResidualDefocus(monkeyID, RGCIDString, centerPoolingScheme)
% Select the optimal residual defocus for a given RGCID in a given monkey
%
% Syntax:
%   optimalResidualDefocus = simulator.animalInfo.optimalResidualDefocusForSingleConeCenterRFmodel(...
%            monkeyID, RGCIDstring, centerPoolingScheme)
%
% Description:
%   Select the optimal residual defocus for a given RGCID in a given monkey
%
% Inputs:
%    monkeyID
%    RGCIDstring
%    centerPoolingScheme
%
% Outputs:
%    residualDefocusForDerivingSyntheticRGCModel

    switch (monkeyID)
        case 'M838'
            switch (RGCIDString)
                case 'L1'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.0;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.0;
                    end

                 case 'L2'
                     switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.057;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.00;
                    end

                case 'L3'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.077;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.072;
                    end

                case 'L4'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.077;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.057;
                    end

                case 'L5'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.062;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.062;
                    end

                case 'L6'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.082;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.000;
                    end

                case 'L7'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.0;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.062;
                    end

                case 'L8'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.042;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.042;
                    end

                case 'L9'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.077;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.082;
                    end
 
                case 'L10'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.077;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.00;
                    end

                case 'L11'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.062;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.042;
                    end


                case 'M1'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.077;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.057;
                    end

                case 'M2'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.0;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.042;
                    end

                case 'M3'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.062;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.067;
                    end

                case 'M4'
                    switch (centerPoolingScheme)
                        case 'single-cone'
                            optimalResidualDefocus = 0.042;
                        case 'multi-cone'
                            optimalResidualDefocus = 0.057;
                    end

                otherwise
                    error('No data for cell %s', RGCIDString);
            end % RGCIDString
            
        otherwise
            error('No data for monkey ''%s''.', monkeyID);
    end  % monnkeyID
            
        
end
