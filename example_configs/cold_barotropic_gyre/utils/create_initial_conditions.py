
import os
import numpy as np
import matplotlib.pyplot as plt
import netCDF4 as nc4

def create_input_files():


    # describe the grid
    n_rows = 62
    n_cols = 62

    ##################################################################################
    print(' - Creating the external forcing conditions')

    ustress_timestep = np.fromfile(os.path.join('..', 'input','windx_cosy.bin'),'>f4').reshape((n_rows, n_cols))

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
        Ustress[t, :, :] = ustress_timestep

    if 'exf' not in os.listdir(os.path.join('..','input')):
        os.mkdir(os.path.join('..','input','exf'))
    Atemp.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf','Atemp_2016'))
    Swdown.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf', 'Swdown_2016'))
    Lwdown.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf', 'Lwdown_2016'))
    Ustress.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf', 'Ustress_2016'))

    ##################################################################################
    print(' - Creating the calving files')

    model_times = np.zeros((1,))
    widths = np.zeros((1,))
    lengths = np.zeros((1,))
    thicknesses = np.zeros((1,))

    width_0 = 100
    length_0 = 90
    thickness_0 = 80
    calving_time = 1201

    print('      - Adding 4 icebergs of dimension (',width_0, length_0, thickness_0,') at '+str(calving_time)+' seconds into the simulation')

    model_times[0] = calving_time
    widths[0] = width_0
    lengths[0] = length_0
    thicknesses[0] = thickness_0

    output_table = np.column_stack([model_times, widths, lengths, thicknesses]).T.astype(float)
    if 'calving_schedules' not in os.listdir(os.path.join('..', 'input')):
        os.mkdir(os.path.join('..', 'input','calving_schedules'))
    for i in range(1,5):
        output_table.ravel('C').astype('>f8').tofile(os.path.join('..', 'input','calving_schedules', 'calving_schedule_00'+str(i)))

create_input_files()



