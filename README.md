# Iceberg Modeling in MITgcm

This repository contains updates and example configurations that I've constructed for the mitberg package, developed by Alan Condron. The mitberg package is archived and available on Zenodo [HERE](https://zenodo.org/records/6518059). 

## Adding the iceberg package
To add the iceberg package to your local version of MITgcm, use the following utility:

```
cd iceberg/utils
python copy_iceberg_pkg_to_mitgcm.py -m /path/to/MITgcm -c /path/to/code/mods/dir
```

## Using the iceberg package
To use the iceberg package from this repository in a configuration, there are a few compile time and run time files to configure.

### Compile time files
There are two compile time files to consider:
- ICEBERG_OPTIONS.h
  
  Contains many options to turn on or off different parts of the compiled code.
  
- ICEBERG_SIZE.h
  
  Defines the maximum number of icebergs that can exist in a simulation, the length of the calving schedule, and the number of calving locations. Each of these parameters sets the size of an array and associated loops in the compiled code.

### Run time files

There are several files to consider at run time:
- data.iceberg
- calving_locations.txt
- calving schedules
