function [error] = reconstruction_error(I1, I2, u_mat, v_mat, bnd_pix, debug_flag)
%
%MB, Oct 27, 2024
%
    %bnd_pix = 1;
    %debug_flag = 1;

    [m, n, c] = size(I1);
    if c > 1
        I1 = rgb2gray(I1);
        I2 = rgb2gray(I2);
    end

    %Reconstruction coordinates
    x_mat = repmat((1 : n), m, 1);
    y_mat = repmat((1 : m)', 1, n);
    x_hat_mat = x_mat + u_mat; %Sampling coordinates
    y_hat_mat = y_mat + v_mat;


    %Reconstruction error
    I1_hat = interp2(I2, x_hat_mat, y_hat_mat, 'linear');
    I1 = I1(bnd_pix:end-bnd_pix+1, bnd_pix:end-bnd_pix+1);
    I1_hat = I1_hat(bnd_pix:end-bnd_pix+1, bnd_pix:end-bnd_pix+1);
    diff_image = I1 - I1_hat;
    valid_pixs = ~isnan(diff_image);
    error = sqrt(innerproduct(diff_image(valid_pixs), diff_image(valid_pixs)));
    
    if debug_flag == 1
        figure; 
        subplot(1, 3, 1); imshow(I1, []); title('I1');
        subplot(1, 3, 2); imshow(I1_hat, []); title('I1_hat');
        subplot(1, 3, 3); imshow(diff_image, []); title('diff_image');
        figure; imshow(I1, []); title('I1');
        figure; imshow(I2, []); title('I2');
        figure; imshow(I1_hat, []); title('I1_hat');
        %figure; imshow(isnan(diff_image), []); title('NaN');
    end

end

function [prod] = innerproduct(mat1, mat2)

    prod = sum(mat1(:) .* mat2(:));

end