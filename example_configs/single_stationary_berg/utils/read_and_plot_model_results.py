
import os
import numpy as np
import matplotlib.pyplot as plt
import netCDF4 as nc4
from matplotlib.gridspec import GridSpec

def read_model_parameters():
    NUMBER_OF_BERGS = 30
    SCHEDULE_LEN = 1
    Nr = 50

    depth = -1*np.fromfile(os.path.join('..','run','RC.data'),'>f4').reshape((Nr,))

    diag_dir = os.path.join('..','run','diags')

    iterations = []
    for file_name in os.listdir(os.path.join(diag_dir,'IBMSOLAR')):
        if file_name[-4:]=='.bin':
            iterations.append(int(file_name.split('.')[-2]))
    iterations = sorted(iterations)

    solar_melt = np.zeros((len(iterations),))
    atm_melt = np.zeros((len(iterations),))
    wave_melt = np.zeros((len(iterations),))
    submerged_melt = np.zeros((Nr, len(iterations)))

    width = np.zeros((len(iterations),))
    length = np.zeros((len(iterations),))
    thickness = np.zeros((len(iterations),))
    volume = np.zeros((len(iterations),))

    # schedule = np.fromfile(os.path.join(diag_dir, 'iceberg',
    #                                    'iceberg' + '{:010d}'.format(iterations[i])), '>f8').reshape(
    #     (15, NUMBER_OF_BERGS,)).T
    # iceberg = iceberg[0, :]

    for i in range(len(iterations)):
        sm = np.fromfile(os.path.join(diag_dir,'IBMSOLAR',
                                                'IBMSOLAR.'+'{:010d}'.format(iterations[i])+'.bin'),'>f8').reshape((NUMBER_OF_BERGS,))
        solar_melt[i] = sm[0]*86400

        am = np.fromfile(os.path.join(diag_dir, 'IBMATMCV',
                                              'IBMATMCV.' + '{:010d}'.format(iterations[i]) + '.bin'), '>f8').reshape((NUMBER_OF_BERGS,))
        atm_melt[i] = am[0]*86400

        wv = np.fromfile(os.path.join(diag_dir, 'IBMWVESN',
                                      'IBMWVESN.' + '{:010d}'.format(iterations[i]) + '.bin'), '>f8').reshape((NUMBER_OF_BERGS, ))
        wave_melt[i] = wv[0]*86400

        subm = np.fromfile(os.path.join(diag_dir, 'IBMSUBPF',
                                      'IBMSUBPF.' + '{:010d}'.format(iterations[i]) + '.bin'), '>f8').reshape((Nr, NUMBER_OF_BERGS))
        submerged_melt[:,i] = subm[:,0] * 86400

        iceberg = np.fromfile(os.path.join(diag_dir, 'iceberg',
                                      'iceberg' + '{:010d}'.format(iterations[i])), '>f8').reshape((15, NUMBER_OF_BERGS,)).T
        iceberg = iceberg[0,:]

        width[i] = iceberg[4]
        length[i] = iceberg[5]
        thickness[i] = iceberg[6]
        volume[i] = iceberg[4] * iceberg[5] * iceberg[6]

    # file_name = os.path.join('..','input','input_conditions.nc')
    # ds = nc4.Dataset(file_name)
    # ds.close()

    return(depth, solar_melt, atm_melt, wave_melt, submerged_melt,
           width, length, thickness, volume)

def plot_model_timeseries(depth, solar_melt, atm_melt, wave_melt, submerged_melt,
                          width, length, thickness, volume):

    plot_width = 19

    fig = plt.figure(figsize=(8,10))

    gs = GridSpec(6, plot_width +1,
                  left=0.15, right=0.92, bottom=0.05, top=0.95)

    ax = fig.add_subplot(gs[0, :plot_width])
    ax.plot(solar_melt,color='orange')
    ax.set_ylabel('Solar Melt\n(m/day)')

    ax = fig.add_subplot(gs[1, :plot_width])
    ax.plot(atm_melt,color='green')
    ax.set_ylabel('Atmospheric Melt\n(m/day)')

    ax = fig.add_subplot(gs[2, :plot_width])
    ax.plot(wave_melt,color='blue')
    ax.set_ylabel('Wave Erosion\n(m/day)')

    ax = fig.add_subplot(gs[3, :plot_width])
    min_melt = 0.0
    max_melt = 0.1
    C = ax.pcolormesh(np.arange(7), depth, submerged_melt, cmap='turbo',
                      vmin=min_melt, vmax=max_melt)
    # plt.colorbar(C)
    ax.set_ylim([np.max(thickness),0])
    ax.set_ylabel('Depth (m)')

    ax3mc = fig.add_subplot(gs[3, -1])
    x = np.array([0, 1])
    y = np.linspace(min_melt, max_melt, 100)
    X, Y = np.meshgrid(x, y)
    ax3mc.pcolormesh(X, Y, Y, cmap='turbo')
    ax3mc.yaxis.tick_right()
    ax3mc.yaxis.set_label_position("right")
    ax3mc.set_ylabel('Melt Rate (m/day)')
    ax3mc.set_xticks([])
    print(np.min(submerged_melt),np.max(submerged_melt))

    ax = fig.add_subplot(gs[4, :plot_width])
    ax.plot(width)
    ax.plot(length)
    ax.plot(thickness)
    ax.set_ylabel('(m)')
    print(width)
    print(length)
    print(thickness)

    ax = fig.add_subplot(gs[5, :plot_width])
    ax.plot(volume)
    ax.set_ylabel('Volume (m$^3$)')

    plt.savefig(os.path.join('..','results','melt_timeseries.png'))
    plt.close(fig)

def collect_and_plot_results():

    depth, solar_melt, atm_melt, wave_melt, submerged_melt, width, length, thickness, volume =\
        read_model_parameters()

    plot_model_timeseries(depth, solar_melt, atm_melt, wave_melt, submerged_melt,
                          width, length, thickness, volume)

collect_and_plot_results()



