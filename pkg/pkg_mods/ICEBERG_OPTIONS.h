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
#undef ICEBERG_DIAG_ON

C--   Diagnostics to check mpi tile exchange
#undef ICEBERG_TILE_DIAG_ON

C--   Allow icebergs to be calved from icesheet
#define ALLOW_ICEBERG_CALVING

C------- THERMODYNAMIC OPTIONS -------

C--   Turn on iceberg Thermodynamics package
C     This option is provided to allow the Thermodynamics
C     component of the code to be switched off if required.
#define ALLOW_ICEBERG_THERMO

C     Two options are available to simulate iceberg melt:
C     o Canadian Ice Service (CIS) model (Kubat et al. 2007) is the 
C       iceberg deterioration component of the CIS iceberg forecasting model.
C       [set with USE_CIS_MELT]
C     o Iceberg model of Grant Bigg (Bigg et al. 1997) used by others 
C       such as Martin and Adcroft (2010) [Set with USE_BIGG_MELT]
C      The biggest difference is the treatment of wave erosion
#define USE_CIS_MELT

C--   Allow overhanging slabs
C     Waterline wave erosion leads to overhanging slabs. When the overhang reaches
C     critical length (Fl) it fractures and the slab calves off. 
C     Not needed with Bigg et al/Martin and Adcroft (2010) wave erosion
#define ALLOW_OVERHANGING_SLABS

C--   Allow bergy bits (Under construction!)
C     Option will allow ice eroded by wave erosion to 
C     become new icebergs. When option is not set all ice from wave erosion 
C     melts in-situ and is added to the total iceberg meltwateri flux.
#undef ALLOW_BERGY_BITS

C--   Allow iceberg meltwater to alter ocean salinity and water temperature
C     Turning this ON will release freshwater melt from the icebergs
C     into the ocean model and alter salinity and temperature 
#define ALLOW_ICEBERG_MELTWATER

C--   Use simple scheme to simulate surface (liquid) runoff from ice sheet
C     at catchments. The total volume to discharge is set
C     in data.iceberg using TotRunoffVol. The runoff is released into the
C     same locations as the icebergs are calved from.
#undef ALLOW_ICESHEET_RUNOFF

C--   Iceberg meltwater tracer (Under construction!)
C     Add a dye tracer to the meltwater released from the icebergs
#undef ICEBERG_ADD_DYE_TRACER

  
C------- ADVECTION OPTIONS -------

C--   Enable iceberg dynamics package
C     This is the main option to make the icebergs drift
#define ALLOW_ICEBERG_ADVECTION

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
#undef ALLOW_SCOURING

C------- SEDIMENT OPTIONS (Under Construction) -------
 
C--   Allow sediment/IRD from icebergs to be deposited on the model sea floor
#undef ALLOW_MITsed


C------- MISC. OPTIONS -------

C--  Write out iceberg statistics related to size, velocity etc.
#define WRITE_ICEBERG_DATA

C--   Reading Pickups as binary files
C     Original pickups were ascii. By setting this the model expects 
C     pickup files to be binary format.
#define ReadBinaryIcebergPickup

C--   Allow MITberg code to interface with older 2008 version of MITgcm
#undef USE_OLD2008

C------- MW OPTIONS -------
C--- Write out a calving list of all the icebergs that were calved
C    since the last output (determine by the dump frequency)
C    This is implemented because the iceberg list only gives a snapshot of
C    the current icebergs, some of which melt before the next output
C    if they are very small
#undef ALLOW_CALVING_OUTPUT

#endif /* ICEBERG_OPTIONS_H */
