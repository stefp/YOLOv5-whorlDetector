postProcessingPredictions <- function(Folder, IOU = 0.001){
    ## # Arguments:
    ## IoU threshold to discard redundant boxes (0, 1)
    ## Folder: folder with "yoloPredictions2UTM" output

    library("data.table")
    library("sf")
    library("stringr")

    
    WhorlsFiles <- Folder
    WhorlsFiles <- list.files(WhorlsFiles, pattern = "_orig",
                              full.names = T)
    
    ## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ## load  tree data
    plotID=  as.numeric(sub("\\D+", "",
                            str_split((basename(WhorlsFiles)),
                                      pattern="_")[[1]][2]))
    treeID=  as.numeric(sub("\\D+", "",
                            str_split((basename(WhorlsFiles)),
                                      pattern="_")[[1]][1]))
    
    Tree <- fread(WhorlsFiles)
    
    ## give each whorl an ID
    Tree[, whorl := 1:nrow(Tree)]
    
    ## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ## Create spatial segments 
    TreeSF <- Tree[, .(Z1, Z2, whorl)]
    TreeSF <- split(TreeSF, TreeSF$whorl)
    
    TreeSF <- lapply(TreeSF, function(XX){
        tmp <- cbind(c(1, 1), c(XX$Z1, XX$Z2))
        tmp <- st_linestring(tmp)
        return(tmp)})
    
    
    List <- Tree[, .(prob, whorl)]
    List <- List[order(-prob), ]
    List[, code := 1]

    repeat{
        
        Whorl <- List[code == 1, ][prob == max(prob), ]$whorl[1]
        
        FindOverlpLines <- sapply(seq_along(TreeSF), function(XX){
            st_length((st_intersection(TreeSF[[Whorl]], TreeSF[[XX]])))
        })
        FindOverlpLines <- which(FindOverlpLines > 0)
        FindOverlpLines <- FindOverlpLines[FindOverlpLines != Whorl]
        
        IoU <- sapply(seq_along(FindOverlpLines), function(XX){
            Intersection <- st_intersection(
                TreeSF[[Whorl]], TreeSF[[FindOverlpLines[XX]]])
            Intersection <- st_length(Intersection)
            
            Union <- st_union(
                TreeSF[[Whorl]], TreeSF[[FindOverlpLines[XX]]])
            Union <- st_length(Union)
            return(Intersection/Union)
        })
        
        FindOverlpLines <- FindOverlpLines[IoU > IOU]
        List <- List[!(whorl %in% FindOverlpLines), ]
        List[whorl == Whorl, code := 0]
        
        if (nrow(List[code == 1, ]) == 0){break
        }
    }
    
    rm("FindOverlpLines", "IoU", "TreeSF", "Whorl")

    ## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ## @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ## the PP data
    Tree <- Tree[whorl %in% List$whorl, ]
    rm(List)
    
    Tree[, whorl := NULL]
    fwrite(Tree, file = "Tree.csv")
}
