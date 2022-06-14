function plotRawFluorescenceTimeCourses
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


    % Select a single session
    whichSession = 2;

    
    spatialFrequencyCyclesPerDegree = 30;

    % Plot raw data for each cell
    for iRGCindex = 1:numel(coneRGCindices) 

        % Load the data
        [temporalSupportSeconds, theResponseTrace, theSpatialFrequency] = ...
            simulator.load.fluorescenceRawTraces(monkeyID, ...
                'whichSession', whichSession, ...
                'whichCenterConeType', centerConeTypes(iRGCindex), ...
                'whichRGCindex', coneRGCindices(iRGCindex), ...
                'whichSpatialFrequency', spatialFrequencyCyclesPerDegree);
       

        idx = find((temporalSupportSeconds>= 12) & (temporalSupportSeconds <= 19));
        mu = mean(theResponseTrace(idx))
        sigma = std(theResponseTrace(idx),0,2)
        figure(111);
        subplot(3,1,1);
        plot(temporalSupportSeconds, theResponseTrace, 'k-')
        subplot(3,1,2);
        plot(temporalSupportSeconds, theResponseTrace-mu, 'k-');
        subplot(3,1,3);
        plot(temporalSupportSeconds, (theResponseTrace-mu)/sigma, 'k-');
        pause

        doPowerAnalysis = ~true;
        if (doPowerAnalysis)
            targetTemporalFrequency = 6.0;
            [temporalSupportSeconds, theResponseTrace, theActualTemporalFrequency] = ...
                powerTimeSeriesAtFrequency(...
                    temporalSupportSeconds, theResponseTrace, targetTemporalFrequency);
            yLabelString = sprintf('power @%2.1f Hz', theActualTemporalFrequency);
        else
             yLabelString = 'fluorescence';
        end

        row = floor((iRGCindex-1)/5)+1;
        col = mod(iRGCindex-1,5)+1;
        axTrace = subplot('Position', subplotPosVectors(row,col).v);

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

        simulator.visualize.rawFluorescenceTraces(hFig, axTrace, ...
            temporalSupportSeconds, theResponseTrace, ...
            cellIDString, ...
            theSpatialFrequency, ...
            'xLims', [temporalSupportSeconds(1) temporalSupportSeconds(end)], ...
            'xTicks', 0:10:100, ....
            'xLabel', 'time (seconds)', ...
            'yLabel', yLabelString, ...
            'yLims', [], ...
            'noXLabel', noXLabel, ...
            'noYLabel', noYLabel);
        drawnow;
    end % iRGCindex
end


function [temporalSupport, powerTimeSeries, theTemporalFrequency] = powerTimeSeriesAtFrequency(timeAxisSeconds, responseTrace,  targetTemporalFrequency)
    % Spectrogram analysis
    spectrogramStruct = simulator.analyze.multiTaperSpectrogram(responseTrace, timeAxisSeconds);

    % Find the index of the frequency most close to the target temporal frequency
    [~, iFreq] = min(abs(spectrogramStruct.frequencySupportHz-targetTemporalFrequency));

    
%    meanPower = spectrogramStruct.power;
%    time = spectrogramStruct.temporalSupportSeconds;

    figure(100);clf;
    for k = 1:50
        t1 = 0+k;
        t2 = t1+8;
        idx = find(...
                (spectrogramStruct.temporalSupportSeconds>=t1) & ...
                (spectrogramStruct.temporalSupportSeconds<=t2));
        meanPower(:,k) = mean(spectrogramStruct.power(:,idx),2);
        time(k) = (t1+t2)/2;
    end

    subplot(2,3,1)
    imagesc(time,spectrogramStruct.frequencySupportHz, meanPower)
    hold on;
    plot([12 12], [0 20], 'w--');
    plot([19 19], [0 20], 'w--');
    idx = find((time>= 12) & (time <= 19));
    meanNonCausalPower = mean(meanPower(:,idx),2);
    stdNonCausalPower = std(meanPower(:,idx),0,2);

    subplot(2,3,4);
    plot(time, meanPower(iFreq,:), 'k-');


    meanPower = bsxfun(@minus, meanPower, meanNonCausalPower);
    subplot(2,3,2)
    imagesc(time,spectrogramStruct.frequencySupportHz, meanPower)

    subplot(2,3,5);
    plot(time, meanPower(iFreq,:), 'k-');
  

    meanPower = bsxfun(@times, meanPower, 1./stdNonCausalPower);

    subplot(2,3,3)
    imagesc(time,spectrogramStruct.frequencySupportHz, meanPower)

    subplot(2,3,6);
    plot(time, meanPower(iFreq,:), 'k-');
   

    pause;

    
    
    observationDurationSeconds = 4.0;
    observationDurationIntervalSeconds = observationDurationSeconds/2;

    observationPeriodsNum = round(spectrogramStruct.temporalSupportSeconds(end)/observationDurationIntervalSeconds);

    
    
    for iObservationPeriod = 1:observationPeriodsNum
        tStart = (iObservationPeriod-1)*observationDurationIntervalSeconds;
        tEnd = tStart + observationDurationSeconds;
        idx = find(...
            (spectrogramStruct.temporalSupportSeconds>=tStart) & ...
            (spectrogramStruct.temporalSupportSeconds<=tEnd));
      
        powerTimeSeries(:,iObservationPeriod) = sum(spectrogramStruct.power(:, idx),2);
        powerTimeSeriesTimeAxis(iObservationPeriod) = tStart;
    end
    figure(21); clf; hold on
    for iObservationPeriod = 1:observationPeriodsNum
        subplot(4,7,iObservationPeriod);
        tStart = powerTimeSeriesTimeAxis(iObservationPeriod);
        tEnd = tStart + observationDurationSeconds;
        plot(spectrogramStruct.frequencySupportHz, powerTimeSeries(:,iObservationPeriod), 'k-');
        hold on;
        plot(spectrogramStruct.frequencySupportHz(iFreq)*[1 1], [0 max(powerTimeSeries(:))], 'r-');
        set(gca, 'YLim', [0 max(powerTimeSeries(:))]);
        title(sprintf('time: %d-%d seconds', tStart, tEnd));
    end

    figure(1000); clf;
    plot(spectrogramStruct.temporalSupportSeconds, spectrogramStruct.power(iFreq,:), 'k-');
    xlabel('time');
    ylabel(sprintf('power at %2.1f Hz', spectrogramStruct.frequencySupportHz(iFreq)));

    nonCausalBins = find(powerTimeSeriesTimeAxis < 20);
    nonCausalSpectrum = mean(powerTimeSeries(:, nonCausalBins),2);
    causalBins = find((powerTimeSeriesTimeAxis > 20));
    causalSpectrum1 = mean(powerTimeSeries(:, causalBins),2);


    figure(23); clf
    plot(spectrogramStruct.frequencySupportHz, nonCausalSpectrum, 'k-');
    hold on
    plot(spectrogramStruct.frequencySupportHz, causalSpectrum1, 'r-');
    patch([5 5 7 7 5],[0 1 1 0 0],[0.5 0.5 0.5], 'FaceAlpha', 0.5);
    
    set(gca, 'XLim', [0 20])
    pause
    % Returned values
    theTemporalFrequency = spectrogramStruct.frequencySupportHz(iFreq);
    temporalSupport = spectrogramStruct.temporalSupportSeconds;
    powerTimeSeries = spectrogramStruct.power(iFreq,:);


end

% 
% 
%     [min(spectrogramStruct.mag(:)) max(spectrogramStruct.mag(:))]
%     [~, iFreq0Hz] = min(abs(spectrogramStruct.frequencySupportHz-0));
%     [~, iFreq6Hz] = min(abs(spectrogramStruct.frequencySupportHz-6.));
%     [~, iFreq3Hz] = min(abs(spectrogramStruct.frequencySupportHz-3));
%     [~, iFreq9Hz] = min(abs(spectrogramStruct.frequencySupportHz-9));
%     [~, iFreq4Hz] = min(abs(spectrogramStruct.frequencySupportHz-4));
% 
%     size(spectrogramStruct.frequencySupportHz)
%     size(spectrogramStruct.mag)
% 
%     figure(222);clf;
%     subplot(3,2,5);
%     cmap = brewermap(6,'greys');
%     plot(spectrogramStruct.temporalSupportSeconds, spectrogramStruct.mag(iFreq0Hz,:), '-', 'Color', squeeze(cmap(3,:)));
%     hold on;
%     plot(spectrogramStruct.temporalSupportSeconds, spectrogramStruct.mag(iFreq4Hz,:), 'm-', 'Color', squeeze(cmap(4,:)));
%     plot(spectrogramStruct.temporalSupportSeconds, spectrogramStruct.mag(iFreq6Hz,:), 'r-', 'LineWidth', 1.5);
%     plot(spectrogramStruct.temporalSupportSeconds, spectrogramStruct.mag(iFreq9Hz,:), 'b-', 'Color', squeeze(cmap(5,:)));
%     legend({...
%         sprintf('%2.2fHz', spectrogramStruct.frequencySupportHz(iFreq0Hz)) ...
%         sprintf('%2.2fHz', spectrogramStruct.frequencySupportHz(iFreq4Hz)) ...
%         sprintf('%2.2fHz', spectrogramStruct.frequencySupportHz(iFreq6Hz)) ...
%         sprintf('%2.2fHz', spectrogramStruct.frequencySupportHz(iFreq9Hz))});
%     set(gca, 'XLim', [spectrogramStruct.temporalSupportSeconds(1) spectrogramStruct.temporalSupportSeconds(end)]);
%     xlabel('time (seconds)');
%     title('select power');
% 
%     subplot(3,2,3);
%     plot(spectrogramStruct.temporalSupportSeconds, sum(spectrogramStruct.mag,1), 'k-');
%     set(gca, 'XLim', [spectrogramStruct.temporalSupportSeconds(1) spectrogramStruct.temporalSupportSeconds(end)]);
%     xlabel('time (seconds)');
%     title('total power');
% 
%     subplot(3,2,4);
%     idxLessThan20 = find(spectrogramStruct.temporalSupportSeconds<=20);
%     idxMoreThan25 = find(spectrogramStruct.temporalSupportSeconds>=25);
%     plot(spectrogramStruct.frequencySupportHz, sum(spectrogramStruct.mag(:,idxLessThan20),2), 'b-'); hold on
%     plot(spectrogramStruct.frequencySupportHz, sum(spectrogramStruct.mag(:,idxMoreThan25),2), 'r-');
%     set(gca, 'XLim', [0 20]);
%     xlabel('frequency (Hz)');
%     legend({'t< 20 sec', 't > 30 sec'});
%     title('0-20 sec');
% 
%     set(gca, 'XLim', [0 20]);
%     xlabel('frequency (Hz)');
%     title('30-60 sec');
% 
%     subplot(3,2,2);
%     plot(spectrogramStruct.frequencySupportHz, sum(spectrogramStruct.mag,2), 'k-');
%     set(gca, 'XLim', [0 20]);
%     xlabel('frequency (Hz)');
%     title('total time');
% 
%     subplot(3,2,1);
%     imagesc(spectrogramStruct.temporalSupportSeconds, spectrogramStruct.frequencySupportHz, spectrogramStruct.mag);
%     set(gca, 'XLim', [spectrogramStruct.temporalSupportSeconds(1) spectrogramStruct.temporalSupportSeconds(end)]);
%     axis 'xy'
%     xlabel('time (seconds)');
%     ylabel('frequency (Hz)')
% 
%     pause
% 
% %     spectrogramStruct = struct(...
% %         'mag', spec, ...
% %         'temporalSupport', stimes, ...
% %         'frequencySupport', sfreqs);
% 
%     
% end
       