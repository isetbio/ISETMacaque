function rfProfileArea(ax,x,y, baseline, faceColor, edgeColor, faceAlpha, lineWidth)
% Visualize a fitted RGC model 
%
% Syntax:
%   simulator.visualize.rfProfileArea(ax,x,y, baseline, ...
%          faceColor, edgeColor, faceAlpha, lineWidth)
%
% Description:
%   Visualize the profile of an RF as a shaded area plot
%
% Inputs:
%    ax,x,y, baseline, ...
%    faceColor, edgeColor, faceAlpha, lineWidth
%
% Outputs:
%    none
%
% Optional key/value pairs:
%    none

    x = [x fliplr(x)];
    y = [y y*0+baseline];

    px = reshape(x, [1 numel(x)]);
    py = reshape(y, [1 numel(y)]);
    pz = -10*eps*ones(size(py)); 
    patch(ax,px,py,pz,'FaceColor',faceColor,'EdgeColor', edgeColor, 'FaceAlpha', faceAlpha, 'LineWidth', lineWidth);
end