%   RESTRUCTURED READ_CXD: function that reads CXD files.
%   MODE: Normal
%   VERB: Debugging
%
%   IMAGES = LFD_MPIV_READ_IMAGES(FILENAME);
%   IMAGES is a IxJxN uint16 matrix where IxJ is the image size and N the number of images.
%   FILENAME is a string containing the path to the .cxd file.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN FUNCTION:
% The main idea is to read the file little by little so the memory is not swamped. A buffer is filled and emptied as features are detected.

function [images,image_size,nb_frames,number_of_images]=read_cxd(file_name,indices)

	MSG = 'LOADING'

	BLOCK_SIZE = 512;
	HEADER_BLOCK_SIZE = 2048*5;

	%% Header info recollection
	[image_size, nb_frames] = read_header_cxd(file_name);
	fid = fopen(file_name);

	% Calculating number of images
	file_info=dir(file_name);
	number_of_images=floor(file_info.bytes/(prod(image_size)*2*nb_frames));
	indices=1:number_of_images;

	%% Initialize buffer and result matrix
	images=uint16(zeros(image_size(2),image_size(1)*nb_frames,length(indices)));
	last_image=indices(end);
	k=0;

	%% Jump over the header
	fread(fid,HEADER_BLOCK_SIZE,'uint16=>uint16','l');

	for i=1:last_image

		sample=fread(fid,BLOCK_SIZE,'uint16=>uint16','l')';
		while detect_pattern(sample) || bullshit(sample) || detect_zero(sample)

			sample=fread(fid,BLOCK_SIZE,'uint16=>uint16','l')';
			if isempty(sample); break; end
		end
		B=sample;

		% A is also a buffer, it contains 10% image_size of what follows.
		try
			[im]=obtain_image(fid,B,image_size,BLOCK_SIZE,nb_frames);
			if find(indices==i);
				k=k+1;
				images(:,:,k)=im;

			fprintf('Obtained image %d\n',i);													% Verbosity:  2
		end
		catch
			fprintf('End of file reached\n');													% Verbosity:  2
			number_of_images=number_of_images-1;
			break
		end
	end

	images=images(:,:,1:min(number_of_images,length(indices)));
	fprintf('%d images contained.\n',number_of_images);											% Verbosity:  1

	close(h);																					% Verbosity: -1

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HEADER DATA EXTRACTION
% Returns the first image size and the number of frames.

function [image_size,nb_frames]=read_header_cxd(file_name)

	% Main hypothesis: there should be at least 5 times 2^12 uint8 in the header
	HEADER_SECTIONS_SIZE = 2^12;
	BLOCK_SIZE=512;

	%% Read header and get image size
	fid = fopen(file_name);
	if fid == -1; error('Cannot open specified CXD (%s). Does it even exist? Seriously...',file_name); end

	%%%% Jumping to the fifth section
	fread(fid,HEADER_SECTIONS_SIZE*4,'uint8=>char');
	A = fread(fid,HEADER_SECTIONS_SIZE*1,'uint8=>char');

	%%%% Retrieving interesting things
	idx1 = strfind(A','Capture Region');
	idx2 = strfind(A','Display Depth');
	capt = A(idx1:idx2-1)';

	%%%% Getting image size
	idxop = strfind(capt,'(');
	idxcl = strfind(capt,')');
	capt = capt(idxop+1:idxcl-1);
	idxvir = strfind(capt,',');
	image_size = [str2double(capt(idxvir(2)+1:idxvir(3)-1)),str2double(capt(idxvir(3)+1:end))];

	%% Read first image
	sample=fread(fid,BLOCK_SIZE,'uint16=>uint16','l')';
	while detect_pattern(sample) || bullshit(sample)
		figure(665)																				% Verbosity:  4
		plot(sample)																			% Verbosity:  4
		title('pattern')																		% Verbosity:  4
		pause																					% Verbosity:  4
		sample=fread(fid,BLOCK_SIZE,'uint16=>uint16','l')';
	end

	A=sample;
	A=[A fread(fid,2*prod(image_size)-length(A),'uint16=>uint16','l')'];
	fclose(fid);

	sample=A(prod(image_size)+1:prod(image_size)+BLOCK_SIZE);

	if bullshit(sample) || detect_pattern(sample) || detect_zero(sample)
		nb_frames=1;
	else
		nb_frames=2;
	end

	fprintf('Image size: %d x %d\n',image_size(1),image_size(2));								% Verbosity:  1
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IMAGE EXTRACTION

function [image]=obtain_image(fid,A,image_size,BLOCK_SIZE,nb_frames)
	% The buffer contains the beginning of the image. So we read 110% of the next image to get the image and the following buffer.
	% This might fail for small images (smaller than 200000 elements);
	A=[A fread(fid,nb_frames*prod(image_size)-length(A),'uint16=>uint16','l')'];

	while any(strfind(A,zeros([1 BLOCK_SIZE]))) % Detect possible WTF block of BLOCK_SIZE null elements.
		A=[A fread(fid,BLOCK_SIZE,'uint16=>uint16','l')'];
		idx=strfind(A,zeros([1 BLOCK_SIZE])); % in the image
		A=[A(1:idx-1) A(idx+BLOCK_SIZE:end)]; % and bypass it
	end

	figure(665)																					% Verbosity:  4
	plot(A)																						% Verbosity:  4
	title('image')																				% Verbosity:  4
	pause																						% Verbosity:  4

	image=reshape(A(1:nb_frames*prod(image_size)),image_size(1)*nb_frames,image_size(2))';

	figure(666)																					% Verbosity: 3
	warning('off','images:initSize:adjustingMag')												% Verbosity: 3
	imshow(imadjust(image));drawnow																% Verbosity: 3

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% NON-IMAGE DETECTION

function out=bullshit(A)
	% The main hypothesis here is that cxd file is made of blocks of BLOCK_SIZE elements in between 12 bits images.
	out=0;
	if any(A>2^12)
		out=1;
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PATTERN DETECTION

function out=detect_pattern(A)
	% We just look for similarity, not exact pattern as some FEFF blocks can appear.
	BLOCK_SIZE=numel(A);
	A=A(:)';
	pattern=1:BLOCK_SIZE/2;
	b=double(A(1:2:BLOCK_SIZE));
	s=sum(mod(b(1:BLOCK_SIZE/2)-1,BLOCK_SIZE/2)+1-pattern==0);
	if s>=BLOCK_SIZE/2*0.66
		out=1;
	else
		out=0;
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ZERO BLOCK

function out=detect_zero(A)
	if all(A==0)
		out=1;
	else
		out=0;
	end
end
