work_dir="$(pwd)"
mkdir -p $work_dir/{hg38_data,scripts}
index_dir_path=$work_dir/hg38_data/

#bash $work_dir/scripts/genomeResources.sh "$index_dir_path" "HPC" 

### Download the human genome data
## Nucleotide sequence of the GRCh38 primary genome assembly (chromosomes and scaffolds)
wget ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/GRCh38.primary_assembly.genome.fa.gz -P $index_dir_path
gunzip $index_dir_path/GRCh38.primary_assembly.genome.fa.gz 

wget ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/gencode.v29.primary_assembly.annotation.gtf.gz -P $index_dir_path
gunzip $index_dir_path/gencode.v29.primary_assembly.annotation.gtf.gz

## calculte chromosome sizes of the genome
#if [ $plateform == "HPC" ];then
#  module load SAMTools/1.2;fi
module load SAMtools/1.9
samtools faidx $index_dir_path/GRCh38.primary_assembly.genome.fa
cut -f1,2 $index_dir_path/GRCh38.primary_assembly.genome.fa.fai > $index_dir_path/hg38.genome

#star genome indexing without gtf annotation

mkdir -p $index_dir_path/star_index
genomeDir="$index_dir_path/star_index/"
genomeFastaFiles="$index_dir_path/GRCh38.primary_assembly.genome.fa"

#script_path=$(dirname "${BASH_SOURCE[0]}")
#qsub -v genomeDir="$genomeDir",genomeFastaFiles="$genomeFastaFiles" $script_path/run_starIndex.sh
script_path=$work_dir/scripts
sbatch --export="genomeDir=$genomeDir,genomeFastaFiles=$genomeFastaFiles" $script_path/run_starIndex.sh
#module load STAR/2.6.0c
#STAR --runThreadN 1 --runMode genomeGenerate --genomeDir $genomeDir --genomeFastaFiles $genomeFastaFiles

### done ###

#mkdir -p $work_dir/SRR1153470
#input_dir_path=$work_dir/SRR1153470/
#wget ftp://ftp.ddbj.nig.ac.jp/ddbj_database/dra/fastq/SRA130/SRA130768/SRX457730/* -P $input_dir_path

mkdir -p $work_dir/SRR1153470
cd $work_dir/SRR1153470
module load SRA-Toolkit/2.9.0-centos_linux64
fastq-dump --defline-seq '@$sn[_$rn]/$ri' --split-files SRR1153470
cd ../

### STAR-Scallop pipeline
#map the trimmed merged reads using STAR
mkdir -p $work_dir/star-scallop
star_dir=$work_dir/star-scallop
output_dir_path=$star_dir/output/SRR1153470
mkdir -p $output_dir_path;
input1=$work_dir/SRR1153470/SRR1153470_1.fastq
input2=$work_dir/SRR1153470/SRR1153470_2.fastq
#I am not sure if star_output_sam_prefix is just a naming variable or it has part in the program, if it is just for naming then:
star_output_sam_prefix=SRR1153470

#if [ "$plateform" == "HPC" ];then
#       script_path=$(dirname "${BASH_SOURCE[0]}")
#       qsub -v index="$index_dir_path/star_index",input1="$input1",input2="$input2",output="$output_dir_path/$star_output_sam_prefix" $script_path/run_star.sh
#    else
#       STAR --runThreadN 1 --genomeDir $index_dir_path/star_index --readFilesIn $input1 $input2 --readFilesCommand zcat --outSAMattributes XS --outFileNamePrefix $output_dir_path/$star_output_sam_prefix
#     fi
#   done
script_path=$work_dir/scripts
index="$index_dir_path/star_index"
output="$output_dir_path/$star_output_sam_prefix"
sbatch --export="index=$index,input1=$input1,input2=$input2,output=$output" $script_path/run_starAlign.sh


##sort, convert to bam
#for sam in $output_dir_path/*.sam; do
#     label=${sam%.sam}
#     if [ "$plateform" == "HPC" ];then
#       qsub -v label="$label" $script_path/run_getBAM.sh
#     else
#       samtools view -u -o $label.bam $label.sam
#       samtools sort -O bam -T $label -o $label.sorted.bam $label.bam
#     fi
#   done

module load SAMtools/1.9
label="$output_dir_path/$star_output_sam_prefix"Aligned.out
samtools view -u -@ 4 -o $label.bam $label.sam
samtools sort -@ 4 -O bam -T $label -o $label.sorted.bam $label.bam


## Split by region
module load SAMTools/0.1.19  ## samtools/0.1.19
region="chr1.1.1000"
samtools view -h aligned_reads.sorted.merged.bam chr1:1-10000 -b > $region.bam
samtools index $region.bam

star_dir=$work_dir/star-scallop
output_dir_path=$star_dir/output/SRR1153470
star_output_sam_prefix=SRR1153470
label="$output_dir_path/$star_output_sam_prefix"Aligned.out

## buildBamIndex.sh
#!/bin/bash -login
#PBS -l walltime=01:00:00,nodes=1:ppn=2,mem=12Gb
#mdiag -A ged
#PBS -m abe
#PBS -N buildBamIndex

module load picard/2.18.1-Java-1.8.0_152 #picardTools/1.113
java -jar $EBROOTPICARD/picard.jar BuildBamIndex INPUT=$label.sorted.bam



