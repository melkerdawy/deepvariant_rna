#!/bin/bash -login
#SBATCH --nodes=1 --ntasks=1
#SBATCH --time=72:00:00
#SBATCH --mem=128G
#SBATCH -A ged
#SBATCH --mail-type=FAIL,BEGIN,END
#SBATCH -J trainModel_chr1

cd $SLURM_SUBMIT_DIR

#INPUT_DIR="${PWD}/input"
OUTPUT_DIR="${PWD}/output_chr1_"$exp
LOG_DIR="${OUTPUT_DIR}/logs"
OUTPUT_DIR_TRAINING="${OUTPUT_DIR}/training_output"
mkdir -p "${OUTPUT_DIR_TRAINING}"
WES_PRETRAINED_MODEL="${PWD}/models/wes/model.ckpt"

singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ --bind input:${OUTPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/model_train \
--dataset_config_pbtxt="${OUTPUT_DIR}/training_set.dataset_config.pbtxt" \
--train_dir="${OUTPUT_DIR_TRAINING}" \
--keep_checkpoint_every_n_hours=0.05 \
--model_name="inception_v3" \
--number_of_steps=50000 \
--save_interval_secs=300 \
--batch_size=512 \
--learning_rate=0.01 \
--start_from_checkpoint="${WES_PRETRAINED_MODEL}" > "${LOG_DIR}/train.log" 2>&1


squeue -l --job ${SLURM_JOB_ID}

