function inspectSessionData

    d{1} = loadUncorrectedDeltaFluoresenceResponses('M838', 'session1only');
    d{2} = loadUncorrectedDeltaFluoresenceResponses('M838', 'session2only');
    d{3} = loadUncorrectedDeltaFluoresenceResponses('M838', 'session3only');

    indexLconeRGC = 11;

    for iSession = 1:3
        theSTFs(iSession,:) = d{iSession}.dFresponsesLcenterRGCs(indexLconeRGC,:);
        theShiftedSTFs(iSession,:) = theSTFs(iSession,:) - min(theSTFs(iSession,:));
        theAbsoluteSTFs(iSession, :) = abs(theSTFs(iSession,:));
    end

    sfAxis = d{1}.diffractionLimitedOTF.sf;

    figure(1);clf;
    ax = subplot(1,3,1);
    plotData(ax, sfAxis, theSTFs, 'raw');

    ax = subplot(1,3,2);
    plotData(ax, sfAxis, theShiftedSTFs, 'subtract min');

    ax = subplot(1,3,3);
    plotData(ax, sfAxis, theAbsoluteSTFs, 'absolute');

end

function plotData(ax, sfAxis, theSTFs, plotTitle)
    p1 = plot(ax,sfAxis,theSTFs(1,:), 'ko-', ...
        'LineWidth', 1.5, 'MarkerFaceColor', [0.5 0.5 0.5], 'MarkerSize', 12);
    hold(ax, 'on');
    p2 = plot(ax,sfAxis,theSTFs(2,:), 'ro-', ...
        'LineWidth', 1.5, 'MarkerFaceColor', [1 0.5 0.5], 'MarkerSize', 12);
    p3 = plot(ax,sfAxis, theSTFs(3,:), 'bo-', ...
        'LineWidth', 1.5, 'MarkerFaceColor', [0.5 0.5 1], 'MarkerSize', 12);
    plot(ax, sfAxis, theSTFs(3,:)*0, 'k--');
    legend([p1 p2 p3], {'session 1', 'session 2', 'session 3'}, 'Location', 'SouthEast')
    xlabel(ax,'spatial frequency (c/deg)')
    title(ax, plotTitle);
    set(ax, 'FontSize', 12, 'YLim', [-0.2 0.6], 'XScale', 'log', 'XLim', [5 50]);
end