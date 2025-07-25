function handles = elastography
    handles.strain_from_uv_flow = @strain_from_uv_flow;
    handles.vorticity_from_uv_flow = @vorticity_from_uv_flow;
    handles.vonMissesCoefficient = @vonMissesCoefficient;
    handles.maxShearStrain = @maxShearStrain;
end

function [exx, eyy, exy, euy, evx, mag] = strain_from_uv_flow(u, v, sigma, epsilon)
    %Fisseha F., October 2023
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
   
   [exx, euy] = gaussgradientV1(u, sigma, epsilon);   
   [evx, eyy] = gaussgradientV1(v, sigma, epsilon);      

   exy = 0.5*(euy + evx);
   % exy = exy .* mask;
   mag = sqrt(exx.^2 + eyy.^2 + 2*exy.^2);
end

function w = vorticity_from_uv_flow(u, v, sigma, epsilon)

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

    [~, euy] = gaussgradientV1(u, sigma, epsilon);   
    [evx, ~] = gaussgradientV1(v, sigma, epsilon); 

    wvx = evx;
    wuy = euy;

    w = wvx - wuy;
end

function coff = vonMissesCoefficient(u, v, sigma, epsilon)

    [exx, eyy, exy, ~, ~, ~] = strain_from_uv_flow(u, v, sigma, epsilon);    
    coff = sqrt(exx.^2 + eyy.^2 - exx.*eyy + 3*exy.^2);

end

function maxshear = maxShearStrain(u, v)
    [exx, eyy, exy, ~, ~, ~] = strain_from_uv_flow(u, v, sigma, epsilon);
    maxshear = sqrt(1/4*(exx-eyy).^2 + exy.^2);
end
