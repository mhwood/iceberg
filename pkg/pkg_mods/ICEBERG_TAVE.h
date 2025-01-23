C
C     *==========================================================*
C     | ICEBERG_TAVE.h
C     *==========================================================*


C     Keep track of time (counter for time averageing)
      _RL Iceberg_TimeAveCounter(Nr,nSx,nSy)

C     Storage arrays for time-averages
      _RL IcebergMWater_Tave(1-OLx:sNx+OLx,1-OLy:sNy+OLy,1,nSx,nSy)
C
C     Units: kg.m^-2.s^-1
      COMMON /ICEBERG_TAVE/ Iceberg_TimeAveCounter,
     &     IcebergMWater_Tave


