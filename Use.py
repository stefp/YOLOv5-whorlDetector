import os
import subprocess
from rpy2 import robjects
import shutil

jpg_folder = "jpg"

if not os.path.exists(jpg_folder):
   os.makedirs(jpg_folder)

robjects.r('''
source("src/pointcloud2images.R")

JPGfromPC(tree_pc = "src/Original_Data/plot12_tree8.las",
          out_dir = "jpg")
''')


if not os.path.exists("yolov5"):
   subprocess.run("git clone https://github.com/ultralytics/yolov5")

## Make and save predictions
## Reusable syntax for new models
from yolov5 import detect 

detect.run(
    weights="src/weights/best.pt",
    imgsz=(640,640),
    conf_thres=0.1,
    source="jpg",
    iou_thres=0.1,
    line_thickness=1,
    save_txt=True,
    save_conf=True
)

## move YOLOv5 predictios to jpg folder
robjects.r('''
        file.copy(list.files("yolov5/runs/detect", full.names = T), "jpg", overwrite = TRUE, recursive = TRUE)
          ''')

shutil.rmtree("yolov5/runs")

## Parse from YOLOv5 format to Zmin Zmax and associated probability
robjects.r('''
source("src/yoloPredictions2UTM.R")
parsePredictions(dir_predictions = "jpg/exp/labels",
                 dir_orig_imgs = "jpg")
''')

## postProcessingPredictions
robjects.r('''
source("src/predictions_postProcessing.R")
postProcessingPredictions("jpg/exp/labels", IOU = 0.001)
''')

## Check final data
import pandas as pd

print(pd.read_csv('Tree.csv'))