function evaluate_speckle

    %Fisseha F., 11/16/2024
    root = 'SpeckleReportedTestSample'; %root directory
    method_name = 'Flow'; %add your method name for evaluation, if not set it to 'Flow' to generate strain estimates from
    %method_name = 'SSTM_estimates'; %Our results
    sstm_est_root = fullfile(root, method_name);%your estimates
    flow_gt_root = fullfile(root, 'Flow');
    seq_root = fullfile(root, 'Sequences');

    % List the subdirectories in each root (seq1, seq2, etc.)
    sstm_est_dirs = dir(sstm_est_root);
    gt_dirs = dir(flow_gt_root);

    % Filter only directories (skip files and '.', '..')
    sstm_est_dirs = sstm_est_dirs([sstm_est_dirs.isdir] & ~startsWith({sstm_est_dirs.name}, '.'));
    gt_dirs = gt_dirs([gt_dirs.isdir] & ~startsWith({gt_dirs.name}, '.'));
    
    % Check that both directories contain the same number of subdirectories
    if length(sstm_est_dirs) ~= length(gt_dirs)
        error('The number of sequence folders in the estimated and ground truth directories must match.');
    end
    fprintf('Total number of sequences =  %d\n', length(gt_dirs));

    results = [];
    handles = elastography();

    %error_type = 3;
    which_flow = 1; %1 for first flow estimate b/n I1 and I2, and 2 for second flowe stimate b/n I2 and I3
    rec_error = false; %compute reconstruction error b/n I1 and warped(I2, Flow)
    save_vis_strain = true; %save colormap of gt and estimated strain maps
    save_strain = true; %save gt and estimated strain maps as .mat files

    %strain magnitude sensitive to the following params
    sigma = 30; 
    epsilon = 1e-6; %determines kernel size
  
    % Iterate through each item in the directory
    for i = 1:length(gt_dirs)
        seq_dir = gt_dirs(i);
        disp(string(gt_dirs(i).name));

        switch which_flow
            case 1 %flow1
                %flow_est_path = fullfile(sstm_est_root, seq_dir.name, 'flow0001.flo');
                flow_gt_path = fullfile(flow_gt_root, seq_dir.name, 'flow001.flo');
                output_name = 'results_flo11.csv';
            case 2 %flow2
                %flow_est_path = fullfile(sstm_est_root, seq_dir.name, 'flow0002.flo');
                flow_gt_path = fullfile(flow_gt_root, seq_dir.name, 'flow002.flo');
                output_name = 'results_flo2.csv';
        end

        uvgt_mat = readFlowFile(flow_gt_path);
        ugt = squeeze(uvgt_mat(:, :, 1));
        vgt = squeeze(uvgt_mat(:, :, 2));
        
        uvest_mat = readFlowFile(flow_gt_path);
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


        [exx_gt, eyy_gt, exy_gt, ~, ~] = handles.strain_from_uv_flow(ugt, vgt, sigma, epsilon);
        [exx_est, eyy_est, exy_est, ~, ~] = handles.strain_from_uv_flow(uest, vest, sigma, epsilon);

        if save_vis_strain
            %save gt strain estimates (based on gt flow)
            [gt_parent_path, ~, ~] = fileparts(flow_gt_root);
            % gt_strain_path = fullfile(gt_parent_path,'Strain_vis' ,seq_dir.name);
            % 
            % save_colormap_of_elastography_maps(gt_strain_path, exx_gt, 'Exx.png');
            % save_colormap_of_elastography_maps(gt_strain_path, eyy_gt, 'Eyy.png');
            % save_colormap_of_elastography_maps(gt_strain_path, exy_gt, 'Exy.png');

            % gt_flow_path = fullfile(gt_parent_path,'Flow_vis__' ,seq_dir.name);
            % save_colormap_of_elastography_maps(gt_flow_path, ugt, 'gt_u1.png');
            % save_colormap_of_elastography_maps(gt_flow_path, vgt, 'gt_v1.png');

            %save estimated strain maps
            est_strain_path = fullfile(sstm_est_root, seq_dir.name);

            save_colormap_of_elastography_maps(est_strain_path, exx_est, 'Exx.png');
            save_colormap_of_elastography_maps(est_strain_path, eyy_est, 'Eyy.png');
            save_colormap_of_elastography_maps(est_strain_path, exy_est, 'Exy.png');

            save_colormap_of_elastography_maps(est_strain_path, uest, 'flow_u1.png');
            save_colormap_of_elastography_maps(est_strain_path, vest, 'flow_v1.png');

        end

        if save_strain
            %save gt strain estimates (based on gt flow)
            [gt_parent_path, ~, ~] = fileparts(flow_gt_root);
            gt_strain_path = fullfile(gt_parent_path, 'Strain_GT' ,seq_dir.name);

            save_elastography_maps_as_mat_file(gt_strain_path, exx_gt, 'Exx.mat');
            save_elastography_maps_as_mat_file(gt_strain_path, eyy_gt, 'Eyy.mat');
            save_elastography_maps_as_mat_file(gt_strain_path, exy_gt, 'Exy.mat');

            %save estimated strain maps
            est_strain_path = fullfile(sstm_est_root, seq_dir.name);

            save_elastography_maps_as_mat_file(est_strain_path, exx_est, 'Exx.mat');
            save_elastography_maps_as_mat_file(est_strain_path, eyy_est, 'Eyy.mat');
            save_elastography_maps_as_mat_file(est_strain_path, exy_est, 'Exy.mat');

        end

        flo_epe = endpointError(uest, vest, ugt, vgt);
        flo_l2 = l2norm(uest, vest, ugt, vgt);
        exx_err = sqrt(sum((exx_est(:) - exx_gt(:)).^2, 'all'));
        eyy_err = sqrt(sum((eyy_est(:) - eyy_gt(:)).^2, 'all'));
        exy_err = sqrt(sum((exy_est(:) - exy_gt(:)).^2, 'all'));

        if rec_error
            results = [results; {seq_dir.name, flo_epe, flo_l2, rec_err, exx_err, eyy_err, exy_err }];
        else
            results = [results; {seq_dir.name, flo_epe, flo_l2, exx_err, eyy_err, exy_err }];
        end

    end
    
    output_name = strcat(method_name, output_name);
    % Write results to CSV file
    %headers = {'Seq', 'floEPE', 'floL2', 'recErr', 'Exx_l2', 'Eyy_l2', 'Exy_l2'};
    if rec_error
         headers = {'Seq', 'floEPE', 'floL2', 'recErr', 'Exx_l2', 'Eyy_l2', 'Exy_l2'};
    else
         headers = {'Seq', 'floEPE', 'floL2', 'Exx_l2', 'Eyy_l2', 'Exy_l2'};
    end
    results_table = cell2table(results, 'VariableNames', headers);
    writetable(results_table, fullfile(root,output_name));

    disp('CSV result saved!!!');
end


%Compute l2 error between the estimate and ground truth flows
function [l2] = l2norm(uest, vest, ugt, vgt)
    l2 = sqrt(sum((ugt - uest).^2 + (vgt - vest).^2, 'all'));
end

% Compute End Point Error (EPE) between estimated and ground truth flows
function [epe] = endpointError(uest, vest, ugt, vgt)
    epe = mean(sqrt((ugt - uest).^2 + (vgt - vest).^2), 'all');
end

