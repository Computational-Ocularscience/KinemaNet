function save_colormap_of_elastography_maps(path, map, name)
    % Fisseha Ferede, 12/05/2023
    f = figure('Visible', 'off'); % Create an invisible figure
    imagesc(map); % Transpose to fix orientation

    % Ensure the specified path exists
    if ~exist(path, 'dir')
        mkdir(path);
    end

    % Set colormap, axis properties, and colorbar
    colormap(jet(500));
    axis equal; % or axis image, to keep the aspect ratio
    axis off;
    colorbar;

    % Capture the figure content and save it
    frame = getframe(f);
    imwrite(frame.cdata, fullfile(path, name));

    % Close the figure to free memory
    close(f);
end
