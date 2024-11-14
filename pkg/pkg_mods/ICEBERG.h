c Contains variables not loaded at runtime
c Alan Condron, UMass Amherst, 2015

#ifdef ALLOW_ICEBERG

#include "ICEBERG_SIZE.h"

      INTEGER ib_id(NUMBER_OF_BERGS), ib_Tile(NUMBER_OF_BERGS)
      INTEGER ibFlag(NUMBER_OF_BERGS)
      INTEGER ib_Tot, ib_face(NUMBER_OF_BERGS)
      INTEGER ibCalvingFace(CALVE_LOCS)
      INTEGER cv_Tot
      _RL ib_i(NUMBER_OF_BERGS), ib_j(NUMBER_OF_BERGS)
      _RL ib_uVel(NUMBER_OF_BERGS), ib_vVel(NUMBER_OF_BERGS)
      _RL ib_wth(NUMBER_OF_BERGS), ib_thk(NUMBER_OF_BERGS)
      _RL ib_scale(NUMBER_OF_BERGS), ib_source (NUMBER_OF_BERGS)
      _RL calve_slab_counter(NUMBER_OF_BERGS)
      _RL IcebergSizeTable(10,4)
      _RL IcebergSizeTables(CALVE_LOCS, 10, 4)
      _RL IcebergCalvingSchedule(SCHEDULE_LEN, 3, CALVE_LOCS)
      _RL ib_calve_counter(CALVE_LOCS)
      _RL CalvingLocations(CALVE_LOCS,4)
      _RL IcebergListA (13,CALVE_LOCS)
      _RL IcebergListA_org (13,CALVE_LOCS)
      _RL CalvingList (NUMBER_OF_BERGS,5)
      _RL CalveStart
      _RL IcebergMeltWater (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL IcebergLiqRunoff (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)

      COMMON /ICEBERG_PARAM003/
     &  ib_calve_counter, calve_slab_counter,
     &  ib_Tot, ib_id, ib_i, ib_j, ib_face,
     &  cv_Tot,
     &  ib_Tile, ib_scale, ib_uVel, ib_vVel, ib_wth, ib_thk,
     &  ibFlag, ib_source, IcebergMeltWater,
     &  IcebergLiqRunoff, CalveStart,
     &  IcebergSizeTable, IcebergListA,
     &  IcebergSizeTables,
     &  IcebergCalvingSchedule,
     &  IcebergListA_org, CalvingLocations,
     &  CalvingList,
     &  ibCalvingFace
     
#endif /* ALLOW_ICEBERG */