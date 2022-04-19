function plotRawSTFs()

    % Monkey to employ
    monkeyID = 'M838';

    % Get all recorded RGC infos
    %[centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);

    % Group RGCs, so that low-pass ones appear in 5th column
    [centerConeTypes, coneRGCindices] = simulator.animalInfo.groupedRGCs(monkeyID);

    % All cells in same figure
    hFig = figure(1); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [10 10 1100 660]);  

    % Set-up figure
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
       'colsNum', 5, ...
       'rowsNum', 3, ...
       'heightMargin',  0.05, ...
       'widthMargin',    0.04, ...
       'leftMargin',     0.07, ...
       'rightMargin',    0.00, ...
       'bottomMargin',   0.1, ...
       'topMargin',      0.0);

    % Plot raw data for each cell
    for iRGCindex = 1:numel(coneRGCindices) 
            STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                'whichSession', 'allSessions', ...
                'undoOTFdeconvolution', true, ...     % remove the baked-in deconvolution by the diffr.limited OTF
                'whichCenterConeType', centerConeTypes{iRGCindex}, ...
                'whichRGCindex', coneRGCindices(iRGCindex));

            row = floor((iRGCindex-1)/5)+1;
            col = mod(iRGCindex-1,5)+1;
            axSTF = subplot('Position', subplotPosVectors(row,col).v);

            if (row < 3)
                noXLabel = true;
            else
                noXLabel = false;
            end

            if (col > 1)
                noYLabel = true;
            else
                noYLabel = false;
            end

            cellIDString = sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
            cellIDString = sprintf('RGC %d', iRGCindex);

            simulator.visualize.fittedSTF(hFig, axSTF, ...
                STFdataToFit.spatialFrequencySupport, ...
                STFdataToFit.responses, ...
                [], ...
                [], [], false, ...
                noXLabel, noYLabel, cellIDString);
            drawnow;
    end


    % Each cell in separate figure
    for iRGCindex = 4 % %1:numel(coneRGCindices) 
            STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                'whichSession', 'allSessions', ...
                'undoOTFdeconvolution', true, ...     % remove the baked-in deconvolution by the diffr.limited OTF
                'whichCenterConeType', centerConeTypes{iRGCindex}, ...
                'whichRGCindex', coneRGCindices(iRGCindex));

            hFig = figure(100+iRGCindex); clf;
            set(hFig, 'Color', [1 1 1], 'Position', [10 10 300 300]);
            axSTF = subplot('Position', [0.23 0.20 0.78*0.7 0.83*0.7]);

            noXLabel = false;
            noYLabel = false;

            cellIDString = sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
            cellIDString = sprintf('RGC %d', iRGCindex);
            cellIDString = '';
            simulator.visualize.fittedSTF(hFig, axSTF, ...
                STFdataToFit.spatialFrequencySupport, ...
                mean(STFdataToFit.responses,3), ...
                [], ...
                [], [], false, ...
                noXLabel, noYLabel, cellIDString);
            drawnow;
            
    end
    
end
