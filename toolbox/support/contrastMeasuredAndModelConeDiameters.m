
function contrastMeasuredAndModelConeDiameters(cm, measuredConeDiameterData)

    medianConeDiameterMicronsModel = zeros(1, numel(measuredConeDiameterData.medianConeDiametersMicrons));    
    horizontalEccSupport = sort(unique(measuredConeDiameterData.horizontalEccMicrons), 'ascend');
    verticalEccSupport = sort(unique(measuredConeDiameterData.verticalEccMicrons), 'ascend');
   
    
    roiWidthMicrons = 30;
    roiHeightMicrons = 30;
    
    [~,idx] = min(abs(measuredConeDiameterData.verticalEccMicrons));
    yOrigin = measuredConeDiameterData.verticalEccMicrons(idx);
    
    [~,idx] = min(abs(measuredConeDiameterData.horizontalEccMicrons));
    xOrigin = measuredConeDiameterData.horizontalEccMicrons(idx);
    
    for iPos = 1:numel(measuredConeDiameterData.horizontalEccMicrons)
        xoMicrons = measuredConeDiameterData.horizontalEccMicrons(iPos);
        yoMicrons = measuredConeDiameterData.verticalEccMicrons(iPos);
        roi = struct(...
            'shape', 'rect', ...
            'units', 'microns', ...
            'center', [xoMicrons yoMicrons], ...
            'width', roiWidthMicrons, ...
            'height', roiHeightMicrons);

        idx = cm.indicesOfConesWithinROI(roi); 
        medianConeDiameterMicronsModel(iPos) = median(cm.coneRFspacingsMicrons(idx));
        
        if (xoMicrons == xOrigin)
            iidx = find(verticalEccSupport == yoMicrons);
            medianConeDiameterMicronsRawDataVerticalSlice(iidx) = measuredConeDiameterData.medianConeDiametersMicrons(iPos);
            medianConeDiameterMicronsModelVerticalSlice(iidx) = medianConeDiameterMicronsModel(iPos);
        end
        
        if (yoMicrons == yOrigin)
            iidx = find(horizontalEccSupport == xoMicrons);
            medianConeDiameterMicronsRawDataHorizontalSlice(iidx) = measuredConeDiameterData.medianConeDiametersMicrons(iPos);
            medianConeDiameterMicronsModelHorizontalSlice(iidx) = medianConeDiameterMicronsModel(iPos);
        end
        
    end
    
    min1 = min(measuredConeDiameterData.medianConeDiametersMicrons);
    min2 = min(medianConeDiameterMicronsModel);
    max1 = max(measuredConeDiameterData.medianConeDiametersMicrons);
    max2 = max(medianConeDiameterMicronsModel);
    
    uniqueRawDataValues = unique(measuredConeDiameterData.medianConeDiametersMicrons);
    uniqueModelDataValuesMean = 0*uniqueRawDataValues;
    uniqueModelDataValueSstd = 0*uniqueRawDataValues;
    
    for k = 1:numel(uniqueRawDataValues)
        idx = find(measuredConeDiameterData.medianConeDiametersMicrons == uniqueRawDataValues(k));
        if (~isempty(idx))
            uniqueModelDataValuesMean(k) = mean(medianConeDiameterMicronsModel(idx), 'omitnan');
            uniqueModelDataValuesStd(k) = std(medianConeDiameterMicronsModel(idx), 'omitnan');
        end
    end
    
    diameterRange = [2 3];
    hFig = figure(2); clf;
    set(hFig, 'Color', [1 1 1], 'Position', [100 100 1500 500]);
    ax = subplot('Position', [0.04 0.07 0.28 0.9]);
    
    errorbar(uniqueRawDataValues, uniqueModelDataValuesMean, uniqueModelDataValuesStd, 'ks', ...
    'MarkerFaceColor', [0.7 0.7 0.7], 'MarkerSize', 12, 'LineWidth', 1.0); 
    hold on;
    scatter(measuredConeDiameterData.medianConeDiametersMicrons, medianConeDiameterMicronsModel, 49, 'ro', ...
        'MarkerFaceColor', [1 0 0], 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.25);
    
    plot([diameterRange(1) diameterRange(2)], [diameterRange(1) diameterRange(2)], 'b-', 'LineWidth', 1.0);
    set(gca, 'XLim', diameterRange, 'YLim', diameterRange, 'FontSize', 16);
    set(gca, 'XTick', 2:0.1:3, 'YTick', 2:0.1:3);
    axis 'square';
    grid on;
    xlabel('median cone diameter (microns) - data');
    ylabel('median cone diameter (microns) - model');
    
    ax = subplot('Position', [0.37 0.07 0.28 0.9]);
    plot(horizontalEccSupport, medianConeDiameterMicronsModelHorizontalSlice, 'k-', 'LineWidth', 1.5); hold on;
    scatter(horizontalEccSupport, medianConeDiameterMicronsRawDataHorizontalSlice, 100, ...
        'o', 'MarkerFaceColor', [0.7 0.7 0.7], 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.25);
    axis 'square';
    set(gca, 'XLim', 140*[-1 1], 'YLim', diameterRange, 'YTick', 2:0.1:3, 'XTick', -200:50:200, 'FontSize', 16);
    grid on;
    box on
    legend({'model (horizontal meridian)', 'data (horizontal meridian)'});
    ylabel('cone diameter (microns)');
    xlabel('retinal space (microns)');
    
    ax = subplot('Position', [0.71 0.07 0.28 0.9]);
    plot(verticalEccSupport, medianConeDiameterMicronsModelVerticalSlice, 'k-', 'LineWidth', 1.5); hold on;
    scatter(verticalEccSupport, medianConeDiameterMicronsRawDataVerticalSlice, 100, ...
        'o', 'MarkerFaceColor', [0.7 0.7 0.7], 'MarkerEdgeColor', 'k', 'MarkerFaceAlpha', 0.25);
    axis 'square';
    set(gca, 'XLim', 140*[-1 1], 'YLim', diameterRange, 'YTick', 2:0.1:3, 'XTick', -200:50:200, 'FontSize', 16);
    grid on;
    box on
    legend({'model (vertical meridian)','data (vertical meridian)'});
    ylabel('cone diameter (microns)');
    xlabel('retinal space (microns)');
    
end

