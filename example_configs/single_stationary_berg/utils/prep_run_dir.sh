mkdir ../run
cd ../run
ln -s ../build/mitgcm .
ln -s ../input/* .
ln -s ../namelist/* .
mkdir ../run/diags
mkdir ../run/diags/IBMATMCV
mkdir ../run/diags/IBMSOLAR
mkdir ../run/diags/IBMSUBPF
mkdir ../run/diags/IBMWVESM
mkdir ../run/diags/iceberg
mkdir ../run/diags/dye_day_snap
echo "use 'mpirun -n 1 mitgcmuv' in the run dir to run the model"