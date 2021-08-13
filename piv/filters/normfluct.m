%   FILTER_FIELDS: applys different filters on the vector fields.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN FUNCTION:

function [data] = normfluct(data)
    epsilon=0.02;
    thresh=1.5;
    [J,I]=size(data.u);
    normfluct=zeros(J,I,2);
    b=1;
    for c=1:2
        if c==1;
            velcomp=data.u;
        else
            velcomp=data.v;
        end

        clear neigh
        for ii = -b:b;
            for jj = -b:b;
                neigh(:, :, ii+2*b, jj+2*b)=velcomp((1+b:end-b)+ii, (1+b:end-b)+jj);
            end
        end

        neighcol = reshape(neigh, size(neigh,1), size(neigh,2), (2*b+1)^2);
        neighcol2= neighcol(:,:, [(1:(2*b+1)*b+b) ((2*b+1)*b+b+2:(2*b+1)^2)]);
        neighcol2 = permute(neighcol2, [3, 1, 2]);
        med=median(neighcol2);
        velcomp = velcomp((1+b:end-b), (1+b:end-b));
        fluct=velcomp-permute(med, [2 3 1]);
        res=neighcol2-repmat(med, [(2*b+1)^2-1, 1,1]);
        medianres=permute(median(abs(res)), [2 3 1]);
        normfluct((1+b:end-b), (1+b:end-b), c)=abs(fluct./(medianres+epsilon));
    end

    info1=(sqrt(normfluct(:,:,1).^2+normfluct(:,:,2).^2)>thresh);
    data.u(info1==1)=NaN;
    data.v(info1==1)=NaN;
