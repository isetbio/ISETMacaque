function analyzeWilliamsLabDataMain()

     monkeyID = 'M838';
    
     % What operation to perform
     operations = struct(...
        'recomputeConeResponses', true, ...             % Step 1. Compute responses
     	'visualizedConeResponses', ~true, ...
        'reFitData', true, ...                           % Step 2. Fit data
        'synthesizeRGCAndComputeResponses', ~true ...    % Step 3. Synthesize RGCs and compute responses for current optics
     );
 
     stimulusType = 'LCDdisplayAchromatic';
     
     switch (stimulusType)
         case 'AO'
             % Monochromatic AO stimulus employed by Williams lab
             visualStimulus = struct(...
                 'type', 'WilliamsLabStimulus', ...
                 'stimulationDurationCycles', 4 ...
             );
            noLCA = false;
         case 'LCDdisplayAchromatic'
            visualStimulus = struct(...
                 'type', 'CRT', ...
                 'stimulationDurationCycles', 4, ...
                 'backgroundChromaticity', [0.31 0.32], ...
                 'backgroundLuminanceCdM2', 1802, ...  % Match the AO stimulus luminance
                 'lmsConeContrasts', [1 1 1] ...
            );
            noLCA = true;
     end
     
     
     % Aperture parameters
     apertureParams.shape = 'Gaussian';
     apertureParams.sigma = 0.204;          % x inner segment diameter (cone diameter)  - From McMahon et al, 2000
     
     % Analyze responses for the midget RGCs within the central +/- 12.5 microns
     eccRadiusMicrons = 12;
     eccCenterMicrons = [0 0];
     
     % Empty - no coupling
     % coneCouplingLambda = 0;
     
     % Positive - coupling with 4 closest neigbors, with weights = exp(-distance / constant), constant = lambda  * cone diameter
     %coneCouplingLambda = 0.35;
     
     % Negative - coupling with closes 1 neighbor with weight = abs(coneCouplingLamnda)
     % coneCouplingLambda = -0.7;

     
     % Examined conditions: residual optical defocus vs none
     %examinedOpticalDefocusDiopters = [0   0.068];   % [0 0];
     %examinedConeCouplingLambdas    = [0   0];       % [0 0.35];
     
     % Examined conditions: cone coupling vs none
     %examinedOpticalDefocusDiopters = [0 0];
     %examinedConeCouplingLambdas    = [0 0.35];
     
     % NOTE: 0.066 defocus was conducted with pixelSize = 0.5 x pixelSize
     % using in the experiment to reduce issues related to quantization
     
     examinedOpticalDefocusDiopters = [0.067];
     examinedConeCouplingLambdas    = [0];   
     
     % subjects to examine
     subjectsExamined = 0; % [10 9 8 6 4 2];  % Choose from 1:10 (or 0, for Diffraction-Limited optics)
     
     
     % Real optics
     for iSubject = 1:numel(subjectsExamined)  
     
         PolansSubject = subjectsExamined(iSubject);
         if (PolansSubject == 0)
            % Diffraction-limited optics
            fprintf(2, 'Employing diffraction-limited optics.\n');
            PolansSubject = [];
         else
             fprintf(2, 'Employing Polans optics (subject %d).\n', PolansSubject);
         end
         
         for k = 1:numel(examinedConeCouplingLambdas)
             coneCouplingLambda = examinedConeCouplingLambdas(k);
             opticalDefocusDiopters = examinedOpticalDefocusDiopters(k);

             if (operations.recomputeConeResponses)
                 computeConeMosaicResponses(monkeyID, apertureParams, coneCouplingLambda, ...
                     opticalDefocusDiopters, PolansSubject, visualStimulus, 'noLCA', noLCA);
             end

             if (operations.visualizedConeResponses)
                 visualizeConeMosaicResponses(monkeyID, apertureParams,  coneCouplingLambda, opticalDefocusDiopters, PolansSubject, visualStimulus);
             end

             if (operations.reFitData)
                 lowerBoundForRsToRcInFreeRcFits = 1.5;
                 
                 % If you want to estimate retinal Rcs under the residual
                 % blur assumption set the following flat to true
                 deconvolveMeasurementsWithResidualBlur = true;
                 
                 % choose which data to get. Optiocs are {'mean', 'resampleSessionData', 'session1only', 'session2only', 'session3only', 'sessionWithHighestSFextension'}
                 sessionData = 'mean'; 
                 fitConeMosaicResponses(monkeyID, apertureParams,  coneCouplingLambda, opticalDefocusDiopters, ...
                     eccCenterMicrons, eccRadiusMicrons, PolansSubject, visualStimulus, lowerBoundForRsToRcInFreeRcFits, ...
                     sessionData, deconvolveMeasurementsWithResidualBlur);
             end 
         end



         if (operations.synthesizeRGCAndComputeResponses)
            synthesizeRGCs(monkeyID, apertureParams,  coneCouplingLambda, opticalDefocusDiopters, eccCenterMicrons, eccRadiusMicrons, PolansSubject, visualStimulus);
         end
     end
         
end

