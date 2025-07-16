C Contains variables loaded from data.iceberg
c Alan Condron, UMass Amherst, 2015

      COMMON /ICEBERG_PARAM001_I/
     &  max_no_bergs, ibBounceCoast, 
     &  IDoffset, ib_debug_level
      INTEGER max_no_bergs
      INTEGER ibBounceCoast
      INTEGER IDoffset
      INTEGER ib_debug_level

      COMMON /ICEBERG_PARAM001_LOG/useIcebergPickup
      LOGICAL useIcebergPickup

      COMMON /ICEBERG_PARAM001_CHAR/
     & CalvingFile, IcebergLocationFile, IcebergSizeFile
      CHARACTER*128 CalvingFile
      CHARACTER*128 IcebergLocationFile
      CHARACTER*128 IcebergSizeFile

      COMMON /ICEBERG_PARAM001_RL/
     &  ib_write_freq, ib_Tice, ibLthWthRatio,
     &  Cwv, Cav, Civ, Cwh, Cah, deltaT_ice, TotIceVol,
     &  IcebergGroup, ib_rho, rho_w, rho_a, rho_si,
     &  ibMeltT, ibMeltS, min_size, 
     &  ibMaxV, IcebergTaveFreq,
     &  IceInc, IceIncTot, TairIncRate,
     &  ScourDepth,
     &  submergedMeltBackgroundVelFloor
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
      _RL IceInc
      _RL IceIncTot
      _RL ScourDepth
      _RL IcebergGroup(10)
      _RL TairIncRate
      _RL submergedMeltBackgroundVelFloor

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


      COMMON /ICEBERG_DIAGS_CHAR/
     & ib_iceberg_filename,
     & ib_melt_profile_filename,
     & ib_solar_melt_filename,
     & ib_atm_melt_filename,
     & ib_wave_melt_filename
      CHARACTER*128 ib_iceberg_filename
      CHARACTER*128 ib_melt_profile_filename
      CHARACTER*128 ib_solar_melt_filename
      CHARACTER*128 ib_atm_melt_filename
      CHARACTER*128 ib_wave_melt_filename

      COMMON /ICEBERG_DIAGS_RL/
     & ib_melt_profile_period,
     & ib_solar_melt_period,
     & ib_atm_melt_period,
     & ib_wave_melt_period
      _RL ib_melt_profile_period
      _RL ib_solar_melt_period
      _RL ib_atm_melt_period
      _RL ib_wave_melt_period

#ifdef ICEBERG_DEBUG_ON
      INTEGER ib_model_debug_level
      INTEGER ib_advection_debug_level
      INTEGER ib_surface_melt_debug_level
      INTEGER ib_submerged_melt_debug_level
      INTEGER ib_calving_debug_level
      INTEGER ib_exchange_info_debug_level
      INTEGER ib_exchange_tile_debug_level

      COMMON /ICEBERG_DEBUG_PARAM/
     &  ib_model_debug_level,
     &  ib_advection_debug_level,
     &  ib_surface_melt_debug_level,
     &  ib_submerged_melt_debug_level,
     &  ib_calving_debug_level,
     &  ib_exchange_info_debug_level,
     &  ib_exchange_tile_debug_level
#endif 
