#-------------------------------------------------------------------------------

library(tidyverse, quietly = TRUE) 
library(DropletUtils, quietly = TRUE) 

# construct SCE object from raw cellranger output
print(paste0(snakemake@input[["output_cellranger"]], "/raw_feature_bc_matrix"))
sce <- read10xCounts(samples = paste0(snakemake@input[["output_cellranger"]], 
                                      "/raw_feature_bc_matrix"), 
                     col.names = TRUE, 
                     type = "sparse" )

# add specified metadata to object 
metadata <- read.csv(file = snakemake@params[["metadata"]], 
                     head = TRUE, 
                     sep = ",", 
                     check.names=FALSE, 
                     stringsAsFactors=FALSE, 
                     as.is=TRUE, 
                     colClasses = "character")

individual_curr <- snakemake@wildcards[["individual"]] # currently loaded individual sample 
IDENTIFIERS <- snakemake@params[["identifiers"]] 

# if necessary concatenate identifiers again to obtain all possible wildcards 
metadata_curr <- metadata
if(! "individual" %in% colnames(metadata_curr)){
  metadata_curr <- metadata_curr %>%
    unite(col = "individual", all_of(IDENTIFIERS), sep = "_", remove = FALSE)
  print('establishing "individual" column, construct_sce_objects.R')
}

# subset data as specified by wildcard and single_cell_object_metadata_fields
metadata_curr <- metadata_curr[which(metadata_curr$individual == individual_curr),]
cols_add <- snakemake@params[["single_cell_object_metadata_fields"]]
metadata_curr <- metadata_curr[,colnames(metadata_curr) %in% cols_add]

# add cell-level metadata to each barcode in the SCE object
for(i in colnames(metadata_curr)){
  colData(sce)[i] <- rep(metadata_curr[1,i], ncol(sce))
}

print(sce)
saveRDS(sce, file = snakemake@output[["sce_objects"]])