%   PREPARE FRAMES: prepare frames to be processed by PIV algorithm.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MAIN FUNCTION:

function new_images=prepare_frames(images,parameters)

    images=flipud(images);
    % Images first element is lower left corner of matrix while data matrices first element is upper left.
    % This flip makes all image <-> data transactions more trivial.

    [new_images,apparrent_mask]=single_to_double_frame(images,parameters)
    parameters.apparrent_mask=apparrent_mask;
