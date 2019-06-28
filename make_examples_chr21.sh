#!/bin/bash -login
#SBATCH --nodes=1 --ntasks=16
#SBATCH --time=8:00:00
#SBATCH --mem=128G
#SBATCH -A ged
#SBATCH --mail-type=FAIL,BEGIN,END
#SBATCH -J make_examples_chr21

cd $SLURM_SUBMIT_DIR


module load parallel/20180422

N_SHARDS="16"
INPUT_DIR="${PWD}/input"
OUTPUT_DIR="${PWD}/output_chr21_"$exp
LOG_DIR="${OUTPUT_DIR}/logs"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${LOG_DIR}"

( time seq 0 $((N_SHARDS-1)) | \
parallel --halt 2 --joblog "${LOG_DIR}/log" --res "${LOG_DIR}" \
singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/  --bind input:${INPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/make_examples \
--mode training \
--ref ${INPUT_DIR}/reference.fasta.gz \
--reads ${INPUT_DIR}/$bam \
--examples ${OUTPUT_DIR}/eval_set.with_label.tfrecord@${N_SHARDS}.gz \
--truth_variants ${INPUT_DIR}/truthdata.vcf.gz \
--confident_regions ${INPUT_DIR}/thruthdata.bed \
--sample_name "eval" \
--task {} \
--regions "chr21"
) > "${LOG_DIR}/training_set.with_label.make_examples.log" 2>&1


squeue -l --job ${SLURM_JOB_ID}




