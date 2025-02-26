function evaluate_rubber
    %FF, 11/16/2024
    
    root = 'D:\RubberTest';
    method_name = 'Rubber_SSTM_sintel+speckle';
    sstm_est_root = fullfile(root, method_name);
    seq_root = fullfile(root, 'Sequences');
    

    % List the subdirectories in each root (seq1, seq2, etc.)
    sstm_est_dirs = dir(sstm_est_root);
    seq_dirs = dir(seq_root);

    % Filter only directories (skip files and '.', '..')
    sstm_est_dirs = sstm_est_dirs([sstm_est_dirs.isdir] & ~startsWith({sstm_est_dirs.name}, '.'));
    seq_dirs = seq_dirs([seq_dirs.isdir] & ~startsWith({seq_dirs.name}, '.'));
    
    % Check that both directories contain the same number of subdirectories

    if length(sstm_est_dirs) ~= length(seq_dirs)
        error('The number of sequence folders in the estimated and ground truth directories must match.');
    end
    fprintf('Total number of sequences =  %d\n', length(seq_dirs));

    results = [];
    handles = elastography();

    which_flow = 1; %1 for first flow estimate b/n I1 and I2, and 2 for second flow estimate b/n I2 and I3
    rec_error = true;
    save_vis_strain = false; %save colormap of gt and estimated strain maps
    save_strain = false; %save gt and estimated strain maps as .mat files

    sigma = 30;
    epsilon = 1e-5;
    bnd_pix = 1;
    debug_flag = 0;
  

    % Iterate through each item in the directory
    for i = 1:length(seq_dirs)
        seq_dir = seq_dirs(i);
        disp(string(seq_dirs(i).name));

        switch which_flow
            case 1 %flow1
                flow_est_path = fullfile(sstm_est_root, seq_dir.name, 'flow0001.flo');
                output_name = 'results_flo1.csv';

            case 2 %flow2
                flow_est_path = fullfile(sstm_est_root, seq_dir.name, 'flow0002.flo');
                output_name = 'results_flo2.csv';

        end

        
        uvest_mat = readFlowFile(flow_est_path);
        uest = squeeze(uvest_mat(:, :, 1));
        vest = squeeze(uvest_mat(:, :, 2));

        if rec_error
            image_files = dir(fullfile(seq_root, seq_dir.name, '*.jpg'));
            % If no .jpg files are found, check for .png files
            if isempty(image_files)
                image_files = dir(fullfile(seq_root, seq_dir.name, '*.png'));
            end

            [~, sorted_idx] = sort({image_files.name});
            image_files = image_files(sorted_idx);

            if which_flow==1
                
                img1 = double(imread(fullfile(seq_root, seq_dir.name, image_files(1).name)));
                img2 = double(imread(fullfile(seq_root, seq_dir.name, image_files(2).name)));
            else
                img1 = double(imread(fullfile(seq_root, seq_dir.name, image_files(2).name)));
                img2 = double(imread(fullfile(seq_root, seq_dir.name, image_files(3).name)));

            end
            rec_err = reconstruction_error(img1, img2, uest, vest, bnd_pix, debug_flag);
            disp(rec_err);
        end


        if save_vis_strain

            [exx_est, eyy_est, exy_est, ~, ~] = handles.strain_from_uv_flow(uest, vest, sigma, epsilon);

            %save estimated strain and flow maps
            est_strain_path = fullfile(sstm_est_root, seq_dir.name);

            save_colormap_of_elastography_maps(est_strain_path, exx_est, 'Exx.png');
            save_colormap_of_elastography_maps(est_strain_path, eyy_est, 'Eyy.png');
            save_colormap_of_elastography_maps(est_strain_path, exy_est, 'Exy.png');

            save_colormap_of_elastography_maps(est_strain_path, uest, 'flow_u1.png');
            save_colormap_of_elastography_maps(est_strain_path, vest, 'flow_v1.png');

        end

        if save_strain
            %save estimated strain maps
            [exx_est, eyy_est, exy_est, ~, ~] = handles.strain_from_uv_flow(uest, vest, sigma, epsilon);
            est_strain_path = fullfile(sstm_est_root, seq_dir.name);

            save_elastography_maps_as_mat_file(est_strain_path, exx_est, 'Exx.mat');
            save_elastography_maps_as_mat_file(est_strain_path, eyy_est, 'Eyy.mat');
            save_elastography_maps_as_mat_file(est_strain_path, exy_est, 'Exy.mat');

        end

        
        results = [results; {seq_dir.name, rec_err }];

    end
    
    output_name = strcat(method_name, output_name);
    % Write results to CSV file
    headers = {'Seq', 'recErr'};
    results_table = cell2table(results, 'VariableNames', headers);
    writetable(results_table, fullfile(root,output_name));

    disp('CSV result saved!!!');
end
