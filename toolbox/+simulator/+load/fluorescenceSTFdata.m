function [stfData, spatialFrequencySupport] = fluorescenceSTFdata(monkeyID)

    load(sprintf('SpatialFrequencyData_%s_OD_2021.mat', monkeyID), 'freqs', 'midget_dfF_otf'); 
    
    stfData = midget_dfF_otf;
    spatialFrequencySupport = freqs;
end
