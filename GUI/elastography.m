function handles = elastography
    handles.strain_from_uv_flow = @strain_from_uv_flow;
    handles.vorticity_from_uv_flow = @vorticity_from_uv_flow;
    handles.vonMissesCoefficient = @vonMissesCoefficient;
    handles.maxShearStrain = @maxShearStrain;
end

function [exx, eyy, exy, euy, evx, mag] = strain_from_uv_flow(u, v, sigma, k_size)
    %FF, October 2023
    %Computes normal and axial strains from optical flow fields.
    %Args:
        %u: optical flow along x
        %v: optical flow along y
        %kx: finite difference kernel along x 
        %ky: finite difference kernel along y 
        %mask: mask applied to capture retinal optic disk 
    %Output:
        %exx: normal strain along x
        %eyy: normal strain along y
        %exy: shear strain
        %mag: magnitude of strain
   [exx, euy] = gaussgradient(u, sigma, k_size);   
   [evx, eyy] = gaussgradient(v, sigma, k_size);      

   exy = 0.5*(euy + evx);
   % exy = exy .* mask;
   mag = sqrt(exx.^2 + eyy.^2 + 2*exy.^2);
end

function [w] = vorticity_from_uv_flow(u, v, sigma, k_size)

    %FF, October 2023

    %Computes normal and axial strains from optical flow fields.
    %Args:
        %u: optical flow along x
        %v: optical flow along y
        %kx: finite difference kernel along x 
        %ky: finite difference kernel along y 
        %mask: mask applied to capture retinal optic disk 
    %Output:
        %w: vorticity vector along z

    [~, euy] = gaussgradient(u, sigma, k_size);   
    [evx, ~] = gaussgradient(v, sigma, k_size); 
   % wvx = convn(v,kx, 'same');
    wvx = evx;
    % wvx = wvx.* mask;
    %wuy = convn(u,ky, 'same');
    wuy = euy;
    % wuy = wuy.* mask;
    w = wvx - wuy;
end

function coff = vonMissesCoefficient(u, v, sigma, k_size)

    [exx, eyy, exy, ~, ~, ~] = strain_from_uv_flow(u, v, sigma, k_size);    
    coff = sqrt(exx.^2 + eyy.^2 - exx.*eyy + 3*exy.^2);

end

function maxshear = maxShearStrain(u, v, sigma, k_size)
    [exx, eyy, exy, ~, ~, ~] = strain_from_uv_flow(u, v, sigma, k_size);
    maxshear = sqrt(1/4*(exx-eyy).^2 + exy.^2);
end
