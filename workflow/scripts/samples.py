import pandas as pd

from snakemake.io import Wildcards

# list identifiers identically to config identifiers and in same order
#IDENTIFIERS = ["Species_ID", "Age_ID", "Fraction_ID"] # find a way to lift directly from config

class Samples:
    """
    Convert the OTP-exported metadata spreadsheet into a pandas.DataFrame
    that provides metadata for the workflow.
    """
    # columns to select
    columns = ["PID",
               "Sample Type",
               "Species Scientific Name",
               "STRAIN",
               "FastQ Path",
               "FastQC Path",
               "Run ID",
               "ILSE_NO",
               "TISSUE",
               "BIRTH",
               "DATE_OF_BIRTH",
               "DATE_OF_DEATH",
               "LANE_NO",
               "READ",
               "CELLRANGER_FASTQ_PATH",
               "individual"] # include individual which is later generated
    #print(IDENTIFIERS)
    #print(columns)
    #columns = columns + IDENTIFIERS 
    #print(columns)
    #columns = None
               
    def __init__(self, config):
        IDENTIFIERS = config["metadata"]["identifiers"]
        metadata_files = config["metadata"]["raw"]

        self.output_base_dir = config["paths"]["output_dir"]
        self.target_templates = config["paths"]["target_templates"]

        metadata_full = pd.concat((pd.read_csv(f) for f in metadata_files), ignore_index=True)

        """Make "individual" column
        
        A single identifier col is copied and renamed to "individual" but 
        entries from multiple identifier cols are concatenated to "individual".
        
        Entries in the "individual" col are used as wildcards.
        
        For metadata_full it is used for downstream functions (?).
        
        This may cause a warning that I still have to take care of but that doesn't seem critical.
        """       
        if not "individual" in metadata_full.columns: 
            print('establishing "individual" column') 
            for i in IDENTIFIERS:
                if i == IDENTIFIERS[0]:
                    metadata_full["individual"] = metadata_full[i].map(str)
                else: 
                    metadata_full["individual"] = metadata_full["individual"] + '_' + metadata_full[i].map(str)
      
        metadata_full["DATE_OF_BIRTH"] = metadata_full.apply(self.rename_date_of_birth, axis=1)
        
        metadata_full = self.get_cellranger_filename(metadata_full)

        self.metadata = self.select_columns(metadata_full, identifiers = IDENTIFIERS)

    def rename_date_of_birth(self,
                             row: pd.Series):
        """Unify the 'BIRTH' and 'DATE_OF_BIRTH' columns into
        a single 'DATE_OF_BIRTH' column.
        """
        values = [row["BIRTH"], row["DATE_OF_BIRTH"]]
        dates = [val for val in values if not pd.isna(val)]
        if len(dates) == 1:
            return dates[0]
        elif len(dates) != 1:
            return pd.NA

    def get_cellranger_filename(self, df: pd.DataFrame) -> pd.DataFrame:

        """Add column containing CellRanger compatible filename,
        i.e. in the format of
        [Sample Name]_S[Sample_Number]_L00[Lane Number]_[Read Type]_001.fastq.gz
        
        Here, [Sample Name] consists of "individual".
        
        See also: https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/fastq-input
        """

        grouped = df.groupby(["individual", "LANE_NO", "READ"])
        groups = []
        for name, group in grouped:
            group = group.sort_values("FastQ Path")  # import to have consistent sorting
            group["multi_sample_idx"] = range(1, len(group)+1)
            group["CELLRANGER_FASTQ_PATH"] = group.agg(
                "{0[individual]}_S{0[multi_sample_idx]}_L00{0[LANE_NO]}_R{0[READ]}_001.fastq.gz".format,
                axis=1,
            )
            groups.append(group)

        return pd.concat(groups)

    def select_columns(self,
                       df: pd.DataFrame,
                       columns: list = None,
                       identifiers: str = None):
        """Select/Subset columns from DataFrame to reduce
        DataFrame dimensions. """

        if not columns:
            columns = self.columns + identifiers
        return df[columns]
            
    @staticmethod
    def filter_by_wildcards(
            wildcards: Wildcards,
            data: pd.DataFrame,
            column: str = None,
            unique: bool = True,
            **add_filters,
    ) -> list:
        """Get item from DataFrame by subsetting using the following index
        attributes provided via Snakemakes wildcards object.
        :return param:
        """

        _identifiers = ["individual", "Species_ID"] # possible wildcards

        if wildcards:
            filters = dict((k, getattr(wildcards, k)) for k in _identifiers)
        else:
            filters = {}

        filters.update(add_filters)
        subset_rows = (
            (data.reset_index()[list(filters)] == pd.Series(filters)).all(axis=1).to_list()
        )  # noqa: E501

        params = data.loc[subset_rows].get(column, None)  # select column `fieldname`
        if params is None:
            return [None]
        elif unique:
            return params.drop_duplicates().to_list()
        else:
            return params.to_list()

    @property
    def targets(self) -> list:
        """Create all target for the workflow."""

        output_base_path = self.output_base_dir

        target_templates = dict((cat, f"{output_base_path}/{path}") for cat, path in self.target_templates.items())

        targets = list(map(lambda x: self.metadata.agg(x.format, axis=1).drop_duplicates().to_list(), target_templates.values()))
        return targets
      
      
      
#grouped = metadata_subset.groupby(["PID", "Sample Type"])["FastQ Path"].apply(list)
