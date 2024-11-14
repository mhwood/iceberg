C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_CALVE_SCHEDULED ( myTime, myIter, myThid )

C     ==================================================================
c     MITberg V1.0 ICEBERG CALVING SCHEME 
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
      _RL myTime

C     local arguements
      INTEGER kSurface
      INTEGER ib_n
      _RL ib_iT, ib_jT
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

C      NumSecYear :: Number of seconds in a year
C      ib_R_low     :: water depth at calving location

      NumSecYear  = 60. * 60. * 24. * 365.25
      if ( buoyancyRelation .eq. 'OCEANICP' ) then
       kSurface        = Nr
      else
       kSurface        = 1
      endif

      _BEGIN_MASTER(myThid)

#ifdef ICEBERG_DIAG_ON
        WRITE(msgBuf,'(A)') 'ICEBERG: CALVING SCHEDULE CALLED'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

C     Loop through each calving location and calving list
C     If the calving time is within deltaT of the current time
C     then calving the iceberg with the given size

C     Check to see if its time to calve a new iceberg from each
C     calving location, and if so do it.

C     Loop through the calving locations
      DO n = 1, NumCalvingLoc 

C     Loop through the schedule length
      DO i = 1, SCHEDULE_LEN
         calving_time = IcebergCalvingSchedule(i,1,n)
         iceberg_width = IcebergCalvingSchedule(i,2,n)

C        Check if its time to calve
         IF ((ABS(calving_time-myTime)<deltaT)
     &            .and.(iceberg_width.gt.0)) THEN ! time to calve

#ifdef ICEBERG_DIAG_ON
        WRITE(msgBuf,'(A)') 'ICEBERG: CALVING EVENT'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

C       Find maximum iceberg ID (to avoid duplicating icebergs)
        max_ib_id = 0
        DO nn = 1,ib_Tot
         IF (ib_id(nn).GT.max_ib_id) max_ib_id = ib_id(nn)
        ENDDO
        
C       Assign information to each calved iceberg
        ib_n = ib_Tot + 1
        ib_id(ib_n) = max_ib_id + 1 !old code: ib_n + IDoffset
        ib_face(ib_n) = ibCalvingFace(n)
        ib_source (ib_n) = CalvingLocations(n,1) ! iceberg source ID
        ib_i(ib_n) = CalvingLocations(n,2)       ! i-pos 
        ib_j(ib_n) = CalvingLocations(n,3)       ! j-pos
        ib_uVel(ib_n) = 0.0                      ! Initial zonal velocity
        ib_vVel(ib_n) = 0.0                      ! Initial meridional velocity
        ibFlag(ib_n) = -1                        ! set as -1 for ice just calved

C--  Assign size catagory (width and thickness) to iceberg
        ib_wth (ib_n) = IcebergCalvingSchedule(i,2,n)
        ib_thk (ib_n) = IcebergCalvingSchedule(i,3,n)      

#ifdef ICEBERG_DIAG_ON
C      Summary of new iceberg added
        WRITE(msgBuf,'(A)'),
     &    'Summary of new iceberg calved into ocean: '
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(3I6, 8F9.2)')
     &   ib_id(ib_n), ib_tile(ib_n), ib_face(ib_n),
     &   ib_i(ib_n), ib_j(ib_n), ib_wth(ib_n), ib_thk(ib_n),
     &   ib_uVel(ib_n), ib_vVel(ib_n),
     &   ib_scale(ib_n),
     &   ib_source(ib_n)
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A)'),
     &    '---End of summary---'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif 

C   Now increment Total Number of icebergs
        ib_Tot = ib_Tot + 1 

        IF (ib_Tot.GT.max_no_bergs) THEN
         WRITE(msgBuf,'(A, I10, A, I10)') 
     &    'ICEBERG: Maximum number of icebergs ',
     &    max_no_bergs, ' exceeded. ibTot =', ib_Tot, '...STOPPING!'
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         STOP
        ENDIF

#ifdef ICEBERG_DIAG_ON
        WRITE(msgBuf,'(A, I10)')
     &  'Number of icebergs in system, after cavling: ', ib_Tot
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

      ENDIF ! time to calve
      ENDDO ! Max number of bergs in schedule
      ENDDO ! NumCalvingLoc

#ifdef ICEBERG_DIAG_ON
        WRITE(msgBuf,'(A, I10)')
     &  'Iceberg calving: Number of icebergs in system: ', ib_Tot
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

#endif

      _END_MASTER(myThid)
      _BARRIER

      RETURN
      END
 
