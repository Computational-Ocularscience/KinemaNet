%clear; clc;

root_folder = 'G7M1_Final_Results_v3_cubic_noclip_psurf';
n_timesteps = 30;

% Define search space for sigma and k (adjust as needed)
sigma_vals = linspace(2.95, 25, 15);
k_vals = 3:2:17;

% Initialize best params tracking
best_loss = inf;
best_sigma = 0;
best_k = 0;


addpath('D:\FEM\Optimizer');

for sigma = sigma_vals
    for k = k_vals
        total_loss = 0;
        count = 0;

        for t = 1:n_timesteps-1
            t_folder = fullfile(root_folder, num2str(t));
            
            % Load strain fields
            strain_file = fullfile(t_folder, 'strain_fields.mat');
            if ~isfile(strain_file)
                fprintf('Missing strain_fields.mat at time %d, skipping...\n', t);
                continue;
            end
            S = load(strain_file);
            Exx_gt = S.Exxgrid;
            Eyy_gt = S.Eyygrid;
            Exy_gt = S.Exygrid;

            % Load flow file
            flo_file = fullfile(t_folder, sprintf('flow_%02d.flo', t));

            if ~isfile(flo_file)
                fprintf('Missing flow file at time %d, skipping...\n', t);
                continue;
            end
            [u, v] = readFlowFile(flo_file); % You need to have this function
            


            % Compute estimated strains
            handles = elastography();
  
            [Exx_est, Eyy_est, Exy_est, ~, ~, ~] = handles.strain_from_uv_flow(u, flipud(v), sigma, k);

            mask_exx = ~isnan(Exx_est) & ~isnan(Exx_gt);
            mask_eyy = ~isnan(Eyy_est) & ~isnan(Eyy_gt);
            mask_exy = ~isnan(Exy_est) & ~isnan(Exy_gt);

            % Compute MSE loss for this time point
            diff_exx = sqrt(sum((Exx_est(mask_exx) - Exx_gt(mask_exx)).^2, 'all'));
            diff_eyy = sqrt(sum((Eyy_est(mask_eyy) - Eyy_gt(mask_eyy)).^2, 'all'));
            diff_exy = sqrt(sum((Exy_est(mask_exy) - Exy_gt(mask_exy)).^2, 'all'));
            

            %mse = mean(diff_exx(:).^2 + diff_eyy(:).^2 + diff_exy(:).^2);
            mse = diff_exx + diff_exy + diff_eyy;

            total_loss = total_loss + mse;
            count = count + 1;
        end

        % Average loss over all time points considered
        avg_loss = total_loss / max(count, 1);

        fprintf('sigma=%.2f, k=%d, avg_loss=%.6f\n', sigma, k, avg_loss);

        if avg_loss < best_loss
            best_loss = avg_loss;
            best_sigma = sigma;
            best_k = k;
            opt_diff_exx = diff_exx;
            opt_diff_exy = diff_exy;
            opt_diff_eyy = diff_eyy;
        end
    end
end

fprintf('Optimal sigma = %.3f, k = %d with loss = %.6f\n', best_sigma, best_k, best_loss);
fprintf('Exx = %.6f, Eyy = %.6f , Exy= %.6f\n', opt_diff_exx, opt_diff_eyy, opt_diff_exy);

