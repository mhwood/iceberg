mkdir ../build_mpi_exch2
cd ../build_mpi_exch2
../../../tools/genmake2 -of ../../../tools/build_options/darwin_amd64_gfortran -mods ../code_mpi_exch2 -mpi
make depend
make
