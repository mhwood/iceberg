Running the Cold Barotropic Gyre Model
**************************************

To run the single iceberg model, compile the model code and run it according to the
instructions below.


Compiling the model with exch2 and a blank list
^^^^^^^^^^^^^^^^^^^
There is no need to compile the blanklist model since it is identical to the model with exch2.

Running the model
^^^^^^^^^^^^^^^^^
After the compilation is successful, we can set up the run directory:

.. code-block:: console

   mkdir ../run_mpi_exch2_blanklist
   cd ../run_mpi_exch2_blanklist
   ln -s ../build_mpi_exch2/mitgcmuv .
   ln -s ../input_blanklist/* .
   ln -s ../input/calving_schedules .

Then, we are ready to run the model. Execute `mitgcmuv` with mpi:

.. code-block:: console

   mpirun -n 4 mitgcmuv

Once the model is successfully run, we can take a look at the result. Let's have a look in the next notebook.