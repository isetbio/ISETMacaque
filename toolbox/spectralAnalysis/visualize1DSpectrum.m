function visualize1DSpectrum(ax,f1,f2,p1,p2,fNyquist, maxPowerFrequency, frequencyPostFix)

   [min(f1) max(f1)]
   [min(f2) max(f2)]
   
   
   maxPower = max(p1);
   p1 = p1 / maxPower;
   maxPower = max(p2);
   p2 = p2 / maxPower;


%    stem(ax,f1, p1, 'filled', 'BaseValue', 0, 'LineWidth', 1.0, 'LineStyle', '-', ...
%              'Color', 'r', 'MarkerSize', 4, 'MarkerFaceColor', [1.0  0.5 0.5]);
%    
%    hold(ax, 'on');
%    stem(ax,f2, p2, 'filled', 'BaseValue', 0, 'LineWidth', 1.0, 'LineStyle', '-', ...
%              'Color', 'b', 'MarkerSize', 4, 'MarkerFaceColor', [0.5  0.5 1]);
%     
   plot(ax, f1, p1, 'r-');
   hold(ax, 'on');
   plot(ax, f2, p2, 'b--');
   plot(ax, fNyquist*[1 1], [0 1], 'b--', 'LineWidth', 1.5)
   hold(ax, 'off');
   set(ax, 'YLim', [0 1], 'YTick', 0:0.2:1, 'XLim', [1 100], 'XScale', 'log');
   xlabel(ax,sprintf('frequency (%s)', frequencyPostFix));
   ylabel(ax,'power');
end
