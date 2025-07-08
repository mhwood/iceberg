Cold Barotropic Gyre Model
**************************

**Overview**

This model is provided as a base-case to examine the iceberg advection in different grid
configurations. The model is tested with a single CPU, 4 CPUs (using MPI), and 4 CPUs on
a grid defined with exch2.

This configuration is based off the barotropic gyre experiment but the temperature has been
made a little colder to reflect typical conditions where icebergs calve. There are 4 icebergs
introduced into the model after the first timestep. The goal of the model is to observe the advection
of icebergs with the currents in the gyre. When using 4 CPUs, the icebergs change from one
processing tile to the next. This demo with exch2 provides functionality for this model on
more complex grids, such as the ECCO Lat-Lon-Cap grid. 

The following pages describe how to set up, run, and interpret the **iceberg** results for this model eaxample:

.. toctree::
   :maxdepth: 2

   model_setup