suppressMessages(library(argparse))
suppressMessages(library(tictoc))
suppressMessages(library(reticulate))
suppressMessages(library(doParallel))
suppressMessages(library(AlphaSimR))
source("ParameterSettings.R")
source("InterfaceLibrary.R")
source("FunctionsLibrary.R")


# For the ANN model
Sys.setenv(OMP_NUM_THREADS = 1, OPENBLAS_NUM_THREADS = 1) 

DATA_DIR <- "data"
MODEL_DIR <- "models"

args <- parseArgs()

if (args$noInteraction == FALSE)
  interactive_menu()


## define variables ##

nModels = 7
nGen = 10
nVar = 9

#load data and establish founder pop at outset so we do not reload data with every rep

genMap <- readRDS(file.path(DATA_DIR, "genMap4616SNPs.rds")) # can load other genMaps 
haplotypes <- readRDS(file.path(DATA_DIR, "doubleHaplo4616.rds")) # can load other genotype data, must match genMap


founderPop = newMapPop(genMap, 
                       haplotypes, 
                       inbred = FALSE, 
                       ploidy = 2L)

## Run repeat loop to run reps ##
if (args$nCores == 1 || modelParallelism) { # Run reps serially
  cli_alert_info("Importing simulation libraries...")

  res <- lapply(1:args$nReps, function(rep){
    cli_alert_info("Simulating rep {rep}/{args$nReps}...")
    source("SimplifiedBreedingCyclePipeline.R") ##Source the SCript for the SCenario you would like to run##
    cli_text("Rep {rep} finished.")

    ret
  })
} else { # Run reps in parallel
  cli_alert_info("Running {args$nReps} reps in {args$nCores} cores...")

  # Create parallel cluster and export variables
  cl <- makeCluster(args$nCores)
  clusterExport(cl, c("args", "loadModelLibs", "DATA_DIR", "MODEL_DIR"))

  res <- parLapply(cl, 1:args$nReps, function(rep){
    source("SimplifiedBreedingCyclePipeline.R") ##Source the SCript for the SCenario you would like to run##
    ret
  })

  # Stop parallel cluster
  stopCluster(cl)
}
res <- bindSimResults(res)

cli_alert_success("Simulation finished!")
cli_text()


##create results directory and enter it##
dirName <- args$outputDir
dir.create(file.path(dirName))

workingDir <- getwd()
setwd(file.path(dirName))

tic()
##create all output files##
Allgeneticvalues <- list()
for (cycle in 1:args$nCycles){
  cli_alert_info("Writing output files for cycle {cycle}...")
  Allgeneticvalues[[cycle]] <- getAllGeneticValues(res$geneticvalues[[cycle]])
  res$correlations[[cycle]] <- getCorrelations(res$correlations[[cycle]])
  res$variances[[cycle]] <- getVariances(res$variances[[cycle]])

  write.csv(Allgeneticvalues[[cycle]], paste("C", cycle, "_", args$model,"_trainAt",args$trainGen,"_trainWith",args$trainingData,"_",args$parentSelections, "Parents_gvs_snp_yield.csv", sep=""))
  write.csv(res$correlations[[cycle]], paste("C", cycle, "_",args$model,"_trainAt",args$trainGen,"_trainWith",args$trainingData,"_",args$parentSelections,"Parents_cors_snp_yield.csv", sep=""))
  write.csv(res$variances[[cycle]], paste("C", cycle, "_",args$model,"_trainAt",args$trainGen,"_trainWith",args$trainingData,"_",args$parentSelections,"Parents_vars_snp_yield.csv", sep=""))
  saveRDS(res$pheno[[cycle]], paste("C", cycle, "_",args$model,"_trainAt",args$trainGen,"_trainWith",args$trainingData,"_",args$parentSelections,"Parents_pheno_snp_yield.rds", sep=""))
  saveRDS(res$alleles[[cycle]], file=paste("C", cycle, "_",args$model,"_trainAt",args$trainGen,"_trainWith",args$trainingData,"_",args$parentSelections,"Parents_alleles_snp_yield.rds", sep=""))
}

cli_text("Time taken to write results:")
toc()
cli_text()
cli_alert_success("Results saved!")
setwd(workingDir) # Go back to previous directory
