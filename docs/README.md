# [Speckle Dataset Generation](https://github.com/Computational-Ocularscience/ElastoNet)<br/>

## Dataset Generation

We generate multi-frame synthetic speckle pattern image sequences and ground-truth flows that represent the underlying deformation of the sequence. Each sequence has a unique reference pattern and contains between 9,000 and 11,000 randomly generated ellipses of varying sizes, with major and minor axes ranging from 7 to 30 pixels. These ellipses are fully filled with random gray scale intensity gradients ranging from 0 to 255. 
We then backward warp each unique pattern with smooth and randomly generated spatial random deformation fields to generate deforming sequences. The random deformation fields are generated using [GSTools](https://gmd.copernicus.org/articles/15/3161/2022/), a library which uses
covariance model to generate spatial random fields. 

## Sample Demo

| Speckle Pattern | Flow Visualization |
|-----------------|-------------------|
| ![](https://github.com/Computational-Ocularscience/ElastoNet/blob/main/docs/sample_seq.gif?raw=true) | ![](https://github.com/Computational-Ocularscience/ElastoNet/blob/main/docs/flow001.png?raw=true) |


## Run Speckle Generator

There are four arguments to be specified by the user. `--output_path` defines the directory where generated image sequences, ground-truth flows and flow visualizations will be saved.  `--seq_number` and `--seq_length` represent the number of random speckle pattern sequences to generate and the number of frames per each sequence, respectively.
Lastly, the `--dimensions` argument specifies the height and width of the output speckle patterns. Optionally, a user can specify `--scales` an argument that defines the max `u` and `v` flow magnitudes, default value is `(10 10)`.


## PyPI installation
This speckle dataset generator can be installed and used as follows: 

Installation
```
conda create -n specklegen_env python=3.8
pip install specklegen==0.1.5
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

## Output Format
The output files include synthetic speckle pattern image sequences, `.flo` ground truth deformation fields containing the `u` and `v` components of the deformation, as well as flow visualization files (heatmaps of the `u` and `v` flows).
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
