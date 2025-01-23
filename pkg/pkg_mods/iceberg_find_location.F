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


      INTEGER myThid
      INTEGER myIter
      INTEGER ib_n
      _RL ib_iG
      _RL ib_jG
      CHARACTER*(MAX_LEN_MBUF) msgBuf

C     REGIONAL CONFIG.
      ib_iG = FLOOR((ib_i(ib_n)-1)/sNx+1)
      ib_jG = FLOOR((ib_j(ib_n)-1)/sNy+1)
      ib_Tile(ib_n) = ((ib_iG-1)*nPy)+(ib_jG-1)


#ifdef ICEBERG_DIAG_ON
       WRITE(msgBuf,'(A)') 'ICEBERG: Summary of ib_Tile'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(2I7)') ib_n, ib_Tile(ib_n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )

#endif


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

      INTEGER myThid
      INTEGER myIter
      INTEGER ib_n
      _RL ib_iT
      _RL ib_jT

      ib_iT=(ib_i(ib_n)-myXGlobalLo)+1.
      ib_jT=(ib_j(ib_n)-myYGlobalLo)+1.

      RETURN
      END

