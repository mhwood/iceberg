C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_CALVE ( myTime, myIter, myThid )

C     ==================================================================
c     MITberg V2.0 ICEBERG CALVING SCHEME 
c     ==================================================================
C
C    o Icebergs are released at predefined locations
C
C    o Ice is calved when indicated by the schedule
C
C    o Thickness of calved iceberg cannot exceed water depth
C
C    ==================================================================

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "GRID.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"

#ifdef ALLOW_EXF
# include "EXF_OPTIONS.h"
# include "EXF_FIELDS.h"
# include "EXF_PARAM.h"
#endif


C     routine arguements
      INTEGER myThid
      INTEGER myIter
      INTEGER bi, bj
      _RL myTime

C     local arguements
      INTEGER kSurface
      INTEGER ib_n
      _RL varOUT
      INTEGER i1, j1
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit, aop, reason
      INTEGER ioUnit
      INTEGER cnt
      INTEGER n, nn, i
      _RL IceVol, VolMelt
      _RL NumSecYear
      _RL ib_R_low
      INTEGER id
      INTEGER max_ib_id

      _RL calving_time
      _RL iceberg_width

#ifndef ALLOW_USE_MPI
      INTEGER, PARAMETER :: mpiMyId = 0
#endif

C      NumSecYear :: Number of seconds in a year
C      ib_R_low     :: water depth at calving location

      NumSecYear  = 60. * 60. * 24. * 365.25
      if ( buoyancyRelation .eq. 'OCEANICP' ) then
       kSurface        = Nr
      else
       kSurface        = 1
      endif

C     Hack for now - no multithreadding
      bi = 1
      bj = 1

      _BEGIN_MASTER(myThid)

#ifdef ICEBERG_DEBUG_ON
       IF (ib_calving_debug_level.ge.1) THEN
       WRITE(msgBuf,'(A)') '|--- ICEBERG CALVING BEGIN DEBUG'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF
#endif 

C     Loop through each calving location and calving list
C     If the calving time is within deltaT of the current time
C     then calving the iceberg with the given size

C     Check to see if its time to calve a new iceberg from each
C     calving location, and if so do it.

C     Loop through the calving locations
      DO n = 1, CALVE_LOCS 

C     Check to see if this calving location is one this processor
      IF ( CalvingLocations(n,2).eq.mpiMyId ) THEN

C     Loop through the schedule length
      DO i = 1, SCHEDULE_LEN
         calving_time = IcebergCalvingSchedule(i,1,n)
         iceberg_width = IcebergCalvingSchedule(i,2,n)
C         WRITE(msgBuf,'(A,F30.10,A,F30.10)'),
C     &  'calving time: ',calving_time,' iceberg_width:',iceberg_width
C        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
C     &                    SQUEEZE_RIGHT, myThid )

C        Check if its time to calve
         IF ((calving_time.ge.myTime).and.
     &         (ABS(calving_time-myTime)<deltaT)
     &            .and.(iceberg_width.gt.1)) THEN ! time to calve

#ifdef ICEBERG_DEBUG_ON
       IF (ib_calving_debug_level.ge.2) THEN
       WRITE(msgBuf,'(A)') '  |--- CALVING EVENT OCCURRED'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF
#endif 

C       Find maximum iceberg ID (to avoid duplicating icebergs)
        max_ib_id = 0
        DO nn = 1,ib_Tot
         IF (ib_id(nn).GT.max_ib_id) max_ib_id = ib_id(nn)
        ENDDO
        
C       Assign information to each calved iceberg
        ib_n = ib_Tot + 1
        ib_id(ib_n) = n*NUMBER_OF_BERGS+ib_n  ! old code: max_ib_id + 1 ! older code: ib_n + IDoffset
        ib_source (ib_n) = CalvingLocations(n,1) ! iceberg source ID
        ib_tile  (ib_n) = CalvingLocations(n,2)  ! iceberg tile ID
        ib_i(ib_n) = CalvingLocations(n,3)       ! i-pos 
        ib_j(ib_n) = CalvingLocations(n,4)       ! j-pos
        ib_uVel(ib_n) = 0.0                      ! Initial zonal velocity
        ib_vVel(ib_n) = 0.0                      ! Initial meridional velocity
        ibFlag(ib_n) = -1                        ! set as -1 for ice just calved

C     Interpolate grid spacing to iceberg
C      ib_iT=ib_i(ib_n) - (FLOOR((ib_i(ib_n)-1)/sNx)*sNx)
C      ib_jT=ib_j(ib_n) - (FLOOR((ib_j(ib_n)-1)/sNy)*sNy)
!       CALL ICEBERG_FIND_IJ (ib_n, ib_iT, ib_jT,   ! find local i,j
!      &                                myIter, myThid)
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_i(ib_n), ib_j(ib_n),
     &                               XC, varOUT, 0, bi, bj, myThid )
      ib_x(ib_n) = varOUT
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_i(ib_n), ib_j(ib_n), 
     &                             YC, varOUT,  0, bi, bj, myThid )
      ib_y(ib_n) = varOUT

C--  Assign size catagory (width and thickness) to iceberg
        ib_wth (ib_n) = IcebergCalvingSchedule(i,2,n)
        ib_lth (ib_n) = IcebergCalvingSchedule(i,3,n)
        ib_thk (ib_n) = IcebergCalvingSchedule(i,4,n)    

C-- Compute the draft and freeboard
        ib_dft(ib_n) = (ib_rho/rho_w)*ib_thk(ib_n)
        ib_fbd(ib_n) = ib_thk(ib_n) - ib_dft(ib_n)

C-- Find the tile
C        CALL ICEBERG_FIND_TILE (ib_n, myIter, myThid )
C   This should really be done with an input mask like other field.
C   For now, will just implement with the locations file

#ifdef ICEBERG_DEBUG_ON
      IF (ib_calving_debug_level.ge.3) THEN
C      Summary of new iceberg added
        WRITE(msgBuf,'(A)')
     &    '   |- Summary of new iceberg calved into ocean: '
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, I6, A, I6, A, F9.2)')
     &   '     |- ID: ',ib_id(ib_n), ', Tile: ',ib_tile(ib_n),
     &   ', Source: ',ib_source(ib_n)
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,F9.2,A,F9.2)')
     &   '     |- x: ',ib_x(ib_n), ', y: ', ib_y(ib_n)
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A,F9.2,A,F9.2)')
     &   '     |- i: ',ib_i(ib_n), ', j: ', ib_j(ib_n)
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A,F9.2,A,F9.2,A,F9.2)')
     &   '     |- width: ',ib_wth(ib_n),
     &   ', length: ',ib_lth(ib_n),', thickness: ',ib_thk(ib_n)
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A,F9.2,A,F9.2)')
     &   '     |- freeboard: ',ib_fbd(ib_n), 
     &   ', draft: ',ib_dft(ib_n)
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A,F9.2,A,F9.2)')
     &   '     |- uVel:',ib_uVel(ib_n), ', vVel:',ib_vVel(ib_n)
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDIF
#endif 

C   Now increment Total Number of icebergs
        ib_Tot = ib_Tot + 1 

        IF (ib_Tot.GT.NUMBER_OF_BERGS) THEN
       WRITE(errorMessageUnit,'(A, I10, A, I10)') 
     &  'ICEBERG: Maximum number of icebergs ',
     &   NUMBER_OF_BERGS, ' exceeded. ibTot =', ib_Tot, '...STOPPING!'
       STOP 'ABNORMAL END: S/R ICEBERG'
        ENDIF

#ifdef ICEBERG_DEBUG_ON
      IF (ib_calving_debug_level.ge.4) THEN
        WRITE(msgBuf,'(A, A, I10)')
     &  '   |- Check number of icebergs in system,',
     &  ' after calving event: ', ib_Tot
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

      ENDIF ! time to calve
      ENDDO ! Max number of bergs in schedule
      ENDIF ! Calving location on this processor
      ENDDO ! NumCalvingLoc

#ifdef ICEBERG_DEBUG_ON
      IF (ib_calving_debug_level.ge.4) THEN
        WRITE(msgBuf,'(A, A, I10)')
     &  '   |- Check number of icebergs in system',
     &  'after all calving: ', ib_Tot
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

#ifdef ICEBERG_DEBUG_ON
       IF (ib_calving_debug_level.ge.1) THEN
       WRITE(msgBuf,'(A)') '|--- ICEBERG CALVING END DEBUG'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF
#endif 

      _END_MASTER(myThid)
      _BARRIER

      RETURN
      END
 
