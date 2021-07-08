%   RAW_TO_VECTORS: computes PIV fields from cxd files.
%
% 	Using it as DATA=RAW_TO_VECTORS(PARAMETERS) allows configuring the processing with an object LFD_MPIV_Parameters:
%
%   Parameter name 		| Parameter values			| Description
%   --------------------|---------------------------|-------------------
%   IntWin				| [64 32 16]				| Array of interrogation window size.
%	Overlap 			| 50 						| Percentage of overlaping of the interrogation windows. Only works with 50.
%	Cumulcross			| 0	or 1					| Switch to 0 to deactive cumulative cross-correlation.
%	SubPixMode			| 1 or 2					| Type of algorithm to use for subpixel determination. Only works with 1.
%   ImDeform			| 'linear' or 'cubic'		| Algorithm for the image deformation..
%	Verbose 			| 0, 1 or 2 				| How much will the program talk to you. Default is 1, 0 is mute and 2 for debug.
%   Rotation			| 90, 180 or 270			| Allows rotation of the image before processing by specified number of degrees.
%   FlipHor				| 0 or 1					| Flips the image horizontally. Using 0 as default.
%   FlipVer				| 0 or 1					| Flips the image vertically. Using 0 as default.
%   ROI					| [Hmin Hmax Vmin Vmax]		| Sets the Region Of Interest in pixels (full image).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN FUNCTION:

function data=raw_to_vectors(cxd_info,varargin)

	%% Start program
	t1=now;

	FlagImages=0;
	
		if any(strcmpi(varargin,'images'))
			FlagImages=1;
			idx=find(strcmpi(varargin,'images'));
			all_images=varargin{idx+1};
			varargin=varargin(setdiff(1:length(varargin),[idx idx+1]));
		end 
	
		parameters=cxd_info.update(varargin{:});  %implement options

	%% Start PIV
	if ~FlagImages

		%% Importing image
		[~,cxd_file_name,~]=fileparts(parameters.cxd_file);
		[all_images,~,nb_frames]=read_cxd(parameters.cxd_file,parameters.image_indices);
		if nb_frames~=parameters.source_frames; parameters.source_frames=nb_frames; end

		%% Preparing frames
		all_images=prepare_frames(all_images,parameters);

	end

	if parameters.cumulcross
		if ~isempty(parameters.ttl_folder)
			d=dir(parameters.ttl_folder);

			cxd_file_name=lower(cxd_file_name);
			cxd_file_name=strip_string(cxd_file_name);
			simi=zeros(1,numel(d));

			for i=1:length(d);
				name=strip_string(d(i).name);
				simi(i)=stringsimilarity(cxd_file_name,name);
			end

			[~,k]=max(simi);
			if parameters.Verbose>1;fprintf('Using synchronisation file: %s\n',d(k).name);end
			load(fullfile(parameters.ttl_folder,d(k).name),'tframe');
			T_acquired=tframe;
		else
			T_acquired=(0:numel(all_images)-1)/parameters.acq_freq;
		end

		f_act=parameters.act_freq;
		nb_phases=parameters.nb_phases;

		if f_act==0;
			nb_phases=1;
			phase=T_acquired*0+1;
		else
			phase=floor(mod(T_acquired+1/(2*f_act),1/f_act)*f_act*nb_phases)+1;
		end

	else
		phase=1:numel(all_images);
		nb_phases=phase(end);
	end


	for pha=1:nb_phases
		images=all_images(phase==pha);

		if parameters.cumulcross
			if nb_phases~=1
				if parameters.Verbose;fprintf('Phase number %d:',pha); fprintf(' %d image pairs\n',numel(images)); end
			else
				fprintf('Cumulative cross-correlation of %d image pairs\n',numel(images))
			end
		else
			if parameters.Verbose;fprintf('Image number %d\n',pha);end
		end
		
		if numel(images)>0
			data_phase=PIV(images,parameters);

			data.u(:,:,pha)=data_phase.u*parameters.scale/parameters.deltat;
			data.v(:,:,pha)=data_phase.v*parameters.scale/parameters.deltat;
			data.s2n(:,:,pha)=data_phase.s2n;

			if ~isfield(data,'x');
				data.x=data_phase.x*parameters.scale;
				data.y=data_phase.y*parameters.scale;
				data.u=repmat(data_phase.u*parameters.scale/parameters.deltat,[1 1 nb_phases]);
				data.v=repmat(data_phase.v*parameters.scale/parameters.deltat,[1 1 nb_phases]);
				data.s2n=repmat(data_phase.s2n,[1 1 nb_phases]);
			end
		end
	end

	%% Scaling

	data.x=data.x*parameters.scale;
	data.y=data.y*parameters.scale;
	data.u=data.u*parameters.scale/parameters.deltat;
	data.v=data.v*parameters.scale/parameters.deltat;

	%% Saving used parameters
	data.parameters=parameters;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STRIP STRING:

function new_string=strip_string(my_string)
	new_string=lower(my_string);
	new_string(new_string=='-')=[];
	new_string(new_string=='_')=[];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CUSTOM STRING SIMILARITY:

function simi=stringsimilarity(string1,string2)
	if length(string1)>length(string2);
		string3=string2;string2=string1;string1=string3;
	end

	simi=0;

	for i=1:(length(string2)-length(string1)+1)
		simi=max(simi,sum(string1==string2(i:length(string1)-1+i)));
	end
end
