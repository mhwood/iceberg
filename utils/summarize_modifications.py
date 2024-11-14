
import os
import subprocess

######################################################################
# This function is the main utility

def assess_differences():
    pwd = os.getcwd()
    pwd_short = pwd.split(os.path.sep)[-1]
    if pwd_short!='utils':
        raise ValueError('Run this code from within the utils dir')

    for file_name in os.listdir(os.path.join('..','pkg','pkg_mods')):
        if file_name[-1] in ['F','h']:
            if file_name in os.listdir(os.path.join('..','pkg','mitberg')):
                print(file_name)
                diff_command = ['diff']
                diff_command.append(os.path.join('..','pkg','mitberg',file_name))
                diff_command.append(os.path.join('..','pkg','pkg_mods',file_name))
                diff_command.append('>')
                diff_command.append(os.path.join('..','pkg','mods_summary',file_name[:-2]+'_mods.txt'))
                print(' '.join(diff_command))
                os.system(' '.join(diff_command))
                # subprocess.run(diff_command)


if __name__ == '__main__':
    assess_differences()

