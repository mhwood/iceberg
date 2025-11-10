mkdir ../build
cd ../build
../../../tools/genmake2 -of ../../../tools/build_options/darwin_amd64_gfortran -mods ../code
make depend
make
