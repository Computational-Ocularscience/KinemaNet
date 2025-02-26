function save_elastography_maps_as_mat_file(path, map, name)
    % Fisseha Ferede, 12/05/2023
    % Save elastography maps as .mat file
    
    % Create the directory if it doesn't exist
    if ~exist(path, 'dir')
        mkdir(path);
    end

    % Construct the full filename and save the map
    save(fullfile(path, strcat(name)), 'map');
end
