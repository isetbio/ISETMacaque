function estimateOptimalResidualDefocus
    defocusD = [0.000 0.020 0.040 0.055 0.063 0.067 0.072 0.075 0.085 0.100];
    L1rmsErr = [1.566 1.572 1.713 2.083 2.061 2.178 2.511 2.86   3.993 4.891];
    L6rmsErr = [6.279 6.000 4.966 3.912 3.923 3.074 3.244 2.77   3.706 7.282];
    L3rmsErr = [4.869 4.662 3.813 3.200 3.084 3.115 2.311 2.158  5.101 10.077];
    L7rmsErr = [4.114 3.733 4.021 4.644 6.866 4.952 6.714 8.27  12.292 18.439 ];
    L11rmsErr= [4.22  3.96  3.4   3.16  3.08  3.57  3.61  3.92  7.62   10.58];
    L4rmsErr = [6.702 6.154 4.796 4.432 3.005 2.783 3.892 3.53  8.916  11.4];
    L8rmsErr = [3.716 3.340 3.286 3.137 5.035 5.115 7.119 7.412 10.18  13.36];
    L9rmsErr = [4.90  4.677 3.977 3.557 3.188 3.292 3.097 2.83  3.484 6.228];

    L1rmsErr = 100*(L1rmsErr-L1rmsErr(1))/L1rmsErr(1);
    L6rmsErr = 100*(L6rmsErr-L6rmsErr(1))/L6rmsErr(1);
    L7rmsErr = 100*(L7rmsErr-L7rmsErr(1))/L7rmsErr(1);
    L3rmsErr = 100*(L3rmsErr-L3rmsErr(1))/L3rmsErr(1);
    L11rmsErr = 100*(L11rmsErr-L11rmsErr(1))/L11rmsErr(1);
    L4rmsErr = 100*(L4rmsErr-L4rmsErr(1))/L4rmsErr(1);
    L8rmsErr = 100*(L8rmsErr-L8rmsErr(1))/L8rmsErr(1);
    L9rmsErr = 100*(L9rmsErr-L9rmsErr(1))/L9rmsErr(1);

    hFig = figure(123);
    clf;
    set(hFig, 'Position', [10 10 1000 500], 'Color', [1 1 1]);

    ax1 = subplot('Position', [0.09 0.11 0.4 0.85]);
    p1 = plot(ax1, defocusD, L1rmsErr, 'ro-', ...
        'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.5); 
    hold(ax1, 'on');
    p2 = plot(ax1,defocusD, L7rmsErr, 'bo-', ...
        'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.5);
    p3 = plot(ax1,defocusD, L8rmsErr, 'go-', ...
        'MarkerEdgeColor', [0 0 0.9], ...
        'MarkerSize', 12, 'MarkerFaceColor', [0.3 1 0.3], 'LineWidth', 1.5);

    plot(ax1, 0.067*[1 1], [-100 500], 'k--', 'LineWidth', 2.0);
    legend(ax1, [p1 p2 p3], {'L1', 'L7', 'L8'}, 'Location', 'NorthWest');
    set(ax1, 'FontSize', 20, 'XLim', [-0.01 0.11], 'XTick', 0:0.02:0.1);
    set(ax1, 'YLim', [-75 200], 'YTick', -100:25:500);
    grid(ax1, 'on');
    xlabel(ax1,'residual defocus (D)')
    ylabel(ax1,'rmsError % change from 0.0D')

    ax2 = subplot('Position', [0.57 0.11 0.4 0.85]);
    p1 = plot(ax2,defocusD, L3rmsErr, 'ro-', ...
        'MarkerSize', 12, 'MarkerFaceColor', [1 0.5 0.5], 'LineWidth', 1.5); 
    hold(ax2, 'on');
    p4 = plot(ax2,defocusD, L4rmsErr, 'go-', ...
        'MarkerEdgeColor', [0.3 0.3 0.3], ...
        'MarkerSize', 12, 'MarkerFaceColor', [0.8 0.8 0.8], 'LineWidth', 1.5);

    p2 = plot(ax2,defocusD, L6rmsErr, 'bo-', ...
        'MarkerSize', 12, 'MarkerFaceColor', [0.5 0.5 1], 'LineWidth', 1.5);
    p3 = plot(ax2,defocusD, L11rmsErr, 'go-', ...
        'MarkerEdgeColor', [0 0 0.9], ...
        'MarkerSize', 12, 'MarkerFaceColor', [0.3 1 0.3], 'LineWidth', 1.5);
    p5 = plot(ax2,defocusD, L9rmsErr, 'yo-', ...
        'MarkerEdgeColor', 0.7*[1.0 0.7 0.3], 'Color', 0.7*[1.0 0.7 0.3], ...
        'MarkerSize', 12, 'MarkerFaceColor', [1.0 0.7 0.5], 'LineWidth', 1.5);
    
    plot(ax2, 0.067*[1 1], [-100 500], 'k--', 'LineWidth', 2.0);
    legend(ax2, [p1 p4 p2 p3 p5], {'L3', 'L4', 'L6', 'L11', 'L9'},  'Location', 'NorthWest');
    set(ax2, 'FontSize', 20, 'XLim', [-0.01 0.11], 'XTick', 0:0.02:0.1);
    set(ax2, 'YLim', [-75 200], 'YTick', -100:25:500);
    grid(ax2, 'on');
    xlabel(ax2,'residual defocus (D)')
end