function evaluate_rubber
    %
    % This script evaluates the accuracy of KinemaNet's optical flow estimates
    % on the experimental rubber dataset using reconstruction error metric.
    %
    % @authors: Fisseha A. Ferede, and Madhusudhanan Balasubramanian
    % Computational Ocularscience Lab,
    % The University of Memphis
    % Date: 11/16/2024
    %

    % Input parameters
    % ----------------------------------------------------------------------
    dataset_root = 'C:\Users\mblsbrmn\OneDrive - The University of Memphis\Lab\Members\Fisseha\Publications\Elastography\Complete Dataset';
    results_root = 'C:\Users\mblsbrmn\OneDrive - The University of Memphis\Lab\Members\Fisseha\Publications\Elastography\Results';
    study_dataset = 'Rubber_Exp_Specimens';
    method_name = 'KinemaNet';
    %
    which_flow = 1; %1 for first flow estimate b/n I1 and I2, and 2 for second flow estimate b/n I2 and I3
    %
    bnd_pix = 1;
    debug_flag = 0;
    % ----------------------------------------------------------------------
    
    % Initialize input and output variables
    % ----------------------------------------------------------------------
    % Folder with experimental sequences of rubber specimens undergoing uniaxial stress-strain testing
    data_exp_root_folder = fullfile(dataset_root, study_dataset, 'Exp_Sequences');
    if ~exist(data_exp_root_folder, 'dir')
        mkdir(data_exp_root_folder);
    end
    %
    % Folder to store KinemaNet deformation (flow) estimates in .flo format and their visualization
    kinemanet_root_folder = fullfile(results_root, study_dataset, method_name);
    if ~exist(kinemanet_root_folder, 'dir')
        mkdir(kinemanet_root_folder);
    end
    % -----------------------------------------------------------------------
    
    % Check if the KinemaNet results exist (data_exp_root_folder) for all data sequences (data_exp_root_folder)
    % -------------------------------------------------------
    data_seq_dirs = dir(data_exp_root_folder);
    kinemat_seq_dirs = dir(kinemanet_root_folder);
    
    % Filter only directories (skip files and '.', '..' folders)
    kinemat_seq_dirs = kinemat_seq_dirs([kinemat_seq_dirs.isdir] & ~startsWith({kinemat_seq_dirs.name}, '.'));
    data_seq_dirs = data_seq_dirs([data_seq_dirs.isdir] & ~startsWith({data_seq_dirs.name}, '.'));

    % Check that
    if length(kinemat_seq_dirs) ~= length(data_seq_dirs)
        error('The number of sequence folders in data folder and KinemaNet results folder must match.');
    end
    fprintf('Total number of sequences =  %d\n', length(data_seq_dirs));
    % -------------------------------------------------------

    % Evaluate KinemaNet deformation estimates using a reconstruction error metric for each experimental sequence
    % -----------------------------------------------------------------------
    results = [];
    for i = 1:length(data_seq_dirs)
        data_curr_seq_folder = data_seq_dirs(i);
        disp(string(data_curr_seq_folder.name));

        switch which_flow
            case 1 %flow1
                flow_est_path = fullfile(kinemanet_root_folder, data_curr_seq_folder.name, 'flow0001.flo');
                output_name = 'results_flo1.csv';

            case 2 %flow2
                flow_est_path = fullfile(kinemanet_root_folder, data_curr_seq_folder.name, 'flow0002.flo');
                output_name = 'results_flo2.csv';

        end
        
        uvest_mat = readFlowFile(flow_est_path);
        uest = squeeze(uvest_mat(:, :, 1));
        vest = squeeze(uvest_mat(:, :, 2));

        % Estimate reconstruction error
        % --------------------------------------------------------
        image_files = dir(fullfile(data_exp_root_folder, data_curr_seq_folder.name, '*.jpg'));
        % If no .jpg files are found, check for .png files
        if isempty(image_files)
            image_files = dir(fullfile(data_exp_root_folder, data_curr_seq_folder.name, '*.png'));
        end

        [~, sorted_idx] = sort({image_files.name});
        image_files = image_files(sorted_idx);

        if which_flow==1
            img1 = double(imread(fullfile(data_exp_root_folder, data_curr_seq_folder.name, image_files(1).name)));
            img2 = double(imread(fullfile(data_exp_root_folder, data_curr_seq_folder.name, image_files(2).name)));
        else
            img1 = double(imread(fullfile(data_exp_root_folder, data_curr_seq_folder.name, image_files(2).name)));
            img2 = double(imread(fullfile(data_exp_root_folder, data_curr_seq_folder.name, image_files(3).name)));

        end
        rec_err = reconstruction_error(img1, img2, uest, vest, bnd_pix, debug_flag);
        disp(rec_err);
        % ---------------------------------------------------------

        results = [results; {data_curr_seq_folder.name, rec_err }];
    end
    
    % Write results to CSV file
    output_name = strcat(method_name, '_', output_name);
    headers = {'Seq', 'recErr'};
    results_table = cell2table(results, 'VariableNames', headers);

    % Update the table with summary statistics
    num_cols = width(results_table);
    
    % Calculate statistics for columns 2 to end
    stats = varfun(@(x) [mean(x), std(x), median(x), range(x)], results_table(:, 2:num_cols));
    stats_mat = table2array(stats);

    % Create a new table row for each statistic
    mean_row = [{'Mean'}, num2cell(stats_mat(1:4:end))];
    std_row = [{'Std Dev'}, num2cell(stats_mat(2:4:end))];
    median_row = [{'Median'}, num2cell(stats_mat(3:4:end))];
    range_row = [{'Range'}, num2cell(stats_mat(4:4:end))];
    
    %Update the results array with summary statistics
    stats_headers = {'Summary Stats', 'recErr'};
    results = [results; stats_headers]; %adding header for easier reading
    results = [results; mean_row];
    results = [results; std_row];
    results = [results; median_row];
    results = [results; range_row];
    results_table = cell2table(results, 'VariableNames', headers);

    writetable(results_table, fullfile(kinemanet_root_folder, output_name));

    disp('CSV result saved!!!');
end
