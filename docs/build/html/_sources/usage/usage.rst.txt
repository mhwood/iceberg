
Usage
=====

The main feature of the this project is the iceberg package itself, but there are also a 
variety of tools provided with this repository that are useful. Here, we start by detailing
how to implement the iceberg package into your own MITgcm simulation. Then, we describe some
of the other tools and how to use them. 


Installing iceberg in MITgcm
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To add the iceberg package in your version of MITgcm, it is recommended that you first clone
a fresh, recent version of MITgcm:

.. code-block:: console

    git clone https://github.com/MITgcm/MITgcm

Then, clone the iceberg repository:

.. code-block:: console

    git clone https://github.com/mhwood/iceberg

Next, we just need to implement the package into your clone of MITgcm using the python utilities 
provided with the iceberg repository:

.. code-block:: console

    cd iceberg/utils
    python copy_iceberg_pkg_to_mitgcm.py -m /path/to/MITgcm -c /path/to/code/mods/dir

The path to MITgcm is provided so that the iceberg files are added in the package directory. The
path to the code modifications directory is provided because there are several updates to the standard
MITgcm boot sequence and source files required for this package.


Using the iceberg package
^^^^^^^^^^^^^^^^^^^^^^^^^

As for all MITgcm packages, there are both compile time and run time requirements for the iceberg package.

Compile-time Considerations
---------------------------
There are two compile time files to consider:

ICEBERG_OPTIONS.h

Contains many options to turn on or off different parts of the compiled code.

ICEBERG_SIZE.h

Defines the maximum number of icebergs that can exist in a simulation,
the length of the calving schedule, and the number of calving locations.
Each of these parameters sets the size of an array and associated loops in the compiled code.

Run-time Considerations
-----------------------

There are several files to consider at run time:

data.iceberg
calving_locations.txt
calving schedules


