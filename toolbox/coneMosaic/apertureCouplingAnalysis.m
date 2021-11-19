function appertureCouplingAnalysis

Chen1993_Figure10data = [...
1.132559004671E-1	6.248363851803E-2; ...
2.939279957012E1	1.386213643065E1; ...
1.001884842723E2	4.838059218231E1];

micronsPerDegree = 200;
innerSegmentDiameterMicronsData = Chen1993_Figure10data(:,1)/60/60*micronsPerDegree;
fullWidthHalfMaxApertureMicronsData = Chen1993_Figure10data(:,2)/60/60*micronsPerDegree;

slope = 0.48;
figure(1); clf;
plot(innerSegmentDiameterMicronsData, fullWidthHalfMaxApertureMicronsData, 'ko');
hold on;
plot(innerSegmentDiameterMicronsData, innerSegmentDiameterMicronsData * slope, 'r-');
pause

sigmaFromInnerSegmentDiameterFactor = slope / (2 * sqrt(2*log(2)));
sigmaMicronsData = innerSegmentDiameterMicronsData * sigmaFromInnerSegmentDiameterFactor;


innerSegmentDiameterMicrons = innerSegmentDiameterMicronsData(2);
coneSpacingMicrons = innerSegmentDiameterMicrons * 2.8/2.3;

fullWidthHalfMaxApertureMicrons = fullWidthHalfMaxApertureMicronsData(2);
sigmaMicrons = sigmaMicronsData(2);
characteristicRadiusMicrons = sigmaMicrons * sqrt(2.0);

spatialSamplesNum = 200;
supportMicrons = 20;
x = linspace(0,supportMicrons,spatialSamplesNum); x = x - mean(x);
innerSegment = x * 0;
innerSegment(abs(x)<= innerSegmentDiameterMicrons/2) = 1;


couplingLamdaFactor = 0.7;
couplingLamdaMicrons = couplingLamdaFactor * innerSegmentDiameterMicrons;
coneCoupling = exp(-abs(x/couplingLamdaMicrons));

fullWidthHalfMaxAperture = x * 0;
fullWidthHalfMaxAperture(abs(x)<=fullWidthHalfMaxApertureMicrons/2) = 1;

gaussianAperture = exp(-0.5*(x/sigmaMicrons).^2);

pillboxApertureDiameterToInnerSegmentDiameterRatio = fullWidthHalfMaxApertureMicrons/innerSegmentDiameterMicrons
gaussianSigmaToInnerSegmentDiameterRatio = sigmaMicrons/innerSegmentDiameterMicrons

[X,Y] = meshgrid(x,x);
gaussianAperture2D = exp(-0.5*(X/sigmaMicrons).^2) .* exp(-0.5*(Y/sigmaMicrons).^2);
dx = x(2)-x(1);
gaussianArea2D = sum(gaussianAperture2D(:)) * dx^2;
gaussianArea2D/(pi*characteristicRadiusMicrons^2)

fullWidthHalfMaxAperture2D = X * 0;
R = sqrt(X.^2 + Y.^2);
fullWidthHalfMaxAperture2D(R<=fullWidthHalfMaxApertureMicrons/2) = 1;
fullWidthHalfMaxApertureArea2D = sum(fullWidthHalfMaxAperture2D(:))*dx^2;
fullWidthHalfMaxApertureArea2D/(pi*(fullWidthHalfMaxApertureMicrons/2)^2)
gaussianAperture = gaussianAperture / gaussianArea2D;
fullWidthHalfMaxAperture = fullWidthHalfMaxAperture / fullWidthHalfMaxApertureArea2D;

figure(2); clf;
subplot(1,2,1)

xArray = 0:dx:10;
xArray = [-fliplr(xArray) xArray(2:end)];
coneImpulseArray = 0*xArray;
coneImpulseArray(find(xArray == 0)) = 1;

coupledGaussianAperture = conv(gaussianAperture, coneCoupling, 'same');
coupledGaussianAperture = coupledGaussianAperture/max(coupledGaussianAperture) * max(gaussianAperture);
innerSegmentArray = conv(coneImpulseArray, innerSegment, 'same');
gaussianApertureArray = conv(coneImpulseArray, gaussianAperture, 'same');
fullWidthHalfMaxApertureArray = conv(coneImpulseArray, fullWidthHalfMaxAperture, 'same');
coneCouplingArray = conv(coneImpulseArray, coneCoupling, 'same');
coupledGaussianApertureArray = conv(coneImpulseArray, coupledGaussianAperture, 'same');

plot(xArray, innerSegmentArray, 'k--', 'LineWidth', 1.5);
hold on;
plot(xArray, fullWidthHalfMaxApertureArray, 'b-', 'LineWidth', 1.5);
plot(xArray, gaussianApertureArray, 'r-', 'LineWidth', 1.5);
plot(xArray, coneCouplingArray, 'k-', 'LineWidth', 3);
plot(xArray, coupledGaussianApertureArray, 'k-', 'LineWidth', 3);
legend({'inner segment', 'FWHM aperture', 'Gaussian aperture'})
xlabel('space (microns)');

subplot(1,2,2);
coneImpulseArray = 0*xArray;
coneImpulseArray(find(xArray == 0)) = 1;
[~,pos] = min(abs(xArray-coneSpacingMicrons));
coneImpulseArray(pos) = 1;
[~,pos] = min(abs(xArray-2*coneSpacingMicrons));
coneImpulseArray(pos) = 1;
[~,pos] = min(abs(xArray+coneSpacingMicrons));
coneImpulseArray(pos) = 1;
[~,pos] = min(abs(xArray+2*coneSpacingMicrons));
coneImpulseArray(pos) = 1;

innerSegmentArray = conv(coneImpulseArray, innerSegment, 'same');
gaussianApertureArray = conv(coneImpulseArray, gaussianAperture, 'same');
fullWidthHalfMaxApertureArray = conv(coneImpulseArray, fullWidthHalfMaxAperture, 'same');
coneCouplingArray = conv(coneImpulseArray, coneCoupling, 'same');

plot(xArray, innerSegmentArray, 'k--', 'LineWidth', 1.5);
hold on;
plot(xArray, fullWidthHalfMaxApertureArray, 'b-', 'LineWidth', 1.5);
plot(xArray, gaussianApertureArray, 'r-', 'LineWidth', 1.5);
plot(xArray, coneCouplingArray, 'k-', 'LineWidth', 1.5);
legend({'inner segment', 'FWHM aperture', 'Gaussian aperture'})
xlabel('space (microns)');


end

