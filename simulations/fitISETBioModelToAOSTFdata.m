function fitISETBioModelToAOSTFdata
% Use the ISETBio computed M838 cone mosaic responses with a single cone 
% spatial pooling (DoG) model to fit the measured STF data

    targetLcenterRGCindices = [11]; %[1 3 4 5 6 7 8 10 11]; % the non-low pass cells
    targetMcenterRGCindices = []; % [1 2 4];   % the non-low pass cells
    
    centerConesSchema =   'single';

    %residualDefocusDiopters = 0.000;
    %residualDefocusDiopters = 0.020;
    %residualDefocusDiopters = 0.040;
    %residualDefocusDiopters = 0.055;
    %residualDefocusDiopters = 0.063;
    residualDefocusDiopters = 0.067;
    %residualDefocusDiopters = 0.072;
    %residualDefocusDiopters = 0.075;
    %residualDefocusDiopters = 0.085;
    %residualDefocusDiopters = 0.100;
    %residualDefocusDiopters = 0.125;
    %residualDefocusDiopters = 0.150;

    % Run 1
    accountForResponseOffset = false;
    accountForResponseSignReversal = false;

    batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal);


    % Run 2
    accountForResponseOffset = true;
    accountForResponseSignReversal = false;
    
    batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal);


    % Run 3
    accountForResponseOffset = false;
    accountForResponseSignReversal = true;
    
    batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal);


    % Run 4
    accountForResponseOffset = true;
    accountForResponseSignReversal = true;
    
    batchFitISETBioModelToAOSTFdata(...
        targetLcenterRGCindices, targetMcenterRGCindices, ...
    centerConesSchema, residualDefocusDiopters, ...
    accountForResponseOffset, accountForResponseSignReversal);



end