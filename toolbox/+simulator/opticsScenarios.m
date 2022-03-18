classdef opticsScenarios
% Enumeration for the available optics scenarios
   enumeration
      M838Optics
      PolansOptics
      diffrLimitedOptics_residualDefocus        % variable Z5 coeff
      diffrLimitedOptics_GaussianBlur           % Gaussian blur
   end
end