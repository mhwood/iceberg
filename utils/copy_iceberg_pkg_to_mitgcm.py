


import os
import shutil
import argparse

######################################################################
# All of these functions are for adding the pkg into the boot sequence

def add_new_lines(lines,indicator,skip_line,add_lines):
    for ll in range(len(lines)):
        line = lines[ll]
        if line[:len(indicator)] == indicator:
            line_split_number = ll + skip_line + 1
    new_lines = lines[:line_split_number] + add_lines + lines[line_split_number:]
    return(new_lines)

def update_PARAMS(inc_dir, code_path):

    if 'PARAMS.h' not in os.listdir(code_path):
        shutil.copyfile(os.path.join(inc_dir,'PARAMS.h'),
                        os.path.join(code_path,'PARAMS.h'))

    f=open(os.path.join(code_path,'PARAMS.h'))
    lines = f.read()
    f.close()
    lines = lines.split('\n')

    pkg_already_added = False
    for line in lines:
        if 'useICEBERG' in line:
            pkg_already_added = True

    if not pkg_already_added:
        print('      - Adding iceberg pkg to PARAMS.h')
        # add the note to the chain
        indicator = '      LOGICAL useShelfIce'
        skip_line = 0
        add_lines = ['      LOGICAL useICEBERG']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        # add the note to the chain
        indicator = '     &        useFRAZIL, useSEAICE, useSALT_PLUME, useShelfIce,'
        skip_line = 0
        add_lines = ['     &        useICEBERG,']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        output = '\n'.join(lines)
        g = open(os.path.join(code_path,'PARAMS.h'),'w')
        g.write(output)
        g.close()
    else:
        print('      - Skipping addition to PARAMS.h - already implemented')

    return(pkg_already_added)

def update_packages_boot(src_dir, code_path):

    if 'packages_boot.F' not in os.listdir(code_path):
        shutil.copyfile(os.path.join(src_dir,'packages_boot.F'),
                        os.path.join(code_path,'packages_boot.F'))

    f=open(os.path.join(code_path,'packages_boot.F'))
    lines = f.read()
    f.close()
    lines = lines.split('\n')

    pkg_already_added = False
    for line in lines:
        if 'ALLOW_ICEBERG' in line:
            pkg_already_added = True

    if not pkg_already_added:

        # add the note to the chain
        indicator = '     &          useShelfIce,'
        skip_line = 0
        add_lines = ['     &          useIceberg,']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        # add the note to the chain
        indicator = '      useShelfIce     =.FALSE.'
        skip_line = 0
        add_lines = ['      useIceberg      =.FALSE.']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        # add the check code
        indicator = '      CALL PACKAGES_PRINT_MSG( useShelfIce'
        skip_line = 1
        add_lines = ['#ifdef ALLOW_ICEBERG',
                     '      CALL PACKAGES_PRINT_MSG( useIceberg,    \'Iceberg\',     \' \' )',
                     '#endif']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        output = '\n'.join(lines)
        g = open(os.path.join(code_path,'packages_boot.F'),'w')
        g.write(output)
        g.close()

    else:
        print('      - Skipping addition to packages_boot - already implemented')

def update_packages_init_fixed(src_dir, code_path):

    if 'packages_init_fixed.F' not in os.listdir(code_path):
        shutil.copyfile(os.path.join(src_dir,'packages_init_fixed.F'),
                        os.path.join(code_path,'packages_init_fixed.F'))

    f=open(os.path.join(code_path,'packages_init_fixed.F'))
    lines = f.read()
    f.close()
    lines = lines.split('\n')

    pkg_already_added = False
    for line in lines:
        if 'ICEBERG_INIT_FIXED' in line:
            pkg_already_added = True

    if not pkg_already_added:
        # add the note to the chain
        indicator = 'C       |-- SHELFICE_INIT_FIXED'
        skip_line = 1
        add_lines = ['C       |-- ICEBERG_INIT_FIXED','C       |']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        # add the check code
        indicator = '        CALL SHELFICE_INIT_FIXED( myThid )'
        skip_line = 2
        add_lines = ['',
                     '#ifdef ALLOW_ICEBERG',
                     '      IF (useIceberg) THEN',
                     '        CALL ICEBERG_INIT_FIXED( myThid )',
                     '      ENDIF',
                     '#endif',]
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        output = '\n'.join(lines)
        g = open(os.path.join(code_path,'packages_init_fixed.F'),'w')
        g.write(output)
        g.close()

    else:
        print('      - Skipping addition to packages_init_fixed - already implemented')

def update_packages_init_variables(src_dir, code_path):

    if 'packages_init_variables.F' not in os.listdir(code_path):
        shutil.copyfile(os.path.join(src_dir,'packages_init_variables.F'),
                        os.path.join(code_path,'packages_init_variables.F'))

    f=open(os.path.join(code_path,'packages_init_variables.F'))
    lines = f.read()
    f.close()
    lines = lines.split('\n')

    pkg_already_added = False
    for line in lines:
        if 'ICEBERG_INIT_VARIA' in line:
            pkg_already_added = True

    if not pkg_already_added:

        # add the note to the chain
        indicator = 'C       |-- SHELFICE_INIT_VARIA'
        skip_line = 0
        add_lines = ['C       |','C       |-- ICEBERG_INIT_VARIA']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        # add the check code
        indicator = '#endif /* ALLOW_SHELFICE */'
        skip_line = 0
        add_lines = ['',
                     '#ifdef ALLOW_ICEBERG',
                     '      IF ( useICEBERG ) THEN',
                     '        CALL ICEBERG_INIT_VARIA( myThid )',
                     '      ENDIF',
                     '#endif /* ALLOW_ICEBERG */',]
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        output = '\n'.join(lines)
        g = open(os.path.join(code_path,'packages_init_variables.F'),'w')
        g.write(output)
        g.close()

    else:
        print('      - Skipping addition to packages_init_variables - already implemented')

def update_packages_readparms(src_dir, code_path):

    if 'packages_readparms.F' not in os.listdir(code_path):
        shutil.copyfile(os.path.join(src_dir,'packages_readparms.F'),
                        os.path.join(code_path,'packages_readparms.F'))

    f=open(os.path.join(code_path,'packages_readparms.F'))
    lines = f.read()
    f.close()
    lines = lines.split('\n')

    pkg_already_added = False
    for line in lines:
        if 'ICEBERG_READPARMS' in line:
            pkg_already_added = True

    if not pkg_already_added:

        # add the note to the chain
        indicator = 'C       |-- SHELFICE_READPARMS'
        skip_line = 0
        add_lines = ['C       |','C       |-- ICEBERG_READPARMS']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        # add the check code
        indicator = '      CALL SHELFICE_READPARMS( myThid )'
        skip_line = 1
        add_lines = ['',
                     '#ifdef ALLOW_ICEBERG',
                     'C--   if useIceberg=T, set ICEBERG parameters; otherwise just return',
                     '      CALL ICEBERG_READPARMS( myThid )',
                     '#endif']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        output = '\n'.join(lines)
        g = open(os.path.join(code_path,'packages_readparms.F'),'w')
        g.write(output)
        g.close()

    else:
        print('      - Skipping addition to packages_readparms - already implemented')

def update_do_the_model_io(src_dir, code_path):

    if 'do_the_model_io.F' not in os.listdir(code_path):
        shutil.copyfile(os.path.join(src_dir,'do_the_model_io.F'),
                        os.path.join(code_path,'do_the_model_io.F'))

    f=open(os.path.join(src_dir,'do_the_model_io.F'))
    lines = f.read()
    f.close()
    lines = lines.split('\n')

    pkg_already_added = False
    for line in lines:
        if 'ICEBERG_OUTPUT' in line:
            pkg_already_added = True

    if not pkg_already_added:
        # add the note to the chain
        indicator = 'C       |-- SHELFICE_OUTPUT'
        skip_line = 0
        add_lines = ['C       |','C       |-- ICEBERG_OUTPUT']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        # add the check code
        indicator = '#endif  /* ALLOW_SHELFICE */'
        skip_line = 0
        add_lines = ['',
                     '#ifdef ALLOW_ICEBERG',
                     '      IF ( useICEBERG ) THEN',
                     '        CALL ICEBERG_OUTPUT( myTime, myIter, myThid )',
                     '        CALL ICEBERG_WRITE_PICKUP( myTime, myIter, myThid )',
                     '      ENDIF',
                     '#endif /* ALLOW_ICEBERG */']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        output = '\n'.join(lines)
        g = open(os.path.join(code_path,'do_the_model_io.F'),'w')
        g.write(output)
        g.close()

    else:
        print('      - Skipping addition to do_the_model_io - already implemented')

def update_boot_sequence_files(mitgcm_path, code_path):

    inc_dir = os.path.join(mitgcm_path,'model','inc')
    src_dir = os.path.join(mitgcm_path, 'model', 'src')

    pkg_already_added = update_PARAMS(inc_dir, code_path)

    # print('      - Adding a block to the package boot sequence')
    update_packages_boot(src_dir, code_path)

    # print('      - Adding a block to the package init_fixed sequence')
    update_packages_init_fixed(src_dir, code_path)

    # print('      - Adding a block to the package init_variables sequence')
    update_packages_init_variables(src_dir, code_path)

    # print('      - Adding a block to the package readparms sequence')
    update_packages_readparms(src_dir, code_path)

    # print('      - Adding a block to the model i/o sequence')
    update_do_the_model_io(src_dir, code_path)

    return(pkg_already_added)


######################################################################
# All of these functions are for adding the pkg into other model files

def update_do_oceanic_phys(src_dir, code_path):

    if 'do_oceanic_phys.F' not in os.listdir(code_path):
        shutil.copyfile(os.path.join(src_dir,'do_oceanic_phys.F'),
                        os.path.join(code_path,'do_oceanic_phys.F'))

    f=open(os.path.join(code_path,'do_oceanic_phys.F'))
    lines = f.read()
    f.close()
    lines = lines.split('\n')

    pkg_already_added = False
    for line in lines:
        if 'ICEBERG [DO_OCEANIC_PHYS]' in line:
            pkg_already_added = True

    if not pkg_already_added:
        print('      - Adding a block to the do_oceanic_phys sequence')

        # add the check code
        indicator = '#endif /* ALLOW_SHELFICE */'
        skip_line = 0
        add_lines = ['',
                     '#ifdef ALLOW_ICEBERG',
                     '      IF (useICEBERG) THEN',
                     '        CALL TIMER_START(\'ICEBERG [DO_OCEANIC_PHYS]\', myThid)',
                     '        CALL ICEBERG_MODEL ( myTime, myIter, myThid )',
                     '        CALL TIMER_STOP (\'ICEBERG [DO_OCEANIC_PHYS]\', myThid)',
                     '      ENDIF',
                     '#endif /* ALLOW_ICEBERG */']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        output = '\n'.join(lines)
        g = open(os.path.join(code_path,'do_oceanic_phys.F'),'w')
        g.write(output)
        g.close()

    else:
        print('      - Skipping addition to packages_boot - already implemented')

def update_external_forcing_surf(src_dir, code_path):

    if 'external_forcing_surf.F' not in os.listdir(code_path):
        shutil.copyfile(os.path.join(src_dir,'external_forcing_surf.F'),
                        os.path.join(code_path,'external_forcing_surf.F'))

    f=open(os.path.join(code_path,'external_forcing_surf.F'))
    lines = f.read()
    f.close()
    lines = lines.split('\n')

    pkg_already_added = False
    for line in lines:
        if 'ICEBERG_FORCING_SURF' in line:
            pkg_already_added = True

    if not pkg_already_added:
        print('      - Adding a block to the external_forcing_surf sequence')

        # add the check code
        indicator = 'C-- external_forcing_surf.F outside bi,bj loop.'
        skip_line = 0
        add_lines = ['',
                     '#ifdef ALLOW_ICEBERG',
                     '      IF (useICEBERG) THEN',
                     '        CALL ICEBERG_FORCING_SURF(',
                     '     &    bi, bj, iMin, iMax, jMin, jMax,',
                     '     &    myTime, myIter, myThid)',
                     '       ENDIF',
                     '#endif /* ALLOW_ICEBERG */',
                     '']
        lines = add_new_lines(lines, indicator, skip_line, add_lines)

        output = '\n'.join(lines)
        g = open(os.path.join(code_path,'external_forcing_surf.F'),'w')
        g.write(output)
        g.close()

    else:
        print('      - Skipping addition to external_forcing_surf - already implemented')

def update_model_src_files(mitgcm_path, code_path):

    src_dir = os.path.join(mitgcm_path, 'model', 'src')

    update_do_oceanic_phys(src_dir, code_path)

    update_external_forcing_surf(src_dir, code_path)


######################################################################
# This function is to add the new package files to the pkg dir

def add_iceberg_package_files(mitgcm_path):

    if 'iceberg' in os.listdir(os.path.join(mitgcm_path,'pkg')):
        shutil.rmtree(os.path.join(mitgcm_path,'pkg','iceberg'))

    os.mkdir(os.path.join(mitgcm_path,'pkg','iceberg'))

    for file_name in os.listdir(os.path.join('..','pkg','mitberg')):
        if file_name[-1]=='F' and file_name not in ['iceberg_adv.F','iceberg_exchange_tile.F',
                                                    'iceberg_icesheet_runoff.F','iceberg_make_IcebergListA.F','iceberg_therm.F']:
            shutil.copyfile(os.path.join('..', 'pkg', 'mitberg', file_name),
                       os.path.join(mitgcm_path, 'pkg', 'iceberg', file_name))
        if file_name[-1]=='h':
            shutil.copyfile(os.path.join('..', 'pkg', 'mitberg', file_name),
                       os.path.join(mitgcm_path, 'pkg', 'iceberg', file_name))

    for file_name in os.listdir(os.path.join('..','pkg','pkg_mods')):
        if file_name[-1]=='F':
            shutil.copyfile(os.path.join('..', 'pkg', 'pkg_mods', file_name),
                       os.path.join(mitgcm_path, 'pkg', 'iceberg', file_name))
        if file_name[-1]=='h':
            shutil.copyfile(os.path.join('..', 'pkg', 'pkg_mods', file_name),
                       os.path.join(mitgcm_path, 'pkg', 'iceberg', file_name))


######################################################################
# This function is the main utility

def copy_files_to_config(mitgcm_path, code_path):
    pwd = os.getcwd()
    pwd_short = pwd.split(os.path.sep)[-1]
    if pwd_short!='utils':
        raise ValueError('Run this code from within the utils dir')

    print(' - Updating the boot sequence files')
    # step 1: edit the old boot sequence files to add the new package
    update_boot_sequence_files(mitgcm_path, code_path)

    print(' - Updating model source files')
    # step 2: edit the other model source files
    update_model_src_files(mitgcm_path, code_path)

    print(' - Copying iceberg files into the pkg directory')
    # step 3: add the new iceberg package
    add_iceberg_package_files(mitgcm_path)

    print(' - Copy successful!')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument("-m", "--mitgcm_directory", action="store",
                        help="Path to the MITgcm directory.", dest="mitgcm_path",
                        type=str, required=True)

    parser.add_argument("-c", "--code_directory", action="store",
                        help="Path to the code directory of the configuration using iceberg.", dest="code_path",
                        type=str, required=True)

    args = parser.parse_args()
    mitgcm_path = args.mitgcm_path
    code_path = args.code_path

    copy_files_to_config(mitgcm_path, code_path)


# these lines are for testing
#
# mitgcm_path = '/Users/mike/Documents/Research/Projects/Ocean_Modeling/MITgcm/MITgcm'
# code_path = '/Users/mike/Documents/Research/Projects/Ocean_Modeling/' \
#             'Projects/Titanic/MITgcm/configurations/code_test'
#
# copy_files_to_config(mitgcm_path,code_path)
