mkdir ../run
cd ../run
ln -s ../build/mitgcmuv .
ln -s ../input/* .
ln -s ../namelist/* .
mkdir ../run/diags
mkdir ../run/diags/iceberg
echo "use './mitgcmuv > output.txt' in the run dir to run the model"