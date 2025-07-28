# KinemaNet
The deep learning processing pipeline shared in this repository extracts various kinematic features from non-invasive observations of deforming scenes (image sequences) as described in our paper:
> Fisseha A. Ferede, Madhusudhanan Balasubramanian, [*KinemaNet: Kinematic Descriptors of Deformation of the ONH for Non-invasive Detection of Glaucoma Progression*](https://computational-ocularscience.github.io/kinemanet.github.io/)

This repository contains:
- [KinemaNet](#kinemanet)
  - [I. KinemaNet Architecture](#i-kinemanet-architecture)
  - [II. Flow Estimation Using SSTM](#ii-flow-estimation-using-sstm)
    - [SSTM Installaion Instructions](#sstm-installaion-instructions)
  - [III. Validation Datasets with Known Ground Truths](#iii-validation-datasets-with-known-ground-truths)
    - [A. Synthetic Speckle Sequences](#a-synthetic-speckle-sequences)
    - [B. Computational Model-based Elastic Material Sequences](#b-computational-model-based-elastic-material-sequences)
  - [IV. Software for Generating Validation Datasets](#iv-software-for-generating-validation-datasets)
    - [A. *Specklegen* for Generating Synthetic Deforming Sequence](#a-specklegen-for-generating-synthetic-deforming-sequence)
    - [B. Computational Models of Deforming Elastic Materials](#b-computational-models-of-deforming-elastic-materials)
    - [C. Matlab Programs for Estimating Strain and Kinematic Feature from COMSOL Exports](#c-matlab-programs-for-estimating-strain-and-kinematic-feature-from-comsol-exports)
  - [V. Evaluation](#v-evaluation)
    - [Flow Evaluation](#flow-evaluation)
    - [Strain Evaluation](#strain-evaluation)
  - [VI. GUI for Visualizing Kinematics Descriptors](#vi-gui-for-visualizing-kinematics-descriptors)
  - [VII. Citation](#vii-citation)

## I. KinemaNet Architecture


The pipeline for generating kinematic features and descriptors of a deforming scene is comprised mainly of an optical flow estimation stage, and a strain tensor estimation stage.

<img src="Kinemanet_architecture.png">

## II. Flow Estimation Using SSTM

For deformation estimation in the KinemaNet pipeline, [**SSTM**](https://github.com/Computational-Ocularscience/SSTM), a multi-frame based optical flow estimation model, can be used to estimate pixel-level scene deformation from image sequences.

### SSTM Installaion Instructions
```bash
# Clone SSTM repository
git clone https://github.com/Computational-Ocularscience/SSTM.git
conda env create -f sstm.yml

# Example SSTM usage: To estimate deformation fields of speckle sequences
conda activate sstm
python SSTM/evaluate.py --model=checkpoints/sstm_t++-sintel.pth --dataset=speckle/sequences
```

## III. Validation Datasets with Known Ground Truths

For evaluating the accuracy of model estimates, 1) synthetic deforming sequences were generated with ***known ground truth deformation fields***; and 2) computational material models of deforming rubber specimen were developed where ***ground truth strain tensor*** at each material locations were available.

### A. Synthetic Speckle Sequences

Each sequence in the speckle dataset have a unique baseline frame with 9,000 and 11,000 randomly generated ellipses of varying sizes, with major and minor axes ranging from 7 to 30 pixels. These ellipses are fully filled with random gray scale intensity gradients ranging from 0 to 255. Using a random deformation field that is smooth and known, each subsequent frame in the speckle sequence is generated starting from the baseline frame using a backward warping process. Random deformation fields are generated using [GSTools](https://gmd.copernicus.org/articles/15/3161/2022/), a library which uses covariance model to generate spatial random fields.

We generated a total of 492 multi-frame synthetic speckle sequences and their ground-truth deformation fields using *Specklegen*. This comprised of 342 training sequences and 150 test sequences.  These datasets can be downloaded from the following data repository:
>[https://memphis-sandbox.digital-commons.com/computational-ocularscience-laboratory/1/](https://memphis-sandbox.digital-commons.com/computational-ocularscience-laboratory/1/)

### B. Computational Model-based Elastic Material Sequences

Components of the strain tensors estimated from a computational model of deforming elastic materials with 4 distinct geometries namely a) rectangular rubber specimen, b) dumbbell rubber specimen, c) rubber specimen with a single circular punch, and d) rubber speciment with two circular punches were used for validating KinemaNet strain calculations.

Computational models of elastic deformation were run for a duration of 30 seconds and the following strain and kinematic features were exported at a sampling interval of 1 seconds: a) normal strains $E_{xx}$ and $E_{yy}$; b) shear strain $E_{xy}$; c) vorticity; d) strain magnitude $e_m$; and e) von Mises strain $\epsilon_{vm}$. These strain and kinmetic estimates for 30 seconds (1 sec sampling interval) for the four deforming elastic specimen can be downloaded from the following data repository:
>[https://memphis-sandbox.digital-commons.com/computational-ocularscience-laboratory/1/](https://memphis-sandbox.digital-commons.com/computational-ocularscience-laboratory/1/)


## IV. Software for Generating Validation Datasets

### A. *Specklegen* for Generating Synthetic Deforming Sequence

Specklegen is available either directly in this repository as **specklegen\synthetic_data_generator.py** and can be used as:
```
python specklegen\synthetic_data_generator.py
   --output_path=<output_path>
   --seq_number=5
   --seq_length=7
   --dimensions 512 512
   --scales 5 7
```
where, 
  - `output_path` defines the directory where generated image sequences, ground-truth flows and flow vizualizations will be saved.  
  - `seq_number` and `seq_length` represent the number of random speckle pattern sequences to generate and the number of frames per each sequence, respectively.
  - `dimensions` argument specifies the height and width of the output speckle patterns. 

Alternatively, [Specklegen](https://pypi.org/project/specklegen/0.1.7/) is available as an independent package in PyPI which can be installed and used as follows.

**Specklegen PyPI Package Installation**:
```bash
conda create -n specklegen_env python=3.8
pip install specklegen==0.1.7
```

**Specklegen PyPI Package Example:**
```python
from specklegen.synthetic_data_generator import data_generator

# Define arguments
output_path = "./output" #output path
seq_number = 10 #number of sequences 
seq_length = 3 #number of frames per sequence
dimensions = (512, 512)  #output flow and sequence dimensions 
scales = (5, 7)  #max flow magnitudes of u and v fields, respectively

# Call function
data_generator(output_path, seq_number, seq_length, dimensions, scales)
```

**Specklegen Output Format:**

Specklegen generates synthetic sequences with $n$ frames stored as "frame0001.png" through "frame000[n].png" in *png* format; horizontal $u$ and vertical $v$ components of ground truth deformation fields in *flo* format as "flow001.flo" through "flow000[n-1].png"; and visual representation of the flow components in png format as "flow0001.png" through "flow000[n-1].png".  The output directory and file structures are shown below.

```
|-- <output_path>
│         |-- Sequences
|         |       |-- Seq 1
|         |       |     |--frame0001.png
|         |       |     |--
|         |       |     |--
|         |       |     |--frame000[n].png
|         |       |-- Seq 2
|         |       |     .
|         |       |     .
│         |-- Flow
|         |       |-- Seq 1
|         |       |     |--flow0001.flo
|         |       |     |--
|         |       |     |--
|         |       |     |--frame000[n-1].flo
|         |       |-- Seq 2
|         |       |     .
|         |       |     .
│         |-- Flow_vis
|         |       |-- Seq 1
|         |       |     |--flow0001.png
|         |       |     |--
|         |       |     |--
|         |       |     |--frame000[n-1].png
|         |       |-- Seq 2
|         |       |     .
|         |       |     .
```

### B. Computational Models of Deforming Elastic Materials

Computational models of deforming elastic materials used for generating ground truth strain measures ($\epsilon_{xx}, \epsilon_{yy}, \epsilon_{xy}$) and kinematic features (vorticity, strain magnitude $\epsilon_m$, von Mises strain $\epsilon_{vm}$) were implemented in COMSOL.  These COMSOL models / programs can be downloaded from the following reposiroty:
>[https://memphis-sandbox.digital-commons.com/computational-ocularscience-laboratory/1/](https://memphis-sandbox.digital-commons.com/computational-ocularscience-laboratory/1/)

### C. Matlab Programs for Estimating Strain and Kinematic Feature from COMSOL Exports

To extract kinematic descriptor outputs from the COMSOL simulation results as described in the dataset section of [Rubber Material Modeling](https://computational-ocularscience.github.io/kinemanet.github.io/#rubber-material-modeling), clone the `fem` directory and follow the following instructions.
This program expects `*.csv` inputs from the COMSOL which can be downloaded from [Dataset page]((https://computational-ocularscience.github.io/kinemanet.github.io/#rubber-material-modeling)) for each of the four rubber geometries.

```matlab
clc; clear; close all;
addpath('fem');  % Add fem directory to path
femExtractor_v1; % Call the function
```
This will output kinematic descriptors `u, v, Exx, Eyy, Exy, Vorticity, Strain Magnitude` and `von Mises Strain` in `*.mat` file format and as colormaps for visualization purposes.

## V. Evaluation

### Flow Evaluation
Note: Using synthetic data with known deformation to validate the KinemaNet deformation fields

To compute ground truth strain estimates as well as evaluate your method (if any), run `evaluate_speckle` under eval directory:

```matlab
clc; clear; close all;
addpath('evaluation');  % Add eval directory to path
evaluate_speckle; % Call the function
```
If you're computing results for ground truth strain estimates only, set the variable `method_name` to `Flow`, a default path where generated ground truth flows are located.
Set `save_vis_strain = true` and `save_strain = true` to save gt and/or estimated strain maps as colormaps and `.mat` files, respectively.

To evaluate your flow and strain estimates (if any) of the test sepckle dataset, set the variable `method_name` to `my_method_name`, a path where your flow estimates are located.

### Strain Evaluation    
Note: using FE model generated flow estimates calculate the strain tensor vs FE estimated strain tensor

## VI. GUI for Visualizing Kinematics Descriptors 
```matlab
clc; clear; close all;
imageUploadGUI  % Launch the GUI
```
GUI demo video:

[![Demo Video](https://github.com/Computational-Ocularscience/KinemaNet/blob/main/GUI/Demo/GUI_snapshot.png)](https://www.youtube.com/watch?v=RYcXPL-BuvE&list=PLwsd7wXvear8K4BZcjDVmZHCgSXQ2tv6c)


## VII. Citation

If you find this work useful please cite:
```
@article{ferede2023sstm,
  title={SSTM: Spatiotemporal recurrent transformers for multi-frame optical flow estimation},
  author={Ferede, Fisseha Admasu and Balasubramanian, Madhusudhanan},
  journal={Neurocomputing},
  volume={558},
  pages={126705},
  year={2023},
  publisher={Elsevier}
}
```
