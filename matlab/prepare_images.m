%   PREPARE_IMAGES: determine which indices must be used to create the interrogation windows.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN FUNCTION:

function [work_images,indices,data,parameters]=prepare_images(images,data,parameters)

    IntWin=parameters.IntWin(parameters.current_pass);
    Step=parameters.Step(parameters.current_pass);
    
    %% first and last indices for the position of vectors
    minix=1+(ceil(Step));
    miniy=1+(ceil(Step));
     
    maxix=Step*(floor(size(images(1).frameA,2)/Step))-(IntWin-1)+(ceil(Step));
    maxiy=Step*(floor(size(images(1).frameA,1)/Step))-(IntWin-1)+(ceil(Step));
    
    number_of_vectors_u=floor((maxix-minix)/Step+1);
    number_of_vectors_v=floor((maxiy-miniy)/Step+1);
    
    %% Center the grid on the image 
    
    LAy=miniy;
    LAx=minix;
    LUy=size(images(1).frameA,1)-maxiy;
    LUx=size(images(1).frameA,2)-maxix;
    shift4centery=round((LUy-LAy)/2);
    shift4centerx=round((LUx-LAx)/2);
    if shift4centery<0 %shift4center will be negative if in the unshifted case the left border is bigger than the right border. the vectormatrix is hence not centered on the image. the matrix cannot be shifted more towards the left border because then image2_crop would have a negative index. The only way to center the matrix would be to remove a column of vectors on the right side. but then we weould have less data....
        shift4centery=0;
    end
    if shift4centerx<0 %shift4center will be negative if in the unshifted case the left border is bigger than the right border. the vectormatrix is hence not centered on the image. the matrix cannot be shifted more towards the left border because then image2_crop would have a negative index. The only way to center the matrix would be to remove a column of vectors on the right side. but then we weould have less data....
        shift4centerx=0;
    end

    miniy=miniy+shift4centery;
    minix=minix+shift4centerx;
    maxix=maxix+shift4centerx;
    maxiy=maxiy+shift4centery;
    
    work_images=images;
    
    %% add a zero padded border to the images
    for cur_image=1:length(images)
        work_images(cur_image).frameA=padarray(images(cur_image).frameA,[ceil(IntWin-Step) ceil(IntWin-Step)], min(min(images(cur_image).frameA)));
        work_images(cur_image).frameB=padarray(images(cur_image).frameB,[ceil(IntWin-Step) ceil(IntWin-Step)], min(min(images(cur_image).frameB)));
    end
    
    %% indices of interrogation window for first frame
    s0 = (repmat((miniy:Step:maxiy)'-1, 1,number_of_vectors_u) + repmat(((minix:Step:maxix)-1)*size(work_images(1).frameA, 1), number_of_vectors_v,1))'; 
    s0 = permute(s0(:), [2 3 1]);
    s1 = repmat((1:IntWin)',1,IntWin) + repmat(((1:IntWin)-1)*size(work_images(1).frameA, 1),IntWin,1);
    indices{1} = repmat(s1, [1, 1, size(s0,3)]) + repmat(s0, [IntWin, IntWin, 1]);
    
    %% Interpolate old vector field on new grid (if apply)
    if ~isempty(data)
        x_old=data.x;
        y_old=data.y;
        u_old=data.u;
        v_old=data.v;
    
        %new grid
        data.x =  repmat((minix:Step:maxix), number_of_vectors_v, 1) + IntWin-Step;
        data.y =  repmat((miniy:Step:maxiy)', 1, number_of_vectors_u) + IntWin-Step;
        
        % interpolate vector field
        data.u=interp2(x_old,y_old,u_old,data.x,data.y,'*spline');
        data.v=interp2(x_old,y_old,v_old,data.x,data.y,'*spline');
     
        %add 1 line around image for border regions... why ?
        U=  padarray(data.u, [1,1], 'replicate');
        V=  padarray(data.v, [1,1], 'replicate');
        
        % linear extrap
        firstlinex=data.x(1,:);
        firstlinex_intp=interp1(1:1:size(firstlinex,2),firstlinex,0:1:size(firstlinex,2)+1,'linear','extrap');
        X=repmat(firstlinex_intp,size(data.x,1)+2,1);
        
        firstliney=data.y(:,1);
        firstliney_intp=interp1(1:1:size(firstliney,1),firstliney,0:1:size(firstliney,1)+1,'linear','extrap')';
        Y=repmat(firstliney_intp,1,size(data.y,2)+2);
        
        X1=X(1,1):1:X(1,end)-1; 
        Y1=(Y(1,1):1:Y(end,1)-1)';
        X1=repmat(X1,size(Y1, 1),1);
        Y1=repmat(Y1,1,size(X1, 2));

        U1 = interp2(X,Y,U,X1,Y1,'*linear');
        V1 = interp2(X,Y,V,X1,Y1,'*linear');
        
        xb = find(X1(1,:) == X(1,1));
        yb = find(Y1(:,1) == Y(1,1));
        
        for cur_image=1:length(work_images)
            work_images(cur_image).frameB = interp2(1:size(work_images(cur_image).frameB,2),(1:size(work_images(cur_image).frameB,1))',double(work_images(cur_image).frameB),X1+U1,Y1+V1,parameters.ImDeform); %linear is 3x faster and looks ok...
        end

        s0 = (repmat(yb-Step+Step*(1:number_of_vectors_v)'-1, 1,number_of_vectors_u) + repmat((xb-Step+Step*(1:number_of_vectors_u)-1)*size(work_images(cur_image).frameB, 1), number_of_vectors_v,1))'; 
        s0 = permute(s0(:), [2 3 1]) - s0(1);
        s2 = repmat((1:IntWin)',1,IntWin) + repmat(((1:IntWin)-1)*size(work_images(cur_image).frameB, 1),IntWin,1);
        indices{2} = repmat(s2, [1, 1, size(s0,3)]) + repmat(s0, [IntWin, IntWin, 1]);
        
    end
        
    parameters.minix=minix;
    parameters.maxix=maxix;
    parameters.miniy=miniy;
    parameters.maxiy=maxiy;

end
