#-------------------------------------------------------------------------------
# call objects from raw cellranger output matrices and add metadata

library(DropletUtils, quietly = TRUE) 
# r and DropletUtils modules must be installed in snakemake conda environment
# https://anaconda.org/conda-forge/r-base
# https://anaconda.org/bioconda/bioconductor-dropletutils

# construct SCE object from raw cellranger output
sce <- read10xCounts(samples = snakemake@input[["output_cellranger"]], 
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

wildcards_curr <- snakemake@wildcards[["individual"]] # to know which sample is currently loaded
identifier <- snakemake@params[["identifier"]] # to know which metadata column to compare it to to get the correct info

# subset data that is relevant for current object only, as specified by wildcard and by by single_cell_object_metadata_fields
metadata_curr <- metadata[which(metadata[which(colnames(metadata) == identifier)] == wildcards_curr),]
cols_add <- snakemake@params[["single_cell_object_metadata_fields"]]
metadata_curr <- metadata_curr[,colnames(metadata_curr) %in% cols_add]

# add cell-level metadata to each barcode in the SCE object
for(i in colnames(metadata_curr)){
  colData(sce)[i] <- rep(metadata_curr[1,i], ncol(sce))
}

saveRDS(sce, file = snakemake@output[["sce_objects"]])

# for testing purposes
#metadata <- read.csv(file = "~/snakemake-cellranger/data/metadata_full.csv", head = TRUE,  sep = ",",     check.names=FALSE,   stringsAsFactors=FALSE,  as.is=TRUE, colClasses = "character")
#sce <- read10xCounts(samples = "/omics/groups/OE0538/internal/users/l012t/snakemake-cellranger/data/cellranger_count/mmus_old_str_2_0/outs/raw_feature_bc_matrix", col.names = TRUE,   type = "sparse" )
