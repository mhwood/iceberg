#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_FORCING_SURF(
     I                            bi, bj, iMin, iMax, jMin, jMax, 
     I                            myTime,myIter,myThid )

C     ==================================================================
C     MITberg V1.0 ICEBERG FRESHWATER FORCING
C     ==================================================================
C
C     o Routine addes freshwater melt from icebergs to 
C       surface of ocean model. This alters local theta and salt. 
C
C     o Salinity and temperature of iceberg runoff are set in data.iceberg
C       as ibMeltS (psu) and ibMeltT (degrees C). Default = 0 
C
C     o For routine to work "ALLOW_ICEBERG_MELTWATER"
C       must be set in ICEBERG_OPTIONS.h. 
C
C     o Meltwater runoff from icebergs is stored in array IcebergMeltWater
C
C     o Units: 
C        surfaceForcingS  :: psu.m/s  (same as g.kg^-1.m.s^-1)
C        surfaceForcingT  :: Kelvin.m/s            
C        theta (potential temperature) :: deg.C at pressure/tracer point
C        salt :: g/kg
C        IcebergMeltWater (Meltwater from icebergs) :: kg.m^-2.s^-1
C        mass2rUnit (1/rhoConsti) :: kg^-1.m^3

C    ========================================================

C     !INPUT PARAMETERS:
      IMPLICIT NONE
#include "SIZE.h"
#include "GRID.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"
#include "FFIELDS.h"

C     INPUT PARAMETERS:
      INTEGER bi, bj, iMin, iMax, jMin, jMax, myIter, myThid
      _RL myTime

C      LOCAL PARAMETERS
      INTEGER i,j
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER ks
      _RL TotMeltVol
      _RS MyMask 

C     MyMask is a location copy of either maskC or maskH, depending on version 
#ifdef ALLOW_ICEBERG
#ifdef ALLOW_ICEBERG_MELTWATER 

      TotMeltVol = 0. _d 0

      IF ( usingPCoords ) THEN
       ks        = Nr
      ELSE
       ks        = 1
      ENDIF
  

      IF ( staggerTimeStep ) THEN 
C      Do nothing for the time being
      ELSE
       WRITE(msgBuf,'(A)') 'staggerTimeStep needed for iceberg model'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                              SQUEEZE_RIGHT, myThid )
       STOP
      ENDIF


C-    Apply mask to IcebergMeltWater
      IF ( useRealFreshWaterFlux ) THEN
        DO j = jMin, jMax
         DO i = iMin, iMax
#ifdef USE_OLD2008
          MyMask = maskH(i,j,bi,bj)
#else
          MyMask = maskC(i,j,1,bi,bj)
#endif
          IcebergMeltWater(i,j,bi,bj) = IcebergMeltWater(i,j,bi,bj)
     &                                   * MyMask
          IcebergLiqRunoff(i,j,bi,bj) = IcebergLiqRunoff(i,j,bi,bj)
     &                                   * MyMask
         ENDDO
        ENDDO
      ENDIF


       IF (convertFW2Salt .EQ. -1.) THEN
C-     use local surface tracer field to calculate forcing term:
        DO j = jMin, jMax
         DO i = iMin, iMax
          surfaceForcingT(i,j,bi,bj) = surfaceForcingT(i,j,bi,bj)
     &     -((IcebergMeltWater(i,j,bi,bj) + IcebergLiqRunoff(i,j,bi,bj))
     &        *(theta(i,j,ks,bi,bj) - ibMeltT)
     &        * mass2rUnit)

          surfaceForcingS(i,j,bi,bj) = surfaceForcingS(i,j,bi,bj)
     &     -((IcebergMeltWater(i,j,bi,bj) + IcebergLiqRunoff(i,j,bi,bj))
     &        *(salt(i,j,ks,bi,bj) - ibMeltS)
     &        * mass2rUnit)

C   Sum total meltwater flux
         TotMeltVol = TotMeltVol + IcebergMeltWater(i,j,bi,bj)
     &                   + IcebergLiqRunoff(i,j,bi,bj)
         ENDDO
        ENDDO

       ELSE

        DO j = jMin, jMax
         DO i = iMin, iMax
          surfaceForcingT(i,j,bi,bj) = surfaceForcingT(i,j,bi,bj)
     &     -((IcebergMeltWater(i,j,bi,bj) + IcebergLiqRunoff(i,j,bi,bj))
     &        *(tRef(ks) - ibMeltT)
     &        * mass2rUnit)

          surfaceForcingS(i,j,bi,bj) = surfaceForcingS(i,j,bi,bj)
     &     -((IcebergMeltWater(i,j,bi,bj) + IcebergLiqRunoff(i,j,bi,bj))
     &        *(convertFW2Salt - ibMeltS)
     &        * mass2rUnit)
         ENDDO
        ENDDO
       ENDIF

#endif /* ALLOW_ICEBERG_MELTWATER  */
#endif /* ALLOW_ICEBERG */

      RETURN
      END
