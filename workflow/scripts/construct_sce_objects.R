#-------------------------------------------------------------------------------
# call objects from raw cellranger output matrices and add metadata

library(DropletUtils, quietly = TRUE) 
# r and DropletUtils modules must be installed in snakemake conda environment
# https://anaconda.org/conda-forge/r-base
# https://anaconda.org/bioconda/bioconductor-dropletutils

#identifiers <- snakemake@params[["identifiers"]]
#single_cell_object_metadata_fields <- snakemake@params[["single_cell_object_metadata_fields"]]

# construct from raw cellranger output
sce <- read10xCounts(samples = snakemake@input[["output_cellranger"]], col.names = TRUE, 
                     type = "sparse" )

# add specified metadata to object 
metadata <- read.csv(file = snakemake@params[["metadata"]], 
                     head = TRUE, 
                     sep = ",", 
                     check.names=FALSE, 
                     stringsAsFactors=FALSE, 
                     as.is=TRUE, 
                     colClasses = "character")

identifiers <- snakemake@params[["identifiers"]]
print(identifiers)

wildcards_curr <- snakemake@wildcards[["individual"]]
print(wildcards_curr)







saveRDS(sce, file = snakemake@output[["sce_objects"]])




metadata <- read.csv(file = "~/snakemake-cellranger/data/metadata_full.csv", head = TRUE,  sep = ",",     check.names=FALSE,   stringsAsFactors=FALSE,  as.is=TRUE, colClasses = "character")
sce <- read10xCounts(samples = "/omics/groups/OE0538/internal/users/l012t/snakemake-cellranger/data/cellranger_count/mmus_old_str_2_0/outs/raw_feature_bc_matrix", col.names = TRUE,   type = "sparse" )



