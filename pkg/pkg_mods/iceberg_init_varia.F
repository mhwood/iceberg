C
#include "ICEBERG_OPTIONS.h"
C
      SUBROUTINE ICEBERG_INIT_VARIA ( myThid  )
C
C     ==================================================================
C     MITberg V1.0 ICEBERG_INIT_VARIA                                   
C     ==================================================================
C
C     o Initialize model by setting several variables and gloabl arrays 
C       to zero to begin with
C
C     o Call subroutine to read: 
C            calving data, pickupfiles, or initial location file
C
C     ==================================================================

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "ICEBERG_PARAMS.h"
#include "ICEBERG.h"

C     == global routine arguments ==
C     myThid - thread number for this instance of the routine.
      INTEGER myThid
      INTEGER i, j, bi, bj

C     == Local arguments ==
      CHARACTER*(MAX_LEN_MBUF) msgBuf

      WRITE(msgBuf,'(A)') 'ICEBERG: iceberg_init_varia.F'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C     Summarize iceberg model options in STDOUT
      CALL ICEBERG_SUMMARY (myThid)

C     Set various global iceberg model parameter to zero
C     or default.       
      ib_Tot                =  0
      ib_i(:)               =  0. _d 0
      ib_j(:)               =  0. _d 0
      ib_wth(:)             = 200.
      ib_thk(:)             = 250.
      CalveStart            = 0. _d 0
      ib_scale(:)           = 0. _d 0
      calve_slab_counter(:) = 0. _d 0
      ib_calve_counter(:)   = 0. _d 0
      ibFlag(:)             = 0
      ib_uVel(:)            = 0. _d 0
      ib_vVel(:)            = 0. _d 0
      ib_source(:)          = 0. _d 0

C     Set global freshwater array to zeros 
      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)
        DO j=1-OLy,sNy+OLy
         DO i=1-OLx,sNx+OLx
          IcebergMeltWater(i,j,bi,bj) = 0. _d 0
          IcebergLiqRunoff(i,j,bi,bj) = 0. _d 0
         ENDDO
        ENDDO
       ENDDO
      ENDDO



C     ------------------------------------------
C         Read iceberg locations from file
C     ------------------------------------------
C
C      Various options
C      o if Calving is turned on then creating IcebergListA
C      o if this is not the first time step (i.e. niter0.NE.0) 
C        and we are reading an Iceberg pickup then call ICEBERG_READ_PICKUP
C      o if calving is turned OFF and an initial location file
C        is specified:
C         i)  If niter0=0 (i.e. first time step) or useIcebergPick = FALSE
C             then read initial location file.
C        ii)  If useIcebergPick = TRUE then only read IcebergPickup, (i.e. no not
C             read initial location file)
C

#ifdef ALLOW_ICEBERG_CALVING 
      WRITE(msgBuf,'(A)')
     &     'ICEBERG: Calving switched ON'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

#ifndef ALLOW_CALVING_SCHEDULE
      WRITE(msgBuf,'(A)')
     &      'ICEBERG: creating IcebergListA'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
       CALL ICEBERG_CREATE_LISTA (myThid)
#endif /* ALLOW_CALVING_SCHEDULE */
      IF (useIcebergPickup.AND.niter0.NE.0) THEN
      WRITE(msgBuf,'(A)')
     &      'ICEBERG: Loading IcebergPickup files'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
       CALL ICEBERG_READ_PICKUP (myThid)
      ENDIF
#endif

#ifndef ALLOW_ICEBERG_CALVING
      WRITE(msgBuf,'(A)')
     &'ICEBERG: Calving is OFF so looking for either IcebergLocationFile
     & or PickupFile' 
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)


      IF (IcebergLocationFile.NE.' ') THEN
 
       IF (useIcebergPickup.AND.niter0.NE.0) THEN
        WRITE(msgBuf,'(A)')
     &  'ICEBERG: useIcebergPickup = TRUE and ninter.NE.0
     &   so will try to read pickup file'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
        CALL ICEBERG_READ_PICKUP (myThid)

       ELSE

        WRITE(msgBuf,'(A)')
     &  'ICEBERG: reading IcebergLocationFile' 
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
        CALL ICEBERG_READ_INITIAL_LOCATION_FILE (myThid)

       ENDIF

      ELSE

       WRITE(msgBuf,'(A)')
     & 'ICEBERG: no IcebergLocationFile specified.. STOP'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
       STOP

      ENDIF
#endif

  
      RETURN
      END
