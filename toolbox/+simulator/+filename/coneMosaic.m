function filename = coneMosaic(monkeyID)
% Generate filename for the coneMosaic object
%
% Syntax:
%   filename = simulator.filename.coneMosaic((monkeyID);
%
% Description: Generate filename for the coneMosaic object
%
%
% History:
%    09/23/21  NPC  ISETBIO TEAM, 2021

    p = getpref('ISETMacaque');
    filename = fullfile(p.generatedDataDir, 'components', sprintf('cMosaic%s.mat', monkeyID));
end