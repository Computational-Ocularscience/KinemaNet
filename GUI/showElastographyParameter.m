function showElastographyParameter(parameter, x0, x1, y0, y1)
    % Ensure valid coordinate values
    if any([x0, y0, x1, y1] < 1)
        uialert(fig, 'Error: Coordinates must be greater than or equal to 1.', 'Input Error');
        return;
    end
    
    % Retrieve the corresponding strain matrix from the base workspace
    data = evalin('base', lower(parameter)); % Convert parameter to lowercase for variable name
    % Create a mask based on the specified coordinates
    mask = false(size(data));
    mask(y0:y1, x0:x1) = true; % Apply the mask to the selected region

    % Apply the mask to the selected data
    maskedData = data;
    maskedData(~mask) = NaN; % Set non-masked values to NaN

    validData = maskedData(~isnan(maskedData));

    if ~isempty(validData)
        minVal = min(validData);
        maxVal = max(validData);
    end

    % Display the heat map for the selected elastography parameter
    figure; % Create a new figure for the heat map
    imagesc(maskedData'); % Display the masked data
    caxis([minVal, maxVal]);
    colorbar; % Add a colorbar to indicate scale
    title([parameter ' Heat Map'], 'FontSize', 12, 'FontWeight', 'bold');
    axis off; % Set equal aspect ratio
    colormap('jet'); % Use a color map for visualization
    %set(gca, 'YDir', 'normal');
end