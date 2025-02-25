function [dx_smoothed, dy_smoothed] = smoothDeformationField(dx, dy, filterSize, sigma)

    gaussianFilter = fspecial('gaussian', filterSize, sigma);

    % Apply Gaussian filter to both deformation field components
    dx_smoothed = imfilter(dx, gaussianFilter, 'replicate');
    dy_smoothed = imfilter(dy, gaussianFilter, 'replicate');
end
