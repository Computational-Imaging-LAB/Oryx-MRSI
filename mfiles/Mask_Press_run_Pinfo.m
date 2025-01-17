%% This function is written to create binary mask volumes of Pressbox with the same dimensions of the reference anatomical image volume.
% Author: Sevim Cengiz, Sevim Cengiz, Bogazici University, 2020
% Contact: sevim_cengiz@icloud.com

% It considers chemical shift correction, if chemical shift correction
% button is on. Also, it creates 9 different binary masks of metabolites considering chemical shift amount.  
% Credits: This function is modified from GannetMask_Philips.m. Link: https://github.com/richardedden/Gannet3.1
% Reference: Edden RAE, Puts NAJ, Harris AD, Barker PB, Evans CJ. Gannet: A batch-processing tool for the quantitative analysis of gamma-aminobutyric acid-edited MR spectroscopy spectra. J. Magn. Reson. Imaging 2014;40:1445–1452. doi: 10.1002/jmri.24478)
% Inputs: Pinfo struct, metabolite number (k), pressbox mask file path,
% chemical shift ex, eco and echo2 values, RFOV direction. 
% Outputs: Pinfo struct. 
% All output files will be saved under ~spectra/nifti/coreg_binary_mask
% folder as nifti files. 
function [Pinfo] = Mask_Press_run_Pinfo(Pinfo,k,MRIPressMask_file,chem_shift_ex,chem_shift_echo,chem_shift_echo2,RFOV_dir)

nii=Pinfo.MRI;
[pathnii,namenii,extnii] = fileparts(nii);
gunzip(nii,pathnii);
nii_file=[pathnii,filesep,namenii];

V=spm_vol(nii_file);
[MRI,XYZ]=spm_read_vols(V);

[~,voxdim] = spm_get_bbox(V,'fv'); 
voxdim = abs(voxdim)';
halfpixshift = -voxdim(1:3)/2;

%Shift imaging voxel coordinates by half an imaging voxel so that the XYZ matrix
%tells us the x,y,z coordinates of the MIDDLE of that imaging voxel.
halfpixshift(3) = -halfpixshift(3);
XYZ=XYZ+repmat(halfpixshift,[1 size(XYZ,2)]);

% get information from SPAR - change later to be read in
% 
if rem((Pinfo.apVOI/2),2)==0
     ap_size=Pinfo.apVOI;
        
else 
     voxsize1= Pinfo.FOV/ Pinfo.nrow;
   ap_size=Pinfo.apVOI-voxsize1; 
end
    


if rem((Pinfo.lrVOI/2),2)==0
     lr_size=Pinfo.lrVOI;
        
else 
     voxsize2=Pinfo.FOV/ Pinfo.ncol;
   lr_size=Pinfo.lrVOI-voxsize2;   
end
    
% ap_size = Pinfo(ii).sparinfo(j).apVOI;
% lr_size = Pinfo(ii).sparinfo(j).lrVOI;
cc_size =  Pinfo.slithickness;
switch RFOV_dir
    case 'RL'

ap_off =Pinfo.voxoffap+chem_shift_ex;
lr_off = Pinfo.voxofflr+chem_shift_echo;
cc_off = Pinfo.voxoffcc+chem_shift_echo2;

    otherwise % AP
        
ap_off =Pinfo.voxoffap+chem_shift_echo;
lr_off = Pinfo.voxofflr+chem_shift_ex;
cc_off = Pinfo.voxoffcc+chem_shift_echo2;

end

ap_ang = Pinfo.voxangap;
lr_ang = Pinfo.voxanglr;
cc_ang = Pinfo.voxangcc;

%We need to flip ap and lr axes to match NIFTI convention
ap_off = -ap_off;
lr_off = -lr_off;

ap_ang = -ap_ang;
lr_ang = -lr_ang;

% define the voxel - use x y z  
% currently have spar convention that have in AUD voxel - will need to
% check for everything in future...
% x - left = positive
% y - posterior = postive
% z - superior = positive
vox_ctr = ...
      [lr_size/2 -ap_size/2 cc_size/2 ;
       -lr_size/2 -ap_size/2 cc_size/2 ;
       -lr_size/2 ap_size/2 cc_size/2 ;
       lr_size/2 ap_size/2 cc_size/2 ;
       -lr_size/2 ap_size/2 -cc_size/2 ;
       lr_size/2 ap_size/2 -cc_size/2 ;
       lr_size/2 -ap_size/2 -cc_size/2 ;
       -lr_size/2 -ap_size/2 -cc_size/2 ];
   
% make rotations on voxel
rad = pi/180;
initrot = zeros(3,3);

xrot = initrot;
xrot(1,1) = 1;
xrot(2,2) = cos(lr_ang *rad);
xrot(2,3) =-sin(lr_ang*rad);
xrot(3,2) = sin(lr_ang*rad);
xrot(3,3) = cos(lr_ang*rad);


yrot = initrot;
yrot(1,1) = cos(ap_ang*rad);
yrot(1,3) = sin(ap_ang*rad);
yrot(2,2) = 1;
yrot(3,1) = -sin(ap_ang*rad);
yrot(3,3) = cos(ap_ang*rad);


zrot = initrot;
zrot(1,1) = cos(cc_ang*rad);
zrot(1,2) = -sin(cc_ang*rad);
zrot(2,1) = sin(cc_ang*rad);
zrot(2,2) = cos(cc_ang*rad);
zrot(3,3) = 1;


% rotate voxel
vox_rot = xrot*yrot*zrot*vox_ctr.';

% calculate corner coordinates relative to xyz origin
vox_ctr_coor = [lr_off ap_off cc_off];
vox_ctr_coor = repmat(vox_ctr_coor.', [1,8]);
vox_corner = vox_rot+vox_ctr_coor;
mask = zeros(1,size(XYZ,2));
sphere_radius = sqrt((lr_size/2)^2+(ap_size/2)^2+(cc_size/2)^2);
distance2voxctr=sqrt(sum((XYZ-repmat([lr_off ap_off cc_off].',[1 size(XYZ, 2)])).^2,1));
sphere_mask(distance2voxctr<=sphere_radius)=1;
mask(sphere_mask==1) = 1;
XYZ_sphere = XYZ(:,sphere_mask == 1);
tri = delaunayn([vox_corner.'; [lr_off ap_off cc_off]]);
tn = tsearchn([vox_corner.'; [lr_off ap_off cc_off]], tri, XYZ_sphere.');
isinside = ~isnan(tn);
mask(sphere_mask==1) = isinside;
mask = reshape(mask, V.dim);
V_mask.fname=[MRIPressMask_file];
V_mask.descrip='MRS_Voxel_Mask';
V_mask.dim=V.dim;
V_mask.dt=V.dt;
V_mask.mat=V.mat;
V_mask=spm_write_vol(V_mask,mask);

%%%% Newly added for VOI press box coregistation view

%%%%New Figureee

% MRIimg= MRI/max(MRI(:));
MRIimg=zeros(size(MRI));
MRIimg_mas = MRIimg + .2*mask;
% construct output
% 
voxel_ctr = [-lr_off -ap_off cc_off];
voxel_ctr(1:2)=-voxel_ctr(1:2);
voxel_search=(XYZ(:,:)-repmat(voxel_ctr.',[1 size(XYZ,2)])).^2;
voxel_search=sqrt(sum(voxel_search,1));
[min2,index1]=min(voxel_search);

[slice(1) slice(2) slice(3)]=ind2sub( V.dim,index1);    
size_max=max(size(MRIimg_mas));
three_plane_img=zeros([size_max 3*size_max]);
im1 = squeeze(MRIimg_mas(:,:,slice(3)));
im1 = im1(end:-1:1,:)'; 
im1 = flipdim(im1 ,1); 
im1 = flipdim(im1,2);
im3 = squeeze(MRIimg_mas(:,slice(2),:));
im3 = im3(end:-1:1,end:-1:1)'; 
im3 = flipdim(im3,2);
im2 = squeeze(MRIimg_mas(slice(1),:,:));
im2 = im2(:,end:-1:1)';

three_plane_img(:,1:size_max) = image_center(im1, size_max);
three_plane_img(:,size_max*2+(1:size_max))=image_center(im3,size_max);
three_plane_img(:,size_max+(1:size_max))=image_center(im2,size_max);

Pinfo.VOIimg(k).fig=three_plane_img; %Fov Mask Save
Pinfo.MRIVOIMask(k).name=MRIPressMask_file; %Fov Mask name save

if k==9

MRIimg2= MRI/max(MRI(:));
MRIimg22 = MRIimg2 + .2*MRIimg2;
three_plane_img2=zeros(size(three_plane_img));
im11 = squeeze(MRIimg22(:,:,slice(3)));
im11 = im11(end:-1:1,:)'; 
im11 = flipdim(im11 ,1); %vertical mirror (Now; up is Anterior, down is Posterior)
im11 = flipdim(im11,2); %horizantal mirror (Now: right left display)
im33 = squeeze(MRIimg22(:,slice(2),:));
im33 = im33(end:-1:1,end:-1:1)'; 
im33 = flipdim(im33,2); %horizantal mirror (Now: right left display)
im22 = squeeze(MRIimg22(slice(1),:,:));
im22 = im22(:,end:-1:1)';
Pinfo.refimg.slice=slice;
three_plane_img2(:,1:size_max) = image_center(im11, size_max);
three_plane_img2(:,size_max*2+(1:size_max))=image_center(im33,size_max);
three_plane_img2(:,size_max+(1:size_max))=image_center(im22,size_max);
Pinfo.refimg.fig=three_plane_img2; %Ref MRI image save








end

