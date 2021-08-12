%   FILTER_FIELDS: applys different filters on the vector fields.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN FUNCTION:

function [data,parameters]=filter_fields2(data,parameters);

    data = apply_mask(data,parameters);

    %% FILTER 1 : Threshold on signal to noise.
    data.u=removeNAN(data.u);
    data.v=removeNAN(data.v);

    %% FILTER 2 : 
    stdthresh=4;
    meanu=nanmean(nanmean(data.u));
    meanv=nanmean(nanmean(data.v));
    std2u=nanstd(reshape(data.u,size(data.u,1)*size(data.u,2),1));
    std2v=nanstd(reshape(data.v,size(data.v,1)*size(data.v,2),1));
    minvalu=meanu-stdthresh*std2u;
    maxvalu=meanu+stdthresh*std2u;
    minvalv=meanv-stdthresh*std2v;
    maxvalv=meanv+stdthresh*std2v;
    data.u(data.u<minvalu)=NaN;
    data.u(data.u>maxvalu)=NaN;
    data.v(data.v<minvalv)=NaN;
    data.v(data.v>maxvalv)=NaN;
    
    try 
        % Smooth predictor
        if parameters.current_pass<length(parameters.IntWin)
            data.u = smoothn(data.u,0.6); %stronger smoothing for first passes
            data.v = smoothn(data.v,0.6);
        else
            data.u = smoothn(data.u); %weaker smoothing for last pass
            data.v = smoothn(data.v);
        end
    catch
        % Can't use smooth predictor
        h=fspecial('gaussian',5,1);
        data.u=imfilter(data.u,h,'replicate');
        data.v=imfilter(data.v,h,'replicate');
     end
     
    if parameters.current_pass==length(parameters.IntWin)
        data = apply_mask(data,parameters,1);
    end
     
end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% APPLY_MASK:

function data = apply_mask(data,parameters,last)

    if nargin<3
        last=0;
    end

    if ~isempty(parameters.apparrent_mask)
        mask=parameters.apparrent_mask;

        [x1,y1]=meshgrid(1:size(mask,1),1:size(mask,2));
        ss=size(data.u);
        [x2,y2]=meshgrid(linspace(1,size(mask,1),ss(1)),linspace(1,size(mask,2),ss(2)));

        mask_vec=interp2(x1,y1,double(mask'),x2,y2,'linear')';
        data.u=data.u.*mask_vec;
        data.v=data.v.*mask_vec;
        
        if last
            data.u(mask_vec<0.5)=NaN;
            data.v(mask_vec<0.5)=NaN;
        end
        
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% REMOVE_NAN:

function data=removeNAN(data,patch_size);

    if nargin<2
        patch_size=1;
    end

    [i,j]=find(isnan(data));
    idx=find(isnan(data));

    s=size(data);
    newdata=zeros(1,length(i));

    if ~isempty(i)

        for k=1:length(i);
            sample=data(max(1,i(k)-patch_size):min(s(1),i(k)+patch_size),max(1,j(k)-patch_size):min(s(2),j(k)+patch_size));
            sample=sample(~isnan(sample));
            if ~isempty(sample);
                newdata(k)=median(sample);
            else
                newdata=0;
            end
        end

        data(idx)=newdata;

    end

end
