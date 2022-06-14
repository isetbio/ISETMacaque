% simulator.animalInfo.serializedRGCindinces(monkeyID, centerConeTypes, coneRGCindices)
function rgcIndices = serializedRGCindices(monkeyID, centerConeTypes, coneRGCindices)

    filepath = fullfile(ISETmacaqueRootPath, 'animals/WilliamsLab');
    fileName = fullfile(filepath, sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID));
    load(fileName, 'cone_center_guesses'); 


    rgcIndices = zeros(1, numel(centerConeTypes));
    switch (monkeyID)
        case 'M838'
            for i = 1:numel(centerConeTypes)
                switch (lower(centerConeTypes{i}))
                    case 'l'
                        idx = find(strcmp(cone_center_guesses, 'L')==1);
                    case 'm'
                        idx = find(strcmp(cone_center_guesses, 'M')==1);
                end
                
                if ((coneRGCindices(i) < 1) || (coneRGCindices(i) > numel(idx)))
                    error('Cell %s%d does not exist in the dataset', centerConeTypes(i), coneRGCindices(i));
                end

                rgcIndices(i) = idx(coneRGCindices(i));
            end

        otherwise
            error('No data for monkey ''%s''.', monkeyID);
    end

end