function validate_recon_error
%
%MB, Oct 28, 2024

    %clc;

    %Inputs
    img_extn = 'png';
    data_name = 'Seq_342';
    %data_name = 'Cotton';
    %method_name = 'DIC_est';
    %method_name = 'DIC_fft_0';
    method_name = 'Speckle_test_SSTM-ft-sintel+speckle';
    bnd_pix = 1;
    debug_flag = 1;

    root_folder = 'D:\SpeckleReportedTest/';
    %root_folder = '../../Datasets/Test/';
    data_root_folder = strcat(root_folder, 'Sequences/');
    flo_root_folder = strcat(root_folder, method_name, '/');
    %
    I1_filename = strcat(data_root_folder, '\', data_name, '\', 'frame001.', img_extn);
    I2_filename = strcat(data_root_folder, '\', data_name, '\', 'frame002.', img_extn);
    flo_file = strcat(flo_root_folder, '\', data_name, '\', 'flow0001.flo');

    %Flow field filtering
    I1 = imread(I1_filename);
    I2 = imread(I2_filename);
    if size(I1, 3) > 1
        I1 = double(rgb2gray(I1));
        I2 = double(rgb2gray(I2));
    else
        I1 = double(I1);
        I2 = double(I2);
    end

    %Flow
    uv_mat = readFlowFile(flo_file);
    u_mat = squeeze(uv_mat(:, :, 1));
    v_mat = squeeze(uv_mat(:, :, 2));
    flow_mag_mat = (u_mat.^2 + v_mat.^2).^0.5;
    figure; 
    subplot(1, 3, 1); imshow(u_mat, []); colormap('jet'); colorbar; title('u');
    subplot(1, 3, 2); imshow(v_mat, []); colormap('jet'); colorbar; title('v');
    subplot(1, 3, 3); imshow(flow_mag_mat, []); colormap('jet'); colorbar; title('Flow magnitude');

    error = reconstruction_error(I1, I2, u_mat, v_mat, bnd_pix, debug_flag);
    fprintf('%s: %.4e\n', flo_file, error);
end