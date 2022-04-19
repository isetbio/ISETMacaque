% simulator.animalInfo.lowPassRGCs(monkeyID)
function RGCIDs = lowPassRGCs(monkeyID)
    switch (monkeyID)
        case 'M838'
            RGCIDs = {'L2', 'L9',  'M3'};

        otherwise
            error('No data for monkey ''%s''.', monkeyID);
    end
           
end
