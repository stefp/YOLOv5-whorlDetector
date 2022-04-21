JPGfromPC <- function(tree_pc = NULL, out_dir = NULL,
                      h_vert_slice_m = 10,
                      slice_thickness_top_m = 0.4,
                      slice_thickness_bottom_m = 3,
                      image_size_px = 640,
                      size_points= 1.5, 
                      alpha_points= 0.05){

    ## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ## ## # Arguments: 
    ## ## dir ectory to a single tree point cloud (.las format)
    ## tree_pc = NULL
    ## ## Directory to folder where images will be saved
    ## out_dir = NULL

    ## ## slicing parameters
    ## ## height in meters of zoomed images
    ## h_vert_slice_m = 10
    ## ## thickness in meters of slices at the top of the tree
    ## slice_thickness_top_m = 0.4
    ## ## thickness in meters of slices at the base of the tree
    ## slice_thickness_bottom_m = 3

    ## ## iamge generation and ggplot parameters
    ## ## size in pixels of the side of the exported square image
    ## image_size_px= 640
    ## ## cex value for plotting the points
    ## size_points= 1.5
    ## ## alpha value for plotting the points 
    ## alpha_points= 0.05
    
    ## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
    ## load required libraries
    require(lidR) ## for reading the lidar data
    require(recexcavAAR) ## point cloud rotations
    require(ggplot2) ## plotting
    require(jpeg) ## plotting

    ## prepare environment
    ## create output folder
    dir.create(out_dir, showWarnings=F)
    ## get filename
    name= tools::file_path_sans_ext(basename(tree_pc))
    
    ## read in the point cloud for the selected tree 
    tree_pc=readLAS(tree_pc)
    tree_pc=tree_pc@data
    ## normalize X, Y, and Z coordinates
    tree_pc$dX=tree_pc$X-min(tree_pc$X)
    tree_pc$dY=tree_pc$Y-min(tree_pc$Y)
    tree_pc$dZ=tree_pc$Z-min(tree_pc$Z)
    
    ## define zoom levels and corresponding slice thickness and also tree top coordinates
    ## defines the height for each zoom levels (y) for plotting
    plot_y_zoom_levels= seq(max(tree_pc$dZ),0, -(h_vert_slice_m)) 
    plot_y_zoom_levels[length(plot_y_zoom_levels)+1]=0
    ## define slice thickness gradient
    slice_thickness= seq(slice_thickness_top_m,
                         slice_thickness_bottom_m,
                         ((slice_thickness_bottom_m - slice_thickness_top_m)/
                          (length(plot_y_zoom_levels))))
    ## define tree top X and Y coordinates as pivot point for point cloud rotation
    treetop=tree_pc[tree_pc$Z==max(tree_pc$Z),]
    treetop_XY=c(treetop$X,treetop$Y)
    
    ## Iterate through each zoom level and export images
    for (zoom in 2:length(plot_y_zoom_levels)){
        ## define slice thickness for the zoom level
        slice_thickness_zoom= slice_thickness[zoom-1]

        ## define upper and lower boundaries for the zoom level
        up=plot_y_zoom_levels[zoom-1]
        low= plot_y_zoom_levels[zoom]
        if(up-low<h_vert_slice_m){
            low=0
            up=h_vert_slice_m
        }
        
        ## slice the point cloud longitudinally
        tree_pc_zoom=tree_pc[tree_pc$dZ<up & tree_pc$dZ>=low,]
        
        ##rotate pointcloud
        tree_pc_zoom_rotate45=tree_pc_zoom
        tree_pc_zoom_rotate45$X= recexcavAAR::rotate(tree_pc_zoom$X, tree_pc_zoom$Y,
                                                     tree_pc_zoom$Z, degrx = 0, degry = 0,
                                                     degrz = 45, 
                                                     pivotx = treetop_XY[1],
                                                     pivoty = treetop_XY[2], pivotz = 0)[,1]
        tree_pc_zoom_rotate45$Y= recexcavAAR::rotate(tree_pc_zoom$X, tree_pc_zoom$Y,
                                                     tree_pc_zoom$Z, degrx = 0, degry = 0,
                                                     degrz = 45, 
                                                     pivotx = treetop_XY[1],
                                                     pivoty = treetop_XY[2], pivotz = 0)[,2]
        tree_pc_zoom_rotate45$Z= recexcavAAR::rotate(tree_pc_zoom$X, tree_pc_zoom$Y, tree_pc_zoom$Z,
                                                     degrx = 0, degry = 0, degrz = 45, 
                                                     pivotx = treetop_XY[1],
                                                     pivoty = treetop_XY[2], pivotz = 0)[,3]
        
        slice_0= tree_pc_zoom[tree_pc_zoom$X<treetop_XY[1]+slice_thickness_zoom&
                              tree_pc_zoom$X>=treetop_XY[1]-slice_thickness_zoom,]
        slice_90= tree_pc_zoom[tree_pc_zoom$Y<treetop_XY[2]+slice_thickness_zoom&
                               tree_pc_zoom$Y>=treetop_XY[2]-slice_thickness_zoom,]
        slice_45= tree_pc_zoom_rotate45[tree_pc_zoom_rotate45$X<treetop_XY[1]+slice_thickness_zoom&
                                        tree_pc_zoom_rotate45$X>=treetop_XY[1]-slice_thickness_zoom,]
        slice_135=tree_pc_zoom_rotate45[tree_pc_zoom_rotate45$Y<treetop_XY[2]+slice_thickness_zoom&
                                        tree_pc_zoom_rotate45$Y>=treetop_XY[2]-slice_thickness_zoom,]
        
        ## export images 
        ## define image filenames with associated metadata
        ## related to image corner UTM coordinates(in the filename)
        image_names_zoom= c(paste0( name
                                  ,"_xminmm",round(min(tree_pc_zoom$X*1000))
                                  ,"_xmaxmm",round(max(tree_pc_zoom$X*1000))
                                  ,"_zmincm",round(min(tree_pc_zoom$Z)*100)
                                  ,"_zmaxcm",round(max(tree_pc_zoom$Z)*100)
                                  ,"_treeTop",
                                   round(up*100),"cmm_rotate0.jpg"),
                            paste0( name
                                  ,"_xminmm",round(min(tree_pc_zoom$X*1000))
                                  ,"_xmaxmm",round(max(tree_pc_zoom$X*1000))
                                  ,"_zmincm",round(min(tree_pc_zoom$Z)*100)
                                  ,"_zmaxcm",round(max(tree_pc_zoom$Z)*100)
                                  ,"_treeTop",
                                   round(up*100),"cm_rotate90.jpg"),
                            paste0(name
                                  ,"_xminmm",round(min(tree_pc_zoom$X*1000))
                                  ,"_xmaxmm",round(max(tree_pc_zoom$X*1000))
                                  ,"_zmincm",round(min(tree_pc_zoom$Z)*100)
                                  ,"_zmaxcm",round(max(tree_pc_zoom$Z)*100)
                                  ,"_treeTop",
                                   round(up*100),"cm_rotate45.jpg"),
                            paste0(name
                                  ,"_xminmm",round(min(tree_pc_zoom$X*1000))
                                  ,"_xmaxmm",round(max(tree_pc_zoom$X*1000))
                                  ,"_zmincm",round(min(tree_pc_zoom$Z)*100)
                                  ,"_zmaxcm",round(max(tree_pc_zoom$Z)*100)
                                  ,"_treeTop",
                                   round(up*100),"cm_rotate135.jpg"))
        
        ## 0 degrees
        jpeg(filename = paste0(out_dir,"/",image_names_zoom[1]),
             width = image_size_px, height = image_size_px, units = "px", 
             pointsize = 12,
             quality = 75,
             bg = "white")
        deg_0=ggplot(slice_0, aes(x=dY, y=dZ))+geom_point(alpha=alpha_points, cex=size_points)+
            theme(plot.margin=unit(c(-0.05,0,-0.05,0), "null"),
                  axis.title.x=element_blank(),
                  axis.text.x=element_blank(),
                  axis.ticks.x=element_blank(),
                  axis.title.y=element_blank(),
                  axis.text.y=element_blank(),
                  axis.ticks.y=element_blank(),
                  legend.position='none',
                  panel.background = element_blank()
                  ) +xlim((max(tree_pc$dY)-h_vert_slice_m)/2 ,
                          max(tree_pc$dY)-(max(tree_pc$dY)-h_vert_slice_m)/2 ) 
        print(deg_0)
        dev.off()
        
        ## 90 degrees
        jpeg(filename = paste0(out_dir,"/",image_names_zoom[2]),
             width = image_size_px, height = image_size_px, units = "px", 
             pointsize = 12,
             quality = 75,
             bg = "white")
        deg_90=ggplot(slice_90, aes(x=dX, y=dZ))+geom_point(alpha=alpha_points, cex=size_points)+
            theme( plot.margin=unit(c(-0.05,0,-0.05,0), "null"),
                  
                  axis.title.x=element_blank(),
                  axis.text.x=element_blank(),
                  axis.ticks.x=element_blank(),
                  axis.title.y=element_blank(),
                  axis.text.y=element_blank(),
                  axis.ticks.y=element_blank(),
                  legend.position='none',
                  panel.background = element_blank()
                  )  +xlim((max(tree_pc$dX)-h_vert_slice_m)/2 ,
                           max(tree_pc$dX)-(max(tree_pc$dX)-h_vert_slice_m)/2 )
        print(deg_90)
        dev.off()
        
        ## 45 degrees
        jpeg(filename = paste0(out_dir,"/",image_names_zoom[3]),
             width = image_size_px, height = image_size_px, units = "px", 
             pointsize = 12,
             quality = 75,
             bg = "white")
        deg_45=ggplot(slice_45, aes(x=dY, y=dZ))+geom_point(alpha=alpha_points, cex=size_points)+
            
            theme(
                plot.margin=unit(c(-0.05,0,-0.05,0), "null"),
                axis.title.x=element_blank(),
                axis.text.x=element_blank(),
                axis.ticks.x=element_blank(),
                axis.title.y=element_blank(),
                axis.text.y=element_blank(),
                axis.ticks.y=element_blank(),
                legend.position='none',
                panel.background = element_blank()
            )+
            xlim((max(tree_pc$dY)-h_vert_slice_m)/2 ,
                 max(tree_pc$dY)-(max(tree_pc$dY)-h_vert_slice_m)/2 ) 
        print(deg_45)
        dev.off()

        ## 135 degrees
        jpeg(filename = paste0(out_dir,"/",image_names_zoom[4]),
             width = image_size_px, height = image_size_px, units = "px",
             pointsize = 12, quality = 75,bg = "white")
        deg_135=ggplot(slice_135, aes(x=dX, y=dZ))+geom_point(alpha=alpha_points, cex=size_points)+
            theme(
                plot.margin=unit(c(-0.05,0,-0.05,0), "null"),
                axis.title.x=element_blank(),
                axis.text.x=element_blank(),
                axis.ticks.x=element_blank(),
                axis.title.y=element_blank(),
                axis.text.y=element_blank(),
                axis.ticks.y=element_blank(),
                legend.position='none',
                panel.background = element_blank()
            )  +xlim((max(tree_pc$dX)-h_vert_slice_m)/2 ,
                     max(tree_pc$dX)-(max(tree_pc$dX)-h_vert_slice_m)/2 )
        print(deg_135)
        dev.off()
    }
}
