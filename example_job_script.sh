#!/bin/bash

# -o: output log file: %j for the job ID, %N for the name of the first executing node
# Change the path of the output logfile

#SBATCH -J collectl_example_script
#SBATCH -N 1
#SBATCH -p CSR
#SBATCH -A csr
#SBATCH --exclusive

$HOME/collectl-slurm/collectl_slurm.sh start

# Wait for collectl to set up
sleep 10s

# Example commands (should be removed)
srun hostname

sleep 10s

#############################################
#                                           #
#     Place your commands here              #
#                                           #
#############################################

$HOME/collectl-slurm/collectl_slurm.sh stop -savelogs
