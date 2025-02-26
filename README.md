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
python synthetic_data_generator.py
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
```

## IV. Evaluation
To compute strain estimates and visual results on synthetic speckle dataset:

```matlab
clc; clear; close all;
evaluate_speckle  % Under eval directory
```

## V. Elastography Visualization GUI
```matlab
clc; clear; close all;
imageUploadGUI  % Launch the GUI
```


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