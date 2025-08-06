function femExtractor(dataset_flag)
    %
    %@authors: Fisseha A. Ferede, and Madhusudhanan Balasubramanian
    %Computational Ocularscience Lab,
    %The University of Memphis.
    %email: fissehaad[at]gmail.com
    %@date: 2023-10-01
    %
    % This script extracts material modeling results from a CSV file and
    % generates strain estimates, heatmaps, and error metrics.
    % It uses the elastography class for strain calculations.
    % Input:
    %   dataset_flag: A string indicating the dataset to process.
    %                 1 - G6M1
    %                 2 - G7M1
    %                 3 - G8M1
    %                 4 - G9M1

    % Input parameters
    % ----------------------------------------------------------------------
    dataset_root = 'C:\Users\mblsbrmn\OneDrive - The University of Memphis\Lab\Members\Fisseha\Publications\Elastography\Complete Dataset';
    results_root = 'C:\Users\mblsbrmn\OneDrive - The University of Memphis\Lab\Members\Fisseha\Publications\Elastography\Results';
    study_dataset = 'Rubber_Material_Model';
    dataset_names = {'G6M1', 'G7M1', 'G8M1', 'G9M1'}; % List of dataset names to process
    %
    model_spatial_resolution = 25; % Set the spatial resolution of the model in microns
    crop = 20; % Set the boundary pixels to crop from the edges of the grid to remove any artifacts in the COMSOL exports
    %
    % Number of time steps and fields
    n_timesteps = 30;  % From t=0 to t=30
    fields_per_step = 8;
    %
    %Optimal kernel parameters for estimating derivatives using fminsearch optimizer
    sigma = 2.986;
    k = 15;
    % ----------------------------------------------------------------------

    % Add necessary paths
    addpath(genpath('Optimizer'));
    
    % Initialize input and output variables
    % ----------------------------------------------------------------------
    dataset_name = dataset_names{dataset_flag}; % Select dataset based on input flag
    l2_errors = zeros(n_timesteps-1, 7); % Initialize L2
    % File containing the material modeling results generated from COMSOL export
    filename = fullfile(dataset_root, study_dataset, 'COMSOL_Material_Models', dataset_name, [dataset_name '_Material_Model_Results.csv']);
    %
    % Folder to store the COMSOL material modeling results as ground truth: flow_01.flo, and strain_fields.mat
    data_gt_root_folder = fullfile(dataset_root, study_dataset, 'GT_Sequences', dataset_name);
    if ~exist(data_gt_root_folder, 'dir')
        mkdir(data_gt_root_folder);
    end
    %
    % To store KinemaNet strain estimates in .mat format and in png format for visualization
    kinemanet_root_folder = fullfile(results_root, study_dataset, 'KinemaNet', dataset_name);
    if ~exist(kinemanet_root_folder, 'dir')
        mkdir(kinemanet_root_folder);
    end
    % ----------------------------------------------------------------------

    % Read the table, skipping the first 9 header rows
    opts = detectImportOptions(filename, 'NumHeaderLines', 9);
    data = readtable(filename, opts);

    % Extract x and y coordinates (first two columns) of the specimen
    x = data{:,1};
    y = data{:,2};
    x_unique = unique(x);
    y_unique = unique(y);
    no_of_rows = length(y_unique);
    no_of_cols = length(x_unique);

    % Create root output folder
    output_root = erase(filename, '.csv');
    if ~exist(output_root, 'dir')
        mkdir(output_root);
    end

    % Get function handles for elastography calculations
    handles = elastography();

    % Loop over COMSOL material dynamics time steps
    for t = 1 : n_timesteps-1
        % Create subfolder for current time step
        data_curr_seq_folder = fullfile(data_gt_root_folder, sprintf('%02d', t));
        if ~exist(data_curr_seq_folder, 'dir')
            mkdir(data_curr_seq_folder);
        end
        %
        kinemanet_curr_seq_folder = fullfile(kinemanet_root_folder, sprintf('%02d', t));
        if ~exist(kinemanet_curr_seq_folder, 'dir')
            mkdir(kinemanet_curr_seq_folder);
        end

        % Column index for the current time step
        col_start = 3 + t * fields_per_step;
        
        % Extract data for the current time step from the COMSOL csv export
        [Ugrid, Vgrid, Exxgrid, Eyygrid, Exygrid, Vortgrid, StrMaggrid, VonMisesgrid] = ...
            est_GT_strain_components(data, col_start, no_of_cols, no_of_rows, crop);

        % KinemaNet estimate of  strain components using functions in elastography.m
        [Exx_est, Eyy_est, Exy_est, ~, ~, str_mag_est] = handles.strain_from_uv_flow(Ugrid, flipud(Vgrid), sigma, k);
        [von_mises_est] = handles.vonMissesCoefficient(Ugrid, flipud(Vgrid), sigma, k);
        [vort_est] = handles.vorticity_from_uv_flow(Ugrid, flipud(Vgrid), sigma, k);

        % Save GT flow and strain fields in raw format (.flo and .mat)
        % --------------------------------------------------------------
        % Save .flo file for u and v
        curr_raw_data_gt_folder = fullfile(data_curr_seq_folder, 'Raw_Data');
        if ~exist(curr_raw_data_gt_folder, 'dir')
            mkdir(curr_raw_data_gt_folder);
        end
        flo_filename = fullfile(curr_raw_data_gt_folder, sprintf('flow_%02d.flo', t));
        writeFlowFile(cat(3, Ugrid, Vgrid), flo_filename);

        % create mask with valid data points for strain estimation
        mask = double(~isnan(Ugrid)); % Identifies specimen coordinates
        
        % Save strain fields in .mat
        save(fullfile(curr_raw_data_gt_folder, 'strain_fields.mat'), ...
            'Exxgrid', 'Eyygrid', 'Exygrid', ...
            'Vortgrid', 'StrMaggrid', 'VonMisesgrid', 'mask');
        % --------------------------------------------------------------

        % Save GT flow and strain fields in png format for visualization
        % --------------------------------------------------------------
        curr_fig_gt_folder = fullfile(data_curr_seq_folder, 'Figures');
        if ~exist(curr_fig_gt_folder, 'dir')
            mkdir(curr_fig_gt_folder);
        end

        Ugrid(isnan(Ugrid)) = 0; % Replace NaNs with zeros for visualization
        Vgrid(isnan(Vgrid)) = 0;
        %
        saveFieldAsHeatmap(Ugrid, x_unique, y_unique, 'u', 'u', curr_fig_gt_folder);
        saveFieldAsHeatmap(Vgrid, x_unique, y_unique, 'v', 'v', curr_fig_gt_folder);
        saveFieldAsHeatmap(Exxgrid, x_unique, y_unique,  'E_{xx}', 'Exx', curr_fig_gt_folder);
        saveFieldAsHeatmap(Eyygrid, x_unique, y_unique,  'E_{yy}', 'Eyy', curr_fig_gt_folder);
        saveFieldAsHeatmap(Exygrid, x_unique, y_unique,  'E_{xy}', 'Exy', curr_fig_gt_folder);
        saveFieldAsHeatmap(Vortgrid, x_unique, y_unique, 'Vorticity', 'Vorticity', curr_fig_gt_folder);
        saveFieldAsHeatmap(StrMaggrid, x_unique, y_unique, 'Strain Magnitude', 'Strain Magnitude', curr_fig_gt_folder);
        saveFieldAsHeatmap(VonMisesgrid, x_unique, y_unique, 'von Mises Strain','von Mises Strain', curr_fig_gt_folder);
        saveFieldAsHeatmap(mask, x_unique, y_unique, 'mask', 'mask', curr_fig_gt_folder);
        % --------------------------------------------------------------

        % Save scaled GT flow and strain fields in png format for visualization
        % --------------------------------------------------------------
        curr_scaled_fig_gt_folder = fullfile(data_curr_seq_folder, 'Scaled_Figures');
        if ~exist(curr_scaled_fig_gt_folder, 'dir')
            mkdir(curr_scaled_fig_gt_folder);
        end
        saveFieldAsHeatmap_v1(Ugrid * model_spatial_resolution, x_unique, y_unique, 'u', curr_scaled_fig_gt_folder);
        saveFieldAsHeatmap_v1(Vgrid * model_spatial_resolution, x_unique, y_unique, 'v', curr_scaled_fig_gt_folder);
        saveFieldAsHeatmap_v1(Exxgrid * model_spatial_resolution, x_unique, y_unique, 'Exx', curr_scaled_fig_gt_folder);
        saveFieldAsHeatmap_v1(Eyygrid * model_spatial_resolution, x_unique, y_unique, 'Eyy', curr_scaled_fig_gt_folder);
        saveFieldAsHeatmap_v1(Exygrid * model_spatial_resolution, x_unique, y_unique, 'Exy', curr_scaled_fig_gt_folder);
        saveFieldAsHeatmap_v1(Vortgrid * model_spatial_resolution, x_unique, y_unique, 'Vorticity', curr_scaled_fig_gt_folder);
        saveFieldAsHeatmap_v1(StrMaggrid * model_spatial_resolution, x_unique, y_unique, 'Strain Magnitude', curr_scaled_fig_gt_folder);
        saveFieldAsHeatmap_v1(VonMisesgrid * model_spatial_resolution, x_unique, y_unique, 'von Mises Strain', curr_scaled_fig_gt_folder);
        % --------------------------------------------------------------

        % Save KinemaNet strain estimates in raw format (.mat)
        % --------------------------------------------------------------
        curr_raw_kinemanet_folder = fullfile(kinemanet_curr_seq_folder, 'Raw_Data');
        if ~exist(curr_raw_kinemanet_folder, 'dir')
            mkdir(curr_raw_kinemanet_folder);
        end
        save(fullfile(curr_raw_kinemanet_folder, 'strain_fields.mat'), ...
            'Exx_est', 'Eyy_est', 'Exy_est', 'vort_est', 'str_mag_est', 'von_mises_est', 'mask');
        % --------------------------------------------------------------

        % Save KinemaNet strain estimates in png format for visualization
        % --------------------------------------------------------------
        curr_fig_kinemanet_folder = fullfile(kinemanet_curr_seq_folder, 'Figures');
        if ~exist(curr_fig_kinemanet_folder, 'dir') 
            mkdir(curr_fig_kinemanet_folder);
        end
        saveFieldAsHeatmap(Exx_est, x_unique, y_unique, 'E_{xx} estimate', 'Exx estimate', curr_fig_kinemanet_folder);
        saveFieldAsHeatmap(Eyy_est, x_unique, y_unique, 'E_{yy} estimate', 'Eyy estimate', curr_fig_kinemanet_folder);
        saveFieldAsHeatmap(Exy_est, x_unique, y_unique, 'E_{xy} estimate', 'Exy estimate', curr_fig_kinemanet_folder);
        saveFieldAsHeatmap(vort_est, x_unique, y_unique, 'Vorticity estimate', 'Vorticity estimate', curr_fig_kinemanet_folder);
        saveFieldAsHeatmap(str_mag_est, x_unique, y_unique, 'Strain Magnitude estimate', 'Strain Magnitude estimate', curr_fig_kinemanet_folder);
        saveFieldAsHeatmap(von_mises_est, x_unique, y_unique, 'von Mises Strain estimate', 'von Mises Strain estimate', curr_fig_kinemanet_folder);
        saveFieldAsHeatmap(mask, x_unique, y_unique, 'mask', 'mask', curr_fig_kinemanet_folder);
        % --------------------------------------------------------------

        % Save scaled KinemaNet strain estimates in png format for visualization
        curr_scaled_fig_kinemanet_folder = fullfile(kinemanet_curr_seq_folder, 'Scaled_Figures');
        if ~exist(curr_scaled_fig_kinemanet_folder, 'dir')
            mkdir(curr_scaled_fig_kinemanet_folder);
        end
        saveFieldAsHeatmap_v1(Exx_est * model_spatial_resolution, x_unique, y_unique, 'Exx', curr_scaled_fig_kinemanet_folder);
        saveFieldAsHeatmap_v1(Eyy_est * model_spatial_resolution, x_unique, y_unique, 'Eyy', curr_scaled_fig_kinemanet_folder);
        saveFieldAsHeatmap_v1(Exy_est * model_spatial_resolution, x_unique, y_unique, 'Exy', curr_scaled_fig_kinemanet_folder);
        saveFieldAsHeatmap_v1(vort_est * model_spatial_resolution, x_unique, y_unique, 'Vorticity', curr_scaled_fig_kinemanet_folder);
        saveFieldAsHeatmap_v1(str_mag_est * model_spatial_resolution, x_unique, y_unique, 'Strain Magnitude', curr_scaled_fig_kinemanet_folder);
        saveFieldAsHeatmap_v1(von_mises_est * model_spatial_resolution, x_unique, y_unique, 'von Mises Strain', curr_scaled_fig_kinemanet_folder);
        % --------------------------------------------------------------

        % Estimate L2 error between GT and KinemaNet estimates
        % --------------------------------------------------------------
        mask_exx = ~isnan(Exx_est) & ~isnan(Exxgrid);
        mask_eyy = ~isnan(Eyy_est) & ~isnan(Eyygrid);
        mask_exy = ~isnan(Exy_est) & ~isnan(Exygrid);
        mask_vort = ~isnan(vort_est) & ~isnan(Vortgrid);
        mask_strmag = ~isnan(str_mag_est) & ~isnan(StrMaggrid);
        mask_vonmises = ~isnan(von_mises_est) & ~isnan(VonMisesgrid);

        if any(mask_exx(:)) && any(mask_eyy(:)) && any(mask_exy(:))
            l2_exx = sqrt(sum((Exx_est(mask_exx) - Exxgrid(mask_exx)).^2, 'all'));
            l2_eyy = sqrt(sum((Eyy_est(mask_eyy) - Eyygrid(mask_eyy)).^2, 'all'));
            l2_exy = sqrt(sum((Exy_est(mask_exy) - Exygrid(mask_exy)).^2, 'all'));
            l2_vort = sqrt(sum((vort_est(mask_vort) - Vortgrid(mask_vort)).^2, 'all'));
            l2_strmag = sqrt(sum((str_mag_est(mask_strmag) - StrMaggrid(mask_strmag)).^2, 'all')); 
            l2_vonmises = sqrt(sum((von_mises_est(mask_vonmises) - VonMisesgrid(mask_vonmises)).^2, 'all'));

            l2_errors(t, :) = [t, l2_exx, l2_eyy, l2_exy, l2_vort, l2_strmag, l2_vonmises];
        end
        % --------------------------------------------------------------
    end

    % Export L2 error statistics
    means = [{'Mean'}, num2cell(mean(l2_errors(:, 2:end), 1, 'omitnan'))];
    stds  = [{'Std'},  num2cell(std(l2_errors(:, 2:end), 0, 1, 'omitnan'))];

    % Convert data to cell array and append mean/std rows
    l2_cells = [num2cell(l2_errors); means; stds];

    % Append mean and std as new rows
    writetable(cell2table(l2_cells, 'VariableNames', ...
        {'t','L2_Exx', 'L2_Eyy', 'L2_Exy', 'L2_Vorticity', 'L2_StrainMag', 'L2_VonMises'}), ...
        fullfile(strcat(kinemanet_root_folder, 'l2_errors.csv')));

end

function [Ugrid, Vgrid, Exxgrid, Eyygrid, Exygrid, Vortgrid, StrMaggrid, VonMisesgrid] = ...
    est_GT_strain_components(data, col_start, no_of_cols, no_of_rows, crop)
    % This function processes COMSOL exports and extracts strain estimates.
    % It is called within femExtractor_v1 to handle the extraction logic.
    
    % Extract column formatted data exported from COMSOL for the current time step
        u = data{:, col_start};
        v = data{:, col_start+1};
        Exx = data{:, col_start+2};
        Eyy = data{:, col_start+3};
        Exy = data{:, col_start+4};
        Vort = data{:, col_start+5};
        Str_mag = data{:, col_start+6};
        VonMiseStr = data{:, col_start+7};
        
        % Reformat all COMSOL deformation and strain components onto regular grid
        Ugrid = flipud(transpose(reshape(u, [no_of_cols, no_of_rows])));
        Vgrid = flipud(transpose(reshape(v, [no_of_cols, no_of_rows])));
        Exxgrid = transpose(reshape(Exx, [no_of_cols, no_of_rows]));
        Eyygrid = flipud(transpose(reshape(Eyy, [no_of_cols, no_of_rows])));
        Exygrid = transpose(reshape(Exy, [no_of_cols, no_of_rows]));
        Vortgrid = transpose(reshape(Vort, [no_of_cols, no_of_rows]));
        StrMaggrid = transpose(reshape(Str_mag, [no_of_cols, no_of_rows]));
        VonMisesgrid = transpose(reshape(VonMiseStr, [no_of_cols, no_of_rows]));

        % Optionally, crop the grids to remove boundary artifacts
        Ugrid = Ugrid(crop+1:end-crop, crop+1:end-crop);
        Vgrid = Vgrid(crop+1:end-crop, crop+1:end-crop);
        Exxgrid = Exxgrid(crop+1:end-crop, crop+1:end-crop);
        Eyygrid = Eyygrid(crop+1:end-crop, crop+1:end-crop);
        Exygrid = Exygrid(crop+1:end-crop, crop+1:end-crop);
        Vortgrid = Vortgrid(crop+1:end-crop, crop+1:end-crop);
        StrMaggrid = StrMaggrid(crop+1:end-crop, crop+1:end-crop);
        VonMisesgrid = VonMisesgrid(crop+1:end-crop, crop+1:end-crop);
end
%% Helper function to write .flo file
function writeFlowFile(flow, filename)
    TAG_FLOAT = 202021.25;
    [h, w, c] = size(flow);
    if c ~= 2
        error('Flow must have two channels (u,v).');
    end

    fid = fopen(filename, 'wb');
    if fid < 0
        error('Cannot open %s for writing.', filename);
    end

    fwrite(fid, TAG_FLOAT, 'float32');
    fwrite(fid, w, 'int32');
    fwrite(fid, h, 'int32');

    % Interleave u and v
    tmp = zeros(h, w * 2, 'single');
    tmp(:, 1:2:end) = flow(:, :, 1); % u
    tmp(:, 2:2:end) = flow(:, :, 2); % v

    % Write data in row-major order
    fwrite(fid, tmp', 'float32');  % transpose to write row-major
    fclose(fid);
end

%% Helper function to save heatmaps
function saveFieldAsHeatmap(Zgrid, x_unique, y_unique, titlename, fieldname, folder)
    figure('Visible','off');

    imagesc(x_unique, y_unique, Zgrid);
    axis image;
    set(gca, 'YDir', 'normal');  
    ax = gca;
    yticks = get(ax, 'YTick');
    if ~isempty(yticks)
        flipped_labels = flip(yticks);
        set(ax, 'YTickLabel', flipped_labels);
    end

    colormap('jet');
    colorbar;
    %title(sprintf('%s heatmap', fieldname));
    title(sprintf('%s', titlename));
    xlabel('x (mm)'); ylabel('y (mm)');
    saveas(gcf, fullfile(folder, [fieldname '.png']));
    close;
end


 function saveFieldAsHeatmap_v1(Zgrid, x_unique, y_unique, fieldname, folder)
     if ~exist(folder, 'dir')
         mkdir(folder);
     end
 
     f = figure('Visible', 'off');
     ax = axes('Parent', f);
 
     imagesc(ax, x_unique, y_unique, Zgrid);
     colormap(ax, jet(500));
     axis(ax, 'image');
     set(gca, 'YDir', 'normal');  
     axis(ax, 'off');
 
     cb = colorbar(ax);
     cb.FontSize = 18;
 
     exportgraphics(f, fullfile(folder, [fieldname '.png']), ...
         'Resolution', 300, ...
         'ContentType', 'image', ...
         'BackgroundColor', 'none');
 
     close(f);
 end
