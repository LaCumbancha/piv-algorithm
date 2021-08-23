function [peak1_x, peak1_y, peak1_indexes, peak2_x, peak2_y, peak2_indexes, s2n] = displacements(correlation)

    % Find first pick
    corr_size = size(correlation, 1);
    max_peak = max(max(correlation));
    max_positions = (correlation == repmat(max_peak, [corr_size corr_size 1]));
    peak1_indexes = find(max_positions);

    [peak1_y, peak1_x, peak1_z] = ind2sub(size(correlation), peak1_indexes);
    [~, idx] = unique(peak1_z);
    peak1_indexes = peak1_indexes(idx);
    peak1_x = peak1_x(idx);
    peak1_y = peak1_y(idx);

    %% Find second pick
    if corr_size >= 64
        filt_size = 9;
    elseif corr_size >= 32;
        filt_size = 4;
    else
        filt_size = 3;
    end

    custom_filter = imfilter(max_positions, ones(filt_size));
    correlation = (1 - custom_filter) .* correlation;
    max_peak = max(max(correlation));
    max_positions = (correlation == repmat(max_peak, [corr_size corr_size 1]));
    peak2_indexes = find(max_positions);

    [peak2_y, peak2_x, peak1_z] = ind2sub(size(correlation), [corr_size, corr_size]);
    [~, idx] = unique(peak1_z);
    peak2_indexes = peak2_indexes(idx);
    peak2_x = peak2_x(idx);
    peak2_y = peak2_y(idx);

    s2n = zeros(1, size(max_peak, 3));
    s2n(permute(max_peak, [1 3 2]) ~= 0) = permute(max_peak(max_peak ~= 0) ./ max_peak(max_peak ~= 0), [1 3 2]);

    % Maximum at a border usually indicates that MAX took the first one it found, so we should put a bad S2N, like 0.
    s2n(peak1_x == 1) = 0;
    s2n(peak1_y == 1) = 0;
    s2n(peak1_x == corr_size) = 0;
    s2n(peak1_y == corr_size) = 0;
    s2n(peak2_x == 1) = 0;
    s2n(peak2_y == 1) = 0;
    s2n(peak2_x == corr_size) = 0;
    s2n(peak2_y == corr_size) = 0;

end