%% This function is for coord files subplot.
% Author: Sevim Cengiz,  Bogazici University , 2020
% Contact: sevim_cengiz@icloud.com
n=1;
for k=1:nrow
        for j=1:ncol
            subplot(nrow,ncol,n);
           
               plot(squeeze(real(flip(a(sh,k,j,:)))),'k' );
               plot(x_ppm,spectra_metabolites-baseline);
               plot(flat_x_ppm(sp,:),squeeze(flat_spectra(sp,:,:)));
            n=n+1;
        end
 end