
#include "ICEBERG_OPTIONS.h"

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
CBOP 0
C !ROUTINE: ICEBERG_TENDENCY_APPLY_T

C !INTERFACE:
      SUBROUTINE ICEBERG_TENDENCY_APPLY_T(
     U                    gT_arr,
     I                    iMin,iMax,jMin,jMax,
     I                    k, bi, bj, myTime, myIter, myThid )

C     !DESCRIPTION:
C     As for S/R ICEBERG_TENDENCY_APPLY_T
C     Add ICEBERG tendency terms to T (theta) tendency.
C     Routine works for one level at a time.

C     !USES:
      IMPLICIT NONE
#include "SIZE.h"
#include "GRID.h"
#include "EEPARAMS.h"
#include "DYNVARS.h"
#include "ICEBERG.h"


C     !INPUT/OUTPUT PARAMETERS:
C     gT_arr    :: the tendency array
C     k         :: Current vertical level index
C     bi,bj     :: Current tile indices
C     myTime    :: Current time in simulation
C     myIter    :: Current iteration number
C     myThid    :: my Thread Id number
      _RL     gT_arr(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      INTEGER iMin, iMax, jMin, jMax
      INTEGER k, bi, bj
      _RL     myTime
      INTEGER myIter
      INTEGER myThid

C     !LOCAL VARIABLES:
      INTEGER i, j

#ifdef ALLOW_ICEBERG

catn: this is the background melt tendency
C      IF ( applyICEBERGBGTendT ) THEN
       DO j=jMin,jMax
        DO i=iMin,iMax
          gT_arr(i,j) = gT_arr(i,j)
     &         + ICEBERGBG_TendT(i,j,k,bi,bj)
        ENDDO
       ENDDO
C      ENDIF

#endif /* ALLOW_ICEBERG */

      RETURN
      END

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|
CBOP 0
C !ROUTINE: ICEBERG_TENDENCY_APPLY_S

C !INTERFACE:
      SUBROUTINE ICEBERG_TENDENCY_APPLY_S(
     U                    gS_arr,
     I                    iMin,iMax,jMin,jMax,
     I                    k, bi, bj, myTime, myIter, myThid )

C     !DESCRIPTION:
C     As for S/R ICEBERG_TENDENCY_APPLY_S
C     Add ICEBERG tendency terms to S tendency.
C     Routine works for one level at a time.

C     !INPUT PARAMETERS:
      IMPLICIT NONE
#include "SIZE.h"
#include "GRID.h"
#include "EEPARAMS.h"
#include "DYNVARS.h"
#include "ICEBERG.h"

C     !INPUT/OUTPUT PARAMETERS:
C     gS_arr    :: the tendency array
C     k         :: Current vertical level index
C     bi,bj     :: Current tile indices
C     myTime    :: Current time in simulation
C     myIter    :: Current iteration number
C     myThid    :: my Thread Id number
      _RL     gS_arr(1-OLx:sNx+OLx,1-OLy:sNy+OLy)
      INTEGER iMin, iMax, jMin, jMax
      INTEGER k, bi, bj
      _RL     myTime
      INTEGER myIter
      INTEGER myThid
      CHARACTER*(MAX_LEN_MBUF) msgBuf
CEOP

C     !LOCAL VARIABLES:
      INTEGER i, j

#ifdef ALLOW_ICEBERG

catn: this is the background melt tendency
C      IF ( applyICEBERGBGTendS ) THEN
       DO j=jMin,jMax
        DO i=iMin,iMax
          gS_arr(i,j) = gS_arr(i,j)
     &         + ICEBERGBG_TendS(i,j,k,bi,bj)
        ENDDO
       ENDDO
C      ENDIF

#endif /* ALLOW_ICEBERG */

      RETURN
      END
