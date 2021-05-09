function  spectra = mrs_fft( fids )
% MRS_FFT returns the discrete Fourier transform (DFT) of FIDs, 
% computed with a fast Fourier transform (FFT) algorithm.    
% 
% spectra = mrs_fft( fids )
%
% ARGS :
% fids = data before Fourier transform 
%
% RETURNS:
% spectra = data after Fourier transform
%
% EXAMPLE: 
% >> spectra = mrs_fft(FIDs); 
% >> plot(spectra)
%
% AUTHOR : Chen Chen
% PLACE  : Sir Peter Mansfield Magnetic Resonance Centre (SPMMRC)
%
% Copyright (c) 2013, University of Nottingham. All rights reserved.

    [~, xs ys zs]=size(fids);
    for x = 1:xs
        for y=1:ys
            for z=1:zs
                spectra(:,x,y,z)=fftshift(fft(fids(:,x,y,z)));
            end
        end
    end
end

