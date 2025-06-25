Running the Single Iceberg Model
********************************

To run the single iceberg model, compile the model code and run it according to the
instructions below.


Compiling the model
^^^^^^^^^^^^^^^^^^^
To compile the model, create a build directory, move into it, and run the typical make sequence with
the following commands:

.. code-block:: console

   mkdir ../build
   cd ../build
   ../../../tools/genmake2 -of ../../../tools/build_options/darwin_amd64_gfortran -mods ../code
   make depend
   make

Note the following assumptions in the code above:
- The build directory is in the following path: `MITgcm/configurations/single_berg/build`
- The `darwin_amd64_gfortran` is appropriate for your system
- We are not compiling with MPI (this model example is set up for only one CPU)

Running the model
^^^^^^^^^^^^^^^^^
After the compilation is successful, we can set up the run directory:

.. code-block:: console

   mkdir ../run
   cd ../run
   ln -s ../build/mitgcmuv .
   ln -s ../input/* .
   ln -s ../namelist/* .
   mkdir ../run/diags
   mkdir ../run/diags/IBMATMCV
   mkdir ../run/diags/IBMSOLAR
   mkdir ../run/diags/IBMSUBPF
   mkdir ../run/diags/IBMWVESN
   mkdir ../run/diags/iceberg
   mkdir ../run/diags/dye_day_snap

Then, we are ready to run the model. Execute `mitgcmuv` (and store the output into a text file, if desired):

.. code-block:: console

   ./mitgcmuv > output.txt

Once the model is successfully run, we can take a look at the result. Let's have a look in the next notebook.