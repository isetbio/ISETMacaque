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
if (strcmp(computerInfo.networkName, 'leviathan.psych.upenn.edu'))
    generatedDataDir = '/media/dropbox_disk/Dropbox (Aguirre-Brainard Lab)/ISETMacaqueSimulations/generatedData';
    setpref(projectName, 'computerName', 'leviathan');
else
    switch (computerInfo.localHostName)
        case 'Santorini'
            generatedDataDir = '/Volumes/SSDdisk/Dropbox/Dropbox (Aguirre-Brainard Lab)/ISETMacaqueSimulations/generatedData'; 
        case 'Ithaka'
            generatedDataDir = '/Volumes/SSDdisk/Dropbox (Aguirre-Brainard Lab)/ISETMacaqueSimulations/generatedData';
        case 'Crete'
            generatedDataDir = '/Volumes/Dropbox/Dropbox (Aguirre-Brainard Lab)/ISETMacaqueSimulations/generatedData';
    end
    setpref(projectName, 'computerName', computerInfo.localHostName);
end

setpref(projectName, 'generatedDataDir', generatedDataDir);






