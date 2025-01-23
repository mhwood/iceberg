
import os
import numpy as np
import matplotlib.pyplot as plt
import netCDF4 as nc4

def read_model_parameters():

    file_name = os.path.join('..','input','input_conditions.nc')
    ds = nc4.Dataset(file_name)

    depth = ds.variables['depth'][:]

    timeseries = {}
    for var_name in ['Theta','Salt','Uvel','Vvel']:
        timeseries[var_name] = ds.variables[var_name.upper()][:,:]
    for var_name in ['Atemp','Lwdown','Swdown','Uwind','Vwind','Area']:
        timeseries[var_name] = ds.variables[var_name.upper()][:]

    ds.close()

    return(depth, timeseries)

def create_input_files():


    # describe the grid
    n_rows = 11
    n_cols = 11
    depth = 500

    ##################################################################################
    print(' - Creating the bathymetry')
    grid = -depth * np.ones((n_rows, n_cols))

    # make walls on the boundaries
    grid[:, 0] = 0
    grid[:, -1] = 0
    grid[0, :] = 0
    grid[-1, :] = 0

    grid.ravel('C').astype('>f4').tofile(os.path.join('..','input','square_bathymetry.bin'))

    ##################################################################################
    print(' - Reading in the model parameters')
    depths, timeseries = read_model_parameters()
    depths = depths[:50]

    ##################################################################################
    print(' - Creating the initial conditions')

    theta = timeseries['Theta'].T
    theta_profile = np.mean(theta[:,theta[0,:]!=0],axis=1)[:50]
    # theta_profile = np.interp(model_depths, depth, theta_profile, left=theta_profile[0])

    salt = timeseries['Salt'].T
    salt_profile = np.mean(salt[:, salt[0, :] != 0], axis=1)[:50]
    # salt_profile = np.interp(model_depths, depth, salt_profile, left=salt_profile[0])

    speed = (timeseries['Uvel'].T**2 + timeseries['Vvel'].T**2)**0.5
    speed_profile = np.mean(speed[:, speed[0, :] != 0], axis=1)[:50]
    print('        - Note, the mean current velocity in this simulation is '+'{:.2f}'.format(np.mean(speed_profile))+' m/s')

    # plt.subplot(1, 2, 1)
    # plt.plot(theta_profile,depths)
    # plt.gca().invert_yaxis()
    # plt.subplot(1, 2, 2)
    # plt.plot(salt_profile,depths)
    # plt.gca().invert_yaxis()
    # plt.show()

    theta_IC = np.zeros((50, n_rows, n_cols))
    salt_IC = np.zeros((50, n_rows, n_cols))
    ptrace_IC = np.zeros((50, n_rows, n_cols))
    for row in range(n_rows):
        for col in range(n_cols):
            theta_IC[:, row, col] = theta_profile
            salt_IC[:, row, col] = salt_profile

    theta_IC.ravel('C').astype('>f4').tofile(os.path.join('..','input','THETA_IC'))
    salt_IC.ravel('C').astype('>f4').tofile(os.path.join('..','input','SALT_IC'))
    ptrace_IC.ravel('C').astype('>f4').tofile(os.path.join('..','input','DYE_IC'))

    ##################################################################################
    print(' - Creating the external forcing conditions')
    #['Atemp','Lwdown','Swdown','Uwind','Vwind','Area']
    timesteps = 4*366
    Atemp = np.zeros((timesteps, n_rows, n_cols))
    Lwdown = np.zeros((timesteps, n_rows, n_cols))
    Swdown = np.zeros((timesteps, n_rows, n_cols))
    Uwind = np.zeros((timesteps, n_rows, n_cols))
    Vwind = np.zeros((timesteps, n_rows, n_cols))
    SIarea = np.zeros((timesteps, n_rows, n_cols))
    SItimeseries = timeseries['Area']
    SItimeseries[:4*31]=SItimeseries[4*31]
    for row in range(n_rows):
        for col in range(n_cols):
            Atemp[:, row, col] = timeseries['Atemp']
            Lwdown[:, row, col] = timeseries['Lwdown']
            Swdown[:, row, col] = timeseries['Swdown']
            Uwind[:, row, col] = timeseries['Uwind']
            Vwind[:, row, col] = timeseries['Vwind']
            SIarea[:, row, col] = SItimeseries

    if 'exf' not in os.listdir(os.path.join('..','input')):
        os.mkdir(os.path.join('..','input','exf'))
    Atemp.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf','Atemp_2016'))
    Lwdown.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf','Lwdown_2016'))
    Swdown.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf', 'Swdown_2016'))
    Uwind.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf', 'Uwind_2016'))
    Vwind.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf', 'Vwind_2016'))
    SIarea.ravel('C').astype('>f4').tofile(os.path.join('..', 'input', 'exf', 'SIarea_2016'))

    ##################################################################################
    print(' - Creating the calving files')

    model_times = np.zeros((1,))
    widths = np.zeros((1,))
    lengths = np.zeros((1,))
    thicknesses = np.zeros((1,))

    width_0 = 100
    length_0 = 90
    thickness_0 = 80
    calving_time = 61

    print('      - Adding an iceberg of dimension (',width_0, length_0, thickness_0,') at '+str(calving_time)+' seconds into the simulation')

    model_times[0] = calving_time
    widths[0] = width_0
    lengths[0] = length_0
    thicknesses[0] = thickness_0

    output_table = np.column_stack([model_times, widths, lengths, thicknesses]).T.astype(float)
    if 'calving_schedules' not in os.listdir(os.path.join('..', 'input')):
        os.mkdir(os.path.join('..', 'input','calving_schedules'))
    output_table.ravel('C').astype('>f8').tofile(os.path.join('..', 'input','calving_schedules', 'calving_schedule_001'))

    f = open(os.path.join('..', 'input','calving_locations.txt'),'w')
    f.write('   1.0   6.0    6.0')
    f.close()

create_input_files()



