
import os
import numpy as np
import matplotlib.pyplot as plt
import netCDF4 as nc4

def create_input_files():


    # describe the grid
    n_rows = 62
    n_cols = 93

    ##################################################################################
    print(' - Creating the external forcing conditions')

    ustress_timestep = np.fromfile(os.path.join('..', 'input','windx_cosy.bin'),'>f4').reshape((n_rows, n_cols-31))

    timesteps = 4*366
    Atemp = np.zeros((timesteps, n_rows, n_cols))
    Atemp_timeseries = 270 - 10 * np.cos(2 * np.pi * np.arange(timesteps) / timesteps)
    Swdown = np.zeros((timesteps, n_rows, n_cols))
    Swdown_timeseries = 150 - 150*np.cos(2*np.pi*np.arange(timesteps)/timesteps)
    Lwdown = 250*np.ones((timesteps, n_rows, n_cols))
    Ustress = np.zeros((timesteps, n_rows, n_cols))

    for row in range(n_rows):
        for col in range(n_cols):
            Atemp[:, row, col] = Atemp_timeseries
            Swdown[:, row, col] = Swdown_timeseries

    for t in range(timesteps):
        Ustress[t, :, 31:] = ustress_timestep

    if 'exf' not in os.listdir(os.path.join('..','input_blanklist')):
        os.mkdir(os.path.join('..','input_blanklist','exf'))
    Atemp.ravel('C').astype('>f4').tofile(os.path.join('..', 'input_blanklist', 'exf','Atemp_2016'))
    Swdown.ravel('C').astype('>f4').tofile(os.path.join('..', 'input_blanklist', 'exf', 'Swdown_2016'))
    Lwdown.ravel('C').astype('>f4').tofile(os.path.join('..', 'input_blanklist', 'exf', 'Lwdown_2016'))
    Ustress.ravel('C').astype('>f4').tofile(os.path.join('..', 'input_blanklist', 'exf', 'Ustress_2016'))

    ##################################################################################
    print(' - Creating the initial conditions')

    pickup_grid = np.fromfile(os.path.join('..', 'input', 'pickup.0000000001.data'), '>f8').reshape((9, n_rows, n_cols-31))
    new_grid = np.zeros((9, n_rows, n_cols))
    new_grid[:, :, 31:] = pickup_grid
    new_grid.ravel('C').astype('>f8').tofile(os.path.join('..', 'input_blanklist', 'pickup.0000000001.data'))

    ##################################################################################
    print(' - Creating the bathymetry file')

    bathy_grid = np.fromfile(os.path.join('..', 'input', 'bathy.bin'), '>f4').reshape((n_rows, n_cols-31))
    new_bathy_grid = np.zeros((n_rows, n_cols))
    new_bathy_grid[:, 31:] = bathy_grid
    new_bathy_grid.ravel('C').astype('>f4').tofile(os.path.join('..', 'input_blanklist', 'bathy.bin'))

create_input_files()



