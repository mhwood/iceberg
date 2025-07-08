C
#include "ICEBERG_OPTIONS.h"
C
      SUBROUTINE ICEBERG_FIND_TILE ( 
     I                               ib_n, 
     I                               myIter, myThid )

C     ==================================================================
C     MITberg V1.0 ICEBERG_FIND_TILE 
C     ==================================================================
C
C     o Find correct tile for each iceberg when using MPI
C
c       ib_i    iceberg i-position on global grid
c       ib_j    iceberg j-position on global grid
c       ib_iT   iceberg i-position on tile
c       ib_jT   iceberg j-position on tile
c       ib_iG   iceberg i tile location
c       ib_jG   iceberg j tile location
c       ib_Tile Current tile location (proc_id) of berg
C       jG_padding Used to get iceberg in correct location (cube-sphere)
C
C     ==================================================================


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

      INTEGER myThid
      INTEGER myIter
      INTEGER ib_n
      _RL ib_iG, ib_jG
#ifdef ALLOW_EXCH2
      _RL tNx, tNy
      INTEGER tile
      INTEGER myTileId, J
#endif
      CHARACTER*(MAX_LEN_MBUF) msgBuf

#ifdef ALLOW_EXCH2
      ! myTileId = W2_myTileList(1,1)
      ! tNx = exch2_tNx(myTileId)
      ! tNy = exch2_tNy(myTileId)

!       DO J=1,exch2_nNeighbours(myTileId)
!          WRITE(msgBuf,'(A,I5,A,I5)')
!      &  'ICEBERG_FIND_TILE J=',
!      &  J,' exch2_neighbourId(J,myTileId) ',
!      &  exch2_neighbourId(J,myTileId)
!        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &                    SQUEEZE_RIGHT, myThid )
!       ENDDO

! #ifdef ICEBERG_DEBUG_ON
!       IF (ib_debug_level.gt.9) THEN
!        WRITE(msgBuf,'(A,F5.1,A,F5.1,A,I5)')
!      &  'ICEBERG_FIND_TILE tNx=',
!      &  tNx,' tNy ', tNy,
!      &    ' myTileId= ',myTileId
!        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &                    SQUEEZE_RIGHT, myThid )
!       ENDIF
! #endif

#endif

#ifdef ALLOW_EXCH2
C     with exch2, the tiles are lined up left to right
      tile = FLOOR((ib_i(ib_n)-1)/sNx)
      ib_Tile(ib_n) = tile
#ifdef ICEBERG_DEBUG_ON
      IF (ib_debug_level.gt.9) THEN
       WRITE(msgBuf,'(A,F5.1,A,F5.1,A,I5)')
     &  'ICEBERG_FIND_TILE ib_i=',
     &  ib_i(ib_n),' ib_j ', ib_j(ib_n),
     &  '  --> ib_Tile ', ib_Tile(ib_n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif /* ICEBERG_DEBUG_ON */


#else /* ALLOW_EXCH2 */
C     REGIONAL CONFIG.
      ib_iG = FLOOR((ib_i(ib_n)-1)/sNx+1)
      ib_jG = FLOOR((ib_j(ib_n)-1)/sNy+1)
      ib_Tile(ib_n) = ((ib_iG-1)*nPy)+(ib_jG-1)
#endif /* ALLOW_EXCH2 */

! #ifdef ICEBERG_DEBUG_ON
!       IF (ib_debug_level.gt.9) THEN
!        WRITE(msgBuf,'(A,I5,A,F5.1,A,I5)')
!      &  'ICEBERG_FIND_TILE ib_iG=',
!      &  ib_iG,' ib_jG ', ib_jG,
!      &    ' ib_Tile= ',ib_Tile
!        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &                    SQUEEZE_RIGHT, myThid )
!       ENDIF
! #endif

      RETURN
      END


C
C

      SUBROUTINE ICEBERG_FIND_IJ (
     I                               ib_n,
     O                               ib_iT, ib_jT,
     I                               myIter, myThid )

C     ==================================================================
C     MITberg V1.0 ICEBERG_FIND_IJ 
C     ==================================================================
C   
C     o Find local(tile) i&j iceberg position 
C
C     ==================================================================


      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "GRID.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"

      INTEGER myThid
      INTEGER myIter
      INTEGER ib_n
      _RL ib_iT
      _RL ib_jT
      CHARACTER*(MAX_LEN_MBUF) msgBuf

#ifdef ALLOW_USE_MPI
      ib_iT=ib_i(ib_n) - (FLOOR((ib_i(ib_n)-0.5)/sNx)*sNx)
      ib_jT=ib_j(ib_n) - (FLOOR((ib_j(ib_n)-0.5)/sNy)*sNy)
#else
      ib_iT=(ib_i(ib_n)-myXGlobalLo)+1.
      ib_jT=(ib_j(ib_n)-myYGlobalLo)+1.
#endif

#ifdef ICEBERG_DEBUG_ON
      IF (ib_debug_level.gt.10) THEN
       WRITE(msgBuf,'(A,F5.1,A,F5.1,A,I5,A,I5)')
     &  'ICEBERG_FIND_IJ ib_iT=',
     &  ib_iT,' ib_jT ', ib_jT,
     &    ' myXGlobalLo= ',myXGlobalLo,
     &    ' myYGlobalLo= ',myYGlobalLo
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

      RETURN
      END

