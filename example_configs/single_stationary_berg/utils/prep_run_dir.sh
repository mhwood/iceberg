mkdir ../run
cd ../run
ln -s ../build/mitgcmuv .
ln -s ../input/* .
ln -s ../namelist/* .
cp ../run/data_daily.diagnostics ../run/data.diagnostics
mkdir ../run/diags
mkdir ../run/diags/IBMATMCV
mkdir ../run/diags/IBMSOLAR
mkdir ../run/diags/IBMSUBPF
mkdir ../run/diags/IBMWVESN
mkdir ../run/diags/iceberg
mkdir ../run/diags/dye_day_snap
echo "use one of the following command in the run dir to run the model:"
echo "use 'mpirun -n 1 mitgcmuv' if compiled with MPI"
echo "use './mitgcmuv' if compiled without MPI"