c Contains variables not loaded at runtime
c Alan Condron, UMass Amherst, 2015
 
      COMMON /ICEBERG_PARAM003/
     &  ib_calve_counter, calve_slab_counter,
     &  ib_Tot, ib_id, ib_i, ib_j, ib_face,
     &  ib_Tile, ib_scale, ib_uVel, ib_vVel, ib_wth, ib_thk,
     &  ibFlag, ib_source, IcebergMeltWater,
     &  IcebergLiqRunoff, CalveStart,
     &  IcebergSizeTable, IcebergListA,
     &  IcebergListA_org, CalvingLocations,
     &  ibCalvingFace

      INTEGER ib_id(15000),ib_Tile(15000),ibFlag(15000)
      INTEGER ib_Tot, ib_face(15000), ibCalvingFace(100)
      _RL ib_i(15000), ib_j(15000)
      _RL ib_uVel(15000), ib_vVel(15000)
      _RL ib_wth(15000), ib_thk(15000)
      _RL ib_scale(15000), ib_source (15000)
      _RL calve_slab_counter(15000)
      _RL IcebergSizeTable(10,4)
      _RL ib_calve_counter(100)
      _RL CalvingLocations(100,4)
      _RL IcebergListA (13,100)
      _RL IcebergListA_org (13,100)
      _RL CalveStart
      _RL IcebergMeltWater (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL IcebergLiqRunoff (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
     
