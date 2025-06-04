% Filename of the CSV
filename = 'G8M1_Material_Model_Results.csv';  % 
sample_name = filename(1:5); %Assumes the sample name is in the first 5 characters of filename
addpath(genpath('Optimizer'));
% Read the table, skipping the first 9 header rows
opts = detectImportOptions(filename, 'NumHeaderLines', 9);
data = readtable(filename, opts);

%Flags
export_estimates = true; %set to 'true' to export KinemaNet strain estimates for given u and v from material modeling
export_simulation_results = true; %set to 'true' to export material modeling results as colormap and .mat file
export_l2_error = true; %set to true to get error l2 norm error between the above two

% Extract x and y coordinates (first two columns)
x = data{:,1};
y = data{:,2};

% Number of time steps and fields
n_timesteps = 30;  % From t=0 to t=30
fields_per_step = 8;

% Create root output folder
output_root = erase(filename, '.csv');
if ~exist(output_root, 'dir')
    mkdir(output_root);
end

x_unique = unique(x);
y_unique = unique(y);
no_of_rows = length(y_unique);
no_of_cols = length(x_unique);

handles = elastography();

%optimal results using fminsearch optimizer
sigma = 2.986;
k = 15;

% Loop over time steps
for t = 1:n_timesteps-1
    % Create subfolder for current time step
    t_folder = fullfile(output_root, num2str(t));
    if ~exist(t_folder, 'dir')
        mkdir(t_folder);
    end
    disp(t);
    
    % Column index for the current time step
    col_start = 3 + t * fields_per_step;
    
    % Extract fields
    u = data{:, col_start};
    v = data{:, col_start+1};
    Exx = data{:, col_start+2};
    Eyy = data{:, col_start+3};
    Exy = data{:, col_start+4};
    Vort = data{:, col_start+5};
    Str_mag = data{:, col_start+6};
    VonMiseStr = data{:, col_start+7};
    
    
    % Interpolate all fields onto regular grid
    Ugrid = flipud(transpose(reshape(u, [no_of_cols, no_of_rows])));
    Vgrid = flipud(transpose(reshape(v, [no_of_cols, no_of_rows])));
    Exxgrid = transpose(reshape(Exx, [no_of_cols, no_of_rows]));
    Eyygrid = flipud(transpose(reshape(Eyy, [no_of_cols, no_of_rows])));
    Exygrid = transpose(reshape(Exy, [no_of_cols, no_of_rows]));
    Vortgrid = transpose(reshape(Vort, [no_of_cols, no_of_rows]));
    StrMaggrid = transpose(reshape(Str_mag, [no_of_cols, no_of_rows]));
    VonMisesgrid = transpose(reshape(VonMiseStr, [no_of_cols, no_of_rows]));

    crop = 20;
    Ugrid = Ugrid(crop+1:end-crop, crop+1:end-crop);
    Vgrid = Vgrid(crop+1:end-crop, crop+1:end-crop);
    Exxgrid = Exxgrid(crop+1:end-crop, crop+1:end-crop);
    Eyygrid = Eyygrid(crop+1:end-crop, crop+1:end-crop);
    Exygrid = Exygrid(crop+1:end-crop, crop+1:end-crop);
    Vortgrid = Vortgrid(crop+1:end-crop, crop+1:end-crop);
    StrMaggrid = StrMaggrid(crop+1:end-crop, crop+1:end-crop);
    VonMisesgrid = VonMisesgrid(crop+1:end-crop, crop+1:end-crop);

    % Ugrid = 25*Ugrid(crop+1:end-crop, crop+1:end-crop);
    % Vgrid = 25*Vgrid(crop+1:end-crop, crop+1:end-crop);
    % Exxgrid = 25*Exxgrid(crop+1:end-crop, crop+1:end-crop);
    % Eyygrid = 25*Eyygrid(crop+1:end-crop, crop+1:end-crop);
    % Exygrid = 25*Exygrid(crop+1:end-crop, crop+1:end-crop);
    % Vortgrid = 25*Vortgrid(crop+1:end-crop, crop+1:end-crop);
    % StrMaggrid = 25*StrMaggrid(crop+1:end-crop, crop+1:end-crop);
    % VonMisesgrid = 25*VonMisesgrid(crop+1:end-crop, crop+1:end-crop);

    % Save .flo file for u and v
    flo_filename = fullfile(t_folder, sprintf('flow_%02d.flo', t));
    writeFlowFile(cat(3, Ugrid, Vgrid), flo_filename);

    % create mask
    mask = double(~isnan(Ugrid));
    
    [Exx_est, Eyy_est, Exy_est, ~, ~, str_mag_est] = handles.strain_from_uv_flow(Ugrid, flipud(Vgrid), sigma, k);
    [von_mises_est] = handles.vonMissesCoefficient(Ugrid, flipud(Vgrid), sigma, k);
    [vort_est] = handles.vorticity_from_uv_flow(Ugrid, flipud(Vgrid), sigma, k);

    % Save color maps as PNGs
    if export_simulation_results
        % Save strain fields in .mat
        Ugrid(isnan(Ugrid)) = 0;
        Vgrid(isnan(Vgrid)) = 0;
        save(fullfile(t_folder, 'strain_fields.mat'), ...
        'Exxgrid', 'Eyygrid', 'Exygrid', ...
        'Vortgrid', 'StrMaggrid', 'VonMisesgrid', 'mask');
        saveFieldAsHeatmap(Ugrid, x_unique, y_unique, 'u', 'u', t_folder);
        saveFieldAsHeatmap(Vgrid, x_unique, y_unique, 'v', 'v', t_folder);
        saveFieldAsHeatmap(Exxgrid, x_unique, y_unique,  'E_{xx}', 'Exx', t_folder);
        saveFieldAsHeatmap(Eyygrid, x_unique, y_unique,  'E_{yy}', 'Eyy', t_folder);
        saveFieldAsHeatmap(Exygrid, x_unique, y_unique,  'E_{xy}', 'Exy', t_folder);
        saveFieldAsHeatmap(Vortgrid, x_unique, y_unique, 'Vorticity', 'Vorticity', t_folder);
        saveFieldAsHeatmap(StrMaggrid, x_unique, y_unique, 'Strain Magnitude', 'Strain Magnitude', t_folder);
        saveFieldAsHeatmap(VonMisesgrid, x_unique, y_unique, 'von Mises Strain','von Mises Strain', t_folder);
        saveFieldAsHeatmap(mask, x_unique, y_unique, 'mask', 'mask', t_folder);

        % Save strain fields in .mat
        save(fullfile(t_folder, 'strain_fields.mat'), ...
        'Exxgrid', 'Eyygrid', 'Exygrid', ...
        'Vortgrid', 'StrMaggrid', 'VonMisesgrid', 'mask');
    end

    % %Estimated strain components saved in PNGs
    if export_estimates
        saveFieldAsHeatmap(Exx_est, x_unique, y_unique,  'E_{xx} estimate', 'Exx estimate', t_folder);
        saveFieldAsHeatmap(Eyy_est, x_unique, y_unique,  'E_{yy} estimate', 'Eyy estimate', t_folder);
        saveFieldAsHeatmap(Exy_est, x_unique, y_unique,  'E_{xy} estimate', 'Exy estimate', t_folder);
        saveFieldAsHeatmap(vort_est, x_unique, y_unique,  'Vorticity estimate', 'Vorticity estimate', t_folder);
        saveFieldAsHeatmap(str_mag_est, x_unique, y_unique, 'Strain Magnitude estimate', 'Strain Magnitude estimate', t_folder);
        saveFieldAsHeatmap(von_mises_est, x_unique, y_unique, 'von Mises Strain estimate', 'von Mises Strain estimate', t_folder);
    end
    if export_l2_error
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
        
    end 

end

if export_l2_error
    means = [{'Mean'}, num2cell(mean(l2_errors(:, 2:end), 1, 'omitnan'))];
    stds  = [{'Std'},  num2cell(std(l2_errors(:, 2:end), 0, 1, 'omitnan'))];

    % Convert data to cell array and append mean/std rows
    l2_cells = [num2cell(l2_errors); means; stds];

    % Append mean and std as new rows
    writetable(cell2table(l2_cells, 'VariableNames', ...
        {'t','L2_Exx', 'L2_Eyy', 'L2_Exy', 'L2_Vorticity', 'L2_StrainMag', 'L2_VonMises'}), ...
        fullfile(strcat(sample_name, 'l2_errors.csv')));
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


% function saveFieldAsHeatmap(Zgrid, x_unique, y_unique, titlename, fieldname, folder)
%     if ~exist(folder, 'dir')
%         mkdir(folder);
%     end
% 
%     f = figure('Visible', 'off');
%     ax = axes('Parent', f);
% 
%     imagesc(ax, x_unique, y_unique, Zgrid);
%     colormap(ax, jet(500));
%     axis(ax, 'image');
%     set(gca, 'YDir', 'normal');  
%     axis(ax, 'off');
% 
%     cb = colorbar(ax);
%     cb.FontSize = 18;
% 
%     exportgraphics(f, fullfile(folder, [fieldname '.png']), ...
%         'Resolution', 300, ...
%         'ContentType', 'image', ...
%         'BackgroundColor', 'none');
% 
%     close(f);
% end
