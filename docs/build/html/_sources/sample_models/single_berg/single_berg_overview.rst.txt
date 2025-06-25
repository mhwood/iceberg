Single Iceberg Model
********************

**Overview**

This model is provided as a base-case to examine the effects of different melt processes
on a static iceberg of a given shape. The model is small and designed to run quickly on a laptop
to test out different forcings, shapes, and other components of the package.

This configuration contains a single iceberg in a column of water and is designed
to test the various melting parameterizatios and processes. The iceberg is "calved"
into the center of an 11x11 domain with 50 depth levels that telescope with depth.
The temperature and salinity conditions as well as the external forcing conditions
(atmospheric temperature, wind, downwelling radiations, and sea ice) are designed
to approximate the conditions in northwest Greenland. Temperature and salinity are
kept approximately constant throughout the run by turning of the temperature and salt stepping.
Momentum stepping is maintained but iceberg advection is turned off so that the
iceberg will remain stationary.

The following pages describe how to set up, run, and interpret the **iceberg** results for this model eaxample:

.. toctree::
   :maxdepth: 2

   model_setup
   running_the_model
   model_results