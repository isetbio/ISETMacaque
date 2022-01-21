function sinusoids
   t = 0:0.01:1;
   for k = 1:10
       phaseDegs = randi(160,1);
       randA = 1+0.1*floor(rand*6);
       y(k,:) = randA * cosd(360*t*4-phaseDegs);
   end

   figure(1); clf;
   for k = 1:10
    subplot(2,1,1);
    hold on
    if (rand > 0.5)
        plot(t, y(k,:), 'r-', 'Color', [1 0.2 0.5], 'LineWidth', 2.0);
    else
        plot(t, y(k,:), 'r-', 'Color', [0.2 0.8 0.4], 'LineWidth', 2.0);
    end
    set(gca, 'XColor', 'none', 'YColor', 'none', 'XTick', 0:0.1:1, 'YTick', 0)
    %grid on
   end
   subplot(2,1,2);
   plot(t, sum(y,1), 'k-', 'LineWidth', 2.0);
   phaseDegs = randi(180,1)
   %grid on
   set(gca, 'XColor', 'none', 'YColor', 'none', 'XTick', 0:0.1:1, 'YTick', 0)

end