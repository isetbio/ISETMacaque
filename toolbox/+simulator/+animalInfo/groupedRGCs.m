% simulator.animalInfo.groupedRGCs(monkeyID)
% Group cells in reducing bandpassiness
function [centerConeTypes, coneRGCindices] = groupedRGCs(monkeyID)

    switch (monkeyID)
        case 'M838'
            centerConeTypes = {'L', 'L', 'L', 'L', 'L', ...
                               'L', 'L', 'L', 'M', 'M', ...
                               'M', 'M', 'L', 'L', 'L'};
            
            coneRGCindices = [
                4   7  3   1 9 ...
                11  6  8   2 3 ...
                4  1  10  5 2];


        otherwise
            error('No data for monkey ''%s''.', monkeyID);
    end



end
