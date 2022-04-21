## function to parse predictions from YOLO format to Zmin Zmax and associated probability
## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
parsePredictions <- function(dir_predictions = NULL,
                             dir_orig_imgs = NULL){
    
    ## get list of all predicted files and split into the different angles
    predictions = list.files(dir_predictions, pattern = "*.txt")
    predictions_0 = predictions[grepl("rotate0", predictions, fixed = TRUE)]
    predictions_45 = predictions[grepl("rotate45", predictions, fixed = TRUE)]
    predictions_90 = predictions[grepl("rotate90", predictions, fixed = TRUE)]
    predictions_135 = predictions[grepl("rotate135", predictions, fixed = TRUE)]

    
    ## for each different angle convert bboxes into Zmin, Zmax, and
    ## corresponding probability score
    iter = 1
    pred_output = list()

    for (pred in list(predictions_0, predictions_45, predictions_90,
                      predictions_135)){

        ## get bbox metadata from the image filename
        meta = data.frame("filename" = pred
                         ,"plotID" = as.numeric(
                              gsub("[[:alpha:]]", "",
                                   do.call(rbind, strsplit(pred, "_"))[, 1]))
                         ,"treeID" = as.numeric(
                              gsub("[[:alpha:]]", "",
                                   do.call(rbind, strsplit(pred, "_"))[, 2]))
                         ,"Xmin" = as.numeric(
                              gsub("[[:alpha:]]", "",
                                   do.call(rbind, strsplit(pred, "_"))[, 3]))
                         ,"Xmax" = as.numeric(
                              gsub("[[:alpha:]]", "",
                                   do.call(rbind, strsplit(pred, "_"))[, 4]))
                         ,"Zmin" = as.numeric(
                              gsub("[[:alpha:]]", "",
                                   do.call(rbind, strsplit(pred, "_"))[, 5]))
                         ,"Zmax" = as.numeric(
                              gsub("[[:alpha:]]", "",
                                   do.call(rbind, strsplit(pred, "_"))[, 6]))
                         ,"topH" = as.numeric(
                              gsub("[[:alpha:]]", "",
                                   do.call(rbind, strsplit(pred, "_"))[, 7]))
                          )
        
        treeID = meta$treeID
        plotID = meta$plotID
        ## bring coordinates from cm and mm to m divide x and y by
        ## 100 to go back to UTM (m)
        meta$Xmin = meta$Xmin/1000
        meta$Xmax = meta$Xmax/1000
        meta$Zmin = meta$Zmin/100
        meta$Zmax = meta$Zmax/100
        
        
        ## calculate X and Z mean
        meta$Xmean = (meta$Xmin + meta$Xmax)/2
        meta$Zmean = (meta$Zmin + meta$Zmax)/2
        
        ## go through each Tree #### 
        tree_list_output = list()
        
        plotID_treeID = unique(paste0(meta$plotID, "_", meta$treeID))

        for(singleTree in 1:length(plotID_treeID)){
            plotID_st =  as.numeric(
                gsub("[[:alpha:]]", "",
                     do.call(
                         rbind, strsplit(plotID_treeID, "_"))[, 1]))[singleTree]
            treeID_st = as.numeric(
                gsub("[[:alpha:]]", "",
                     do.call(
                         rbind, strsplit(plotID_treeID, "_"))[, 2]))[singleTree]
            meta_st = meta[meta$plotID == plotID_st&meta$treeID == treeID_st, ]
            
            ## go through each slice in a tree #### 
            ## sort slices by height from lowest to highest
            meta_st = meta_st[order(meta_st$Zmin), ]
            slice_output_list = list()
            
            for (slice in 1:nrow(meta_st)){
                one_slice = read.table(
                    paste0(dir_predictions, "/",
                           meta_st[slice, ]$filename), header = F)
                
                ## assign names based on yolo file sructure
                names(one_slice) = c("class","center_X",
                                     "center_Y","width",
                                     "height","prob")
                
                ## get metadata for that slice
                meta_st_slice = meta_st[slice, ]
                img_height_m = meta_st_slice$Zmax - meta_st_slice$Zmin
                img_width_m = ifelse(
                    grepl("slice_X", meta_st[slice, ]$filename,
                          fixed = TRUE),
                    meta_st_slice$Ymax - meta_st_slice$Ymin,
                    meta_st_slice$Xmax-meta_st_slice$Xmin)

                ## get image size
                img = readJPEG(
                    paste0(dir_orig_imgs, "/",
                           tools::file_path_sans_ext(
                                      meta_st[slice, ]$filename),
                           ".jpg"))
                
                image_width_px = dim(img)[1]
                image_height_px = dim(img)[2]
                
                ## calculate the pixel size in m
                px_size_height = img_height_m/image_height_px
                px_size_width = img_width_m/image_width_px
                
                ## convert from yolov5 format to xmin xmax ymin ymax
                one_slice$Z1_UTM = (
                    (one_slice$center_Y - one_slice$height/2) *
                    image_height_px * px_size_height) +
                    meta_st_slice$Zmin
                one_slice$Z2_UTM = (
                    (one_slice$center_Y + one_slice$height/2) *
                    image_height_px*px_size_height) +
                    meta_st_slice$Zmin
                
                ## order based on height increasing
                one_slice=one_slice[order(one_slice$Z1_UTM),]
                
                ## put results in a data.frame ####
                output_slice=data.frame("treeID"=treeID[1]
                                       ,"plotID"=plotID[1]
                                       ,"prob"=one_slice$prob
                                       ,"Z1"=one_slice$Z1_UTM
                                       ,"Z2"=one_slice$Z2_UTM
                                        )

                ## store output in the list
                slice_output_list[[slice]]=output_slice
            }
            
            ## merge list
            whorls_all_tree= do.call(rbind, slice_output_list)

            ## add plot and tree ID 
            whorls_all_tree$plotID=plotID_st
            whorls_all_tree$treeID=treeID_st
            
            ## store output in a list
            tree_list_output[[singleTree]]=whorls_all_tree
        }
        
        ## store output 
        pred_output[[iter]]=do.call(rbind,tree_list_output )
        iter=iter+1
    }

    ## PUT TOGHETHER WHORL POINTS FROM THE FOUR
    ## DIFFERENT SLICES OF THE SAME STEM
    all_whorls = do.call(rbind, pred_output)
    write.table(all_whorls,
                paste0(dir_predictions, "/tree",
                       unique(all_whorls$treeID),
                       "_plot", unique(all_whorls$plotID),
                       "_orig.txt"), sep=",",
                dec = ".", quote = F, row.names = F)
}
