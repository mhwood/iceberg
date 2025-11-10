mkdir ../build_mpi
cd ../build_mpi
../../../tools/genmake2 -of ../../../tools/build_options/darwin_amd64_gfortran -mods ../code_mpi -mpi
make depend
make
