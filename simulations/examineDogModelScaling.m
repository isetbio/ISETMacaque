function examineDogModelScaling
    
    Kc = 1;
    Rc = 1/60;
    Ks = 1/10;
    Rs = Rc * 3.5;
    gainChange = 2.0;

    forwardAnalysis(1, Kc, Ks, Rc, Rs, gainChange)

    reverseAnalysis(2, Kc, Ks, Rc, Rs, gainChange);

end

function reverseAnalysis(figNo, Kc, Ks, Rc, Rs, gainChange)
    
    xDegs = linspace(-2,2,1024);
    sfCPD = linspace(0,100,1024);

    theRFprofile = Kc*Rc*sqrt(pi)*exp(-(xDegs/Rc).^2) -...
                   Ks*Rs*sqrt(pi)*exp(-(xDegs/Rs).^2);

    [sfAxis, theActualSTF, theFullSTF] = amplitudeSpectrum(xDegs, theRFprofile);

    yOffset = -0.01;
    theFullSTF = abs(theFullSTF + yOffset) .* exp(1i*angle(theFullSTF));
    theFullSTF = (theFullSTF + yOffset) * gainChange;
    theRFprofileGain = ifft(theFullSTF);


    halfNFFT = numel(theFullSTF)/2-1;
    theActualSTFGain = abs(theFullSTF(1:halfNFFT));
    

    figure(figNo); clf;
    ax = subplot(1,2,1);
    plot(ax,xDegs, theRFprofile, 'r-', 'LineWidth', 1.5);
    hold(ax, 'on');
    plot(ax,xDegs, theRFprofileGain, 'b--', 'LineWidth', 1.5);
    xlabel(ax, 'space (degs)');
    set(ax, 'XLim', [-0.25 0.25], 'XTick', -0.5:0.1:0.5, ...
        'YLim', [-0.04 0.04], 'YTick', -0.04:0.01:0.04);

    ax = subplot(1,2,2);
    plot(ax,sfAxis, theActualSTF, 'r-', 'LineWidth', 1.5);
    hold(ax, 'on');
    plot(ax,sfAxis, theActualSTFGain, 'b--', 'LineWidth', 1.5);
    set(ax, 'XScale', 'log', 'XLim', [0.1 100]);
    xlabel(ax, 'spatial frequency (c/deg)');
    ylabel(ax, 'amplitude spectrum')
end


function forwardAnalysis(figNo, Kc, Ks, Rc, Rs, gainChange)
    xDegs = linspace(-2,2,1024);
    sfCPD = linspace(0,100,1024);

    theRFprofile = Kc*Rc*sqrt(pi)*exp(-(xDegs/Rc).^2) -...
                   Ks*Rs*sqrt(pi)*exp(-(xDegs/Rs).^2);

    
    theRFprofileGain = theRFprofile * gainChange;
    
    % Theoretical STF: We use the absolute value of Equation 9 of
    % Enroth-Cuggell, because we ignore the phase, just looking at the amplitude
    theSTF = 1000*pi*abs(Kc*Rc^2*exp(-(pi*Rc*sfCPD).^2) - ...
                         Ks*Rs^2*exp(-(pi*Rs*sfCPD).^2));

    [sfAxis, theActualSTF] = amplitudeSpectrum(xDegs, theRFprofile);
    [sfAxis, theActualSTFGain] = amplitudeSpectrum(xDegs, theRFprofileGain);

    scalingFactor = max(theSTF)/max(theActualSTF);
    theActualSTF = theActualSTF * scalingFactor;
    theActualSTFGain = theActualSTFGain * scalingFactor;


    figure(figNo); clf;
    ax = subplot(1,2,1);
    plot(ax,xDegs, theRFprofile, 'r-', 'LineWidth', 1.5);
    hold(ax, 'on');
    plot(ax,xDegs, theRFprofileGain, 'b--', 'LineWidth', 1.5);
    xlabel(ax, 'space (degs)');
    set(ax, 'XLim', [-0.25 0.25], 'XTick', -0.5:0.1:0.5, ...
        'YLim', [-0.04 0.04], 'YTick', -0.04:0.01:0.04);

    ax = subplot(1,2,2);
    plot(ax,sfCPD, theSTF, 'k:', 'LineWidth', 1.5);
    hold on;
    plot(ax,sfAxis, theActualSTF, 'r-', 'LineWidth', 1.5);
    plot(ax,sfAxis, theActualSTFGain, 'b--', 'LineWidth', 1.5);

    legend({'theory', 'fft(profile)', sprintf('fft(profile x %2.1f)', gainChange)});
    set(ax, 'XScale', 'log', 'XLim', [0.1 100]);
    xlabel(ax, 'spatial frequency (c/deg)');
    ylabel(ax, 'amplitude spectrum')
         
end

function [sfAxis, theHalfSTFAmplitude, theFullSTF] = amplitudeSpectrum(xDegs, theRFprofile)
    theFullSTF = fft(theRFprofile);
    theSTFamplitude = abs(theFullSTF);
    dt = xDegs(2)-xDegs(1);
    sfMax = 1/(2*dt);
    halfNFFT = numel(theSTFamplitude)/2-1;
    deltaSF = sfMax/halfNFFT;

    sfAxis = (0:(halfNFFT-1))*deltaSF;
    theHalfSTFAmplitude = theSTFamplitude(1:halfNFFT);
end
