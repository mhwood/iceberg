import numpy as np
import matplotlib.pyplot as plt
import seaborn as sb
import os
import argparse

def mapping_to_cores(arr, nrow, ncol, nX, nY, exch2: bool = False):
    dX = ncol / nX
    dY = nrow / nY

    core_coords = []

    for i in range(nY):
        for j in range(nX):
            core_coords.append([dX * i, j * dY])
    
    core_coords = np.array(core_coords)
    if exch2:
        sort_indices = np.lexsort((core_coords[:,1], core_coords[:,0]))
        core_coords = core_coords[sort_indices]
    else:
        sort_indices = np.lexsort((core_coords[:,0], core_coords[:,1]))
        core_coords = core_coords[sort_indices]

    new_location_arr = []
    for coord in range(len(arr)):
        distance = 1000000000
        tmp_coord = []
        for i, core in enumerate(core_coords):
            if (arr[coord,1] >= core[0] and arr[coord,2] >= core[1]): #Ensure in the first quartet of core's origin
                tmp_distance = np.sqrt((arr[coord,1] - core[0]) ** 2 + (arr[coord,2] - core[1]) ** 2)
                if tmp_distance < distance:
                    distance = tmp_distance
                    tmp_coord = [coord, i, arr[coord,1], arr[coord,2]]
        new_location_arr.append(tmp_coord)
    
    return np.array(new_location_arr)
    
def debug_visualization(arr):
    new_location_arr = np.array(new_location_arr).astype(int)

    plt.xlim(0, ncol)
    plt.ylim(0, nrow)
    sb.set_palette("bright")
    ax = sb.scatterplot(
        y=new_location_arr[:,1],
        x=new_location_arr[:,2],
        hue=new_location_arr[:,0],
        palette="bright"
    )

    for i in range(1, nY):
        ax.axhline(y=dX*i, color='black')
    for i in range(1, nX):
        ax.axvline(x=dY*i, color='black')
    
    ax.show()

def write_calving_location_file(output_path, output_table):
    output = ''

    for row in range(np.shape(output_table)[0]):
        for col in range(np.shape(output_table)[1]):
            # output+='{:<4.1f}'.format(output_table[row,col])
            if col == 0:
                output += str(output_table[row, col]).rjust(6, ' ')
            elif col == 1:
                output += str(output_table[row, col]).rjust(7, ' ')
            elif col == 2:
                output += str(output_table[row, col]).rjust(7, ' ')
            elif col == 3:
                output += str(output_table[row, col]).rjust(7, ' ') + '   '
        if row < np.shape(output_table)[0] - 1:
            output += '\n'

    f = open(os.path.join(output_path, 'new_calving_locations.txt'), 'w')
    f.write(output)
    f.close()
    
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Generate calving schedules for glaciers")
    parser.add_argument(
        "-i", "--input_path",
        
        type=str,
        required=True,
        help="Path to the original calving_location.txt"
    )
    parser.add_argument(
        "--output_path",
        type=str,
        required=False,
        default='.',
        help="Path to output folder"
    )
    parser.add_argument(
        "--nx",
        type=int,
        required=True,
        help="Number of processors in X axis of the grid"
    )
    parser.add_argument(
        "--ny",
        type=int,
        required=True,
        help="Number of processors in Y axis of the grid"
    )
    parser.add_argument(
        "--nr",
        type=int,
        required=True,
        help="Number of rows in the grid"
    )
    parser.add_argument(
        "--nc",
        type=int,
        required=True,
        help="Number of cols in the grid"
    )
    parser.add_argument(
        "-e", "--exch",
        type=int,
        required=True,
        help="1 if enable exch2, 0 otherwise"
    )
    input_path = parser.parse_args().input_path
    output_path = parser.parse_args().output_path
    arr = np.loadtxt(input_path)
    nX = parser.parse_args().nx
    nY = parser.parse_args().ny
    nrow = parser.parse_args().nr
    ncol = parser.parse_args().nc
    exch2 = parser.parse_args().exch
    
    if ((ncol % nX != 0) or (nrow % nY != 0)):
        print(f"WARNING: nPx and nPy are not divisible by calving_locations dimensions ({nrow}, {ncol})")
        
    if exch2 == 1:
        new_arr = mapping_to_cores(arr, nrow, ncol, nX, nY, True)
    else:
        new_arr = mapping_to_cores(arr, nrow, ncol, nX, nY, False)
    
    write_calving_location_file(output_path, new_arr)