function [KsKcRatio, axesHandles] = KsKcVersusEccentricity(varargin)
% Return the Ks/Kc  ratios
%
% Syntax:
%   [integratedSurroundCenterRatios, axesHandles] = KsKcVersusEccentricity('generateFigure', false)
%
% Description:
%   Return the Ks/Kc ratios
%   These are the data from figure 6 of Croner & Kaplan
%
% Inputs:
%    none
%
% Outputs:
%    KsKcRatios, axesHandles
%
% Optional key/value pairs:
%    'generateFigure'   false
%    'extraData'  data struct
%

    p = inputParser;
    p.addParameter('generateFigure', false, @islogical);
    p.addParameter('extraData1', [], @(x)(isempty(x)||(isstruct(x))));
    p.addParameter('extraData2', [], @(x)(isempty(x)||(isstruct(x))));
    
    p.parse(varargin{:});
    generateFigure = p.Results.generateFigure;
    
    extraData1 = p.Results.extraData1;
    addExtraData1 = ~(isempty(extraData1));
    
    extraData2 = p.Results.extraData2;
    addExtraData2 = ~(isempty(extraData2));
    
    d = KsKcRatioVsEccentricity();
    KsKcRatio.eccDegs = d(:,1);
    KsKcRatio.ratio = d(:,2);
    
    axesHandles = struct();
    
    if (generateFigure) || (addExtraData1) || (addExtraData2)
        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'colsNum', 2, ...
           'rowsNum', 1, ...
           'heightMargin',  0.03, ...
           'widthMargin',    0.16, ...
           'leftMargin',     0.07, ...
           'rightMargin',    0.01, ...
           'bottomMargin',   0.12, ...
           'topMargin',      0.02);
   
        axesHandles.hFig = figure();
        set(axesHandles.hFig, 'Color', [1 1 1], 'Position', [10 10 1560 740]);
        
        ax = subplot('Position', subplotPosVectors(1,1).v);
        axesHandles.ax1 = ax;
        hold(ax, 'on');
        
        legends = {};
        plotHandles = [];
        
        if (addExtraData1) && (~isempty(extraData1.eccDegs))
            hold(ax, 'on');
            p = scatter(ax, extraData1.eccDegs, extraData1.values,13*13, ...
                'filled', 'MarkerEdgeColor', [1 0.8 0.2]*0.5, 'MarkerFaceColor', [1 0.8 0.2], ...
                'MarkerFaceAlpha', 0.5, 'LineWidth', 1.0);
            legends{numel(legends)+1} = extraData1.legend;
            plotHandles(numel(plotHandles)+1) = p;
        end
        
        if (addExtraData2) && (~isempty(extraData2.eccDegs))
            hold(ax, 'on');
            p = scatter(ax, extraData2.eccDegs, extraData2.values,13*13, ...
                'filled', 'MarkerEdgeColor', [1 0.5 0.2]*0.5, 'MarkerFaceColor', [1 0.5 0.2], ...
                'MarkerFaceAlpha', 0.5, 'LineWidth', 1.0);
            legends{numel(legends)+1} = extraData2.legend;
            plotHandles(numel(plotHandles)+1) = p;
        end
            
 
        % C&K ratios
        p = scatter(ax,KsKcRatio.eccDegs, KsKcRatio.ratio, 13*13, ...
            'filled', 'MarkerEdgeColor', [0.3 0.3 0.3], 'MarkerFaceColor', [0.8 0.8 0.8], ...
            'MarkerFaceAlpha', 0.5, 'LineWidth', 1.0);
        legends{numel(legends)+1} = 'C&K';
        plotHandles(numel(plotHandles)+1) = p;
          
        xlabel(ax,'eccentricity (degs)');
        ylabel(ax, sprintf('Ks/Kc ratio'));
        axis(ax, 'square');
        set(ax, 'XScale', 'log', 'YScale', 'log');
        set(ax, 'XLim', [0.003 30], ...
            'XTick',       [0.003   0.01   0.03   0.1   0.3    1    3    10    30   100], ...
            'XTickLabels', {'.003', '.01', '.03', '.1', '.3', '1', '3', '10', '30', '100'}, ...
            'YLim', [1e-4 1], 'YTick', [1e-4 1e-3 1e-2 1e-1 1],  'YTickLabel', {'1e-4', '1e-3', '1e-2', '1e-1', '1'}, ...
            'FontSize', 30);
        grid(ax, 'on');  box(ax, 'off');
        
        lgd = legend(ax,plotHandles, legends, 'Location', 'NorthOutside', ...
            'FontSize', 16);
        lgd.NumColumns = 2;
        set(lgd,'Box','off');
        
        
        % Histograms
        ax = subplot('Position', subplotPosVectors(1,2).v);
        axesHandles.ax2 = ax;
        hold(ax, 'on');
        
        legends = {};
        plotHandles = [];
        
        edges = -4:0.25:0;
        [counts,bins] = histcounts(log10(KsKcRatio.ratio), edges);
        p = bar(ax,bins(1:end-1), counts, 1, 'FaceColor', [0.8 0.8 0.8], 'EdgeColor', [0.3 0.3 0.3]);
        legends{numel(legends)+1} = 'C&K';
        plotHandles(numel(plotHandles)+1) = p;
        
        if (addExtraData1) && (~isempty(extraData1.eccDegs))
            hold(ax, 'on');
            [counts,bins] = histcounts(log10(extraData1.values), edges);
            p = bar(ax,bins(1:end-1), counts, 0.8, 'FaceColor', [1 0.8 0.2], 'EdgeColor', [1 0.8 0.2]*0.5);
            legends{numel(legends)+1} = extraData1.legend;
            plotHandles(numel(plotHandles)+1) = p;
        end
        
        if (addExtraData2) && (~isempty(extraData2.eccDegs))
            hold(ax, 'on');
            [counts,bins] = histcounts(log10(extraData2.values), edges);
            p = bar(ax,bins(1:end-1), counts, 0.4, 'FaceColor', [1 0.5 0.2], 'EdgeColor', [1 0.5 0.2]*0.5);
            legends{numel(legends)+1} = extraData2.legend;
            plotHandles(numel(plotHandles)+1) = p;
        end
        
        lgd = legend(ax, legends, 'Location', 'NorthOutside', 'FontSize', 16);
        lgd.NumColumns = 2;
        set(lgd,'Box','off');
            
        xlabel(ax,'Ks/Kc ratio');
        ylabel(ax, 'count');
        axis(ax, 'square');
        set(ax, 'XScale', 'linear', 'YScale', 'linear');
        dx = bins(2)-bins(1);
        set(ax, 'XLim', [-4-dx/2 0], ...
            'XTick',       -4:0.5:0, ...
            'XTickLabels', {'1e-4', '', '1e-3', '', '1e-2', '', '1e-1', '', '1'}, ...
            'FontSize', 30);
        grid(ax, 'on');  box(ax, 'off');

    end
    
        
end

function d = KsKcRatioVsEccentricity()
    d = [ ...
        4.066931602445E-1	5.304190787105E-3; ...
        9.404128512522E-1	1.323689402470E-2; ...
        1.254398996202E0	1.449298918378E-2; ...
        1.254828513448E0	9.990598437384E-3; ...
        1.050381243213E0	8.529469118639E-3; ...
        1.050501116124E0	7.534709501530E-3; ...
        1.947013095406E0	4.791168190972E-2; ...
        2.229098836882E0	6.720725198234E-2; ...
        2.211478054791E0	3.739560379405E-2; ...
        2.429720603956E0	1.434599200245E-2; ...
        1.966725244462E0	8.442490648167E-3; ...
        2.602397267638E0	5.692597235014E-3; ...
        2.352384201490E0	2.644317098748E-3; ...
        3.003487251974E0	1.282098028064E-2; ...
        3.905021362813E0	1.700224600400E-2; ...
        3.936585291952E0	2.699270420741E-2; ...
        4.508793417270E0	2.412031513960E-2; ...
        5.479953239401E0	2.107510290964E-2; ...
        6.492334378741E0	2.084461588602E-2; ...
        6.604492095571E0	1.720975556789E-2; ...
        6.950633699666E0	1.343073466406E-2; ...
        4.287990560576E0	1.198941017102E-2; ...
        4.182762437352E0	6.376852936734E-3; ...
        5.919118909033E0	8.748616880269E-3; ...
        6.445959814714E0	5.036139493010E-3; ...
        5.923234568517E0	4.110650139127E-3; ...
        7.136147400118E0	4.980510786947E-3; ...
        7.702845158449E0	4.302100539332E-3; ...
        4.034992248313E0	6.010036569393E-2; ...
        6.826433749511E0	4.337773952488E-2; ...
        1.204309681344E1	5.318590685231E-2; ...
        1.620079386286E1	5.823370902953E-2; ...
        1.474958279755E1	1.132321170154E-1; ...
        2.313083745212E1	5.089502326046E-2; ...
        3.007759059218E1	5.895341110312E-2; ...
        3.563235634881E1	6.168973418063E-2; ...
        9.503675875579E0	3.060036759560E-2; ...
        9.586359044450E0	2.498075087232E-2; ...
        1.357192002466E1	2.110631840812E-2; ...
        1.749967666688E1	2.336986943513E-2; ...
        2.180902657627E1	2.995873369473E-2; ...
        2.354019852420E1	2.676812696036E-2; ...
        2.145023336212E1	2.019077857812E-2; ...
        1.663595719043E1	1.803073008608E-2; ...
        1.380638046280E1	1.742582270300E-2; ...
        1.594881857866E1	1.455325568687E-2; ...
        1.392794254413E1	1.270903573740E-2; ...
        1.044058345825E1	1.299272539226E-2; ...
        9.351592993190E0	1.255839977950E-2; ...
        1.089515155163E1	1.002589994090E-2; ...
        1.393256705346E1	8.860170710163E-3; ...
        1.582504316912E1	6.915462371979E-3; ...
        1.858689542719E1	8.378505721175E-3; ...
        2.075413317535E1	7.486608633079E-3; ...
        2.791628753828E1	9.175348084191E-3; ...
        1.109188163294E1	3.594211372361E-3; ...
        1.292175096370E1	3.105019630784E-3; ...
        6.027874193145E0	2.236356529982E-3; ...
        6.237164587383E0	1.745235725639E-3; ...
        8.535842550262E0	1.491190115128E-3; ...
        1.443322180458E1	1.934249080508E-3; ...
        1.624505690670E1	3.002884906564E-3; ...
        1.596934844863E1	3.596349810028E-3; ...
        2.795280232010E1	2.216830104951E-3; ...
        1.360716532640E1	1.260155431697E-3; ...
        2.079076791998E1	1.101470928654E-3; ...
        2.484394666525E1	9.732932340550E-4; ...
        7.151043390204E0	5.166390578382E-4; ...
        5.184896887886E0	2.777675554421E-4; ...
        9.632515743653E0	1.351384792234E-4 ...
    ];
end