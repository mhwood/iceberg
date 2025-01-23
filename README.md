# Iceberg Modeling in MITgcm

This repository contains updates and example configurations that I've constructed for the mitberg package, developed by Alan Condron. The mitberg package is archived and available on Zenodo [HERE](https://zenodo.org/records/6518059). 

## Adding the iceberg package
To add the iceberg package to your local version of MITgcm, use the following utility:

```
cd iceberg/utils
python copy_iceberg_pkg_to_mitgcm.py -m /path/to/MITgcm -c /path/to/code/mods/dir
```
