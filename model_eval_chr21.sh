#!/bin/bash -login
#SBATCH --nodes=1 --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --mem=128G
#SBATCH -A ged
#SBATCH --mail-type=FAIL,BEGIN,END
#SBATCH -J evalModel_chr1

cd $SLURM_SUBMIT_DIR

OUTPUT_DIR="${PWD}/output_chr21_"$exp
LOG_DIR="${OUTPUT_DIR}/logs"
OUTPUT_DIR_TRAINING="${PWD}/output_chr1_"$exp/training_output


singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ --bind input:${OUTPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/model_eval \
--dataset_config_pbtxt="${OUTPUT_DIR}/eval_set.dataset_config.pbtxt" \
--checkpoint_dir="${OUTPUT_DIR_TRAINING}" \
--batch_size=512 > "${LOG_DIR}/eval.log" 2>&1


squeue -l --job ${SLURM_JOB_ID}

