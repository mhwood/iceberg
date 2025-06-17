import argparse
import subprocess


def run_pipeline(gate_path='data', grid_path='data'):
    import os

    if not os.path.exists(gate_path):
        raise FileNotFoundError(f"Missing required file: {gate_path}")
    if not os.path.exists(grid_path):
        raise FileNotFoundError(f"Missing required file: {grid_path}")

    cmd_flux = ['python3', 'create_greenland_flux_timeseries.py']
    print(f"Running: {' '.join(cmd_flux)}")
    proc_flux = subprocess.Popen(cmd_flux, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in proc_flux.stdout:
        print(line, end='', flush=True)
    proc_flux.wait()

    cmd_calving = ['python3', 'create_greenland_calving_timeseries.py']
    cmd_gate = ['python3', 'gate_location_extractor.py']

    print(f"Running: {' '.join(cmd_calving)}")
    proc_calving = subprocess.Popen(cmd_calving, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    print(f"Running: {' '.join(cmd_gate)}")
    proc_gate = subprocess.Popen(cmd_gate, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    for line in proc_calving.stdout:
        print(line, end='', flush=True)
    for line in proc_gate.stdout:
        print(line, end='', flush=True)

    proc_calving.wait()
    proc_gate.wait()

    cmd_loc_meta = ['python3', 'create_location_metadata.py']
    print(f"Running: {' '.join(cmd_loc_meta)}")
    proc_loc_meta = subprocess.Popen(cmd_loc_meta, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    os.makedirs('data/calving_schedules', exist_ok=True)
    cmd_final = ['python3', 'create_calving_files.py']
    print(f"Running: {' '.join(cmd_final)}")
    proc_final = subprocess.Popen(cmd_final, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    for line in proc_loc_meta.stdout:
        print(line, end='', flush=True)
    for line in proc_final.stdout:
        print(line, end='', flush=True)

    proc_loc_meta.wait()
    proc_final.wait()

    os.remove(os.path.join(gate_path, 'gate_loc.npy'))
    os.remove(os.path.join(gate_path, 'coast_line_points.npy'))
    print("Finished creating calving schedules")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument("-gate", "--gate-path", action="store",
                        help="The directory to gate.nc file.", dest="gate_path",
                        default='data',
                        type=str, required=False)

    parser.add_argument("-grid", "--grid-path", action="store",
                        help="The directory to .mitgrid file.", dest="grid_path",
                        default='data',
                        type=str, required=False)

    args = parser.parse_args()
    run_pipeline(args.gate_path, args.grid_path)
