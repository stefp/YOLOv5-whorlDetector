# YOLOv5-whorlDetector
This repo contains the R scripts to detect whorls from dense drone laser scanning point clouds. 

The full methodology is described in:

Puliti, S., McLean, J.P., Cattaneo, N., Fischer, C., Astrup, R. 2021 Tree height-growth trajectory estimation using uni-temporal UAV laser scanning data and deep learning. _Forestry_ volume .... pp .... DOI: ..... 

![schematic_overview_methods_gituhb](https://user-images.githubusercontent.com/5663984/164417744-bb5badfd-d8e8-41dc-9431-df448951e234.png)


# Usage
In this repo you will be able to process a single tree according to the developed methodology in R.

## 1- First clone the repository
git clone ...

## 2 - Download the whorl detector model (*.pt) the google drive
The model can be dowloaded from this link (https://drive.google.com/file/d/1_kNcQrUuSiYxvjItw_nBJWiRq9YIdR0D/view?usp=sharing) and should be stored in the .../YOLOv5-whorlDetector/src/whorl_detector_weights folder

## 3 - run the "Use.r" file

