function [resampled_mean_dfF_otf, resampled_std_dfF_otf]= ...
    resampleDfFoMeasurements(nSamples, visualizeResampling, visualizeAllSessionData)

    % Generate data filename
    rootDirName = ISETmacaqueRootPath();
    
    % Mean (over all sessions) data
    load(fullfile(rootDirName, 'dataResources/WilliamsLab/spatialFrequencyData_M838_OD_2021.mat'), 'freqs', 'cone_center_guesses', 'midget_dfF_otf', 'otf');
    spatialFrequency = freqs;

    % Data from each session
    load(fullfile(rootDirName, 'dataResources/WilliamsLab/838_data_alltrials.mat'), 'midget_dfF_otf_all');

    % Error for each session
    load(fullfile(rootDirName, 'dataResources/WilliamsLab/838_errorData_alltrials.mat'), 'midget_dfF_otf_all_errors');

    cellsNum = size(midget_dfF_otf_all,1);
    resampled_mean_dfF_otf = zeros(cellsNum, numel(spatialFrequency));
    resampled_std_dfF_otf = zeros(cellsNum, numel(spatialFrequency));
    
    switch (nSamples)
        case -99
           % Return the mean over all sessions
           resampled_mean_dfF_otf = squeeze(mean(midget_dfF_otf_all,3));
           resampled_std_dfF_otf = squeeze(mean(midget_dfF_otf_all_errors,3));
           return;
        case 0
            % Return data from the best session
            for iCell = 1:cellsNum
                switch (iCell)
                    case {8,9,12,14}
                        % For these cells, the best session was #1
                        bestSession = 1;
                        resampled_mean_dfF_otf(iCell,:) = squeeze(midget_dfF_otf_all(iCell,:,bestSession));
                        resampled_std_dfF_otf(iCell,:) = squeeze(midget_dfF_otf_all_errors(iCell,:,bestSession));
                    case {5, 6,7,10,15}
                        % For these cells, the best session was #2
                        bestSession = 2;
                        resampled_mean_dfF_otf(iCell,:) = squeeze(midget_dfF_otf_all(iCell,:,bestSession));
                        resampled_std_dfF_otf(iCell,:) = squeeze(midget_dfF_otf_all_errors(iCell,:,bestSession));
                    case {1,2,3,4}
                        % For these cells, the best session was #3
                        bestSession = 3;
                        resampled_mean_dfF_otf(iCell,:) = squeeze(midget_dfF_otf_all(iCell,:,bestSession));
                        resampled_std_dfF_otf(iCell,:) = squeeze(midget_dfF_otf_all_errors(iCell,:,bestSession));
                    otherwise
                        % Return the mean over all sessions
                        resampled_mean_dfF_otf(iCell,:) = squeeze(mean(midget_dfF_otf_all(iCell,:,:),3));
                        resampled_std_dfF_otf(iCell,:) = squeeze(mean(midget_dfF_otf_all_errors(iCell,:,:),3));
                end
            end
            return;
        case -1
            % Only the first session data
            resampled_mean_dfF_otf = squeeze(midget_dfF_otf_all(:,:,1));
            return;
        case -2
            % Only the 2nd session data
            resampled_mean_dfF_otf = squeeze(midget_dfF_otf_all(:,:,2));
            return;
        case -3
            % Only the 3rd session data
            resampled_mean_dfF_otf = squeeze(midget_dfF_otf_all(:,:,3));
            return;
    end
        
    if (nSamples < 0)
        error('nSamples must be > 1 or -1,-2,-3, not %d\n', nSamples);
    end
    
    if (visualizeResampling)
        hFig = figure(123); clf;
        set(hFig, 'Position', [10 10 1900 1000], 'Color', [1 1 1]);
        rowsNum = 3;
        colsNum = 5;
        sv = NicePlot.getSubPlotPosVectors(...
            'colsNum', colsNum, ...
            'rowsNum', rowsNum, ...
            'heightMargin',  0.05, ...
            'widthMargin',    0.04, ...
            'leftMargin',     0.04, ...
            'rightMargin',    0.01, ...
            'bottomMargin',   0.08, ...
            'topMargin',      0.01);
        sv = sv';
    end
   
    
    
    for iCell = 1:cellsNum
        theSessionMeanResponses = squeeze(midget_dfF_otf_all(iCell,:,:));

        resampledSFresponses = bootstrp(nSamples,@mean, theSessionMeanResponses');
        meanResampledResponse = squeeze(mean(resampledSFresponses,1));
        stdResampledResponse = squeeze(std(resampledSFresponses,0,1));
        
        resampled_mean_dfF_otf(iCell,:) = meanResampledResponse;
        resampled_std_dfF_otf(iCell,:)  = stdResampledResponse;
        
        if (visualizeResampling)
            ax = subplot('Position', sv(iCell).v);

            for iSample = 1:nSamples
                scatter(ax, spatialFrequency, resampledSFresponses(iSample,:), 169, 'filled', ...
                'MarkerFaceAlpha', 1/nSamples, 'MarkerFaceColor', [1 0 0], ...
                'MarkerEdgeColor', 'none');
                hold(ax, 'on');
            end

            plot(ax,spatialFrequency, meanResampledResponse, 'k-', ...
                'LineWidth', 3.0);
            plot(ax,spatialFrequency, meanResampledResponse, 'r-', ...
                'LineWidth', 1.5);
            errorbar(spatialFrequency, meanResampledResponse, stdResampledResponse, 'LineWidth', 1.5);

           % plot(ax,spatialFrequency, squeeze(midget_dfF_otf(iCell, :)), 'k--', 'LineWidth', 1.5)

            set(ax, 'XScale', 'log', 'XLim', [1 100], 'YLim', [min(resampledSFresponses(:)) max([0.6 max(resampledSFresponses(:)) ])], ...
                'XTick', [1 3 10 30 100], 'YTick', -0.1:0.1:1, 'FontSize', 15);
            grid(ax, 'on');
            axis(ax, 'square');
            if (iCell > 10)
                xlabel(ax, 'spatial frequency (c/deg)');
            end
            switch (iCell)
                case {1,6,11}
                     ylabel(ax, '\DeltaF / F_o');
            end
            drawnow
        end
       
    end
    if (visualizeResampling)
        NicePlot.exportFigToPDF('resampling.pdf', hFig, 300);
    end
    
    
    if (visualizeAllSessionData)

        sessionsNum = size(midget_dfF_otf_all,3);
        colors = brewermap(sessionsNum, 'set1');
        
        for iSession = 0:sessionsNum
            hFig = figure(100+iSession);
            clf;
            set(hFig, 'Position', [10 10 1900 1000], 'Color', [1 1 1]);
        
       
        
            for iCell = 1:size(midget_dfF_otf_all,1)

                ax = subplot('Position', sv(iCell).v);
                hold(ax, 'on');
                
                switch (cone_center_guesses{iCell})
                    case 'L'
                        cellColor = [1 0.1 0.5];
                    case 'M'
                        cellColor = [0.1 0.5 0.5];
                end
                
                if (iSession == 0)
                    p = [];
                    for kSession = 1:sessionsNum
                        color = squeeze(colors(kSession,:));
                        sessionResponse = squeeze(midget_dfF_otf_all(iCell,:, kSession));
                        sessionErrors = squeeze(midget_dfF_otf_all_errors(iCell, :, kSession));

                        p(kSession) = plot(ax, spatialFrequency, sessionResponse, ...
                            'ko', 'LineWidth', 1.5, 'MarkerFaceColor', color, 'MarkerEdgeColor', color*0.5, 'MarkerSize', 12);
                        errorbar(ax, spatialFrequency, sessionResponse, sessionErrors, ...
                            'LineWidth', 1.5, 'Color', color*0.5);
                    end

                    p(4) = plot(ax,spatialFrequency, squeeze(mean(midget_dfF_otf_all(iCell, :,:),3)), 'k-', ...
                        'LineWidth', 3);

                   % p(5) = scatter(ax,spatialFrequency, squeeze(midget_dfF_otf(iCell, :)), 169, 'filled', ...
                   %     'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.8 0.8 0.8], 'MarkerEdgeColor', [0 0 0], 'LineWidth', 1.5);


                    legend(ax,[p(1) p(2) p(3) p(4)], ...
                        {'session 1', 'session 2', 'session 3', 'mean over sessions'}, ...
                        'Location', 'NorthWest');
                else
                    for kSession = 1:sessionsNum
                        if (kSession ~= iSession)
                            sessionResponse = squeeze(midget_dfF_otf_all(iCell,:, kSession));
                            switch (kSession)
                                case 1
                                    symbol = 's';
                                case 2
                                    symbol = 'v';
                                case 3
                                    symbol = 'o';
                            end
                            hL = plot(ax, spatialFrequency, sessionResponse, '-', 'LineWidth', 1.5);
                            hL.Color = [cellColor(1) cellColor(2) cellColor(3) 0.3];
                    
                            scatter(ax, spatialFrequency, sessionResponse, 169, 'filled', symbol,...
                            'MarkerFaceAlpha', 0.3, 'MarkerEdgeAlpha', 0.3, ...
                            'MarkerFaceColor', cellColor, 'MarkerEdgeColor', cellColor*0.5, 'LineWidth', 1.5);
                        end
                        
                    end
                    
                    switch (iSession)
                        case 1
                            symbol = 's';
                        case 2
                            symbol = 'v';
                        case 3
                            symbol = 'o';
                    end
                            
                    sessionResponse = squeeze(midget_dfF_otf_all(iCell,:, iSession));
                    sessionErrors = squeeze(midget_dfF_otf_all_errors(iCell, :, iSession));
                    
                    hL = plot(ax, spatialFrequency, sessionResponse, '-', 'LineWidth', 1.5);
                    hL.Color = [cellColor(1)*0.5 cellColor(2)*0.5 cellColor(3)*0.5 1];
                    
                    errorbar(ax, spatialFrequency, sessionResponse, sessionErrors, symbol,...
                        'LineWidth', 1.5, 'Color', cellColor*0.5, 'MarkerSize', 13, ...
                        'MarkerFaceColor', cellColor, 'MarkerEdgeColor', cellColor*0.5,'LineWidth', 1.5);
                        
%                     scatter(ax, spatialFrequency, sessionResponse, 169, 'filled', symbol, ...
%                             'MarkerFaceColor', cellColor, 'MarkerEdgeColor', cellColor*0.5,'LineWidth', 1.5);
%                         
                    plot(ax,spatialFrequency, squeeze(mean(midget_dfF_otf_all(iCell, :, :),3)), '--',...
                     'Color', 'k', 'LineWidth', 1.5);

               
                end
                
                set(ax, 'XScale', 'log', 'XLim', [1 100], 'YLim', [-0.1 1], ...
                    'XTick', [1 3 10 30 100], 'YTick', -0.2:0.2:1, 'FontSize', 18);
                grid(ax, 'on');
                if (iCell > 10)
                    xlabel(ax, 'spatial frequency (c/deg)');
                end
                switch (iCell)
                    case {1,6,11}
                         ylabel(ax, '\DeltaF / F_o');
                end 
            end
            if (iSession == 0)
                NicePlot.exportFigToPDF('allSessions.pdf', hFig, 300);
            else
                NicePlot.exportFigToPDF(sprintf('session_%d.pdf', iSession),hFig, 300);
            end
        end
        
    end
    
end
