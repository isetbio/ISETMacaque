function plotRawSTFs()
    % Plot the STFs (single sessions and averaged) for all the cells

    % Monkey to employ
    monkeyID = 'M838';

    useOriginalCellLabeling = ~true;

   
    if (useOriginalCellLabeling)
         % Get all recorded RGC infos
        [centerConeTypes, coneRGCindices] = simulator.animalInfo.allRecordedRGCs(monkeyID);
    else
        % Group RGCs, so that low-pass ones appear in 5th column
        [centerConeTypes, coneRGCindices] = simulator.animalInfo.groupedRGCs(monkeyID);
    end

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

            if (useOriginalCellLabeling)
                cellIDString = sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex);
            else
                cellIDString = sprintf('RGC %d', iRGCindex);
            end

            yAxisScaling = 'linear';  % choose between {'linear' and 'log'}
            simulator.visualize.fittedSTF(hFig, axSTF, ...
                STFdataToFit.spatialFrequencySupport, ...
                STFdataToFit.responses, ...
                [], ...
                [], [], false, ...
                cellIDString, ...
                'noXLabel', noXLabel, ...
                'noYLabel', noYLabel, ...
                'yAxisScaling', 'linear');
            drawnow;
    end


    % Each cell in separate figure
    for iRGCindex = 1:numel(coneRGCindices) 
            STFdataToFit = simulator.load.fluorescenceSTFdata(monkeyID, ...
                'whichSession', 'allSessions', ...
                'undoOTFdeconvolution', true, ...     % remove the baked-in deconvolution by the diffr.limited OTF
                'whichCenterConeType', centerConeTypes{iRGCindex}, ...
                'whichRGCindex', coneRGCindices(iRGCindex));

            hFig = figure(100+iRGCindex); clf;
            set(hFig, 'Color', [1 1 1], 'Position', [10 10 300 300], 'Name', sprintf('%s%d', STFdataToFit.whichCenterConeType, STFdataToFit.whichRGCindex));
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
                cellIDString, ...
                'noXLabel', noXLabel, ...
                'noYLabel', noYLabel, ...
                'yAxisScaling', 'log');
            drawnow;
            
    end
    
end

