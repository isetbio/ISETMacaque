function filename = residualDefocusOTF(residualDefocusDiopters)
% Generate filename for the residual defocus oTF
%
% Syntax:
%   filename = simulator.filename.residualDefocusOTF(residualDefocusDiopters)
%
% Description: Generate filename for the residual defocus OTF
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021

    p = getpref('ISETMacaque');
    filename = fullfile(p.generatedDataDir, 'components', ...
        sprintf('residualDefocusOTF_%2.4fD.mat', residualDefocusDiopters));
end
