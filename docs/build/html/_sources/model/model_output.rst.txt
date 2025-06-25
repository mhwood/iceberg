Model Output
============

There are several options for output from the iceberg model which are all specified in the
data.iceberg file.

Iceberg State
^^^^^^^^^^^^^
The state of all icebergs in the model wil be written at a frequency as specified by the `ib_write_freq`
parameter. The shape of this output will be (15, `NUMBER_OF_BERGS``) where `NUMBER_OF_BERGS`` is the
compile-time parameter specified in ICEBERG_SIZE.h. 

Note that the model will NOT output files when there are no icebergs in the domain.

The 15 parameters in the iceberg state files are 
as follows:

.. list-table:: Parameters Stored in the Iceberg State Files
   :widths: 25 25 50
   :header-rows: 1

   * - Number
     - Name
     - Description
   * - 1
     - ID
     - The unique ID of the iceberg (counted incrementally 
       since the start of the model)
   * - 2
     - Tile
     - The processing tile of the icebergs (when using MPI).
   * - 3
     - i-Location
     - The "column" of the iceberg on the global grid.
       When using `exch2`, this is in reference to raveled `exch2` grid.
   * - 4
     - j-Location
     - The "row" of the iceberg on the global grid.
       When using `exch2`, this is in reference to raveled `exch2` grid.
   * - 5
     - Width
     - The width of the iceberg in meters.
   * - 6
     - Length
     - The length of the iceberg in meters.
   * - 7
     - Thickness
     - The thickness of the iceberg in meters.
   * - 8
     - Draft
     - The draft of the iceberg in meters.
   * - 9
     - Freeboard
     - The freeboard of the iceberg in meters.
   * - 10
     - u-Velocity
     - The velocity of the iceberg in the u-direction. Note that the velocity is in reference to the local grid orientation. 
   * - 11
     - v-Velocity
     - The velocity of the iceberg in the v-direction. Note that the velocity is in reference to the local grid orientation. 
   * - 12
     - Flag
     - A flag for the iceberg state. 0 indicates the iceberg is freely floating, 1 indicates it is drifting with sea ice, 2 indicates the iceberg is grounded on the seafloor.
   * - 13
     - Source
     - The ID of the calving location (as identified in the calving_location.txt file).
   * - 14
     - Scale
     - The number of icebergs that this iceberg represents. When using the `GROUP_SMALL_ICEBERGS`` option, smaller icebergs are collected into a larger one. This field quantifies this effect.
   * - 15
     - Slab Counter
     - When using...

