c Contains variables not loaded at runtime
c Alan Condron, UMass Amherst, 2015

#ifdef ALLOW_ICEBERG

#include "ICEBERG_SIZE.h"

      INTEGER ib_id(NUMBER_OF_BERGS), ib_Tile(NUMBER_OF_BERGS)
      INTEGER ibFlag(NUMBER_OF_BERGS)
      INTEGER ib_Tot
      _RL ib_i(NUMBER_OF_BERGS), ib_j(NUMBER_OF_BERGS)
      _RL ib_x(NUMBER_OF_BERGS), ib_y(NUMBER_OF_BERGS)
      _RL ib_uVel(NUMBER_OF_BERGS), ib_vVel(NUMBER_OF_BERGS)
      _RL ib_wth(NUMBER_OF_BERGS), ib_lth(NUMBER_OF_BERGS)
      _RL ib_thk(NUMBER_OF_BERGS), ib_dft(NUMBER_OF_BERGS)
      _RL ib_fbd(NUMBER_OF_BERGS)
      _RL ib_source(NUMBER_OF_BERGS), ib_scale(NUMBER_OF_BERGS)
      _RL IcebergCalvingSchedule(SCHEDULE_LEN, 4, CALVE_LOCS)
      _RL CalvingLocations(CALVE_LOCS,4)
      _RL IcebergMeltWater(1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL calve_slab_counter(NUMBER_OF_BERGS)
      _RL sProf  (NUMBER_OF_BERGS,Nr)
      _RL tProf  (NUMBER_OF_BERGS,Nr)
      _RL ptProf (NUMBER_OF_BERGS,Nr)
      _RL prProf (NUMBER_OF_BERGS,Nr)
      _RL uProf  (NUMBER_OF_BERGS,Nr)
      _RL vProf  (NUMBER_OF_BERGS,Nr)
      _RL wProf  (NUMBER_OF_BERGS,Nr)
      _RL mProf (NUMBER_OF_BERGS,Nr)
      _RL HeatFlux(NUMBER_OF_BERGS,Nr)
      _RL FwFlux(NUMBER_OF_BERGS,Nr)
      _RL delta_z(NUMBER_OF_BERGS,Nr)
#ifdef ALLOW_USE_MPI
      INTEGER exchange_list(NUMBER_OF_BERGS, 2) ! source and target procs
#endif /* ALLOW_USE_MPI */

      COMMON /ICEBERG_PARAM003/
     &  ib_id, ib_Tile, ibFlag, 
     &  ib_Tot, 
     &  ib_i, ib_j,
     &  ib_x, ib_y,
     &  ib_uVel, ib_vVel,
     &  ib_wth, ib_lth, ib_thk,
     &  ib_dft, ib_fbd,
     &  ib_source, ib_scale,
     &  IcebergCalvingSchedule,
     &  CalvingLocations, IcebergMeltWater,
     &  calve_slab_counter,
     &  sProf, tProf, ptProf, prProf, 
     &  uProf, vProf, wProf,
     &  mProf, 
     &  FwFlux, HeatFlux,
#ifdef ALLOW_USE_MPI
     &  exchange_list,
#endif /* ALLOW_USE_MPI */
     &  delta_z


      COMMON /ICEBERG_FIELDS_RL/
     &     icebergBG_TendT,
     &     icebergBG_TendS
      _RL icebergBG_TendT (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)
      _RL icebergBG_TendS (1-OLx:sNx+OLx,1-OLy:sNy+OLy,Nr,nSx,nSy)

      COMMON /ICEBERG_DIAGS_FIELDS/
     &     iceberg_MeltProfile,
     &     iceberg_SolarMelt,
     &     iceberg_AtmMelt,
     &     iceberg_WaveMelt,
     &     iceberg_MeltProfileCount,
     &     iceberg_SolarMeltCount,
     &     iceberg_AtmMeltCount,
     &     iceberg_WaveMeltCount
      _RL iceberg_MeltProfile(NUMBER_OF_BERGS,Nr) 
      _RL iceberg_SolarMelt(NUMBER_OF_BERGS) 
      _RL iceberg_AtmMelt(NUMBER_OF_BERGS) 
      _RL iceberg_WaveMelt(NUMBER_OF_BERGS) 
      INTEGER iceberg_MeltProfileCount(NUMBER_OF_BERGS)
      INTEGER iceberg_SolarMeltCount(NUMBER_OF_BERGS)
      INTEGER iceberg_AtmMeltCount(NUMBER_OF_BERGS)
      INTEGER iceberg_WaveMeltCount(NUMBER_OF_BERGS)
     
#endif /* ALLOW_ICEBERG */