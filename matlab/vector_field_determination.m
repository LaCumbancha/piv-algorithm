%   VECTOR FIELD DETERMINATION:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  MAIN FUNCTION:

function [data,parameters]=vector_field_determination(correlation,data,parameters,is_it_last);

    if nargin<4
        is_it_last=0;
    end
    
    try
        s2n_threshold=parameters.s2n;
    catch
        s2n_threshold=1;
    end

    IntWin=parameters.IntWin(parameters.current_pass);
    minix= parameters.minix;
    maxix= parameters.maxix;
    miniy=parameters.miniy;
    maxiy=parameters.maxiy;
    step=parameters.Step(parameters.current_pass);

    %% Normalize result
    minres = permute(repmat(squeeze(min(min(correlation))), [1, size(correlation, 1), size(correlation, 2)]), [2 3 1]);
    deltares = permute(repmat(squeeze(max(max(correlation))-min(min(correlation))), [1, size(correlation, 1), size(correlation, 2)]), [2 3 1]);
    correlation = ((correlation-minres)./deltares)*255;

    %% Find first and second peak
    [x1,y1,index1,x2,y2,index2,s2n]=find_all_displacement(correlation);

    %% Sub-pixel determination
    if (rem(IntWin,2) == 0) %for the subpixel displacement measurement
        SubPixOffset=1;
    else
        SubPixOffset=0.5;
    end

    if parameters.SubPixMode==1
        [vector] = SUBPIXGAUSS (correlation,IntWin, x1, y1, index1,SubPixOffset);
    elseif parameters.SubPixMode==2 %% prone to errors
        [vector] = SUBPIX2DGAUSS (correlation,IntWin, x1, y1, index1,SubPixOffset);
    end
    
    %% Create data 
    data_empty=1;
    if ~isempty(data)
        data_empty=0;
    end
    
    data.x = repmat((minix:step:maxix)+IntWin/2, length(miniy:step:maxiy), 1);
    data.y = repmat(((miniy:step:maxiy)+IntWin/2)', 1, length(minix:step:maxix));
    vector = permute(reshape(vector, [size(data.x') 2]), [2 1 3]);
    
    s2n=s2n(reshape((1:numel(data.x)),size(data.x,2),size(data.x,1)))';
    
    %% signal to noise filter
    if is_it_last
    vector(:,:,1)=vector(:,:,1).*(s2n>s2n_threshold);
    vector(:,:,2)=vector(:,:,2).*(s2n>s2n_threshold);
    end
    
    %% assignement
    if ~data_empty
        data.u=data.u + vector(:,:,1);
        data.v=data.v + vector(:,:,2);
    else
        data.u=vector(:,:,1);
        data.v=vector(:,:,2);
    end
    data.x = repmat((minix:step:maxix)+IntWin/2, length(miniy:step:maxiy), 1);
    data.y = repmat(((miniy:step:maxiy)+IntWin/2)', 1, length(minix:step:maxix));
    data.s2n=s2n;
    
    if parameters.current_pass==length(parameters.IntWin)
        data.x=data.x-IntWin/2;
        data.y=data.y-IntWin/2;
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  SUBPIXGAUSS:

function [vector] = SUBPIXGAUSS(result_conv, IntWin, x, y, idx, SubPixOffset)

    z= (1:length(idx))';
    xi = find(~((x <= (size(result_conv,2)-1)) & (y <= (size(result_conv,1)-1)) & (x >= 2) & (y >= 2)));
    x(xi) = [];
    y(xi) = [];
    z(xi) = [];
    xmax = size(result_conv, 2);
    vector = NaN(size(result_conv,3), 2);
  
    if(numel(x)~=0)
        ip = sub2ind(size(result_conv), y, x, z);
        
        f0 = log(result_conv(ip));
        f1 = log(result_conv(ip-1));
        f2 = log(result_conv(ip+1));
        peaky = y + (f1-f2)./(2*f1-4*f0+2*f2);
        f0 = log(result_conv(ip));
        f1 = log(result_conv(ip-xmax));
        f2 = log(result_conv(ip+xmax));
        peakx = x + (f1-f2)./(2*f1-4*f0+2*f2);

        SubpixelX=peakx-(IntWin/2)-SubPixOffset;
        SubpixelY=peaky-(IntWin/2)-SubPixOffset;
        vector(z, :) = [SubpixelX, SubpixelY];  
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  SUBPIX2DGAUSS:
    
function [vector] = SUBPIX2DGAUSS(result_conv, IntWin, x, y, idx, SubPixOffset)

    z= (1:length(idx))';
    xi = find(~((x <= (size(result_conv,2)-1)) & (y <= (size(result_conv,1)-1)) & (x >= 2) & (y >= 2)));
    x(xi) = [];
    y(xi) = [];
    z(xi) = [];
    xmax = size(result_conv, 2);
    vector = NaN(size(result_conv,3), 2);

    if(numel(x)~=0)
        c10 = zeros(3,3, length(z));
        c01 = c10;
        c11 = c10;
        c20 = c10;
        c02 = c10;
        ip = sub2ind(size(result_conv), y, x, z);

        for i = -1:1
            for j = -1:1
                c10(j+2,i+2, :) = i*log(result_conv(ip+xmax*i+j));
                c01(j+2,i+2, :) = j*log(result_conv(ip+xmax*i+j));
                c11(j+2,i+2, :) = i*j*log(result_conv(ip+xmax*i+j));
                c20(j+2,i+2, :) = (3*i^2-2)*log(result_conv(ip+xmax*i+j));
                c02(j+2,i+2, :) = (3*j^2-2)*log(result_conv(ip+xmax*i+j));
            end
        end
        c10 = (1/6)*sum(sum(c10));
        c01 = (1/6)*sum(sum(c01));
        c11 = (1/4)*sum(sum(c11));
        c20 = (1/6)*sum(sum(c20));
        c02 = (1/6)*sum(sum(c02));

        deltax = squeeze((c11.*c01-2*c10.*c02)./(4*c20.*c02-c11.^2));
        deltay = squeeze((c11.*c10-2*c01.*c20)./(4*c20.*c02-c11.^2));
        peakx = x+deltax;
        peaky = y+deltay;

        SubpixelX = peakx-(IntWin/2)-SubPixOffset;
        SubpixelY = peaky-(IntWin/2)-SubPixOffset;

        vector(z, :) = [SubpixelX, SubpixelY];
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  FIND_ALL_DISPLACEMENT: find all integer pixel displacement in a stack of correlation windows.
%
%   Usage: [IPEAK1,JPEAK1,INDEX1,IPEAK2,JPEAK2,INDEX2,S2N]=find_all_displacement(COR)
%
%   CORR is a (N x N x N_corr) array where N is the size of the square correlation maps, and N_corr the number of correlation maps, usually the same number 
%   than interrogation windows. 
%
%   IPEAK1, JPEAK1 are the horizontal and vertical indices of the first maximum for each slice of COR in the third dimension.
%
%   IPEAK2, JPEAK2 are the horizontal and vertical indices of the second maximum for each slice of COR in the third dimension.
%
%   INDEX1 and INDEX2 are the absolute indexes of the maximums in COR(:).
%  
%   S2N is the ratio between the first and the second peak. 0 indicates non confiable results (peaks at edges and absence of seconf peak).
%
%   No loop! (Well, no explicit loop)
%   The matrix CORR contains all the intercorrelations, in different slices  indexed in the third dimension of c. We do all the operations at once, for each slice.

function [ipeak1,jpeak1,index1,ipeak2,jpeak2,index2,s2n]=find_all_displacement(correlations)

    % Find first pick
    N=size(correlations,1);
    who_is_the_max=max(max(correlations)); % that's a 1x1xnumber of interrogation window vector
    we_are_the_max=(correlations==repmat(who_is_the_max,[N N 1])); % value of max
    index1=find(we_are_the_max);              % absolute index in c(:)

    [jpeak1,ipeak1,k]=ind2sub([N,N],index1);

    % Now what happen if you have two elements equals to the max ? Let's see if they are in the same layer! Then we take the first one. 
    % Surely the second one will be the second peak. Anyway this would be a bad vector.
    [~,idx]=unique(k);
    index1=index1(idx);
    ipeak1=ipeak1(idx);
    jpeak1=jpeak1(idx);

    %% Find second pick
    if N>=64
        filt_size=9;
    elseif N>=32;
        filt_size=4;
    else
        filt_size=3;
    end

    r=imfilter(we_are_the_max,ones(filt_size));  % Most obvious implicit loop, still better than a parfor.

    % Before: we_are_the_max(:,:,i)  | After: r(:,:,i)
    %
    % 000000000000000000000000000000 | 000000000000000000000000000000 
    % 000000000000000000000000000000 | 000000000000000000000000000000
    % 000000000000000000000000000000 | 000001111i_s000000000000000000
    % 000000000000000000000000000000 | 000001111i_s000000000000000000
    % 000000i_s000000000000000000000 | 000001111i_s000000000000000000-pixj1
    % 000000000000000000000000000000 | 000001111i_s000000000000000000
    % 000000000000000000000000000000 | 000001111i_s000000000000000000
    % 000000000000000000000000000000 | 000000000000000000000000000000
    % 000000000000000000000000000000 | 000000000000000000000000000000
    % 000000000000000000000000000000 | 000000000000000000000000000000
    % 000000000000000000000000000000 | 000000000000000000000000000000
    % 000000000000000000000000000000 | 000000000000000000000000000000
    % 000000000000000000000000000000 | 000000000000000000000000000000
    %       |                                 |
    %       pixi1                             pixi1

    correlations=(1-r).*correlations;                                  % Mask out the peak. 
    who_is_the_max2=max(max(correlations));
    we_are_the_max2=(correlations==repmat(who_is_the_max2,[N N 1]));
    index2=find(we_are_the_max2);

    [jpeak2,ipeak2,k]=ind2sub([N,N],index2);
    [~,idx]=unique(k);
    index2=index2(idx);
    ipeak2=ipeak2(idx);
    jpeak2=jpeak2(idx);

    s2n=zeros(1,size(who_is_the_max,3));
    s2n(permute(who_is_the_max2,[1 3 2])~=0)=permute(who_is_the_max(who_is_the_max2~=0)./who_is_the_max2(who_is_the_max2~=0),[1 3 2]);

    % Maximum at a border usually indicates that Max took the first one it found... Let's put it a shitty signal to noise, like 0 ;)
    s2n(jpeak1==1)=0;
    s2n(ipeak1==1)=0;
    s2n(jpeak1==N)=0;
    s2n(ipeak1==N)=0;
    s2n(jpeak2==1)=0;
    s2n(ipeak2==1)=0;
    s2n(jpeak2==N)=0;
    s2n(ipeak2==N)=0;

end
