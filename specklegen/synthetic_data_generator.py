# -*- coding: utf-8 -*-
"""
Created on Fri Sep 13 12:30:13 2024

@author: Fisseha A. Ferede
email: fissehaad[at]gmail.com
"""

import numpy as np
import cv2
import random
import argparse
#import os.path as osp
#from glob import glob
import os
import matplotlib.pyplot as plt
import gstools as gs


"""
  Ellipses with gradient fill
"""
def speckle_pattern_generator(dimensions):
    """
    Generate random speckle patterns.
    
    Parameters:
    dimensions: [int w, int h]: two integer inputs representing the width and height of the reference 
    speckle pattern to be generated.
    
    Returns:
    np.ndarray: A grayscale image (2D NumPy array of dtype uint8) containing the generated speckle pattern.
    """
    # Image dimensions
    width, height = dimensions
    width = 2 * width
    height = 2 * height

    # Create a black background
    image = np.zeros((height, width), dtype=np.uint8)

    
    num_ellipses = random.randint(9000, 11000)

    for _ in range(num_ellipses):
        # Random center location of the ellipse
        center_x = random.randint(0, width - 1)
        center_y = random.randint(0, height - 1)

        # Random axis lengths (major and minor)
        axis_length = (random.randint(7, 30), random.randint(7, 30))

        # Random angle of rotation
        angle = random.randint(0, 180)

        # Random grayscale intensity range (for the gradient)
        min_intensity = random.randint(15, 100)
        max_intensity = random.randint(min_intensity+20 , 255)

        # Create random gradient center for intensity within or near the ellipse
        gradient_center_x = random.randint(center_x - axis_length[0], center_x + axis_length[0])
        gradient_center_y = random.randint(center_y - axis_length[1], center_y + axis_length[1])

        # Create gradient for the ellipse
        Y, X = np.ogrid[:height, :width]
        distance_from_center = np.sqrt((X - gradient_center_x) ** 2 + (Y - gradient_center_y) ** 2)

        # Define the maximum distance for the gradient effect
        max_distance = np.sqrt(axis_length[0] ** 2 + axis_length[1] ** 2)

        # Create gradient between min_intensity and max_intensity
        gradient = min_intensity + (1 - distance_from_center / max_distance) * (max_intensity - min_intensity)
        gradient = np.clip(gradient, min_intensity, max_intensity).astype(np.uint8)

        # Create an elliptical mask
        mask = np.zeros((height, width), dtype=np.uint8)
        thickness = -1  # Fully filled ellipse
        cv2.ellipse(mask, (center_x, center_y), axis_length, angle, 0, 360, 255, thickness)

        # Apply the gradient only within the ellipse
        image[mask == 255] = gradient[mask == 255]

    # Blur the image to smooth the pattern
    blurred_image = cv2.GaussianBlur(image, (5, 5), 0)
  

    return blurred_image


def write_flo(filename, u, v):
    """
    Write optical flow to a .flo file.
    
    Parameters:
    filename (str): Name of the .flo file to save.
    u (np.ndarray): Horizontal displacement (u) field.
    v (np.ndarray): Vertical displacement (v) field.
    """
    # Verify that u and v have the same shape
    assert u.shape == v.shape, "The shape of u and v must be the same."

    # Get the height and width of the displacement fields
    height, width = u.shape

    # Create the .flo file and write the magic number, width, and height
    with open(filename, 'wb') as f:
        # Write the magic number (float32)
        f.write(np.array([202021.25], dtype=np.float32).tobytes())
        
        # Write width and height (int32)
        f.write(np.array([width, height], dtype=np.int32).tobytes())
        
        # Interleave u and v and write the displacement field (float32)
        uv = np.stack((u, v), axis=2)  # Combine u and v into a 3D array
        uv = uv.astype(np.float32)
        f.write(uv.tobytes())
        
def warp_image_with_flow(image, u, v):
    """
    Warp an image using an optical flow field (u, v).
    
    Parameters:
    image (np.ndarray): The input image to warp.
    u (np.ndarray): Horizontal displacement field (flow in x-direction).
    v (np.ndarray): Vertical displacement field (flow in y-direction).
    
    Returns:
    np.ndarray: Warped image.
    """
    # Verify that the displacement field matches the image dimensions
    assert u.shape == v.shape == image.shape[:2], "Flow field dimensions must match image dimensions."

    # Get image dimensions
    height, width = u.shape

    # Create a grid of coordinates corresponding to the image's pixels
    x, y = np.meshgrid(np.arange(width), np.arange(height))

    # Add the flow field to the pixel coordinates
    map_x = (x - u).astype(np.float32)
    map_y = (y - v).astype(np.float32)

    # Warp the image using remap with bilinear interpolation
    warped_image = cv2.remap(image, map_x, map_y, interpolation=cv2.INTER_LINEAR, borderMode=cv2.BORDER_CONSTANT, borderValue=0)

    return warped_image



def random_deformation_pattern(dimensions, scales):
    """
    Generate two independent spatial random fields (u and v components)
    with randomly selected parameters, including the generator type.

    Parameters:
    - dimensions: tuple, (height, width) of the random fields.

    Returns:
    - u_field: 2D ndarray, the generated u component of the random field.
    - v_field: 2D ndarray, the generated v component of the random field.
    """
    # List of available generators
    generator_types = ['Fourier', 'RandMeth', 'IncomprRandMeth', 'VectorField', 'VelocityField']
    
    # Randomly select a generator type
    generator_type = np.random.choice(generator_types)
    print(generator_type)

    # Randomly select parameters
    length_scale = np.random.uniform(100, 300)  # Length scale between 100 and 300
    variance = np.random.uniform(0.5, 3)  # Variance between 0.5 and 3
    #mode_no = np.random.randint(16, 65) * 2  # Even number between 32 and 128
    period = np.random.uniform(400, 600)  # Period between 400 and 600
    


    # Create the spatial grid based on the given dimensions
    height, width = dimensions
    height = 2*height
    width = 2*width
    x = np.linspace(0, period, width, endpoint=False)
    y = np.linspace(0, period, height, endpoint=False)

    # Create a Gaussian covariance model for u and v components
    model = gs.Gaussian(dim=2, var=variance, len_scale=length_scale)

    if generator_type in ['IncomprRandMeth', 'VectorField', 'VelocityField']:
        # For these generators, we typically do not set mode_no
        srf = gs.SRF(
            model,
            generator=generator_type,
            period=period
        )
        # Generate the vector field, which will have shape (2, height, width)
        vector_field = srf((x, y), mesh_type="structured")
        u_field = vector_field[0]  # Extract the u component
        v_field = vector_field[1]  # Extract the v component
    else:
        # Fourier generator can use mode_no
        mode_no = np.random.randint(16, 65) * 2  # Even number between 32 and 128

        srf_u = gs.SRF(
            model,
            generator=generator_type,
            period=period,
            mode_no=mode_no
        )
        u_field = srf_u((x, y), mesh_type="structured")

        srf_v = gs.SRF(
            model,
            generator=generator_type,
            period=period,
            mode_no=mode_no
        )
        v_field = srf_v((x, y), mesh_type="structured")
        
    #mag_factor1 = np.random.uniform( 3 / np.abs(np.max(u_field)), 3 / np.abs(np.max(u_field)) + 4)
    #mag_factor2 = np.random.uniform( 3 / np.abs(np.max(v_field)), 3 / np.abs(np.max(v_field)) + 4)
    
    #mag_factor1 = np.random.uniform( 15 / np.abs(np.max(u_field)), 15 / np.abs(np.max(u_field)) + 10)
    #mag_factor2 = np.random.uniform( 15 / np.abs(np.max(v_field)), 15 / np.abs(np.max(v_field)) + 10)
    
    scale_x, scale_y = scales
    
    mag_factor1 = scale_x / np.abs(np.max(u_field))
    mag_factor2 = scale_y / np.abs(np.max(u_field))
        
    u_field = mag_factor1*u_field
    v_field = mag_factor2*v_field
    

    return u_field, v_field  # Return generator type as well

def vizualize_flow(path, u, v):
    plt.figure(figsize=(12, 6))

    plt.subplot(1, 3, 1)
    plt.title('Displacement Field u (x-direction)')
    plt.imshow(u, cmap='jet')
    plt.colorbar()
    
    plt.subplot(1, 3, 2)
    plt.title('Displacement Field v (y-direction)')
    plt.imshow(v, cmap='jet')
    plt.colorbar()
    
    plt.subplot(1, 3, 3)
    plt.title('Displacement Field magnitude ')
    
    uu = (v**2 + u**2)
    
    plt.imshow(uu, cmap='jet')
    plt.colorbar()
    plt.tight_layout()
    plt.savefig(path)
    plt.close()

def data_generator(output_path, number_of_sequences, seq_length, output_dimension, scales):
    
    h, w = output_dimension
        
    h1 = h - h // 2 #work on twice the image size and crop h,w around the center
    h2 = h + h // 2
    
    w1 = w - w // 2
    w2 = w + w // 2
    
    for i in range(number_of_sequences):
          
        
        image1 = speckle_pattern_generator(output_dimension) #generate speckle pattern
        u1, v1 = random_deformation_pattern(output_dimension, scales) #generate random deformation field
        image2 = warp_image_with_flow(image1, u1, v1)
        
        
        image_output_dir = os.path.join(output_path, 'Sequences', 'Seq_%03d' % i)
        if not os.path.exists(image_output_dir):
            os.makedirs(image_output_dir)
        
        flow_output_dir = os.path.join(output_path, 'Flow', 'Seq_%03d' % i)
        if not os.path.exists(flow_output_dir):
            os.makedirs(flow_output_dir)
            
        flow_vis_output_dir = os.path.join(output_path, 'Flow_vis', 'Seq_%03d' % i)
        if not os.path.exists(flow_vis_output_dir):
            os.makedirs(flow_vis_output_dir)
        
        print(image_output_dir)
        
        
        cv2.imwrite(os.path.join(image_output_dir, 'frame%03d.png' % 1), image1[h1:h2, w1:w2]) #save image1 (speckle pattern)
        cv2.imwrite(os.path.join(image_output_dir, 'frame%03d.png' % 2), image2[h1:h2, w1:w2])
        
        write_flo(os.path.join(flow_output_dir, 'flow%03d.flo' % 1), u1[h1:h2, w1:w2], v1[h1:h2, w1:w2]) #flow 1
        vizualize_flow(os.path.join(flow_vis_output_dir, 'flow%03d.png' % 1), u1[h1:h2, w1:w2], v1[h1:h2, w1:w2])
        
        
        u, v = u1, v1
        image = image2
        #for more than two frame cases add some random incremental flows
        for j in range (2, seq_length, 1):
            #u1, v1 = random_deformation_pattern(output_dimension)
            #u = u + 0.2*u1
            #v = v + 0.2*v1
            
            image = warp_image_with_flow(image, u, v)
            
            cv2.imwrite(os.path.join(image_output_dir, 'frame%03d.png' % (j+1) ), image[h1:h2, w1:w2])
            write_flo(os.path.join(flow_output_dir, 'flow%03d.flo' % j), u[h1:h2, w1:w2], v[h1:h2, w1:w2])
            vizualize_flow(os.path.join(flow_vis_output_dir, 'flow%03d.png' % j), u[h1:h2, w1:w2], v[h1:h2, w1:w2])
    
def set_seed(seed):
    random.seed(seed)
    np.random.seed(seed)

def main():
    # Create argument parser
    parser = argparse.ArgumentParser(description="A script that generates random multiple frame speckle pattern sequences, ground truth flow")
    
    # Add arguments
    parser.add_argument('--output_path', type=str, help="Path to save sequences and gt flow", required=True)
    parser.add_argument('--seq_number', type=int, help="Number of sequences to generate", required=True)
    parser.add_argument('--seq_length', type=int, help="Number of frames per sequence", required=True)
    parser.add_argument('--dimensions', type=int, nargs=2, help="Output image dimensions as height and width", required=True)
    parser.add_argument('--scales', type=int, nargs=2, default=[10, 10], help="max flow magnitude for u and v respectively (default: [10, 10])", required=False)
    # Parse the arguments
    args = parser.parse_args()
    
    #set_seed(1000)    
    data_generator(args.output_path, args.seq_number, args.seq_length, args.dimensions, args.scales)
    

if __name__ == "__main__":
    main()
