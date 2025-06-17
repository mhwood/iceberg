import argparse
import netCDF4 as nc4
import numpy as np
import os
from eccoseas.downscale import hFac

def read_gate_file(location_path: str):
    ds = nc4.Dataset(os.path.join(location_path,'gate.nc'))
    gates = ds.variables['gate']
    lon = ds.variables['mean_lon'][:]
    lat = ds.variables['mean_lat'][:]
    name_mouginot = ds.variables['name_Mouginot'][:]

    for gate in gates:
        index = np.where(gates==gate)[0][0]
        print('Reading '+name_mouginot[index])
        name_mouginot[index] = str(gate) + '_' + str(name_mouginot[index])

    return np.array([lon, lat, name_mouginot]).T


def write_gate_loc_file(output_path: str, arr: np.ndarray):
    np.save(os.path.join(output_path,'gate_loc.npy'), arr)
    print(f'Saved gate_loc.npy in {output_path}')


def camelize(x: str): # To transform all capitalized to camel case
    parts=x.split('_')
    parts = [part.capitalize() for part in parts]
    return '_'.join(parts)


def finding_coastline_points(input_dir='data', center_row=275, center_col=130, min_row= 160, max_row=345, min_col=50) -> list:
    n_rows = 360
    n_cols = 180

    model_grid = np.fromfile(os.path.join(input_dir, 'greenland.mitgrid'), '>f8').reshape((16, n_rows + 1, n_cols + 1))
    # recreate the grids that will be used in the model
    XC = model_grid[0, :-1, :-1]
    YC = model_grid[1, :-1, :-1]

    # read in the bathymetry file
    bathy = np.fromfile(os.path.join(input_dir, 'greenland_bathymetry.bin'), '>f4').reshape(np.shape(XC))
    surface_mask = hFac.create_surface_hFacC_grid(bathy, delR=1)

    center = (center_row, center_col)
    coastline_points = []

    for i in range(160, 345):  # we don't care about edge points. Also, avoid northern points as conflicted with Canada mainlands

        for j in range(50, n_cols - 1):
            if surface_mask[i][j]:
                # First quadrant (bottom-right)
                if i > center[0] and j > center[1]:
                    if surface_mask[i][j - 1] == 0 and surface_mask[i][j + 1] == 1:
                        coastline_points.append([i,j])
                    elif surface_mask[i - 1][j] == 0 and surface_mask[i + 1][j] == 1:
                        coastline_points.append([i,j])

                # Second quadrant (bottom-left)
                elif i > center[0] and j < center[1]:
                    if surface_mask[i][j - 1] == 1 and surface_mask[i][j + 1] == 0:
                        coastline_points.append([i,j])
                    elif surface_mask[i - 1][j] == 0 and surface_mask[i + 1][j] == 1:
                        coastline_points.append([i,j])

                # Third quadrant (top-left)
                elif i < center[0] and j < center[1]:
                    if surface_mask[i][j - 1] == 1 and surface_mask[i][j + 1] == 0:
                        coastline_points.append([i,j])
                    elif surface_mask[i - 1][j] == 1 and surface_mask[i + 1][j] == 0:
                        coastline_points.append([i,j])

                # Fourth quadrant (top-right)
                elif i < center[0] and j > center[1]:
                    if i < 220 and j > 145:
                        continue
                    if surface_mask[i][j - 1] == 0 and surface_mask[i][j + 1] == 1:
                        coastline_points.append([i,j])
                    elif surface_mask[i - 1][j] == 1 and surface_mask[i + 1][j] == 0:
                        coastline_points.append([i,j])

    return coastline_points


def write_coastline_points(output_dir, coastline_points: list):
    np.save(arr=coastline_points, file=os.path.join(output_dir, 'coast_line_points.npy'))
    print(f'Saved coastline_points.npy in {output_path}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument("-d", "--config_dir", action="store",
                        help="The directory where the gate.nc file is stored.", dest="location_path",
                        default='data',
                        type=str, required=False)
    parser.add_argument("-o", "--output_dir", action="store",
                        help="The directory where the output file will be stored.", dest="output_path",
                        default='data',
                        type=str, required=False)
    parser.add_argument("-g", "--grid_dir", action="store",
                        help="The directory where the mitgrid file will be stored.", dest="grid_dir",
                        default='data',
                        type=str, required=False)

    location_path = parser.parse_args().location_path
    output_path = parser.parse_args().output_path
    grid_dir = parser.parse_args().grid_dir
    write_gate_loc_file(output_path, read_gate_file(location_path))
    coastline_points = finding_coastline_points(input_dir=grid_dir) # modify this to customize search range
    write_coastline_points(output_path, coastline_points)
