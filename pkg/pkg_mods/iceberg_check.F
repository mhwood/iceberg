C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_CHECK ( myTime, myIter, myThid )

C     ==================================================================
c     MITberg V2.0 ICEBERG CHECK 
c     ==================================================================
C
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

      CHARACTER*(MAX_LEN_MBUF) msgBuf

#ifdef ICEBERG_DEBUG_ON
      IF (ib_debug_level.ge.2) THEN
        WRITE(msgBuf,'(A)') 'ICEBERG: CHECK CALLED'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

C     Notes for checks to build in

C     Not safe for multithreadding

C     Make sure calving locationds are on the grid

      RETURN
      END
 
