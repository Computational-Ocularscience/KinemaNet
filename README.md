# ELASTONET
This repository contains the source code for our paper:

[ElastoNet: Kinematic descriptors of deformation of ONH images for glaucoma progression detection](https://arxiv.org/pdf/2304.14418)<br/>
Fisseha A. Ferede, Madhusudhanan Balasubramanian<br/>

## I. Architecture

<img src="Elastonet_architecture.png">

## II. Speckle Dataset Generation

We generate multi-frame synthetic speckle pattern image sequences and ground-truth flows that represent the underlying deformation of the sequence. Each sequence has a unique reference pattern and contains between 9,000 and 11,000 randomly generated ellipses of varying sizes, with major and minor axes ranging from 7 to 30 pixels. These ellipses are fully filled with random gray scale intensity gradients ranging from 0 to 255. 
We then backward warp each unique pattern with smooth and randomly generated spatial random deformation fields to generate deforming sequences. The random deformation fields are generated using [GSTools](https://gmd.copernicus.org/articles/15/3161/2022/), a library which uses
covariance model to generate spatial random fields. 

### Sample Demo

<p align="center">
   <img src="specklegen/sample/sample_seq.gif" width="225" height="225" alt="Demo GIF">
   <img src="specklegen/sample/flow001.png" width="550" height="275" alt="Demo Image">
</p>

### Run Speckle Generator

There are four arguments to be specified by the user. `--output_path` defines the directory where generated image sequences, ground-truth flows and flow vizualizations will be saved.  `--seq_number` and `--seq_length` represent the number of random speckle pattern sequences to generate and the number of frames per each sequence, respectively.
Lastly, the `--dimensions` argument specifies the height and width of the output speckle patterns. 
```
python specklegen\synthetic_data_generator.py
   --output_path=<output_path>
   --seq_number=5
   --seq_length=7
   --dimensions 512 512
   --scales 5 7
```

### PyPI installation
We published this speckle data generator package on PyPI [Specklegen](https://pypi.org/project/specklegen/0.1.6/). Alternatively, this library can be installed and used as follows:

Installation
```
conda create -n specklegen_env python=3.8
pip install specklegen==0.1.6
```
Usage

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

### Output Format
The output files includes synthetic speckle pattern image sequences, `.flo` ground truth deformation field which contains the `u` and `v` components of the flow, as well as flow visualizations file, heatmap of the `u` and `v` flows.

```
├── <output_path>/
│   ├── Sequences├──Seq1├──frame0001.png
│   │            │              .
│   │            │      ├──frame000n.png     
│   │            │ 
│   ├── Flow     ├──Seq1├──flow0001.flo
│   │            │              .
│   │            │      ├──frame000n-1.flo
│   │            │     
│   ├── Flow_vis ├──Seq1├──flow0001.png
│   │            │              .
│   │            │      ├──frame000n-1.png
```

## III. Flow Estimation

```bash
# Clone SSTM repository
git clone https://github.com/Computational-Ocularscience/SSTM.git
conda env create -f sstm.yml
conda activate sstm
python SSTM/evaluate.py --model=checkpoints/sstm_t++-sintel.pth --dataset=speckle/sequences
```

## IV. Evaluation

### For Synthetic Dataset
To compute ground truth strain estimates as well as evaluate your method (if any), run `evaluate_speckle` under eval directory:

```matlab
clc; clear; close all;
addpath('eval');  % Add eval directory to path
evaluate_speckle; % Call the function
```
If you're computing results for ground truth strain estimates only, set the variable `method_name` to `Flow`, a default path where generated ground truth flows are located.
Set `save_vis_strain = true` and `save_strain = true` to save gt and/or estimated strain maps as colormaps and `.mat` files, respectively.

To evaluate your flow and strain estimates (if any) of the test sepckle dataset, set the variable `method_name` to `my_method_name`, a path where your flow estimates are located.
    

## V. Elastography Visualization GUI
```matlab
clc; clear; close all;
imageUploadGUI  % Launch the GUI
```
GUI demo video:

[![Demo Video](https://github.com/Computational-Ocularscience/ElastoNet/blob/main/GUI/Demo/GUI_snapshot.png)](https://www.youtube.com/watch?v=w8ZAxRauuDA&list=PLwsd7wXvear-qbWi7rvkdfhtEfZmVp21c&index=3)


## VI. Cite

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
