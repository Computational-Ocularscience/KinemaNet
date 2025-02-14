# ELASTONET
This repository contains the source code for our paper:

[ElastoNet: Kinematic descriptors of deformation of ONH images for glaucoma progression detection](https://arxiv.org/pdf/2304.14418)<br/>
Fisseha A. Ferede, Madhusudhanan Balasubramanian<br/>

<img src="Elastonet_architecture.png">



## Speckle Dataset Generation

We generate multi-frame synthetic speckle pattern image sequences and ground-truth flows that represent the underlying deformation of the sequence. Each sequence has a unique reference pattern and contains between 9,000 and 11,000 randomly generated ellipses of varying sizes, with major and minor axes ranging from 7 to 30 pixels. These ellipses are fully filled with random gray scale intensity gradients ranging from 0 to 255. 

We then backward warp each unique pattern with smooth and randomly generated spatial random deformation fields to generate deforming sequences. The random deformation fields are generated using [GSTools](https://gmd.copernicus.org/articles/15/3161/2022/), a library which uses
covariance model to generate spatial random fields. 

### Sample Demo

<p align="center">
   <img src="Speckle/sample/sample_seq.gif" width="512" height="512" alt="Demo GIF">
   <img src="Speckle/sample/flow001.png" width="512" height="512" alt="Demo Image">
</p>

### Run Speckle Generator

`--pattern` represents a path where 3D image volumes in `.tiff` format and/or sub-directories containing z-slices of a given volume in a sorted order are located.
`--model_path` a path where the model used for evaluation is located (Download pretrained models [Saved models](https://drive.google.com/drive/folders/1vFvyuP4FdU8A0_Y0iA7CHSvlAFPH6StX?usp=sharing)).
`--outputfile` a path where the upsampled volumes will be saved. 
`--times_to_interpolate` isotropizing factor by which the volume input is upscaled. If it's in `2^n` order, it invokes recursive spatial interpolation to achieve the target number of frames, if not it will invoke the interpolation to the nearest `2^n` order and apply bicubic interpolation to upsample or downsample.
`--output_volume` if true, isotropized volume will be saved in `.tiff` format.
`--remove_sliced_volumes` if true, removes the intermediate 2D slices generated from a 3D `.tiff` volume input.


```Shell
python3 /Z-upscaling-main/eval/interpolator_cli.py \
   --pattern "/Z-upscaling-main/Demo/*" \
   --model_path /Z-upscaling-main/ModelPaths/test_run_ft_em_/saved_model_2M \
   --outputfile /Z-upscaling-main/Demo_out \
   --times_to_interpolate 8 \
   --output_volume "True" \
   --remove_sliced_volumes "False"

```

### Output Format
The output files which includes synthetic speckle pattern image sequences, `.flo` ground truth deformation field which contains the `u` and `v` components of the flow, as well as flow visualizations, heatmap of the `u` and `v` flows.

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


## Cite

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