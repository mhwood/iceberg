# Glacier Calving Schedule Maker Application

Welcome to the Glacier Calving Schedule Maker. This is the tool to generate calving schedules from Greenland's glaciers
(gate) data for the iceberg simulation model using MIT-gcm.


## Package Requirements:

In order for the app to run, you need the following packages install in your Python environment:

- Pandas
- NumPy
- scipy
- Dash
- Plotly
- NetCDF4
- Dash Bootstrap Components

Run the following commands to install the required packages:

### Using conda:
```bash
conda create -n ocean python=3.11
conda activate ocean
conda install pandas numpy dash plotly scipy
conda install conda-forge::netcdf4 
conda install conda-forge::dash-bootstrap-components
```

### Using pip
```bash
python3 -m venv ocean
source ocean/bin/activate
pip install pandas numpy scipy dash plotly netCDF4 dash-bootstrap-components
```

## Input and Requirements:

The input files for this app are:

- Glacier Gate Dataset: `gate.nc`
- Greenland Grid: `greenland.mitgrid`
- Greenland Bathymetry Dataset: `greenland_bathymetry.bin`

*IMPORTANT:* All files *MUST* be placed in the `data` folder

## Run the app:

In your terminal application window, go to `src` folder and execute

```bash
python index.py
```

## Folder Structure:

- [src](src/) contains all source codes
  - [src/data](src/data): contains input and output files
  - [src/assets](src/assets): contains stylesheets for the website

