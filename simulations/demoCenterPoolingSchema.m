function demoCenterPoolingSchema()

    % Set the cone mosaic params
    cMosaicParams = struct(...
        'coneCouplingLambda', 0, ...
        'apertureShape', 'Gaussian', ...
        'apertureSigmaToDiameterRatio', 0.204, ...
        'integrationTimeSeconds', 5/1000, ...
        'wavelengthSupport', 400:20:700);


    monkeyID = 'M838';
    
    % Modify the default cone mosaic with the examined cone mosaic params
    theConeMosaic = simulator.coneMosaic.modify(monkeyID, cMosaicParams);
    allConePositions = theConeMosaic.coneRFpositionsDegs;
    
    [~,centerConeIndex] =  min(theConeMosaic.coneRFspacingsDegs);
    centerConeCharacteristicRadiusDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(centerConeIndex);
 
    
    videoOBJ = VideoWriter('centerCones', 'MPEG-4');
        videoOBJ.FrameRate = 30;
        videoOBJ.Quality = 100;
        videoOBJ.open();
        
    totalInputTimeSeries = [];
    fractionalRcTimeSeries = [];
    
    for fractionalRc = 1:0.01:4
        RcDegs = centerConeCharacteristicRadiusDegs * fractionalRc;
   
        [centerConeIndices, centerConeWeights, ...
         centerConesFractionalNum, centroidPosition] = ...
            simulator.modelRGC.coneIndicesAndWeightsForCenter(...
                    RcDegs, ...
                    centerConeCharacteristicRadiusDegs, ...
                    centerConeIndex, ...
                    allConePositions);
            
        idx = find(theConeMosaic.coneTypes(centerConeIndices) == cMosaic.SCONE_ID);
        centerConeWeights(idx) = 0.0;
        centerConeRcDegs = sqrt(2) * 0.204 * theConeMosaic.coneRFspacingsDegs(centerConeIndices);
        [hFig, totalInput] = visualizeCenterConePooling(theConeMosaic, centerConeIndices, centerConeWeights, ...
            centerConeRcDegs, theConeMosaic.coneTypes(centerConeIndices), centroidPosition, fractionalRc, ...
            fractionalRcTimeSeries, totalInputTimeSeries);  
        totalInputTimeSeries(numel(totalInputTimeSeries)+1) = totalInput;
        fractionalRcTimeSeries(numel(fractionalRcTimeSeries)+1) =  fractionalRc;
        
        drawnow;
        videoOBJ.writeVideo(getframe(hFig));

    end
    videoOBJ.close();
            
end



function [hFig,totalInput] = visualizeCenterConePooling(theConeMosaic, centerConeIndices, centerConeWeights, centerConeRcDegs, ...
    centerConeTypes, centroidPosition, fractionalRc, fractionalRcTimeSeries, totalInputTimeSeries)
    diskOutline(:,1) = cosd(0:10:360);
    diskOutline(:,2) = sind(0:10:360);
    
    xSupport = linspace(centroidPosition(1)-0.03, centroidPosition(1)+0.03, 201);
    ySupport = linspace(centroidPosition(2)-0.03, centroidPosition(2)+0.03, 201);
    [X,Y] = meshgrid(xSupport, ySupport);
    
    
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10  480 1140]);
    
    
    % The cone lattice and pooling weights
    ax = subplot('Position', [0.09 0.59 0.88 0.40]);
    hold(ax, 'on');
    
    % The cones
    for iCone = 1:numel(centerConeIndices)
        theConeIndex = centerConeIndices(iCone);
        xx = theConeMosaic.coneRFpositionsDegs(theConeIndex,1) + 0.45*centerConeRcDegs(iCone)*diskOutline(:,1)/(sqrt(2.0)*0.204);
        yy = theConeMosaic.coneRFpositionsDegs(theConeIndex,2) + 0.45*centerConeRcDegs(iCone)*diskOutline(:,2)/(sqrt(2.0)*0.204);
        switch (centerConeTypes(iCone))
            case cMosaic.LCONE_ID
                coneColor = [1 0.1000 0.5000];
            case cMosaic.MCONE_ID
                coneColor = [0.1000 1 0.5000];
            case cMosaic.SCONE_ID
                coneColor = [0.6000 0.1000 1];
        end
        pz = -10*eps*ones(size(yy)); 
        patch(ax, xx*60, yy*60, pz, coneColor*0.3, 'FaceColor', coneColor*0.5, 'EdgeColor', coneColor, 'FaceAlpha', 0.5, 'LineWidth', 1.50); 
    end
    
    % The pooling weights (lines)
    for iCone = 1:numel(centerConeIndices)
        theConeIndex = centerConeIndices(iCone);
        xx = [centroidPosition(1) theConeMosaic.coneRFpositionsDegs(theConeIndex,1)]*60;
        yy = [centroidPosition(2) theConeMosaic.coneRFpositionsDegs(theConeIndex,2)]*60;
        plot(ax, xx, yy, 'k-', 'LineWidth', max([0.5 centerConeWeights(iCone)*4]));
    end 
    
    % The pooling weights (text)
    for iCone = 1:numel(centerConeIndices)
        theConeIndex = centerConeIndices(iCone);
        text(ax, theConeMosaic.coneRFpositionsDegs(theConeIndex,1)*60-0.1, theConeMosaic.coneRFpositionsDegs(theConeIndex,2)*60+0.1, ...
            sprintf('%2.3f', centerConeWeights(iCone)), 'FontSize', 15, 'Color', [0 0 0]); %, 'BackgroundColor', [0.2 0.2 0.2]);
    end 
    plot(ax, centroidPosition(1)*60, centroidPosition(2)*60, 'rh', 'MarkerSize', 25, 'LineWidth', 1.0, 'MarkerFaceColor', [1 0.8 0.3], 'MarkerEdgeColor', [1 0.8 0.3]*0.5);
    
    axis(ax,'equal');
    set(ax, 'XLim', [xSupport(1) xSupport(end)]*60, 'YLim', [ySupport(1) ySupport(end)]*60, 'FontSize', 15);
    set(ax, 'XTick', [-100:1:100], 'YTick', -100:1:100);
    box(ax, 'on'); grid(ax, 'on');
    title(ax, sprintf('pooling Rc: %2.2f x coneRc, sum(cone weights): %2.3f',fractionalRc, sum(centerConeWeights)));
    
    % The cone apertures (weighted)
    ax = subplot('Position', [0.09 0.26 0.88 0.3]);
    hold(ax, 'on');
    for iCone = 1:numel(centerConeIndices)
        switch (centerConeTypes(iCone))
            case cMosaic.LCONE_ID
                coneColor = [1 0.1000 0.5000];
            case cMosaic.MCONE_ID
                coneColor = [0.1000 1 0.5000];
            case cMosaic.SCONE_ID
                coneColor = [0.6000 0.1000 1];
        end
        theConeIndex = centerConeIndices(iCone);
        gaussianProfile = exp(-0.5*((xSupport-theConeMosaic.coneRFpositionsDegs(theConeIndex,1))/centerConeRcDegs(iCone)).^2);
        shadedAreaPlot(ax,xSupport*60, centerConeWeights(iCone)*gaussianProfile, ySupport(1), coneColor*0.5, coneColor, 0.5, 1.0); 
    end
    set(ax, 'XLim', [xSupport(1) xSupport(end)]*60, 'XTick', -100:1:100, 'YLim', [0 1.01], 'YTick', 0:0.1:1, 'FontSize', 15);
    box(ax, 'on'); grid(ax, 'on');
    
    title('weighted cone signals');
    
    % The integrated cone pooling signal
    ax = subplot('Position', [0.09 0.05 0.88 0.15]);
    cla(ax);
    rfProfile2D = [];

    for iCone = 1:numel(centerConeIndices)
        theConeIndex = centerConeIndices(iCone);
        gaussianProfile2D = exp(-0.5*((X-theConeMosaic.coneRFpositionsDegs(theConeIndex,1))/centerConeRcDegs(iCone)).^2) .* ...
                            exp(-0.5*((Y-theConeMosaic.coneRFpositionsDegs(theConeIndex,2))/centerConeRcDegs(iCone)).^2);

        gaussianProfile2D(gaussianProfile2D<0.001) = 0;
        if (isempty(rfProfile2D))
            rfProfile2D = centerConeWeights(iCone)*gaussianProfile2D;
        else
            rfProfile2D = rfProfile2D + centerConeWeights(iCone)*gaussianProfile2D;
        end
    end
    dX = (xSupport(2)-xSupport(1))*60;
    dY = (ySupport(2)-ySupport(1))*60;
    totalInput = sum(rfProfile2D(:))*dX*dY;
    rfLineSpeadFunctionX = sum(rfProfile2D,1)*dX;
    rfLineSpeadFunctionY = sum(rfProfile2D,2)*dY;
 
    shadedAreaPlot(ax,xSupport*60, rfLineSpeadFunctionX, ySupport(1), [1 0.8 0.3], [1 0.8 0.3]*0.5, 0.5, 1.5); 
    shadedAreaPlot(ax,xSupport*60, rfLineSpeadFunctionY, ySupport(1), [0.3 0.8 1], [0.3 0.8 2]*0.5, 0.5, 1.5); 
    legend({'integral (x)', 'integral (y)'});
    set(ax, 'XLim', [xSupport(1) xSupport(end)]*60,  'XTick', -100:1:100, 'YTick', 0:0.1:0.5, 'YLim', [0 0.5], 'FontSize', 15);
    box(ax, 'on'); grid(ax, 'on');
    title(sprintf('line spread functions'));
    xlabel('space (arc min)');
    
    
%     ax = subplot('Position', [0.09 0.04 0.88 0.12]);
%     if (isempty(totalInputTimeSeries))
%         totalInputTimeSeries = totalInput;
%         fractionalRcTimeSeries = fractionalRc;
%     end
%     
%     plot(ax, fractionalRcTimeSeries, totalInputTimeSeries, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', [0.7 0.7 0.7], 'LineWidth', 1.0);
%     
%     set(ax, 'XLim', [1 5.5], 'YLim', [0 0.3], 'YTick', 0:0.1:0.5, 'FontSize', 15);
%     box(ax, 'on'); grid(ax, 'on');
%     xlabel('cone Rc');
%     ylabel('total input');
    
end

function shadedAreaPlot(ax,x,y, baseline, faceColor, edgeColor, faceAlpha, lineWidth)

    x = [x fliplr(x)];
    y = [y y*0+baseline];

    px = reshape(x, [1 numel(x)]);
    py = reshape(y, [1 numel(y)]);
   % px = [px(1) px px(end)];
    %py = [baseline py baseline];
    pz = -10*eps*ones(size(py)); 
    patch(ax,px,py,pz,'FaceColor',faceColor,'EdgeColor', edgeColor, 'FaceAlpha', faceAlpha, 'LineWidth', lineWidth);
end


