% This returns the A,b matrices where sum(Ai,i)*x=sum(bi,i), so if these
% are input for each pixel 
function [A,b]=fp_make_Ab_matrices(x,y,fx,fy,ft,sx)

fixed=0;
if fixed==1
   A=ns(zeros(6));
   b=ns(zeros(6,1));
else
    % Normalize the coordinates by the nearest power of 2
    x=x*2^(-sx);
    y=y*2^(-sx);

    % Pass 1
    fx2=fx.*fx;
    fxft=fx.*ft;
    fxfy=fx.*fy;
    fy2=fy.*fy;
    fyft=fy.*ft;
    x2=x.*x;
    y2=y.*y;
    xy=x.*y;

    % Pass 2
    fx2_t_x=fx2.*x;
    fx2_t_y=fx2.*y;
    fx2_t_x2=fx2.*x2;
    fx2_t_y2=fx2.*y2;
    fx2_t_xy=fx2.*xy;

    fy2_t_x=fy2.*x;
    fy2_t_y=fy2.*y;
    fy2_t_x2=fy2.*x2;
    fy2_t_y2=fy2.*y2;
    fy2_t_xy=fy2.*xy;

    fxfy_t_x=fxfy.*x;
    fxfy_t_y=fxfy.*y;
    fxfy_t_x2=fxfy.*x2;
    fxfy_t_y2=fxfy.*y2;
    fxfy_t_xy=fxfy.*xy;

    fxft_t_x=fxft.*x;
    fyft_t_x=fyft.*x;
    fxft_t_y=fxft.*y;
    fyft_t_y=fyft.*y;
    sf=2^-sx;
   A=zeros(6);
   b=zeros(6,1);
end
% Overall FP format for each A matrix 1:11:20 (the summation will have to be larger)
maxa=0;
maxA=zeros(6,1);

all_vec=[];
for i=1:length(x)
    if fixed==1
      [tA,tb]=fp_make_Ab_matrix(x(i),y(i),fx(i),fy(i),ft(i),sx);
        
       maxA=max(abs([double(tA),double(maxA),double(tb)]'))';
        all_vec=[all_vec;tA(:);tb(:)];
        A=ns(A)+ns(tA);
        b=ns(b)+ns(tb);
    else
        tA=[sf*fx2(i), fx2_t_x(i), fx2_t_y(i), sf*fxfy(i), fxfy_t_x(i), fxfy_t_y(i);
            sf*fx2_t_x(i), fx2_t_x2(i), fx2_t_xy(i), sf*fxfy_t_x(i), fxfy_t_x2(i), fxfy_t_xy(i);
            sf*fx2_t_y(i), fx2_t_xy(i), fx2_t_y2(i), sf*fxfy_t_y(i), fxfy_t_xy(i), fxfy_t_y2(i);
            sf*fxfy(i), fxfy_t_x(i), fxfy_t_y(i), sf*fy2(i), fy2_t_x(i), fy2_t_y(i);
            sf*fxfy_t_x(i), fxfy_t_x2(i), fxfy_t_xy(i), sf*fy2_t_x(i), fy2_t_x2(i), fy2_t_xy(i);
            sf*fxfy_t_y(i), fxfy_t_xy(i), fxfy_t_y2(i), sf*fy2_t_y(i), fy2_t_xy(i), fy2_t_y2(i)];
        tb=[sf*fxft(i);
            sf*fxft_t_x(i);
            sf*fxft_t_y(i);
            sf*fyft(i);
            sf*fyft_t_x(i);
            sf*fyft_t_y(i)];
             maxA=max(abs([double(tA),double(maxA),double(tb)]'))';
        A=A+tA;
        b=b+tb;
    end
   if fixed==0
       maxa=max(abs([maxa;tA(:);tb(:)]));
   end
end
if fixed==1
    b=double(-b);
    A=double(A);
    disp('Max Row Values')
    disp(maxA)
else
    %disp('Max Row Values')
    disp(maxA)
    cl=clock();
    save(sprintf('%f-%f-%f.mat',cl(4),cl(5),cl(6)),'A','b');
    %disp(sprintf('MAXta:%f',maxa))
    %disp(sprintf('MAXA:%f',max([A(:);b(:)])))
    b=-b;
end
disp('A')
disp(double(A))
disp('b')
disp(double(b))

function val=ns(x)
% Overall FP format for each A matrix 1:11:20 (the summation will have to
% be larger)
coord_word=38;
coord_whole=6;
val=fi(x,1,coord_word,coord_word-coord_whole-1,'MaxProductWordLength',1024,'MaxSumWordLength',1024,'RoundMode','Round','SumMode','KeepLSB','SumWordLength',38);


function absnormal(x)
assert(sum(abs(x)>=                 1)==0)