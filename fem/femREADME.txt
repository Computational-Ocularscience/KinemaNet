README fem
Fisseha Ferede: fissehaad@gmail.com
 6/42025
======================

Part 1
======
To extract kinematic descriptor outputs from the COMSOL simulation results including u, v, Exx, Eyy, Exy, Vorticity, von Mises strain, and Strain magnitude,
run femExtractor_v1.m. This program expects csv output file for each material model from COMSOL which is provided in the dataset section. E.g. 'G7M1_Material_Model_Results.csv' for the Dumbbell Shaped rubber.

The program has the following flags that determines what outputs to export
%Flags
export_estimates = true; %set to 'true' to export KinemaNet strain estimates for given u and v from material modeling
export_simulation_results = true; %set to 'true' to export material modeling results as colormap and .mat file
export_l2_error = true; %set to true to get error l2 norm error between the above two

The outputs are stored in 'G7M1_Material_Model_Results' folder

Part 2 (optional)
To get optimimal k and sigma values for our KinemaNet that minimizes the l2 error against COMSOL simulation result, point root folder in Optimimizer/optimizer_v2_fminsearch.m to a path where your outputs from part I are stored (make sure is export_estimates = true; in part 1), e.g. ''G9M1_Material_Model_Results'
