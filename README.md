# ELASTONET
This repository contains the source code for our paper:

[ElastoNet: Kinematic descriptors of deformation of ONH images for glaucoma progression detection](https://arxiv.org/pdf/2304.14418)<br/>
Fisseha A. Ferede, Madhusudhanan Balasubramanian<br/>

<img src="Elastonet_architecture.png">

## Demo

<p style="display: flex; justify-content: center; gap: 20px; flex-direction: row; flex-wrap: nowrap; align-items: center; min-width: 700px;">
   <div style="text-align: center; width: 220px;">
      <img src="https://github.com/Fisseha21/Z-upscaling/blob/main/demos/Input_downsampledFIB25_vol.gif" width="200" height="200" alt="Input Downsampled Volume">
      <div style="margin-top: 8px;">Input Downsampled Volume</div>
   </div>

   <div style="text-align: center; width: 220px;">
      <img src="https://github.com/Fisseha21/Z-upscaling/blob/main/demos/zUpx8_FIB25_vol.gif" width="200" height="200" alt="Upscaled Volume">
      <div style="margin-top: 8px;">Upscaled Volume (Z × 8)</div>
   </div>

   <div style="text-align: center; width: 220px;">
      <img src="https://github.com/Fisseha21/Z-upscaling/blob/main/demos/GT_FIB25_vol.gif" width="200" height="200" alt="Ground Truth Volume">
      <div style="margin-top: 8px;">Ground Truth Volume</div>
   </div>
</p>






## Evaluation

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

## Cite

If you find this work useful please cite:
```
@article{ferede2024z,
  title={Z-upscaling: Optical Flow Guided Frame Interpolation for Isotropic Reconstruction of 3D EM Volumes},
  author={Ferede, Fisseha A and Khalighifar, Ali and John, Jaison and Venkataraman, Krishnan and Khairy, Khaled},
  journal={arXiv preprint arXiv:2410.07043},
  year={2024}
}
```