# Defines some variables and functions based on what model was chosen

# ADD NEW MODELS HERE
if (args$model == "rf"){
    fileTrain <- "RF_RD.R"
    modelLibs <- c("caret","ranger","tidyverse","e1071","randomForest","foreach","import")
    hasParallelVersion <- TRUE

    getEBV <- function(gen){
        M = as.data.frame(pullSegSiteGeno(gen))
        colnames(M) <- paste("ID",2:(ncol(M)+1),sep="")
        EBV <- as.numeric(predict(rf_fit, M))
        as.matrix(EBV)
    }
}

if (args$model == "rrblup") {
    fileTrain <- "rrblup_sc.R"
    modelLibs <- c("rrBLUP","devtools","dplyr","tidyverse","ggplot2","cluster","factoextra")
    hasParallelVersion <- FALSE

    getEBV <- function(gen){
        genMat <- pullSegSiteGeno(gen) 
        genMat <- genMat-1
        genMat %*% markerEffects
    }
}

if (args$model == "svm"){
    fileTrain <- "SVM_RD.R"
    modelLibs <- c("e1071")
    hasParallelVersion <- FALSE

    getEBV <- function(gen){
        M = as.data.frame(pullSegSiteGeno(gen))
        colnames(M) <- paste("ID",2:(ncol(M)+1),sep="")
        EBV <- as.numeric(predict(SVMfit, M))
        as.matrix(EBV)
    }
}

if (args$model == "ann"){
    fileTrain <- "ANN_RD.R"
    modelLibs <- c("tidyverse","keras","tensorflow","readr","devtools")
    hasParallelVersion <- FALSE

    getEBV <- function(gen){
        geno <- as.matrix(pullSegSiteGeno(gen))
        model_Final %>% predict(geno)
    }
}
