function fitISETBioModelToAOSTFdata
% Use the ISETBio computed M838 cone mosaic responses with a single cone 
% spatial pooling (DoG) model to fit the measured STF data

    % Multi-start >1 or single attempt
    startingPointsNum = 512;

    % Leviathan: do 10 and 8
    targetLcenterRGCindices = [10]; %[1 3 4 5 6 7 8 10 11]; % the non-low pass cells
    targetMcenterRGCindices = []; % [1 2 4];   % the non-low pass cells


    % Run the signed response model variant
    accountForResponseOffset = true;
    accountForResponseSignReversal = false;


    % Hypothesis 1
    centerConesSchema =  'single';      % single-cone RF center
    residualDefocusDiopters = 0.000;    % zero residual defocus

    batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal, ...
    startingPointsNum);


    % Hypothesis 2
    centerConesSchema =  'single';      % single-cone RF center
    residualDefocusDiopters = 0.067;    % 0.067D residual defocus
    
    batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal, ...
    startingPointsNum);


    % Hypothesis 3
    centerConesSchema =  'multiple';   % multiple-cones in RF center
    residualDefocusDiopters = 0.000;   % zero residual defocus
    
    batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal, ...
    startingPointsNum);


    % Hypothesis 4
    centerConesSchema =  'multiple';   % multiple-cones in RF center
    residualDefocusDiopters = 0.067;   % 0.067D residual defocus
    
    batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal, ...
    startingPointsNum);



end