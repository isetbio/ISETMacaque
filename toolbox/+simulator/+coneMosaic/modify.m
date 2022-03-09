function theConeMosaic = modify(monkeyID, coneMosaicParams)

     % Load cone mosaic model
    load(simulator.utils.cMosaicFilename(monkeyID), 'cm');
    theConeMosaic = cm;
    clear 'cm';

    % Cone mosaic modifications
    % 1. Spectral support
    theConeMosaic.wave = coneMosaicParams.wavelengthSupport;
    
    % 2. Aperture modifiers
    newConeApertureModifiers = theConeMosaic.coneApertureModifiers;
    newConeApertureModifiers.smoothLocalVariations = true;
    newConeApertureModifiers.shape = coneMosaicParams.apertureShape;
    if (strcmp(coneMosaicParams.apertureShape, 'Gaussian'))
        newConeApertureModifiers.sigma = coneMosaicParams.apertureSigmaToDiameterRatio;
    end
    theConeMosaic.coneApertureModifiers = newConeApertureModifiers;

    % 3. Cone coupling
    theConeMosaic.coneCouplingLambda = coneMosaicParams.coneCouplingLambda;
    
    % 4. Integration time
    theConeMosaic.integrationTime = coneMosaicParams.integrationTimeSeconds;
end
