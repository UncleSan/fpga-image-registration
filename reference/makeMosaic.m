function tmos=makeMosaic(saved_file,verbose)
if ~exist('verbose')
    verbose=0;
end
load(saved_file)
% Loaded variables [ssd_error, overlap_pct, homographies,dir_list,directory]
mosaic=[];
H_prev=eye(3);
first_im=1;
orig_img=[];
min_x=1;
max_x=inf;
min_y=1;
max_y=inf;
temp_imgs=cell(length(dir_list)-1,1);
temp_xd=zeros(length(dir_list)-1,2);
temp_yd=zeros(length(dir_list)-1,2);
% Pass 1, find out the final mosaic size
for i=1:length(dir_list)-1
    im0=imread(strcat(directory,dir_list(i).name));
    im1=imread(strcat(directory,dir_list(i+1).name));
    if ndims(im0)==2
       im0=repmat(im0,[1 1 3]);
       im1=repmat(im1,[1 1 3]);
    end
    if first_im
        first_im=0;
        max_x=size(im0,2);
        max_y=size(im0,1);
        orig_img=im0;
    end
    H_prev=H_prev*homographies(i*3-2:i*3,:);
    H_im1_to_im0=inv(H_prev);
    H_im1_to_im0=H_im1_to_im0/H_im1_to_im0(9);
    [image1_warped,xd,yd]=imtransform(double(im1),maketform('projective',H_im1_to_im0'),'Fill',NaN);
    temp_imgs(i)={image1_warped};
    temp_xd(i,:)=xd;
    temp_yd(i,:)=yd;
    min_x=min(xd(1),min_x);
    min_y=min(yd(1),min_y);
    max_x=max(xd(2),max_x);
    max_y=max(yd(2),max_y);
end
hold off
H_prev=eye(3);
first_img=1;
pixel_count=zeros(ceil(max_y-min_y+1),ceil(max_x-min_x+1));
mosaic=zeros(ceil(max_y-min_y+1),ceil(max_x-min_x+1),3);

% Pass 2, put images on mosaic

% Place orig image
orig_size=size(orig_img);
xd=[1 orig_size(2)];
yd=[1 orig_size(1)];
mosaic(yd(1):yd(2),xd(1):xd(2),:)=mosaic(yd(1):yd(2),xd(1):xd(2),:)+double(orig_img);
pixel_count(yd(1):yd(2),xd(1):xd(2))=pixel_count(yd(1):yd(2),xd(1):xd(2))+double(1);

for i=1:length(dir_list)-1
    im0=imread(strcat(directory,dir_list(i).name));
    im1=imread(strcat(directory,dir_list(i+1).name));
    H_prev=H_prev*homographies(i*3-2:i*3,:);
    H_im1_to_im0=inv(H_prev);
    H_im1_to_im0=H_im1_to_im0/H_im1_to_im0(9);
    image1_warped=temp_imgs{i};
    t_nan=uint8(~isnan(image1_warped));
    image1_warped=uint8(image1_warped);
    xd=round(temp_xd(i,:)-min_x+1); % NOTE :  This rounding makes the mosaic off by up to half a pixel in either direction
    yd=round(temp_yd(i,:)-min_y+1);
    xd(2)=xd(1)+size(image1_warped,2)-1;
    yd(2)=yd(1)+size(image1_warped,1)-1;
    
    mosaic(yd(1):yd(2),xd(1):xd(2),:)=mosaic(yd(1):yd(2),xd(1):xd(2),:)+double(image1_warped);
    pixel_count(yd(1):yd(2),xd(1):xd(2))=pixel_count(yd(1):yd(2),xd(1):xd(2))+double(t_nan(:,:,1));
    if verbose==1
        tmos=mosaic;
        tmos(:,:,1)=tmos(:,:,1)./pixel_count;
        tmos(:,:,2)=tmos(:,:,2)./pixel_count;
        tmos(:,:,3)=tmos(:,:,3)./pixel_count;
        imshow(uint8(tmos))
        pause
    end
end
if verbose==0
    tmos=mosaic;
    tmos(:,:,1)=tmos(:,:,1)./pixel_count;
    tmos(:,:,2)=tmos(:,:,2)./pixel_count;
    tmos(:,:,3)=tmos(:,:,3)./pixel_count;
end