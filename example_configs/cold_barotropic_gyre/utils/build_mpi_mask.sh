mkdir ../build_mpi_mask
cd ../build_mpi_mask
../../../tools/genmake2 -of ../../../tools/build_options/darwin_amd64_gfortran -mods ../code_mpi_mask -mpi
make depend
make
