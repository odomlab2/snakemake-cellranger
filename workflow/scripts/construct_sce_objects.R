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

#wildcards_curr <- snakemake@wildcards[[identifiers[1]]]
#print(wildcards_curr)

# construct a unique Object_ID from the identifiers and add to metadata if necessary
for(i in snakemake@wildcards){
  print(i)
}
print(class(c(snakemake@wildcards)))

#object_id_curr <- paste(identifiers, collapse = "_")
#print(object_id_curr)




saveRDS(sce, file = snakemake@output[["sce_objects"]])


