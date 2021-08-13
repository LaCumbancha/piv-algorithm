%   RESTRUCTURED LFD_MPIV_CommandLine: computes PIV fields from CXD files
%   Only one input: LFD_MPIV_Parameters. This array could be generated using LFD_MPIV_Interface.
%   By default, single frame time series will be converted in double frame time series (1-2 2-3 3-4 ...) and cumulative cross-correlation will be performed. 
%   Three passes (64x64 32x32 and 16x16) are performed.
%
%   Quick option guide:
%
%   Parameter name 		| Parameter values	| Description
%   --------------------|-------------------|-------------------
%   IntWin				| [64 32 16]		| Array of interrogation window size.
%   Cumulcross			| 1					| Switch to 0 to deactive cumulative cross-correlation.
%   ImageIndices		| []				| Indices of images to include. Empty means all images are used.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN FUNCTION

function data_PIV=LFD_MPIV_CommandLine(the_input,varargin)

	%%% Copy input parameters into the ''parameters'' variable.
	for i=1:numel(the_input)
		parameters(i)=the_input(i).copy;
		parameters(i).update(varargin{:});
	end

	%%% Populate ''case_name_collection'' with the export file names. It correlates with parameter by index.
	case_name_collection={};
	for i=1:length(parameters);
		if ~any(strcmp(case_name_collection,parameters(i).export_filename))
			case_name_collection{numel(case_name_collection)+1}=parameters(i).export_filename;        
		end
	end
	
	%%% Iterate over every case and export the output data.
	for i_case=1:length(case_name_collection)

		%%% Setting only one value in ''this_parameters_idx'' (1) and ''this_z'' (height), for this ''i_case''.
		this_parameters_idx=zeros(1,length(parameters));
		this_z=zeros(1,length(parameters));
		for i=1:length(parameters);
			if strcmp(case_name_collection{i_case},parameters(i).export_filename)
				this_parameters_idx(i)=1;
				this_z(i)=parameters(i).height;
			end
		end
		
		%%% Getting this case parameters.
		this_case_parameters=parameters(this_parameters_idx>0);

		%%% Retrieving ''this_z'' for this case (its height) and ''sort_idx'' (that it's always 1).
		[this_z,sort_idx]=sort(this_z(this_parameters_idx>0));

		%%% Overwriting ''this_case_parameters'' with the first case parameters, because ''sort_idx'' it's always 1.
		this_case_parameters=this_case_parameters(sort_idx);
		
		%%% There is only 1 element in ''this_z'', so it will be just 1 iteration.
		for i_height = 1:numel(this_z)

			data=raw_to_vectors(this_case_parameters(i_height));
			if i_height==1
				try
					clear data_PIV
				catch
				end

				%%% Check how repmat works. It's just a transformation.
				data_PIV.x=repmat(data.x,[1 1 length(this_z)]);
				data_PIV.y=repmat(data.y,[1 1 length(this_z)]);
				data_PIV.z=repmat(permute(this_z,[1 3 2]),[size(data_PIV.x,1) size(data_PIV.x,2)]);
				data_PIV.u=repmat(data_PIV.y*0,[1 1 1 size(data.u,3)]);
				data_PIV.v=repmat(data_PIV.y*0,[1 1 1 size(data.u,3)]);
				data_PIV.w=repmat(data_PIV.y*0,[1 1 1 size(data.u,3)]);
				data_PIV.s2n=repmat(data_PIV.y*0,[1 1 1 size(data.u,3)]);
			end

			data_PIV.u(:,:,i_height,:)=permute(data.u,[1 2 4 3]);
			data_PIV.v(:,:,i_height,:)=permute(data.v,[1 2 4 3]);
			data_PIV.s2n(:,:,i_height,:)=permute(data.s2n,[1 2 4 3]);
			data_PIV.parameters(i_height)=this_case_parameters(i_height);
		end

		%%% Saving data in output file.
		save_name=fullfile(data_PIV.parameters(1).export_folder,data_PIV.parameters(1).export_filename);
		if ~isempty(save_name)
			save(sprintf('%s.mat',save_name),'data_PIV');
		end
				
	end

end
