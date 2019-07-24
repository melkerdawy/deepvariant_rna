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
Models_file="${OUTPUT_DIR_TRAINING}/models.txt"

cd ${OUTPUT_DIR_TRAINING}
ls model.ckpt-*.index | cut -f 1-2 -d "." > ${Models_file}
cd -

singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ --bind input:${OUTPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/model_eval \
--dataset_config_pbtxt="${OUTPUT_DIR}/eval_set.dataset_config.pbtxt" \
--checkpoint_dir="${OUTPUT_DIR_TRAINING}" \
--keep_checkpoint_every_n_hours=0.05 \
--batch_size=512 > "${LOG_DIR}/eval.log" 2>&1

OUTPUT_DIR_TRAINING_NEW="${PWD}/output_chr1_"$exp/training_output/new
mkdir -p "${OUTPUT_DIR_TRAINING_NEW}"


#head of models.txt
cp "${line}".* "${OUTPUT_DIR_TRAINING_NEW}"
#delete the first line
while IFS= read -r line
do
#while grep hatsawy 7aga 

done < ${Models_file}

squeue -l --job ${SLURM_JOB_ID}
