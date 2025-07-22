import pandas
import pandas as pd
import numpy as np
import os
import netCDF4 as nc4
import datetime
from eccoseas.downscale import hFac
import copy

input_dir = 'data'
data_dir = 'data/Glacier'


def import_flux_data():
    flux_data = nc4.Dataset(os.path.join(data_dir, 'Ice Flux Timeseries.nc'))
    flux_df = np.zeros((len(flux_data.variables), flux_data.dimensions['dec_yr'].size))
    for i, val in enumerate(flux_data.variables):
        flux_df[i] = flux_data.variables[val][:]

    flux_df = flux_df.T
    flux_df = pd.DataFrame(flux_df, columns=list(flux_data.variables.keys()))
    flux_df.set_index('dec_yr', inplace=True)
    flux_df.sort_index(ascending=True, inplace=True)

    return flux_df

def import_bathy_mask_map():
    n_rows = 360
    n_cols = 180

    model_grid = np.fromfile(os.path.join(input_dir, 'greenland.mitgrid'), '>f8').reshape((16, n_rows + 1, n_cols + 1))
    # recreate the grids that will be used in the model
    XC = model_grid[0, :-1, :-1]
    YC = model_grid[1, :-1, :-1]

    # read in the bathymetry file
    bathy = np.fromfile(os.path.join(input_dir, 'greenland_bathymetry.bin'), '>f4').reshape(np.shape(XC))
    surface_mask = hFac.create_surface_hFacC_grid(bathy, delR=1)
    return surface_mask.tolist()

# Iterator strategy for tracking current browsed glacier
class GlacierIterator:
    def __init__(self, gate_list):
        self.data = gate_list
        self.index = 1

    def __iter__(self):
        return self

    def __next__(self):
        value = self.data[self.index]
        self.index = (self.index + 1) % len(self.data)
        return value

    def prev(self):
        # Move index back, wrapping around cyclically
        self.index = (self.index - 1) % len(self.data)
        value = self.data[self.index - 1]
        return value

    def jump_to(self, gate_number):
        if gate_number in self.data:
            self.index = self.data.index(gate_number)
        else:
            raise ValueError(f"Gate number {gate_number} not found in data list.")


class DataCollector:
    def __init__(self):
        if os.path.exists(os.path.join(input_dir, 'glacier_data.csv')):
            self.df = pd.read_csv(os.path.join(input_dir, 'glacier_data.csv'))
            self.df['gate_no'] = self.df['name'].apply(lambda x: int(x.split("_")[0]))
        else:
            self.df = pd.DataFrame(columns=['x','y','row','col','name','index','mapped_row','mapped_col'])
        self.iterator = GlacierIterator(self.df['gate_no'].tolist())
        self.flux_df = import_flux_data()

        n_rows = 360
        n_cols = 180
        model_grid = np.fromfile(os.path.join(input_dir, 'greenland.mitgrid'), '>f8').reshape(
            (16, n_rows + 1, n_cols + 1))
        self.XC = model_grid[0, :-1, :-1]
        self.YC = model_grid[1, :-1, :-1]

        self.mask_map = import_bathy_mask_map()

    def get_available_gate_numbers(self):
        return self.df['gate_no'].tolist()

    def get_next_available_gate_number(self):
        return next(self.iterator)

    def get_previous_available_gate_number(self):
        return self.iterator.prev()

    def set_current_gate_number(self, gate_no):
        self.iterator.jump_to(gate_no)

    def get_gate_index(self, gate_number):
        return '{:03d}'.format(self.df.index[self.df['gate_no'] == gate_number].item() + 1)

    def get_all_glacier_loc_data(self, gate_number):
        if gate_number in self.get_available_gate_numbers():
            return self.df[self.df['gate_no'] == gate_number].iloc[0, :]
        else:
            return self.df.iloc[0, :]

    def get_glacier_original_coordinates(self, gate_number):
        data = self.get_all_glacier_loc_data(gate_number)
        return data['x'], data['y']

    def get_glacier_original_row_col(self, gate_number):
        data = self.get_all_glacier_loc_data(gate_number)
        return data['row'], data['col']

    def get_glacier_mapped_coordinate(self, gate_number):
        row, col = self.get_glacier_mapped_row_col(gate_number)
        return self.lookup_coordinate_from_row_col(row, col)

    def get_glacier_mapped_row_col(self, gate_number):
        data = self.get_all_glacier_loc_data(gate_number)
        return data['mapped_row'], data['mapped_col']

    def get_glacier_name(self, gate_number):
        data = self.get_all_glacier_loc_data(gate_number)
        return ' '.join(data['name'].split('_')[1:])

    def get_full_glacier_name(self, gate_number):
        data = self.get_all_glacier_loc_data(gate_number)
        return data['name']

    def lookup_coordinate_from_row_col(self, row, col):
        return self.XC[row, col], self.YC[row, col]

    def get_flux_data_by_year(self, gate_number, year) -> pandas.Series:
        gate_name = self.get_all_glacier_loc_data(gate_number)['name']
        return self.flux_df[(self.flux_df.index >= float(year)) & (self.flux_df.index < float(year + 1))][gate_name]

    def get_glacier_dimension(self, gate_number):
        name = self.get_glacier_name(gate_number)
        file_path = os.path.join(input_dir, 'calving_schedules','1992')
        origin = datetime.datetime(1992, 1, 1)
        file = os.path.join(file_path, f'calving_schedule_{self.get_gate_index(gate_number)}')
        df = np.fromfile(file, '>f8')
        df = df.reshape((4, int(len(df) / 4))).T
        df = df[np.where(df[:, 0] != 0)]
        time = origin + pd.to_timedelta(df[:, 0], unit='s')

        return name, time, df

    def get_log_count_by_year(self, gate_number, year = 2015):
        gate_name = self.get_full_glacier_name(gate_number)
        ds = nc4.Dataset(os.path.join(data_dir, 'Iceberg Size Distribution.nc'))
        vol = np.array(ds[gate_name]['volume'])
        count = np.array(ds[gate_name]['iceberg_count'][year-1990, :])
        data = np.stack([vol, count], axis=1)
        data = data[data[:,1] != 0]
        data = np.log10(data)
        data = data[data[:, 1] != 0]
        return data

    def get_mask_map_with_points(self, gate_number):
        data = self.get_all_glacier_loc_data(gate_number)
        mask_map = copy.deepcopy(self.mask_map)
        mask_map[data['row']][data['col']] = 2
        mask_map[data['mapped_row']][data['mapped_col']] = 3
        return mask_map
