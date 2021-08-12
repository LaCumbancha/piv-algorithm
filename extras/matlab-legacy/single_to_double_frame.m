%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  SINGLE_TO_DOUBLE_FRAME: Transforms image time series in successive double frame buffers
%
%   Using it as DBL_FRAME=SINGLE_TO_DOUBLE_FRAME(SGL_FRAME,OPTIONS) will return an [nI,nJ,nImages] 3D-array containing all images.

%   Params.FRAME_SKIP is an integer (default at 1).
%   Params.FRAME_MODE is a string. Only 'TimeSeries' (default) and 'Successive' are allowed.
%
%   In 'TimeSeries' mode, the images are transformed as follows (FRAME_SKIP=1):
%
%   1 2 3 4 5 6 7 8 9  => 9 images, 8 double frame buffers.
%   A A A A A A A A
%     B B B B B B B B
%
%   In 'Successive' mode, the images are transformed as follows (FRAME_SKIP=1):
%
%   1 2 3 4 5 6 7 8 9  => 9 images, 4 double frame buffers.
%   A   A   A   A
%     B   B   B   B
%
%   Each unit of step shifts the B frame one unit further. In successive modes this automatically shifts the next A frame too. With FRAME_SKIP=3:
%
%   'TimeSeries' mode:
%
%   1 2 3 4 5 6 7 8 9  => 9 images, 6 double frame buffers.
%   A A A A A A
%         B B B B B B
%
%   'Successive' mode:
%
%   1 2 3 4 5 6 7 8 9  => 9 images, 2 double frame buffers.
%   A       A
%         B       B
%

function [dbl_frame,apparent_mask] = single_to_double_frame(sgl_frame,parameters)

	nImages=size(sgl_frame,3);

	step=parameters.frame_skip;			% Default: 1
	mode=parameters.frame_mode;			% Default: TimeSeries

	switch mode
		case 'TimeSeries'
			idxFrameA=1:(nImages-step);
		case 'Successive'
			idxFrameA=1:(step+1):(nImages-step-1);
	end

	idxFrameB=idxFrameA+step;

	if isempty(parameters.mask)
		parameters.mask=ones(size(sgl_frame(:,:,1)));
	else
		if ~all(size(parameters.mask)==size(sgl_frame(:,:,1)))        
			parameters.mask=ones(size(sgl_frame(:,:,1)));
		end
	end

	for i=1:length(idxFrameA);
		dbl_frame(i).frameA=sgl_frame(:,:,idxFrameA(i));
		dbl_frame(i).frameB=sgl_frame(:,:,idxFrameB(i));
		if i==1
			masked_image=sgl_frame(:,:,idxFrameA(i))+uint16((1-parameters.mask)*2^16);
			dbl_frame=repmat(dbl_frame,[1 length(idxFrameA)]);
		end
	
		if ~isempty(parameters.roi)
			roi=parameters.roi;
			s2=size(dbl_frame(i).frameA);
		
			x_range=max(1,roi(3)):min(roi(4),s2(1));
			y_range=max(1,roi(1)):min(roi(2),s2(2));
			[x_range(1) x_range(1) x_range(end) x_range(end)];
			[y_range(1) y_range(end) y_range(end) y_range(1)];

			if i==1
				masked_image=masked_image(x_range,y_range);
			end
			dbl_frame(i).frameA=dbl_frame(i).frameA(x_range,y_range);
			dbl_frame(i).frameB=dbl_frame(i).frameB(x_range,y_range);
		end

	end

	apparent_mask=uint16(masked_image~=uint16(2^16));

end
