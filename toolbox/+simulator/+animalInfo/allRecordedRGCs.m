% simulator.animalInfo.allRecordedRGCs(monkeyID)

function [centerConeTypes, coneRGCindices] = allRecordedRGCs(monkeyID, varargin)

    p = inputParser;
    p.addParameter('excludedRGCIDs', {}, @iscell);
    p.parse(varargin{:});
    excludedRGCIDs = p.Results.excludedRGCIDs;

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
    
    if (~isempty(excludedRGCIDs))
        centerConeTypesValid = {};
        coneRGCindicesValid = [];
        for iRGC = 1:numel(centerConeTypes)
            cellIDString = sprintf('%s%d', centerConeTypes{iRGC}, coneRGCindices(iRGC));
            if (~ismember(cellIDString, excludedRGCIDs))
                centerConeTypesValid{numel(centerConeTypesValid)+1} = centerConeTypes{iRGC};
                coneRGCindicesValid(numel(coneRGCindicesValid)+1) = coneRGCindices(iRGC);
            else
                fprintf(2,'Excluding cell %s from the analysis\n', cellIDString);
            end
        end
        centerConeTypes = centerConeTypesValid;
        coneRGCindices = coneRGCindicesValid;
    end

end
