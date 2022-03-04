% ISETMacaqueLocalHookTemplate
%
% Template for setting preferences and other configuration things, for the
% ISETMacaque project.

% 10/23/18  NPC   Wrote it.

%% Define project
projectName = 'ISETMacaque';

%% Clear out old preferences
if (ispref(projectName))
    rmpref(projectName);
end

%% Specify project location
projectBaseDir = tbLocateProject('ISETMacaque');

%% Specificy generatedData dir location
computerInfo = GetComputerInfo;

generatedDataDir = projectBaseDir;
switch (computerInfo.localHostName)
    case 'Santorini'
        generatedDataDir = '/Volumes/SSDdisk/Dropbox/Dropbox (Aguirre-Brainard Lab)/ISETMacaqueSimulations/generatedData'; 
    case 'Ithaka'
        generatedDataDir = '/Volumes/SSDdisk/Dropbox (Aguirre-Brainard Lab)/ISETMacaqueSimulations/generatedData';
end

setpref(projectName, 'computerName', computerInfo.localHostName);
setpref(projectName, 'generatedDataDir', generatedDataDir);






