C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_ICESHEET_RUNOFF ( bi, bj, myThid)

C     ==================================================================
c     MITberg V1.0 SIMPLE LIQUID RUNOFF SCHEME
c     ==================================================================
C
C    o Runoff from ice sheet is released from calving margins
C
C    o TotRunoffVol is the volume of runoff to release per year 
C      Set in data.iceberg with units Gt/yr
C
C    o Routine called at every time step
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
#ifdef ALLOW_EXCH2
#include "W2_EXCH2_SIZE.h"
#include "W2_EXCH2_TOPOLOGY.h"
#include "W2_OPTIONS.h"
#include "W2_EXCH2_PARAMS.h"
#endif /* ALLOW_EXCH2 */
#ifdef ALLOW_EXF
# include "EXF_OPTIONS.h"
# include "EXF_FIELDS.h"
# include "EXF_PARAM.h"
#endif

C     routine arguements
      INTEGER myThid
      INTEGER bi, bj

C     local arguements
      INTEGER i2, j2
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER n
      _RL NumSecYear
      _RL LiqRunoff
      _RL run_i, run_j
      INTEGER proc_id
      INTEGER ierr, status(MPI_STATUS_SIZE)
      _RL ib_iG
      _RL ib_jG
      INTEGER IbTileTmp
#ifdef ALLOW_EXCH2
      INTEGER jG_padding
#endif

      IF (TotRunoffVol.GT.0.0) THEN

#ifdef ICEBERG_DIAG_ON
        WRITE(msgBuf,'(A)')
     &     'ICEBERG: Liquid ice sheet runoff scheme called'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, E20.3)')
     &     'ICEBERG: Total runoff volume (m3/yr): ', TotRunoffVol
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

       CALL MPI_COMM_RANK (MPI_COMM_WORLD, proc_id, ierr)

       NumSecYear  = 60. * 60. * 24. * 365.25

       DO n = 1,NumCalvingLoc

C     make local copies of i and j calving/runoff locations
        run_i = CalvingLocations(n,2)
        run_j = CalvingLocations(n,3)

C Find tile for runoff source
#ifdef ALLOW_EXCH2
C     CUBE-SPHERE CONFIG.
      jG_padding = (facet_dims(1)/sNx)    ! pad for cube-sphere
      ib_iG = FLOOR((run_i-1)/sNx+1) ! iceberg i tile number 
      ib_jG = FLOOR((run_j-1)/sNy+1)
     &             * jG_padding - jG_padding ! iceberg j tile number
      IF (ib_iG.LE.0) ib_iG = 1
      IF (ib_jG.LT.0) ib_jG = 0
      ibTileTmp = ( (nTiles/nFacets) * (ibCalvingFace(n)-1) )
     &                 + ib_iG + ib_jG -1
#else
C     REGIONAL CONFIG.
        ib_iG = FLOOR((run_i-1)/sNx+1)
        ib_jG = FLOOR((run_j-1)/sNy+1)
        ibTileTmp = ((ib_iG-1)*nPy)+(ib_jG-1)
#endif

        IF (proc_id.EQ.ibTileTmp) THEN 

#ifdef ALLOW_EXCH2
         i2 = INT(run_i - (FLOOR((run_i-1)/sNx)*sNx))
         j2 = INT(run_j - (FLOOR((run_j-1)/sNy)*sNy))
#else
         i2 = INT((run_i - myXGlobalLo) +1.)
         j2 = INT((run_j - myYGlobalLo) +1.)
#endif

#ifdef ICEBERG_DIAG_ON
         WRITE(msgBuf,'(A, 2I, 2F8.3, I, 2F8.3)')
     &   'ICEBERG runoff: ', i2, j2, run_i,run_j,ibTileTmp,
     &     myXGlobalLo,myYGlobalLo
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
 
C     Add freshwater from ice sheet at calving margin to global meltwater field
C     to simulate liquid runoff from glaciers/icestreams. 
         LiqRunoff = TotRunoffVol * CalvingLocations(n,4)! (m3.yr-1)
         LiqRunoff = LiqRunoff / NumSecYear           ! Volume (m3.s-1)
         LiqRunoff = LiqRunoff / rA(i2,j2,bi,bj)      ! scale by area (m3 --> m.s-1)
         LiqRunoff = LiqRunoff * rhoConstFresh        ! m.s-1 * (kg.m-3) --> kg.m^-2.s-1
C        Add runoff at calving margins to global field (units: kg.m^-2.s^-1)
         IcebergLiqRunoff (i2,j2,bi,bj) = IcebergLiqRunoff(i2,j2,bi,bj)
     &                                                     + LiqRunoff
        ENDIF 

       ENDDO

       ENDIF
      RETURN
      END
 
