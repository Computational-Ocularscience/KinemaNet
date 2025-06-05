function showElastographyParameter(fig, parameter, x0, x1, y0, y1)
    % Validate coordinates
    if any([x0, y0, x1, y1] < 1)
        uialert(fig, 'Error: Coordinates must be greater than or equal to 1.', 'Input Error');
        return;
    end

    % Get the strain matrix from appdata
    data = getappdata(fig, lower(parameter));
    
    if isempty(data)
        uialert(fig, ['Data "' parameter '" not available.'], 'Missing Data');
        return;
    end

    % Apply mask for selected region
    mask = false(size(data));
    mask(y0:y1, x0:x1) = true;

    maskedData = data;
    maskedData(~mask) = NaN;

    validData = maskedData(~isnan(maskedData));
    if isempty(validData)
        uialert(fig, 'Selected region has no valid data.', 'Empty Selection');
        return;
    end

    minVal = min(validData);
    maxVal = max(validData);

    % Plot heatmap
    figure;
    imagesc(maskedData);
    caxis([minVal, maxVal]);
    colorbar;
    title([parameter ' Heat Map'], 'FontSize', 12, 'FontWeight', 'bold');
    axis off;
    colormap('jet');
end
