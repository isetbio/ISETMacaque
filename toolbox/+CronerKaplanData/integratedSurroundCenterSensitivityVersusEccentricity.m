function [integratedSurroundCenterRatios, axesHandles] = integratedSurroundCenterSensitivityVersusEccentricity(varargin)
% Return the integrated S/C sensitivity ratios
%
% Syntax:
%   [intSurroundCenterSensitivityRatios, axesHandles] = ...
%      CronerKaplanData.integratedSurroundCenterSensitivityRatios('generateFigure', false)
%
% Description:
%   Return the integrated S/C sensitivity ratios
%   These are the data from figure 11 of Croner & Kaplan
%
% Inputs:
%    none
%
% Outputs:
%    intSurroundCenterSensitivityRatios, axesHandles
%
% Optional key/value pairs:
%    'generateFigure'   false
%    'extraData'  data struct
%

    p = inputParser;
    p.addParameter('generateFigure', false, @islogical);
    p.addParameter('computeStatsBetweenDataSets', false, @islogical);
    p.addParameter('extraData1', [], @(x)(isempty(x)||(isstruct(x))));
    p.addParameter('extraData2', [], @(x)(isempty(x)||(isstruct(x))));
    
    p.parse(varargin{:});
    generateFigure = p.Results.generateFigure;
    computeStatsBetweenDataSets = p.Results.computeStatsBetweenDataSets;

    extraData1 = p.Results.extraData1;
    addExtraData1 = ~(isempty(extraData1));
    
    extraData2 = p.Results.extraData2;
    addExtraData2 = ~(isempty(extraData2));
    
    d = integratedSurroundCenterSensitivityVsEccentricity();
    integratedSurroundCenterRatios.eccDegs = d(:,1);
    integratedSurroundCenterRatios.ratios = d(:,2);
    
    if (computeStatsBetweenDataSets)
        % Run stats between C&K and Physiological optics
        nullHypothesisData = integratedSurroundCenterRatios.ratios(:);
        testHypothesisData = extraData1.values(:);
        [testPassedIntSurrCenterSensCronerVsPhysioOptics, pValIntSurrCenterSensCronerVsPhysioOptics] = ttest2(nullHypothesisData, testHypothesisData, ... 
                    'Vartype', 'unequal')
    
        testHypothesisData = extraData2.values(:);
        [testPassedIntSurrCenterSensCronerVsAOSLOOptics, pValIntSurrCenterSensCronerVsAOSLOOptics] = ttest2(nullHypothesisData, testHypothesisData, ... 
                    'Vartype', 'unequal')
        
        nullHypothesisData = extraData1.values(:);
        testHypothesisData = extraData2.values(:);
        [testPassedIntSurrCenterSensPhysioVsAOSLOOptics, pValIntSurrCenterSensPhysioVsAOSLOOptics] = ttest2(nullHypothesisData, testHypothesisData, ... 
                    'Vartype', 'unequal')

        fprintf('Paused to see the computed stats. Hit enter to continue.')
        pause;
    end


    axesHandles = struct();
    
    colorExtraData1 = [1 0.8 0.2];
    colorExtraData2 = [0.2 0.8 0.9];

    if (generateFigure) || (addExtraData1) || (addExtraData2)
        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'colsNum', 2, ...
           'rowsNum', 1, ...
           'heightMargin',  0.03, ...
           'widthMargin',    0.16, ...
           'leftMargin',     0.08, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.12, ...
           'topMargin',      0.02);
   
        axesHandles.hFig = figure();
        set(axesHandles.hFig, 'Color', [1 1 1], 'Position', [10 10 1560 840]);
        
        
        ax = subplot('Position', subplotPosVectors(1,1).v);
        axesHandles.ax1 = ax;
        hold(ax, 'on');
        
        legends = {};
        plotHandles = [];
        
         % C&K ratios
        p = scatter(ax,integratedSurroundCenterRatios.eccDegs, integratedSurroundCenterRatios.ratios, 17*17, ...
            'filled', 'MarkerEdgeColor', [0.3 0.3 0.3], 'MarkerFaceColor', [0.8 0.8 0.8], ...
            'MarkerFaceAlpha', 0.5, 'LineWidth', 1.5);
        legends{numel(legends)+1} = 'Croner & Kaplan ''95';
        plotHandles(numel(plotHandles)+1) = p;

        if (addExtraData1) && (~isempty(extraData1.eccDegs))
            hold(ax, 'on');
            p = scatter(ax, extraData1.eccDegs, extraData1.values,17*17, ...
                'filled', 'MarkerEdgeColor', colorExtraData1*0.5, 'MarkerFaceColor', colorExtraData1, ...
                'MarkerFaceAlpha', 0.5, 'LineWidth', 1.0);
            legends{numel(legends)+1} = extraData1.legend;
            plotHandles(numel(plotHandles)+1) = p;
        end
        
        if (addExtraData2) && (~isempty(extraData2.eccDegs))
            hold(ax, 'on');
            p = scatter(ax, extraData2.eccDegs, extraData2.values,17*17, ...
                'filled', 'MarkerEdgeColor', colorExtraData2*0.5, 'MarkerFaceColor', colorExtraData2, ...
                'MarkerFaceAlpha', 0.5, 'LineWidth', 1.0);
            legends{numel(legends)+1} = extraData2.legend;
            plotHandles(numel(plotHandles)+1) = p;
        end
            
 
       
       
%        
        xlabel(ax,'eccentricity (degs)');
        ylabel(ax, sprintf('integrated surround/center\nsensitivity ratio'));
        axis(ax, 'square');
        set(ax, 'XScale', 'log', 'YScale', 'linear');
        set(ax, 'XLim', [0.003 30], ...
            'XTick',       [0.003   0.01   0.03   0.1   0.3    1    3    10    30   100], ...
            'XTickLabels', {'.003', '.01', '.03', '.1', '.3', '1', '3', '10', '30', '100'}, ...
            'YLim', [0 7], 'YTick', 0:0.5:7.0, ...
            'YTickLabel', {'0', '', '1', '', '2', '', '3', '', '4', '', '5', '', '6', '', '7'}, ...
            'FontSize', 30);
        grid(ax, 'on');  box(ax, 'off');
        xtickangle(ax, 0)
        
        addLegendsToPlot(ax, plotHandles, legends, 'NorthOutside', 24);
        
        
        % Histograms
        ax = subplot('Position', subplotPosVectors(1,2).v);
        axesHandles.ax2 = ax;
        hold(ax, 'on');
        
        legends = {};
        plotHandles = [];
        
        edges = 0:0.25:8;
        [counts,bins] = histcounts(integratedSurroundCenterRatios.ratios, edges);
        maxY = max(counts);
        p = bar(ax,bins(2:end), counts, 1, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.3 0.3 0.3]);
        legends{numel(legends)+1} = 'Croner & Kaplan ''95';
        plotHandles(numel(plotHandles)+1) = p;
        
        if (addExtraData1) && (~isempty(extraData1.eccDegs))
            hold(ax, 'on');
            [counts,bins] = histcounts(extraData1.values, edges);
            maxY = max([maxY max(counts)]);
            p = bar(ax,bins(1:end-1), counts, 0.8, 'FaceColor', colorExtraData1, 'EdgeColor', colorExtraData1*0.5);
            legends{numel(legends)+1} = extraData1.legend;
            plotHandles(numel(plotHandles)+1) = p;
        end
        
        if (addExtraData2) && (~isempty(extraData2.eccDegs))
            hold(ax, 'on');
            [counts,bins] = histcounts(extraData2.values, edges);
            maxY = max([maxY max(counts)]);
            p = bar(ax,bins(1:end-1), counts, 0.4, 'FaceColor', colorExtraData2, 'EdgeColor', colorExtraData2*0.5);
            legends{numel(legends)+1} = extraData2.legend;
            plotHandles(numel(plotHandles)+1) = p;
        end
        
        xtickangle(ax, 0)
        
        


        
        xlabel(ax,'integrated surround/center sensitivity ratio');
        ylabel(ax, 'count');
        axis(ax, 'square');
        set(ax, 'XScale', 'linear', 'YScale', 'linear');
        dx = bins(2)-bins(1);
        set(ax, 'XLim', [0 7], ...
            'XTick',       0:0.5:7, ...
            'XTickLabels', {'0', '', '1', '', '2', '', '3', '', '4'}, ...
            'FontSize', 30);
        grid(ax, 'on');  box(ax, 'off');
        
        % Median lines
        medianIntSurrCenterSensRatio = median(integratedSurroundCenterRatios.ratios);
        plot(medianIntSurrCenterSensRatio*[1 1], [0 maxY+1], 'k-', 'LineWidth', 6);
        plot(medianIntSurrCenterSensRatio*[1 1], [0 maxY+1], 'w--', 'LineWidth', 6);
        fprintf('Mean RcRs - C&K: %f\n', medianIntSurrCenterSensRatio);

        if (~isempty(extraData1))
            medianExtraData1 = median(extraData1.values(:));
            fprintf('Mean RcRs - ExtraData1: %f\n', medianExtraData1);
            plot(medianExtraData1*[1 1], [0 maxY+1], 'k-', 'LineWidth', 6);
            plot(medianExtraData1*[1 1], [0 maxY+1], 'k--', 'Color', colorExtraData1, 'LineWidth', 6);
        end

        if (~isempty(extraData2))
            medianExtraData2 = median(extraData2.values(:));
            fprintf('Mean RcRs - ExtraData2: %f\n', medianExtraData2);
            plot(medianExtraData2*[1 1], [0 maxY+1], 'k-',  'LineWidth', 6);
            plot(medianExtraData2*[1 1], [0 maxY+1], 'k--', 'Color', colorExtraData2,'LineWidth', 6);
        end

        [lgd, legendHandle] = legend(ax, legends, 'Location', 'NorthOutside', 'FontSize', 24);
        lgd.NumColumns = 1;

        objhl = findobj(legendHandle, 'type', 'patch');
        set(objhl, 'Markersize', 14);

        set(lgd,'Box','off');
        
    end
    
        
end



function addLegendsToPlot(ax, plotHandles, legends, location, fontSize)
    [lgd, legendHandle] = legend(ax,plotHandles, legends, 'Location', location, ...
        'FontSize', fontSize);
    set(lgd,'Box','off');
    if (numel(legends)<4)
        lgd.NumColumns = 1;
    elseif (numel(legends)<8)
        lgd.NumColumns = 2;
    elseif (numel(legends)<12)
        lgd.NumColumns = 3;
    else
        lgd.NumColumns = 4;
    end
    objhl = findobj(legendHandle, 'type', 'patch');
    set(objhl, 'Markersize', 14);
end

function d = integratedSurroundCenterSensitivityVsEccentricity()
    d = [ ...
            1.001465341655E0	6.454856205158E-1; ...
            1.236024861002E0	6.034468295931E-1; ...
            1.011426519276E0	5.375313580493E-1; ...
            2.254371777362E0	5.671121235396E-1; ...
            2.580469276320E0	5.330304785822E-1; ...
            2.028934599626E0	5.102875372561E-1; ...
            1.986992799117E0	4.648318002731E-1; ...
            9.787119148791E-1	3.920758832026E-1; ...
            1.258044306270E0	3.648110915091E-1; ...
            3.862839826885E-1	3.125135983181E-1; ...
            4.011733218692E-1	1.511503849471E-1; ...
            2.551424579468E0	3.478023807215E-1; ...
            2.414484600806E0	3.318893994721E-1; ...
            3.975977833758E0	4.092064873480E-1; ...
            4.154859612930E0	4.705752055804E-1; ...
            4.282048122973E0	5.921697279812E-1; ...
            2.984893087729E0	6.500874224404E-1; ...
            2.151614366115E0	6.807455679313E-1; ...
            3.953538970486E0	6.523876680621E-1; ...
            4.185791690805E0	6.353488116053E-1; ...
            4.591368901728E0	7.399057882306E-1; ...
            6.103475664581E0	8.524487458091E-1; ...
            6.206652493833E0	7.342698587872E-1; ...
            6.853290203182E0	7.263336837221E-1; ...
            6.442260558193E0	6.808674612890E-1; ...
            6.260547707487E0	6.501804808103E-1; ...
            5.387319420889E0	6.137920368249E-1; ...
            6.818268799757E0	6.058781433413E-1; ...
            9.398108949070E0	6.468605251638E-1; ...
            9.302376789408E0	6.843578055001E-1; ...
            1.118776557679E1	7.514568222271E-1; ...
            1.459270579662E1	8.504171898469E-1; ...
            1.368015707204E1	7.401639924400E-1; ...
            1.400258466346E1	7.458549704966E-1; ...
            1.557057887549E1	7.527176976049E-1; ...
            1.695602140080E1	7.379843294948E-1; ...
            1.875196929860E1	7.743989871055E-1; ...
            2.036557521869E1	7.869448281828E-1; ...
            2.110071012711E1	8.199202581518E-1; ...
            2.188386839712E1	8.324425069663E-1; ...
            3.000526893869E1	8.167641376635E-1; ...
            2.322757883092E1	7.699806805581E-1; ...
            2.299826203664E1	7.552014386038E-1; ...
            3.505139181244E1	6.294074934269E-1; ...
            2.268694902236E1	6.290562308477E-1; ...
            1.313239715739E1	6.765120674424E-1; ...
            1.216469496515E1	6.639845759029E-1; ...
            1.115746262592E1	5.798650522569E-1; ...
            1.037409464692E1	5.696155247575E-1; ...
            9.545953795864E0	5.445919980287E-1; ...
            7.377038437039E0	5.502121992970E-1; ...
            7.104207024727E0	5.070226302227E-1; ...
            6.414369260854E0	4.831393961954E-1; ...
            5.680597460948E0	4.353912776783E-1; ...
            1.088599432213E1	5.219027946346E-1; ...
            1.424836361444E1	5.822255892168E-1; ...
            1.585976759000E1	6.186350041024E-1; ...
            1.660119376850E1	5.834287946189E-1; ...
            1.558966239472E1	5.459000579321E-1; ...
            1.849885053253E1	5.175736144133E-1; ...
            2.094909051827E1	4.630977689583E-1; ...
            2.441243469531E1	4.291052503270E-1; ...
            2.773307189611E1	4.416995866111E-1; ...
            2.809807041504E1	4.860281377054E-1; ...
            1.347967526561E1	4.128855696614E-1; ...
            1.574390336609E1	3.743135306870E-1; ...
            1.283901426283E1	3.560491872465E-1; ...
            8.638752650853E0	3.763844070871E-1; ...
            7.524778429332E0	4.490800328195E-1; ...
            6.101588283558E0	3.729032376449E-1; ...
            5.413008773700E0	3.353836757270E-1; ...
            7.214094542061E0	3.161166611181E-1; ...
            7.219232412623E0	2.604349888985E-1; ...
            6.118679567265E0	1.876764504654E-1; ...
            6.352819668607E0	1.501831021728E-1; ...
            9.539033398780E0	1.195918014265E-1; ...
            1.381908928623E1	2.344861211961E-1; ...
            1.612683200474E1	2.243244093415E-1 ...
        ];
end
