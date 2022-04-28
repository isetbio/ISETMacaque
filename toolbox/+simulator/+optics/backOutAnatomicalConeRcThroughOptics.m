function backedOutConeRc = backOutAnatomicalConeRcThroughOptics(eccDegs, coneRc, opticsParamsForBackingOutConeRc)
    

    monkeyID = opticsParamsForBackingOutConeRc.monkeyID;
    opticsParams.wavelengthSupport = opticsParamsForBackingOutConeRc.wavelengthSupport;
    opticsParams.type = opticsParamsForBackingOutConeRc.opticsType;
    opticsParams.pupilSizeMM = opticsParamsForBackingOutConeRc.pupilSizeMM;
    opticsParams.residualDefocusDiopters = opticsParamsForBackingOutConeRc.residualDefocusDiopters;
    opticsParams.subjectID = opticsParamsForBackingOutConeRc.PolansSubjectID;

    % Generate the optics for backing out the anatomical data
    [~, thePSFdata] = simulator.optics.generate(monkeyID, opticsParams);


    thePSFdata.psf = thePSFdata.psf / max(thePSFdata.psf(:));
    xSupportDegs = thePSFdata.supportMinutesX/60;

    hFig = figure(99); clf;
    [X,Y] = meshgrid(xSupportDegs*60,xSupportDegs*60);
    contourf(X,Y,thePSFdata.psf );
    set(gca, 'XLim', [-10 10], 'YLim', [-10 10])
    axis 'square'
    colormap(gray(1024));

    % Fitting options 
    options = optimset(...
            'Display', 'off', ...
            'Algorithm', 'interior-point',... % 'sqp', ... % 'interior-point',...
            'GradObj', 'off', ...
            'DerivativeCheck', 'off', ...
            'MaxFunEvals', 10^5, ...
            'MaxIter', 10^3);
    ms = MultiStart(...
          'Display', 'off', ...
          'StartPointsToRun','bounds-ineqs', ...  % run only initial points that are feasible with respect to bounds and inequality constraints.
          'UseParallel', false);
      
    multiStartsNum = 128;

    hFig = figure(101); clf;
    set(hFig, 'Position', [10 10 3555 1146]);
    iiRc = 0;
    for iRc = 1:numel(eccDegs)
        
        coneAperture = exp(-(xSupportDegs/coneRc(iRc)).^2);
        coneAperture2D = coneAperture' * coneAperture;
        effectiveConeAperture2D = conv2(coneAperture2D, thePSFdata.psf, 'same');
        effectiveConeAperture2D = effectiveConeAperture2D/max(effectiveConeAperture2D(:));

        % Sum over y-axis
        effectiveConeApertureProfile = sum(effectiveConeAperture2D,1);
        effectiveConeApertureProfile = effectiveConeApertureProfile / max(effectiveConeApertureProfile(:));

        % Fit a Gaussian to the effectiveConeApertureProfile
        Gparams.initialValues = [max(effectiveConeApertureProfile) 1/60 0];
        Gparams.lowerBounds   = [1e-3 0.1/60 -1];
        Gparams.upperBounds   = [1     60/60  1];

        gaussianAperture = @(params,xSupportDegs)(params(1)*exp(-((xSupportDegs-params(3))/params(2)).^2));
        theObjective = @(p) (sum((gaussianAperture(p, xSupportDegs) - effectiveConeApertureProfile).^2));
        theProblem = createOptimProblem('fmincon',...
          'objective', theObjective, ...
          'x0', Gparams.initialValues, ...
          'lb', Gparams.lowerBounds, ...
          'ub', Gparams.upperBounds, ...
          'options', options...
          );
        % Run the multi-start
        Gparams.bestFitValues = run(ms, theProblem, multiStartsNum);

        % Generate best fit effective aperture
        gaussianApertureFit = gaussianAperture(Gparams.bestFitValues, xSupportDegs);
            
        % Save the backed out coneRc
        backedOutConeRc(iRc) = Gparams.bestFitValues(2);
        offset = Gparams.bestFitValues(3);
        gain = Gparams.bestFitValues(1);

        % Plot
        
        if (iRc <= 32) && (mod(iRc-1,4) == 0)
            iiRc = iiRc  + 1;
            

            subplot(3,8,  iiRc);
           
            hold on;
            mm = (size(coneAperture2D,2)-1)/2+1;
            coneProfile = coneAperture2D(mm,:);
            makeShadedPlot(xSupportDegs*60, coneProfile,[0.5 0.5 0.5], [0 0 0]);
            %makeShadedPlot(xSupportDegs*60, thePSFdata.psf(mm,:), [1 0.5 0.5], [1 0 0]);

            set(gca, 'XLim', [-10 10]);
            
            axis 'square';
            xtickangle(0);
            set(gca, 'XTick', [-10:2:10],'FontSize', 16, 'YTickLabel', {}, 'YTick', 0:0.2:1);
            grid on; box off;
            title(sprintf('ecc:%2.2f degs', eccDegs(iRc)));

            subplot(3,8, 8 + iiRc);
            makeShadedPlot(xSupportDegs*60, effectiveConeApertureProfile,[1 0.5 0.5], [1 0 0]);
            hold on;
            mm = (size(coneAperture2D,2)-1)/2+1;
            
            
            plot((offset + backedOutConeRc(iRc)*[-1 1])*60, gain*exp(-1)*[1 1], 'b-', 'LineWidth', 1.5);
            set(gca, 'XLim', [-10 10]);
            
            axis 'square';
            xtickangle(0);
            set(gca, 'XTick', [-10:2:10],'FontSize', 16, 'YTickLabel', {}, 'YTick', 0:0.2:1);
            grid on; box off;

            subplot(3,8, 16 + iiRc);
            hold on;
            mm = (size(coneAperture2D,2)-1)/2+1;
            coneProfile = coneAperture2D(mm,:);
            makeShadedPlot(xSupportDegs*60, effectiveConeApertureProfile,[1 0.5 0.5], [1 0 0]);
           
            makeShadedPlot(xSupportDegs*60, gaussianApertureFit, [0.5 1 1], [0 0.6 1]);
            plot((offset + backedOutConeRc(iRc)*[-1 1])*60, gain*exp(-1)*[1 1], 'b-', 'LineWidth', 1.5);
            set(gca, 'XLim', [-10 10]);
            xlabel('space (arc min)')
            axis 'square';
            xtickangle(0);
            set(gca, 'XTick', [-10:2:10],'FontSize', 16, 'YTickLabel', {}, 'YTick', 0:0.2:1);
            grid on; box off;


        end

    end
    drawnow;
    pause

    hFig = figure(100); clf;
    set(hFig, 'Position', [10 10 600 600], 'Color', [1 1 1]);
    plot(eccDegs, coneRc, 'ro-', 'MarkerSize', 12, 'LineWidth', 1.5); hold on
    plot(eccDegs, backedOutConeRc, 'bo-', 'MarkerSize', 12, 'LineWidth', 1.5);
    ax = gca;
    xlabel(ax,'eccentricity (degs)');
    ylabel(ax,'characteristic radius (degs)');
    axis(ax, 'square');
    set(ax, 'XScale', 'log', 'YScale', 'log');
    xtickangle(ax,0);
    set(ax, 'XLim', [0.006 30], ...
        'XTick',       [0.003   0.01   0.03   0.1   0.3    1    3    10    30   100], ...
        'XTickLabels', {'.003', '.01', '.03', '.1', '.3', '1', '3', '10', '30', '100'}, ...
        'YLim', [0.0015 2], ...
        'YTick', [0.001 0.003 0.01 0.03 0.1 0.3 1 3 10],  ...
        'YTickLabels', {'.001' '.003', '.01', '.03', '.1', '.3', '1', '3', '10'}, ...
        'LineWidth', 1.5, 'XColor', [0.2 0.2 0.2], 'YColor', [0.2 0.2 0.2], ...
        'FontSize', 30);
     set(ax,'TickDir','both', 'TickLength',[0.1, 0.01]/8);
     grid(ax, 'on');  box(ax, 'off');

end

function makeShadedPlot(x,y, faceColor, edgeColor)
    px = reshape(x, [1 numel(x)]);
    py = reshape(y, [1 numel(y)]);
    px = [px(1) px px(end)];
    py = [1*eps py 2*eps];
    pz = -10*eps*ones(size(py)); 
    patch(px,py,pz,'FaceColor',faceColor,'EdgeColor',edgeColor, 'FaceAlpha', 0.5);
end

