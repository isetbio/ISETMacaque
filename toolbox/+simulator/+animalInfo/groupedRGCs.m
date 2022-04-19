% simulator.animalInfo.groupedRGCs(monkeyID)
function [centerConeTypes, coneRGCindices] = groupedRGCs(monkeyID)

    switch (monkeyID)
        case 'M838'
            centerConeTypes = {'L', 'L', 'L', 'L', 'L', ...
                               'L', 'L', 'L', 'L', 'L', ...
                               'L', 'M', 'M', 'M', 'M'};
            coneRGCindices = [
                1  3  4  5 2 ...
                6  7  8 10 9 ...
                11 1  2  4 3];
        otherwise
            error('No data for monkey ''%s''.', monkeyID);
    end



end
