C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_CALVE ( myIter, myThid )

C     ==================================================================
c     MITberg V1.0 ICEBERG CALVING SCHEME 
c     ==================================================================
C
C    o Icebergs are released at predefined locations
C
C    o Ice is calved when CalveStart > CalveDelay
C      (Modify CalveDelay to delay onset of calving)
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


C     local arguements
      INTEGER kSurface
      INTEGER ib_n
      _RL ib_iT, ib_jT
      INTEGER i1, j1
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit, aop, reason
      INTEGER ioUnit
      INTEGER cnt
      INTEGER n, nn
      _RL IceVol, VolMelt
      _RL NumSecYear
      _RL ib_R_low
      INTEGER id
      INTEGER max_ib_id

#ifdef ALLOW_CALVING_OUTPUT
      INTEGER max_cv_id, nnc
#endif

C     IcebergListA  Table containing number of icebergs and frequency
C                   to discharge them, as follows 
C                   Structure is 13 x no. calving locations +1
C
C      COLUMN N=1  (glacier 1)                       COL N+1   COL.(NumCalveLoc+1)
C      | 1 | tot ice vol drained by glacier (km3/yr)      |           0  
C      | 2 | num bergs (size cat. 1)                      |        ib_scale
C      | 3 | num bergs (size cat. 2)                      |        ib_scale
C      | 4 | num bergs (size cat. 3)                      |        ib_scale
C      | 5 | num bergs (size cat. 4)                      |        ib_scale
C      | 6 | num bergs (size cat. 5)                      |        ib_scale
C      | 7 | num bergs (size cat. 6)                      |        ib_scale
C      | 8 | num bergs (size cat. 7)                      |        ib_scale
C      | 9 | num bergs (size cat. 8)                      |        ib_scale
C      |10 | num bergs (size cat. 9)                      |        ib_scale
C      |11 | num bergs (size cat 10)                      |        ib_scale
C      |12 | Tot num of bergs to calve (sum 2-11)         |           0
C      |13 | Iceberg calving freq. (seconds)              |           0
C
C      VolMelt   ::  Volume water released to ocean at calving margin
C                    as liquid runoff (m3.s-1)
C      NumSecYear :: Number of seconds in a year
C      ib_R_low     :: water depth at calving locatin
C

      NumSecYear  = 60. * 60. * 24. * 365.25
      if ( buoyancyRelation .eq. 'OCEANICP' ) then
       kSurface        = Nr
      else
       kSurface        = 1
      endif


      _BEGIN_MASTER(myThid)

C     CalveStart is a counter from zero to no. seconds per year
C     Once CalveStart eq NumSecYear then CalveStart is reset
      CalveStart = CalveStart + deltaT 
#ifdef ICEBERG_DIAG_ON
        WRITE(msgBuf,'(A)') 'ICEBERG: CALVING CALLED'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, f10.3)') 'CalveStart: ', CalveStart
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

C     Check to see if its time to calve a new iceberg from each
C     calving location, and if so do it.
      DO n = 1, NumCalvingLoc 
       ib_calve_counter (n) = ib_calve_counter (n) + deltaT

C      Calve when it it time and there are icebergs to calve
       IF (ib_calve_counter(n).GE.IcebergListA (13,n) 
     &          .AND.CalveStart.GT.CalveDelay 
     &          .AND.IcebergListA (12,n).GT.0) THEN     

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
        cnt = 0   ! set flag to ZERO
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
C    Note we calve smallest to largest from IcebergSizeTable
        DO nn = 1,10
         IF (IcebergListA(nn+1,n).GT.0.AND.cnt.EQ.0) THEN
          ib_wth (ib_n) = IcebergSizeTable (nn,3)
          ib_thk (ib_n) = IcebergSizeTable (nn,4)      

c          IF (isnan(ib_wth(ib_n))) THEN
c           WRITE(msgBuf,'(A, F11.1, F11.1)'), 
c     &     'NaN in iceberg size (iceberg_calve.F) ... STOPPING!', 
c     &       ib_wth(ib_n),
c     &       IcebergSizeTable (nn,3)
c           CALL PRINT_ERROR( msgBuf , myThid)
c           STOP
c          ENDIF

          IcebergListA (nn+1,n) = IcebergListA (nn+1,n) - 1
          ib_scale(ib_n) = IcebergListA (nn+1,NumCalvingLoc+1)
          cnt = 1   ! Flag to stop calving
         ENDIF
        ENDDO
 
C      Sum number of icebergs left (from Master field) to calve
        IF (cnt.EQ.1) IcebergListA (12,n) = SUM (IcebergListA (2:11,n))

C#ifdef ICEBERG_DIAG_ON
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
C#endif 

#ifdef ALLOW_CALVING_OUTPUT
C     Find calving row (to find the next one)
      max_cv_id = 0
      DO nnc = 0,cv_Tot-1
      IF (CalvingList(nnc,1).NE.0) THEN
        max_cv_id = nnc
      ENDIF
      ENDDO

C     Add the iceberg info to the next row
C     Assumption is that this can't exceed the 
C     total number of possible icebergs (seems fair)
      CalvingList(nnc+1,1) = ib_id(ib_n)
      CalvingList(nnc+1,2) = myIter

#endif

C   Now increment Total Number of 4
        ib_Tot = ib_Tot + 1 

        IF (ib_Tot.GT.max_no_bergs) THEN
         WRITE(msgBuf,'(A, I10, A, I10)') 
     &    'ICEBERG: Maximum number of icebergs ',
     &    max_no_bergs, ' exceeded. ibTot =', ib_Tot, '...STOPPING!'
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         STOP
        ENDIF

        ib_calve_counter (n) = 0. ! reset counter

       ENDIF
#ifdef ICEBERG_DIAG_ON
        WRITE(msgBuf,'(A, I10)')
     &  'Number of icebergs in system, after cavling: ', ib_Tot
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
      ENDDO

C--  RESET CALVING IF CalveStart > No. Seconds per year
      IF (CalveStart.GT.NumSecYear) THEN
       CalveStart = 0. _d 0

C      Increase total ice volume (if required)
       IF (IceInc.GT.0.0.AND.niter0.NE.0)  
     &     IceIncTot = IceIncTot + IceInc
C
C      Increase total liquid runoff (if required)
       IF (RunoffInc.GT.0.0.AND.niter0.NE.0) THEN    
         RunoffIncTot = RunoffIncTot + RunoffInc
C        Calc. total volume of runoff to release (m3/yr-1) 
         TotRunoffVol = TotRunoffVol + RunoffInc
         WRITE(msgBuf,'(A, E20.5)')
     &      'ICEBERG: Total liquid runoff (m3/yr): ', TotRunoffVol
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         WRITE(msgBuf,'(A, E20.5)')
     &  'ICEBERG: Runoff increase rate (m3.yr-2)[RunoffInc] ',RunoffInc
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, E20.5)')
     &  'ICEBERG: RunoffIncTot: ' , RunoffIncTot
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       ENDIF
C    Remake IcebergListA
       CALL ICEBERG_CREATE_LISTA (myThid) !update 
       IcebergListA = IcebergListA_org  ! Reset IcebergListA
      ENDIF

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
 
