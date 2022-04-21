
## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
## poin tcloud to images
source("../src/pointcloud2images.R")

dir.create("jpg")
JPGfromPC(tree_pc = "../src/Original_Data/plot12_tree8.las",
          out_dir = "jpg")

## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
## Predict using YOLOv5
## Clone Yolov5 and install dependencies
system("git clone https://github.com/ultralytics/yolov5")
system("cd yolov5 && pip install -r requirements.txt")

## Predict
command <- paste0("cd yolov5 && ",
                  "python3 detect.py ",
                  "--weights ../../src/whorl_detector_weights/best.pt ",
                  "--img 640 --conf 0.1 ",
                  "--source ../jpg ",
                  "--iou-thres=0.1 ",
                  "--line-thickness 1 ",
                  "--save-txt ",
                  "--save-conf")
system(command)

## move YOLOv5 predictios to jpg folder
file.copy(list.files("./yolov5/runs/detect", full.names = T),
          "./jpg", overwrite = TRUE, recursive = TRUE)

unlink("./yolov5/runs", recursive = TRUE)

## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
## Parse from YOLOv5 format to Zmin Zmax and associated probability
source("../src/yoloPredictions2UTM.R")

parsePredictions(dir_predictions = "./jpg/exp/labels",
                 dir_orig_imgs = "./jpg")
                 
## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
## postProcessingPredictions
source("../src/predictions_postProcessing.R")

postProcessingPredictions("./jpg/exp/labels", IOU = 0.001)

## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
## Final data.
data.table::fread("Tree.csv")
