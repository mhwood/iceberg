import argparse
import os
import numpy as np
import netCDF4 as nc4
from scipy.interpolate import interp1d

def read_flux_timeseries_from_nc(input_folder):
    file_path = os.path.join(input_folder, 'Glacier', 'Ice Flux Timeseries.nc')
    ds = nc4.Dataset(file_path)
    dec_yrs = ds.variables['dec_yr'][:]

    all_timeseries = []
    for g in list(ds.variables.keys())[1:]:
        all_timeseries.append(np.column_stack([dec_yrs,
                                               ds.variables[g][:]]))

    glacier_names = list(ds.variables.keys())[1:]
    ds.close()

    return glacier_names, all_timeseries

def compute_cumulative_flux(timeseries, year):
    timeseries_subset = np.copy(timeseries)

    timeseries_subset = timeseries_subset[timeseries_subset[:, 0] >= year, :]
    timeseries_subset = timeseries_subset[timeseries_subset[:, 0] < year + 1, :]

    cumulative_flux_timeseries = np.copy(timeseries_subset)
    cumulative_flux_timeseries[:, 1] = 0

    # plt.plot(timeseries_subset[:,0],timeseries_subset[:,1])
    # plt.show()

    for index in range(1, np.shape(cumulative_flux_timeseries)[0]):
        cumulative_flux_timeseries[index, 1] = cumulative_flux_timeseries[index - 1, 1] + \
                                               timeseries_subset[index, 1] * (
                                                       timeseries_subset[index, 0] -
                                                       timeseries_subset[index - 1, 0])

    # plt.plot(cumulative_flux_timeseries[:, 0], cumulative_flux_timeseries[:, 1])
    # plt.show()

    return (cumulative_flux_timeseries)

def compute_cumulative_flux_from_annual_mean(timeseries, year):
    timeseries_subset = np.copy(timeseries)

    dense_time = np.linspace(year, year + 1, 365)  # Daily time resolution

    interp_func = interp1d(timeseries_subset[:, 0], timeseries_subset[:, 1])
    dense_flux = interp_func(dense_time)

    mean_flux = np.mean(dense_flux)

    return (mean_flux)


def compute_iceberg_size_distribution(total_volume_flux, printing=False):
    # define some constants
    size_categories = 50
    beta = -1 * (1.95 + 1.87 + 1.62) / 3  # Sulak et al average
    max_size = 10
    min_size = 4

    # define the volume intervals
    interval_size = (max_size - min_size) / size_categories
    v = np.linspace(min_size, max_size, size_categories + 1)
    v = v[:-1] + interval_size / 2
    v_edges = np.linspace(min_size, max_size, size_categories + 1)
    v = 10 ** v
    v_edges = 10 ** v_edges

    # compute the density of fragments function
    # n(v) = c v^-beta
    # integrate over the size interval to get total number of bergs
    n = (v ** beta)

    # compute total volume to solve for c
    iceberg_volumes_test = np.zeros_like(n)
    for vi in range(len(v)):
        iceberg_volumes_test[vi] = n[vi] * v[vi] * (v_edges[vi + 1] - v_edges[vi])
    c = total_volume_flux / np.sum(iceberg_volumes_test)

    # estimate the number of bergs in each size interval
    number_of_bergs = np.zeros_like(n)
    for vi in range(len(v)):
        number_of_bergs[vi] = c * n[vi] * (v_edges[vi + 1] - v_edges[vi])

    # round the number of bergs to the nearest integer
    number_of_bergs = np.round(number_of_bergs)

    # compute difference due to rounding and adjust the categories one by one until
    # the total volume flux is matched
    total_volume_flux_check = np.sum(number_of_bergs * v)
    for k in range(100): # limit this so we don't get stuck in an infinite loop
        for vi in range(len(v)):
            if number_of_bergs[vi] > 0:
                number_of_bergs[vi] += 1
                total_volume_flux_check = np.sum(number_of_bergs * v)
                if total_volume_flux_check >= total_volume_flux:
                    break

    iceberg_volumes = np.sum(number_of_bergs * v)
    if printing:
        print('        - Total number of bergs: ' + str(np.sum(number_of_bergs)))
        print('        - Total iceberg volume: ' + str(np.sum(iceberg_volumes)) + ' (check: ' + str(total_volume_flux) + ')')
        print('        - Ratio: '+ str(np.sum(iceberg_volumes) / total_volume_flux) + ' (should be close to 1)')
    return (v, number_of_bergs)


def compute_size_distributions(glacier_names, flux_timeseries, printing=False):
    start_year = 1990
    end_year = 2020

    calving_fraction = 0.9  # Fraction of calving flux that contributes to iceberg formation (not direct melt)

    iceberg_volume_set = []
    iceberg_count_set = []
    years = np.arange(start_year, end_year + 1)

    for g in range(len(glacier_names)):
        #if printing:
        print(' - Working on glacier ' + str(glacier_names[g]))
        timeseries = flux_timeseries[g]

        for year in range(start_year, end_year + 1):
            annual_flux = compute_cumulative_flux_from_annual_mean(timeseries, year)
            total_calving_flux = annual_flux * calving_fraction
            if printing:
                print('    - Calving flux in year ' + str(year) + ': ' + str(total_calving_flux) + ' Gt')
            total_calving_volume = total_calving_flux * 1e12 / 917
            if printing:
                print('    - Calving volume in year ' + str(year) + ': ' + '{:.2e}'.format(total_calving_volume) + ' m3')
            iceberg_volumes, number_of_bergs = compute_iceberg_size_distribution(total_calving_volume)
            if printing:
                print('    - Total number of icebergs in year ' + str(year) + ': ' + str(int(np.sum(number_of_bergs))))
            if year == start_year:
                iceberg_counts = np.zeros((end_year - start_year + 1, np.size(iceberg_volumes)))
                iceberg_volume_set.append(iceberg_volumes)
            iceberg_counts[year - start_year, :] = number_of_bergs

        iceberg_count_set.append(iceberg_counts)

    return (years, iceberg_volume_set, iceberg_count_set)


def save_distributions_to_nc(glacier_names, years, iceberg_volume_set, iceberg_count_set):
    output_file = os.path.join('data', 'Glacier', 'Iceberg Size Distribution.nc')
    ds = nc4.Dataset(output_file, 'w')

    ds.createDimension('year', np.shape(years)[0])
    ds.createDimension('volume', np.shape(iceberg_volume_set[0])[0])

    d = ds.createVariable('year', 'f4', ('year',))
    d[:] = years

    for g in range(len(glacier_names)):
        grp = ds.createGroup(glacier_names[g])

        v = grp.createVariable('volume', 'f4', ('volume',))
        v[:] = iceberg_volume_set[g]

        c = grp.createVariable('iceberg_count', 'f4', ('year', 'volume'))
        c[:] = iceberg_count_set[g]

    ds.close()


if __name__ == '__main__':
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

    glacier_names, flux_timeseries = read_flux_timeseries_from_nc(input_folder)

    #import matplotlib.pyplot as plt
    # timeseries = flux_timeseries[glacier_names.index('129_UPERNAVIK_ISSTROM_N')]
    # plt.plot(timeseries[:,0], timeseries[:, 1])
    # plt.show()

    # flux_timeseries = [flux_timeseries[glacier_names.index('129_UPERNAVIK_ISSTROM_N')]]
    # glacier_names = ['129_UPERNAVIK_ISSTROM_N']

    years, iceberg_volume_set, iceberg_count_set = \
        compute_size_distributions(glacier_names, flux_timeseries)

    # plt.loglog(iceberg_volume_set[0], iceberg_count_set[0][0, :], 'b.', label='Iceberg Count Distribution')
    # plt.show()

    save_distributions_to_nc(glacier_names, years, iceberg_volume_set, iceberg_count_set)

