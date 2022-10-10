
REMOTE_DIR="/omics/odcf/project/OE0538/DO-0008/mmus/sequencing/10x_scRNA_sequencing/core/run210113_A00382_0212_BHVWY5DMXX/"
FILES="AS-559165-LR-54592_R*.fastq.gz"
DATA_DIR="data/example-data"

mkdir -p $DATA_DIR

scp dkfz-worker:$REMOTE_DIR/$FILES data/example-data

mkdir $DATA_DIR/.tmp

for FILEPATH in $(ls $DATA_DIR/*.fastq.gz);
do
  FILENAME=$(basename $FILEPATH)
  zcat $FILEPATH | head -1000000 | gzip -c > $DATA_DIR/.tmp/$FILENAME
  mv $DATA_DIR/.tmp/$FILENAME  $DATA_DIR
done


scp dkfz-worker:/omics/groups/OE0526/internal/services/otp/otp-scripts/export/molgenis/2022-09-21-13-39-12/OE0538_DO-0008_mmus/data-files.csv $DATA_DIR/.tmp/metadata.csv
head -1 $DATA_DIR/.tmp/metadata.csv > $DATA_DIR/metadata.csv
grep "${FILES/"*.fastq.gz"/}" $DATA_DIR/.tmp/metadata.csv  >> $DATA_DIR/metadata.csv
sed -i "s|$REMOTE_DIR|$DATA_DIR/|g" $DATA_DIR/metadata.csv

rm -r $DATA_DIR/.tmp
