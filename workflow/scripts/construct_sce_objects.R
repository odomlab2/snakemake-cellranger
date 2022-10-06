#-------------------------------------------------------------------------------
# call objects from raw cellranger output matrices and add metadata

library(DropletUtils, quietly = TRUE) 
# r and DropletUtils modules must be installed in snakemake conda environment
# https://anaconda.org/conda-forge/r-base
# https://anaconda.org/bioconda/bioconductor-dropletutils

#identifiers <- snakemake@params[["identifiers"]]
#single_cell_object_metadata_fields <- snakemake@params[["single_cell_object_metadata_fields"]]


#print(metadata)
#print(identifiers)
#print(single_cell_object_metadata_fields)

print(snakemake@input[["output_cellranger"]])

# construct from raw cellranger output
sce <- read10xCounts(samples = snakemake@input[["output_cellranger"]], col.names = TRUE, 
                     type = "sparse" )


saveRDS(sce, file = snakemake@output[["sce_objects"]])
