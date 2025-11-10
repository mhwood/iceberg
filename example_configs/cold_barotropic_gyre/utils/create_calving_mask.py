
import os
import numpy as np
import matplotlib.pyplot as plt
import netCDF4 as nc4

def create_calving_mask():

    # describe the grid
    n_rows = 62
    n_cols = 62

    # read in the calving locations
    location_file = os.path.join('..', 'namelist_mpi', 'calving_locations.txt')
    calving_locations = np.genfromtxt(location_file)

    Locations = np.zeros((n_rows, n_cols))
    counter = 1
    for loc in calving_locations:
        tile_number = int(loc[1])
        tile_i = int(loc[2])
        tile_j = int(loc[3])
        sNx = 31
        sNy = 31
        n_tiles_y = n_rows // sNy
        tile_col = tile_number // n_tiles_y
        tile_row = tile_number % n_tiles_y
        # determine the global i,j (procs count up cols)
        global_i = tile_col * sNx + (tile_i - 1)
        global_j = tile_row * sNy + (tile_j - 1)
        Locations[global_j, global_i] = counter
        counter += 1

    plt.pcolormesh(Locations)
    C = plt.colorbar()
    plt.show()

    # save the calving mask to a binary file
    Locations.ravel('C').astype('>f4').tofile(os.path.join('..', 'namelist_mpi_mask', 'calving_mask.bin'))


create_calving_mask()



