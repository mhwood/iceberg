import numpy as np
import os
import pandas as pd
import argparse


def mapping_to_row_and_col(coordinate_list, grid_path, n_rows, n_cols):
    model_grid = np.fromfile(os.path.join(grid_path), '>f8').reshape((16, n_rows + 1, n_cols + 1))
    # recreate the grids that will be used in the model
    XC = model_grid[0, :-1, :-1]
    YC = model_grid[1, :-1, :-1]
    coordinate = np.zeros((n_rows, n_cols, 2), dtype=np.float32)
    for row in range(n_rows):
        for col in range(n_cols):
            coordinate[row, col] = (XC[row, col], YC[row, col])

    glacier_map = []
    for loc in coordinate_list:
        glacier_map.append(look_up(loc[0], loc[1], coordinate, loc[2]))
    return glacier_map


def get_distance(x1, y1, x2, y2):
    if x1 != 0 and x2 != 0 and y1 != 0 and y2 != 0:
        return np.hypot(x2 - x1, y2 - y1)
    return 10000000


def look_up(x, y, coordinate, gate_name):
    min_loc = (-1, -1, 100000)
    for row in range(coordinate.shape[0]):
        for col in range(coordinate.shape[1]):
            distance = get_distance(coordinate[row, col, 0], coordinate[row, col, 1], x, y)
            if distance < min_loc[2]:
                min_loc = (row, col, distance)
    return x, y, min_loc[0], min_loc[1], gate_name


# I/O functions
def read_glacier_loc_from_loc_file(loc_file_path: str):
    return np.load(loc_file_path, allow_pickle=True)


def write_glacier_loc_to_loc_file(data, output_path: str):
    df = pd.DataFrame(data, columns=['x', 'y', 'row', 'col', 'name'])
    df.to_csv(os.path.join(output_path, 'glacier_loc.csv'))


def look_up_nearest_coastline_point(x, y, coastline_points, gate_name):
    min_loc = (-1, -1, 100000)
    for row in coastline_points:
        distance = get_distance(int(row[0]), int(row[1]), x, y)
        if distance < min_loc[2]:
            min_loc = (row[0], row[1], distance)
    return int(min_loc[0]), int(min_loc[1]), gate_name


def create_calving_location_grid(glacier_location_list, coastline_points):
    output_grid = []
    counter = 1

    for glacier in range(len(glacier_location_list)):
        row, col, name = look_up_nearest_coastline_point(glacier_location_list[glacier][2],
                                                         glacier_location_list[glacier][3], coastline_points,
                                                         glacier_location_list[glacier][4])
        # print(glacier+' ('+str(glacier)+')')

        # for i in range(len(rows)):
        # multiple glaciers can calve into the same spot
        row_index = counter - 1
        # output_grid[row_index, 0] = counter
        # output_grid[row_index, 1] = row+1 # col in fortran counting (!)
        # output_grid[row_index, 2] = col+1 # row in fortran counting (!)
        # output_grid[row_index, 3] = name
        output_grid.append([counter, row + 1, col + 1, name])
        counter += 1

    # output_grid = output_grid[output_grid[:,0]!=0,:]

    return output_grid


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate calving schedules for glaciers")
    parser.add_argument(
        "--input_folder",
        type=str,
        required=False,
        default='data',
        help="Path to the input folder containing necessary files data"
    )

    args = parser.parse_args()

    input_folder = args.input_folder
    grid_path = os.path.join(input_folder, 'greenland.mitgrid')

    locations = read_glacier_loc_from_loc_file(os.path.join(input_folder, 'gate_loc.npy'))
    mapped = mapping_to_row_and_col(locations, grid_path, 360, 180)

    coastline_points = np.load(os.path.join(input_folder, 'coast_line_points.npy'), allow_pickle=True)
    mapped_points = create_calving_location_grid(coastline_points=coastline_points, glacier_location_list=mapped)
    df_mapped = pd.DataFrame(mapped_points, columns=['index', 'mapped_row', 'mapped_col', 'name'])
    df_original = pd.DataFrame(mapped, columns=['x', 'y', 'row', 'col', 'name'])

    merged_df = pd.merge(df_original, df_mapped, on='name')
    merged_df.to_csv(os.path.join(input_folder, 'glacier_data.csv'), index=False)
