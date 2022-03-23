% simulator.animalInfo.allRecordedRGCs(monkeyID)

function [centerConeTypes, coneRGCindices] = allRecordedRGCs(monkeyID)

    switch (monkeyID)
        case 'M838'
            LconeRGCsNum  = 11;
            MconeRGCsNum = 4;
            centerConeTypes(1:LconeRGCsNum) = {'L'};
            centerConeTypes(LconeRGCsNum+(1:MconeRGCsNum)) = {'M'};
            coneRGCindices(1:LconeRGCsNum) = 1:LconeRGCsNum;
            coneRGCindices(LconeRGCsNum+(1:MconeRGCsNum)) = 1:MconeRGCsNum;
            
        otherwise
            error('No data for monkey ''%s''.', monkeyID);
    end
    
end
