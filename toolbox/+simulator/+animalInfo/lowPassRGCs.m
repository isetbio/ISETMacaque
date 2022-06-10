% simulator.animalInfo.lowPassRGCs(monkeyID)
function [RGCIDs, centerConeTypes, coneRGCindices] = lowPassRGCs(monkeyID)
    switch (monkeyID)
        case 'M838'
            RGCIDs = {'L2', 'L9',  'M3'};
            centerConeTypes = {'L', 'L', 'M'};
            coneRGCindices = [2 9 3];
        otherwise
            error('No data for monkey ''%s''.', monkeyID);
    end
           
end
