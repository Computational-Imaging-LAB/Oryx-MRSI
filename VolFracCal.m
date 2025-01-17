% This function is written to calculate CSF, WM, GM fraction values of each
% spectra.
% Author: Sevim Cengiz, Bogazici University, 2021
% Contact: sevim_cengiz@icloud.com
% Credits:
% This function is modified from OspreySeg. See: https://github.com/schorschinho/osprey
% Inputs: Pinfo struct, number of slice, column, row, metabolite no, images
% of gray matter, white matter, CSF.
% Output: Pinfo struct which stores fraction values of CSF, WM, and GM at each spectral voxel.

function [Pinfo]=VolFracCal(Pinfo,sli,row,col,met,csf_img,gm_img,wm_img)
met=1;
mask_csf=(csf_img(:,:,:).*Pinfo.metab(met).littlevoxels(sli,row,col).littlemask(:,:,:));
mask_gm=(gm_img(:,:,:).*Pinfo.metab(met).littlevoxels(sli,row,col).littlemask(:,:,:));
mask_wm=(wm_img(:,:,:).*Pinfo.metab(met).littlevoxels(sli,row,col).littlemask(:,:,:));

CSFsum = sum(sum(sum(mask_csf(:,:,:))));
GMsum  = sum(sum(sum(mask_gm(:,:,:))));
WMsum  = sum(sum(sum(mask_wm(:,:,:))));

% Normalize
frac_GM = GMsum / (GMsum + WMsum + CSFsum);
frac_WM = WMsum / (GMsum + WMsum + CSFsum);
frac_CSF= CSFsum / (GMsum + WMsum + CSFsum);

Pinfo.frac_GM(met,sli,row,col)=frac_GM;
Pinfo.frac_WM(met,sli,row,col)=frac_WM;
Pinfo.frac_CSF(met,sli,row,col)=frac_CSF;
end