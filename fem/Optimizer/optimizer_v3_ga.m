clear; clc;

root_folder = 'G7M1_Final_Results_v3_cubic_noclip_psurf';
n_timesteps = 30;

addpath('D:\FEM\Optimizer');

% GA parameters
nvars = 2;  % number of variables: sigma and k
lb = [1, 1];    % lower bounds for [sigma, k]
ub = [50, 50];  % upper bounds for [sigma, k]

% GA options
options = optimoptions('ga', ...
    'Display','iter', ...
    'PopulationSize', 50, ...
    'MaxGenerations', 100, ...
    'UseParallel', true);  % optional: use parallel if you have Parallel Toolbox

% Run GA
[x_opt, fval] = ga(@(x) loss_wrapper(x, root_folder, n_timesteps), nvars, [], [], [], [], lb, ub, [], options);

% Round k to odd integer after GA
best_sigma = x_opt(1);
best_k = round_to_odd(x_opt(2));

[~, opt_diff_exx, opt_diff_eyy, opt_diff_exy] = compute_loss(best_sigma, best_k, root_folder, n_timesteps);

fprintf('Optimal sigma = %.3f, k = %d with loss = %.6f\n', best_sigma, best_k, fval);
fprintf('Exx = %.6f, Eyy = %.6f, Exy = %.6f\n', opt_diff_exx, opt_diff_eyy, opt_diff_exy);

% ======================= Wrapper Function ==========================
function loss = loss_wrapper(x, root_folder, n_timesteps)
    sigma = x(1);
    k = round_to_odd(x(2));  % enforce odd integer
    [loss, ~, ~, ~] = compute_loss(sigma, k, root_folder, n_timesteps);
end

% ======================= Force Odd Integer for k ===================
function odd_k = round_to_odd(k)
    k = max(1, round(k));  % round and ensure >= 1
    if mod(k, 2) == 0
        odd_k = k + 1;
    else
        odd_k = k;
    end
end

% ======================= Loss Function =============================
function [loss, total_exx, total_eyy, total_exy] = compute_loss(sigma, k, root_folder, n_timesteps)
    total_loss = 0;
    total_exx = 0;
    total_eyy = 0;
    total_exy = 0;
    count = 0;

    for t = 1:n_timesteps-1
        t_folder = fullfile(root_folder, num2str(t));

        strain_file = fullfile(t_folder, 'strain_fields.mat');
        if ~isfile(strain_file)
            fprintf('Missing strain_fields.mat at time %d, skipping...\n', t);
            continue;
        end

        S = load(strain_file);
        Exx_gt = S.Exxgrid;
        Eyy_gt = S.Eyygrid;
        Exy_gt = S.Exygrid;

        flo_file = fullfile(t_folder, sprintf('flow_%02d.flo', t));
        if ~isfile(flo_file)
            fprintf('Missing flow file at time %d, skipping...\n', t);
            continue;
        end

        [u, v] = readFlowFile(flo_file);

        handles = elastography();
        [Exx_est, Eyy_est, Exy_est, ~, ~, ~] = handles.strain_from_uv_flow(u, flipud(v), sigma, k);

        mask_exx = ~isnan(Exx_est) & ~isnan(Exx_gt);
        mask_eyy = ~isnan(Eyy_est) & ~isnan(Eyy_gt);
        mask_exy = ~isnan(Exy_est) & ~isnan(Exy_gt);

        if ~any(mask_exx(:)) || ~any(mask_eyy(:)) || ~any(mask_exy(:))
            continue;
        end

        diff_exx = sqrt(sum((Exx_est(mask_exx) - Exx_gt(mask_exx)).^2, 'all'));
        diff_eyy = sqrt(sum((Eyy_est(mask_eyy) - Eyy_gt(mask_eyy)).^2, 'all'));
        diff_exy = sqrt(sum((Exy_est(mask_exy) - Exy_gt(mask_exy)).^2, 'all'));

        mse = diff_exx + diff_eyy + diff_exy;

        total_loss = total_loss + mse;
        total_exx = total_exx + diff_exx;
        total_eyy = total_eyy + diff_eyy;
        total_exy = total_exy + diff_exy;

        count = count + 1;
    end

    if count == 0
        loss = inf;
    else
        loss = total_loss / count;
        total_exx = total_exx / count;
        total_eyy = total_eyy / count;
        total_exy = total_exy / count;
    end
end
