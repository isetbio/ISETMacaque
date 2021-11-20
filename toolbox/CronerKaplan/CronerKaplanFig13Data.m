function [eccentricityDegs, retinalRcDegs, PcellDendriticTreeRadii] = CronerKaplanFig13Data()

    d = [...
     1.9589      0.077146; ...
     4.6312      0.068447; ...
     3.7032      0.063688; ...
     1.0364      0.044208; ...
     2.0224        0.0494; ...
     2.3134      0.045495; ...
     2.5479      0.033787; ...
     1.2716      0.029032; ...
    0.40144      0.025574; ...
    0.28625      0.020806; ...
     1.1595     0.0082244; ...
     1.1025     0.0030227; ...
     1.2729       0.02253; ...
     1.9689      0.025557; ...
     1.4479      0.017759; ...
     2.7273     0.0064733; ...
     3.7724     0.0060285; ...
     2.8983      0.022945; ...
     2.6672      0.017312; ...
     4.1176      0.022499; ...
     4.0035      0.011662; ...
     4.5844     0.0099214; ...
     3.9986       0.03724; ...
     4.2876       0.04374; ...
     6.3175      0.054122; ...
     7.1296      0.057582; ...
     6.6672      0.047182; ...
     6.0297      0.041553; ...
     5.4501      0.036791; ...
     5.3928       0.03289; ...
     5.6846      0.025083; ...
     6.3793      0.035046; ...
     7.1963      0.013361; ...
     7.1973     0.0077255; ...
     8.7064     0.0094432; ...
     7.4854      0.019428; ...
     7.6575       0.02983; ...
       8.47      0.031122; ...
     6.4968      0.027675; ...
     8.2924      0.048899; ...
     9.2771      0.060593; ...
     11.017      0.068378; ...
      10.38      0.060581; ...
     11.194      0.054936; ...
     9.6851      0.052352; ...
     9.6859      0.048016; ...
     9.3966      0.042817; ...
     9.9783      0.037175; ...
     10.445      0.027632; ...
     11.259      0.017653; ...
     15.674      0.005466; ...
     13.521      0.028033; ...
     12.824      0.034543; ...
     12.243       0.03585; ...
     12.879      0.047115; ...
       14.1      0.037564; ...
     16.018      0.029306; ...
     18.456      0.030147; ...
     16.595      0.044907; ...
      15.55      0.047519; ...
     13.689      0.060112; ...
     14.909      0.057931; ...
     13.801      0.081353; ...
     14.612      0.094784; ...
     15.832      0.087834; ...
      16.94       0.06051; ...
       18.8       0.05312; ...
     20.368      0.050935; ...
     21.238      0.050059; ...
     21.874      0.067393; ...
     22.626      0.078657; ...
     23.149      0.075616; ...
     24.197      0.062599; ...
      24.49       0.04959; ...
     31.686       0.06035; ...
     28.078       0.10461; ...
     29.994       0.10676; ...
     34.974        0.1726; ...
     38.944      0.054636; ...
     16.056       0.12945 ...
        ];
    
    eccentricityDegs = d(:,1);
    retinalRcDegs = d(:,2);
    
    d = [...
      0.80891     0.019933; ... 
      1.7387     0.015155 ; ...
      1.9699     0.020354 ; ...
        2.55     0.022949 ; ...
      2.3192     0.015582 ; ...
      3.0741     0.014707 ; ...
      3.3055     0.019039 ; ...
      3.9437     0.020767 ; ...
      3.8287     0.015132 ; ...
      4.4669     0.017293 ; ...
      4.4678     0.012524 ; ...
      5.0477     0.015986 ; ...
      5.4546      0.01338 ; ...
      5.6866     0.014245 ; ...
      6.2665     0.017707 ; ...
      5.7416     0.030285 ; ...
      5.9748      0.02508 ; ...
      6.7877     0.024637 ; ...
      6.6141     0.021605 ; ...
      7.6025     0.014224 ; ...
      8.0663     0.017254 ; ...
       7.194     0.025067 ; ...
      6.9026     0.030706 ; ...
      7.3082     0.035036 ; ...
      7.4813     0.040237 ; ...
       8.123     0.024189 ; ...
      8.9929     0.028949 ; ...
      9.0502      0.03285 ; ...
      10.326     0.040206 ; ...
      10.269      0.03327 ; ...
       11.72     0.035422 ; ...
      12.534     0.030645 ; ...
      12.593     0.025008 ; ...
      12.071     0.025014 ; ...
      12.647      0.04495 ; ...
      13.113     0.040176 ; ...
      13.288     0.035839 ; ...
      14.327     0.062706 ; ...
      14.271      0.05577 ; ...
      14.272     0.050134 ; ...
       15.43     0.065295 ; ...
      16.186     0.060952 ; ...
      16.651      0.05401 ; ...
      16.306      0.03754 ; ...
      17.986     0.054863 ; ...
      17.988     0.049227 ; ...
      18.742     0.049652 ; ...
      21.935     0.050051 ; ...
      19.669     0.060047 ; ...
      19.377     0.069588 ; ...
      19.782     0.074786 ; ...
      20.593     0.085615 ; ...
      20.768     0.079977 ; ...
      20.479     0.076079 ; ...
      21.001     0.075206 ; ...
      21.582     0.074766 ; ...
      20.596     0.070442 ; ...
      20.597     0.065673 ; ...
      20.656     0.060036 ; ...
      22.919     0.065214 ; ...
      23.031     0.085589 ; ...
      24.598     0.091641 ; ...
      19.486      0.10384 ; ...
      25.936     0.077754 ; ...
      26.163       0.1042 ; ...
      26.452       0.1094 ; ...
      26.103      0.11027 ; ...
      26.915      0.11503 ; ...
      27.903      0.10981 ; ...
      28.021     0.098974 ; ...
      29.063      0.11934 ; ...
       29.12      0.12454 ; ...
      30.049      0.11976 ; ...
      30.918      0.13362 ; ...
      29.115      0.14925 ; ...
      29.985      0.15011; ...
      32.186      0.18087 ...
        ];
    
    PcellDendriticTreeRadii.eccDegs = d(:,1);
    PcellDendriticTreeRadii.RcDegs = d(:,2);
end