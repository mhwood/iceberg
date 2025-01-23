C
C     /==========================================================\
C     | ICEBERG_OPTIONS.h                                        |
C     | o CPP options file for iceberg package.                  |
C     |==========================================================|
C     | Use this file for selecting options within the iceberg   |
C     | package.                                                 |
C     \==========================================================/

#ifndef ICEBERG_OPTIONS_H
#define ICEBERG_OPTIONS_H
#include "PACKAGES_CONFIG.h"
#include "CPP_OPTIONS.h"


C--   Diagnostics mode. Define to print out additional stats. from model
#define ICEBERG_DIAG_ON

C--   Diagnostics to check mpi tile exchange
#undef ICEBERG_TILE_DIAG_ON

C------- THERMODYNAMIC OPTIONS -------

C--   Turn on iceberg surface melt routines
C     This option is provided to allow the Thermodynamics
C     component of the code to be switched off if required.
#define ALLOW_ICEBERG_SURFACE_MELT

C     Two options are available to simulate iceberg melt:
C     o Canadian Ice Service (CIS) model (Kubat et al. 2007) is the 
C       iceberg deterioration component of the CIS iceberg forecasting model.
C       [set with USE_CIS_MELT]
C     o Iceberg model of Grant Bigg (Bigg et al. 1997) used by others 
C       such as Martin and Adcroft (2010) [Set with USE_BIGG_MELT]
C      The biggest difference is the treatment of wave erosion
#undef USE_CIS_MELT

C--   Allow overhanging slabs
C     Waterline wave erosion leads to overhanging slabs. When the overhang reaches
C     critical length (Fl) it fractures and the slab calves off. 
C     Not needed with Bigg et al/Martin and Adcroft (2010) wave erosion
#undef ALLOW_OVERHANGING_SLABS

C--   Allow iceberg meltwater to alter ocean salinity and water temperature
C     Turning this ON will release freshwater melt from the icebergs
C     into the ocean model and alter salinity and temperature 
#define ALLOW_ICEBERG_MELTWATER

  
C------- ADVECTION OPTIONS -------

C--   Enable iceberg dynamics package
C     This is the main option to make the icebergs drift
#undef ALLOW_ICEBERG_ADVECTION

C--   Group smaller icebergs together to reduce computational time
C     Calving icebergs from Greenland produce >10,000 small icebergs
C     Setting this option allows, for example, 1 iceberg particle to represent
C     more than 1 iceberg (user defined in data.iceberg).
#define GROUP_SMALL_ICEBERGS

C--   Only consider water drag on icebergs. This should cause
C     icebergs to be treated like passive lagrangian floats
#undef USE_LAGRANGIAN_FLOAT

C--   Limit maximum iceberg velocity to avoid unrealistic drift
C     Maximum speed is set in data.iceberg
#define CAP_ICEBERG_VELOCITY

C--   Consider wave forcing in the advection terms
#undef ALLOW_WAVE_ADVECTION

C--   Allow multi-level icebergs
C     By default the iceberg package uses only the surface 
C     ocean forcing to calculate water drag. This is typical of many existing
C     icebrg models. When this flag is set the ocean drag at each vertical
C     model level the iceberg penetrates is considered for both 
C     the dynamic and thermodyanmic code. 
#define ALLOW_ICEBERG_MULTILEVEL

C--   Consider iceberg sail shape
C     By default an iceberg is assumed to be tabular in shape
C     above the water line. When this option is set the area
C     of the iceberg above water (the sail area) becomes a pinnacle shape
C     typical of icebergs observed at the Grand Banks region. 
#undef USE_ICEBERG_SAIL_MODEL

C--   Iceberg keel model
C     Use a polynomial fit to estimate the keel shape and sail area of icebergs
C     based on the model of Barker et al (2004). This creates a more
C     realistic (conical) iceberg shape above and below the waterline and
C     alters drag forces for advection. Only works when multilevel icebergs are allowed.
#define USE_ICEBERG_KEEL_MODEL 

C--   Tabular icebergs
C     Assume tabular shape. Note that you must select either keel model
C     or tabular icebergs.
#undef USE_TABULAR_ICEBERGS

C--  Consider mass added to an iceberg due to the water that the iceberg
C    drags along with it. This 'added mass' is used in the Canadian
C    Ice Service (CIS) model (Kubut et al. 2005)
#undef ICEBERG_USE_ADDED_MASS

C--  Allow icebergs to role over based on stability criteria
#define ALLOW_ICEBERG_TO_ROLL

C--  Assume icebergs drift with sea-ice when sea-ice area GT 90%
#define ICEBERGS_DRIFT_WITH_SEAICE

C--  Let icebergs penetrate into sediment. Depth of scour set in data.iceberg
#define ALLOW_SCOURING

C------- SEDIMENT OPTIONS (Under Construction) -------
 
C--   Allow sediment/IRD from icebergs to be deposited on the model sea floor
#undef ALLOW_MITsed


C------- MISC. OPTIONS -------

C--  Write out iceberg statistics related to size, velocity etc.
#define WRITE_ICEBERG_DATA

C--   Allow MITberg code to interface with older 2008 version of MITgcm
#undef USE_OLD2008

C------- MW. OPTIONS -------

C--- Allow calving
C    Note: MW overhauled this part of the code
C    Now, this option allows the user to prescribe an individual 
C    calving schedule for each calving location giving
C    the time of calving and the size of each berg
C    Everything is now contained in the schedule so there is no
C    info need about periods, delays, etc
C    We also dont need a calving pickup anymore either
#define ALLOW_ICEBERG_CALVING

C--- Allow multilayer melt
C    This option allows the iceberg to melt on multiple layers
C    In the given configuration, the melt is all injected
C    into the surface layers
#define ALLOW_ICEBERG_MULTILEVEL_MELT

C--- Allow melt profile output
C    This option allows the output of profiles of melt
C    and other variables for each iceberg
#define ALLOW_PROFILE_OUTPUT

#endif /* ICEBERG_OPTIONS_H */

