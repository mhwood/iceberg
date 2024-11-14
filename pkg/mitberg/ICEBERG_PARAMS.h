C Contains variables loaded from data.iceberg
c Alan Condron, UMass Amherst, 2015

      COMMON /ICEBERG_PARAM001_I/
     &  max_no_bergs, ibBounceCoast, 
     &  NumCalvingLoc,
     &  IDoffset
      INTEGER max_no_bergs
      INTEGER ibBounceCoast
      INTEGER NumCalvingLoc
      INTEGER IDoffset

      COMMON /ICEBERG_PARAM001_LOG/useIcebergPickup
      LOGICAL useIcebergPickup

      COMMON /ICEBERG_PARAM001_CHAR/
     & CalvingFile, IcebergLocationFile, IcebergSizeFile
      CHARACTER*128 CalvingFile
      CHARACTER*128 IcebergLocationFile
      CHARACTER*128 IcebergSizeFile

      COMMON /ICEBERG_PARAM001_RL/
     &  ib_write_freq, ib_Tice, ibLthWthRatio,
     &  Cwv, Cav, Civ, Cwh, Cah, deltaT_ice, TotIceVol, IceFracLiq,
     &  IcebergGroup, ib_rho, rho_w, rho_a, rho_si,
     &  ibMeltT, ibMeltS, min_size, CalveDelay,
     &  TotCalvePeriod, ibMaxV, IcebergTaveFreq,
     &  IceInc, IceIncTot, TairIncRate, TotRunoffVol,
     &  RunoffInc, RunoffIncTot, ScourDepth
      _RL ib_write_freq
      _RL ib_Tice
      _RL ib_rho
      _RL rho_w
      _RL rho_a
      _RL rho_si
      _RL ibLthWthRatio
      _RL Cwv
      _RL Cav
      _RL Civ
      _RL Cwh
      _RL Cah
      _RL deltaT_ice
      _RL ibMeltT
      _RL ibMeltS
      _RL min_size
      _RL ibMaxV
      _RL IcebergTaveFreq
      _RL TotIceVol
      _RL TotRunoffVol
      _RL IceFracLiq
      _RL IceInc
      _RL RunoffInc
      _RL IceIncTot
      _RL RunoffIncTot
      _RL ScourDepth
      _RL IcebergGroup(10)
      _RL TotCalvePeriod
      _RL CalveDelay
      _RL TairIncRate

      COMMON /ICEBERG_PARAM002/
     &  MwScale, ibuWindScale, ibvWindScale, ibTairScale,
     &  ibTwaterScale, ibMaxWind, ibFreshwaterScale
      _RL MwScale
      _RL ibuWindScale
      _RL ibvWindScale
      _RL ibTairScale
      _RL ibTwaterScale
      _RL ibMaxWind
      _RL ibFreshwaterScale
