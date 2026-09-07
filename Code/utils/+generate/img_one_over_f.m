function img = img_one_over_f(width);
% daniel berger 2007.03
% abartels notes: 
% to analyze img power:
%		img_fft2d.m
%
% width = pixels. MUST BE EVEN. e.g. 256 or 512.
% graphics_flag = 0: no graph, 1: yes.
%
%	img: normalized to [0,1].
% NOTE: 1/f image has skewed intensity histogram, 
%   with very few values > .9 or >.8.
%   To get higher mean luminance, do e.g.
%       img(img>.8)=.8; img=img+.2; 

graphics_flag= 1;

w=width;
wh=width/2;

fimg=zeros(w,w);
img=zeros(w,w);

%//generate image with random phase and amplitude 1 everywhere
for x=1:1:w
  for y=1:1:w
    ph=pi*unidrnd(30000)/15000;
    fimg(x,y)=complex(cos(ph),sin(ph));
  end;
end;

a=zeros(w,w);

%//do 1/f filtering. dc offset is in (1,1). spatial frequency at (m,n) is f=sqrt((m-1)^2+(n-1)^2)
for x=1:1:w
  for y=1:1:w
    if (x-wh-1~=0)||(y-wh-1~=0)
      a(x,y)=1.0/sqrt((x-wh-1)^2+(y-wh-1)^2);
      %//fimg(x,y)=fimg(x,y)*a;
    end;
  end;
end;
a=ifftshift(a);

%//display 1/f image
if 	graphics_flag,
	figure;
	imagesc(a);
	title('One-over-f amplitudes');
end;

fimg=fimg.*a;

%//do inverse fourier transform
cimg=ifft2(fimg); 

%//compute amplitude image (discard complex phase)
for x=1:1:w
  for y=1:1:w
    r=real(cimg(x,y));
    i=imag(cimg(x,y));
    img(x,y)=sqrt(r*r+i*i);
  end;
end;

%//normalize image
mmin=min(min(img));
mmax=max(max(img));

img=(img-mmin)/(mmax-mmin);

%//display 1/f noise image
%figure('position',[100 100 size(img,2) size(img,1)]);
if 	graphics_flag,
	figure(2);
	imagesc(img);
	colormap gray;
	%set(gca,'position',[0 0 1 1]);
	title('1-over-f filtered white noise');
end;