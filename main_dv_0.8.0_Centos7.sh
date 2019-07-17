#!/bin/sh

#  building_0.8.0_Centos7.sh
#  
#
#  Created by Tamer Mansour on 6/7/19.
#  

# I subscribed for CentOS in AWS marketplace https://aws.amazon.com/mp/centos/ Then choosed to run from EC2 and continued as usual but expand the storage to 40 GB (login as the user "centos" rather than the user "root")

# 1) singularity 2.6.0 installation:

#confirm Dependencies  ## many packages were excluded bc not avaiable in centos e.g. build-essential, libssl-dev, uuid-dev, libgpgme11-dev, libseccomp-dev, pkg-config
sudo yum update
sudo yum install -y squashfs-tools

sudo yum install -y python-virtualenv
sudo yum install -y gcc

#singularity # https://github.com/sylabs/singularity/blob/2.5.2/INSTALL.md
sudo yum groupinstall "Development Tools"
sudo yum install wget
sudo yum install libarchive-devel
#VER=2.6.0
VER=2.5.2
wget https://github.com/sylabs/singularity/releases/download/$VER/singularity-$VER.tar.gz
tar xvf singularity-$VER.tar.gz
cd singularity-$VER
./configure --prefix=/usr/local
make
sudo make install
cd ..


# 2) docker installation
#INSTALL DOCKER  ## https://github.com/NaturalHistoryMuseum/scratchpads2/wiki/Install-Docker-and-Docker-Compose-(Centos-7)
sudo yum update
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce
sudo usermod -aG docker $(whoami)
sudo systemctl enable docker.service
sudo systemctl start docker.service

# 4) creating the container
sudo docker pull gcr.io/deepvariant-docker/deepvariant:0.8.0
sudo docker tag gcr.io/deepvariant-docker/deepvariant:0.8.0 localhost:5000/deepvariant:latest
sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2
sudo docker push localhost:5000/deepvariant:latest
SINGULARITY_NOHTTPS=1 singularity build deepvariant.simg docker://localhost:5000/deepvariant:latest

#Download the test bundle:
INPUT_DIR="${PWD}/quickstart-testdata"
DATA_HTTP_DIR="https://storage.googleapis.com/deepvariant/quickstart-testdata"
mkdir -p ${INPUT_DIR}
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/NA12878_S1.chr20.10_10p1mb.bam
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/NA12878_S1.chr20.10_10p1mb.bam.bai
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/test_nist.b37_chr20_100kbp_at_10mb.bed
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/test_nist.b37_chr20_100kbp_at_10mb.vcf.gz
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/test_nist.b37_chr20_100kbp_at_10mb.vcf.gz.tbi
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/ucsc.hg19.chr20.unittest.fasta
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/ucsc.hg19.chr20.unittest.fasta.fai
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/ucsc.hg19.chr20.unittest.fasta.gz
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/ucsc.hg19.chr20.unittest.fasta.gz.fai
wget -P ${INPUT_DIR} "${DATA_HTTP_DIR}"/ucsc.hg19.chr20.unittest.fasta.gz.gzi

singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/  \
deepvariant.simg \
/opt/deepvariant/bin/run_deepvariant \
--model_type=WGS \
--ref=${INPUT_DIR}/ucsc.hg19.chr20.unittest.fasta \
--reads=${INPUT_DIR}/NA12878_S1.chr20.10_10p1mb.bam \
--regions "chr20:10,000,000-10,010,000" \
--output_vcf=output.vcf.gz \
--output_gvcf=output.g.vcf.gz

singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ \
deepvariant.simg \
/opt/deepvariant/bin/make_examples \
--mode calling \
--ref=${INPUT_DIR}/ucsc.hg19.chr20.unittest.fasta \
--reads=${INPUT_DIR}/NA12878_S1.chr20.10_10p1mb.bam \
--examples output.examples.tfrecord \
--regions "chr20"


# 5) running the scripts through singularity on the HPC
# cp the file simg file to your working directory on HPC.
## copy to HPC ## remember to change the ec2 ip address
scp -i "10012018_EC2Key.pem" centos@ec2-3-82-97-175.compute-1.amazonaws.com:/home/centos/deepvariant.simg .

INPUT_DIR="${PWD}/quickstart-testdata"
singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ --bind input:${INPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/run_deepvariant \
--model_type=WGS \
--ref=${INPUT_DIR}/ucsc.hg19.chr20.unittest.fasta \
--reads=${INPUT_DIR}/NA12878_S1.chr20.10_10p1mb.bam \
--regions "chr20" \
--output_vcf=output.vcf.gz \
--output_gvcf=output.g.vcf.gz

INPUT_DIR="${PWD}/quickstart-testdata"
singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ --bind input:${INPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/make_examples \
--mode calling \
--ref=${INPUT_DIR}/ucsc.hg19.chr20.unittest.fasta \
--reads=${INPUT_DIR}/NA12878_S1.chr20.10_10p1mb.bam \
--examples output.examples.tfrecord \
--regions "chr20"

#Traceback (most recent call last):
#File "/tmp/Bazel.runfiles_Zo2roG/runfiles/com_google_deepvariant/deepvariant/make_examples.py", line 41, in <module>
#import numpy as np
#File "/mnt/home/mansourt/.local/lib/python2.7/site-packages/numpy/__init__.py", line 142, in <module>
# ....
#ImportError:
#Importing the multiarray numpy extension module failed.  Most
#likely you are trying to import a failed build of numpy.
#If you're working with a numpy git repo, try `git clean -xdf` (removes all
#files not under version control).  Otherwise reinstall numpy.
#Original error was: libmkl_rt.so: cannot open shared object file: No such file or directory



### Trials with virual environment
##################################
alias python=python2   ## which python     >  /usr/bin/python2   && python --version  > Python 2.7.5
#pip install --upgrade pip                       ## part of miniconda
#pip install --upgrade --force-reinstall numpy   ## it seems to be installed in user python2 but did not fix the error
#pip install --upgrade --force-reinstall virtualenv  ## Successfully installed virtualenv-16.6.0 in miniconda ## it does not install in the user python2

cd ~
curl --location --output virtualenv-16.6.0.tar.gz https://github.com/pypa/virtualenv/tarball/16.6.0
tar xvfz virtualenv-16.6.0.tar.gz
cd pypa-virtualenv-8cd7254
python virtualenv.py ~/env-deepVar
source ~/env-deepVar/bin/activate  # which python  > ~/env-deepVar/bin/python2
pip install numpy
pip install mkl
pip install dlib
pip uninstall numpy scipy -y
pip install intel-scipy
pip uninstall dlib

cd $SCRATCH/Tamer2/kerdawy
INPUT_DIR="${PWD}/quickstart-testdata"
singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ --bind input:${INPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/make_examples \
--mode calling \
--ref=${INPUT_DIR}/ucsc.hg19.chr20.unittest.fasta \
--reads=${INPUT_DIR}/NA12878_S1.chr20.10_10p1mb.bam \
--examples output.examples.tfrecord \
--regions "chr20"



### Trials with plan conda environment
#######################################
source activate workEnv1  # python 2.7.15
conda install nomkl numpy scipy scikit-learn numexpr
conda remove mkl mkl-service
conda install tensorflow

INPUT_DIR="${PWD}/quickstart-testdata"
singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ --bind input:${INPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/make_examples \
--mode calling \
--ref=${INPUT_DIR}/ucsc.hg19.chr20.unittest.fasta \
--reads=${INPUT_DIR}/NA12878_S1.chr20.10_10p1mb.bam \
--examples output.examples.tfrecord \
--regions "chr20"

## 2019-06-07 19:29:48.884907: F tensorflow/python/lib/core/bfloat16.cc:675] Check failed: PyBfloat16_Type.tp_base != nullptr

pip uninstall numpy
INPUT_DIR="${PWD}/quickstart-testdata"
singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/ --bind input:${INPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/make_examples \
--mode calling \
--ref=${INPUT_DIR}/ucsc.hg19.chr20.unittest.fasta \
--reads=${INPUT_DIR}/NA12878_S1.chr20.10_10p1mb.bam \
--examples output.examples.tfrecord \
--regions "chr20"
##############################


## Run using parallel on HPC
#sbatch make_examples.sh
sbatch --export="exp=directAlign,bam=reads.bam" make_examples_chr21.sh
sbatch --export="exp=directAlign,bam=reads.bam" make_examples_chr1.sh

## Shuffling using a tool on deep variant web site develpoed for Shuffle tf.Example files using beam
SHUFFLE_SCRIPT_DIR="${PWD}/tools"
mkdir -p ${SHUFFLE_SCRIPT_DIR}
wget https://raw.githubusercontent.com/google/deepvariant/r0.8/tools/shuffle_tfrecords_beam.py -O ${SHUFFLE_SCRIPT_DIR}/shuffle_tfrecords_beam.py

conda activate workEnv1
conda install -c conda-forge python-snappy
pip install apache_beam
#source ~/env-deepVar/bin/activate   ## Python 2.7.5
#pip install apache_beam

exp=directAlign
OUTPUT_DIR="${PWD}/output_chr1_"$exp

time python ${SHUFFLE_SCRIPT_DIR}/shuffle_tfrecords_beam.py \
--input_pattern_list="${OUTPUT_DIR}/training_set.with_label.tfrecord-?????-of-00016.gz" \
--output_pattern_prefix="${OUTPUT_DIR}/training_set.with_label.shuffled" \
--output_dataset_config_pbtxt="${OUTPUT_DIR}/training_set.dataset_config.pbtxt" \
--output_dataset_name="HG001" \
--runner=DirectRunner

exp=directAlign
OUTPUT_DIR="${PWD}/output_chr21_"$exp

time python ${SHUFFLE_SCRIPT_DIR}/shuffle_tfrecords_beam.py \
--input_pattern_list="${OUTPUT_DIR}/eval_set.with_label.tfrecord-?????-of-00016.gz" \
--output_pattern_prefix="${OUTPUT_DIR}/eval_set.with_label.shuffled" \
--output_dataset_config_pbtxt="${OUTPUT_DIR}/eval_set.dataset_config.pbtxt" \
--output_dataset_name="HG0021" \
--runner=DirectRunner


## model training
## gsutil  ## https://cloud.google.com/storage/docs/listing-objects
conda create -n gsutil python=2.7
source activate gsutil
conda install -c flyem-forge gsutil-env
source activate gsutil-env
pip install oauth2client
mkdir -p models/wes
gsutil cp -R  gs://deepvariant/models/DeepVariant/0.8.0/DeepVariant-inception_v3-0.8.0+data-wes_standard/* models/wes/.

sbatch --export="exp=directAlign" model_train_chr1.sh

## Model eval
sbatch --export="exp=directAlign" model_eval_chr21.sh

## create testing dataset

INPUT_DIR="${PWD}/input"
OUTPUT_DIR_TESTING="${PWD}/testing_dataset
mkdir -p "${OUTPUT_DIR_TESTING}"

singularity -s exec -B /usr/lib/locale/:/usr/lib/locale/  --bind input:${INPUT_DIR}/ \
deepvariant.simg \
/opt/deepvariant/bin/make_examples \
--mode calling \
--ref ${INPUT_DIR}/reference.fasta.gz \
--reads ${INPUT_DIR}/$bam \
--examples ${OUTPUT_DIR_TESTING}/test_set.tfrecord.gz \
--sample_name "test" \
--regions "chr20"

