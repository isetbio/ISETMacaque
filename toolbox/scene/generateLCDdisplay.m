function theDisplay = generateLCDdisplay(wavelengthSupport, desiredPixelSizeDegs, viewingDistanceMeters)

    theDisplay = displayCreate('LCD-Apple', ...
        'wave', wavelengthSupport, ...
        'viewing distance',viewingDistanceMeters);
    
    % Linear, 12-bit LUT
    bitDepth = 12;
    N = 2^bitDepth;
    gTable = repmat(linspace(0, 1, N), 3, 1)';
    theDisplay = displaySet(theDisplay, 'gTable', gTable);
    
    
    % Correct the dpi so we end up with a pixel size (in visual degrees) that
    % matches the retinal pixel size of the WilliamsLab
    
    % 1. Get current pixel size in degs
    pixelSizeDegs = displayGet(theDisplay, 'degperpixel');
    scaleFactorToMatchWilliamsDotsPerInch = pixelSizeDegs/desiredPixelSizeDegs;
    
    % 3. original dots per inch
    dpiOriginal = displayGet(theDisplay, 'dpi');
    dpiDesired = dpiOriginal * scaleFactorToMatchWilliamsDotsPerInch;
    
    % 4. Set desired dots per inch
    theDisplay = displaySet(theDisplay, 'dpi', dpiDesired);
    
    % 5. Verify that we matched it
    pixelSizeDegs = displayGet(theDisplay, 'degperpixel');
    [pixelSizeDegs desiredPixelSizeDegs]         
end