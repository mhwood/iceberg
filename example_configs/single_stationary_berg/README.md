# Single Stationary Iceberg

This configuration contains a single iceberg in a column of water and is designed to test the various melting parameterizatios and processes. The iceberg is "calved" into the center of an 11x11 domain with 50 depth levels that telescope with depth. The temperature and salinituy conditions as well as the external forcing conditions (atmospheric temperature, wind, downwelling radiations, and sea ice) are designed to approximate the conditions in northwest Greenland. Temperature and salinity are kept constant throughout the run by turning of the temperature and salt stepping. Momentum stepping is maintained but iceberg advection is turned off so that the iceberg will remain stationary.

To build the model, move to the utils directory and run the build script (note that you need to add the iceberg package to this configuration using the general utility).

To create the conditions for the model run, use the following utility:
```
python create_initial_conditions.py
```


