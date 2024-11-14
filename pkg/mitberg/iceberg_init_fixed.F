c
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_INIT_FIXED( myThid  )

C     ==================================================================
C     MITberg V1.0 ICEBERG_INIT_FIXED
C     ==================================================================
C
C     o initializes Fixed array
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
#ifdef ALLOW_EXF
# include "EXF_OPTIONS.h"
# include "EXF_FIELDS.h"
# include "EXF_PARAM.h"
#endif

C     == routine arguments ==
C     myThid - thread number for this instance of the routine.
      INTEGER myThid


#ifdef ALLOW_DIAGNOSTICS
      IF ( useDiagnostics ) THEN
        CALL ICEBERG_DIAGNOSTICS_INIT( myThid )
      ENDIF
#endif

      
      RETURN
      END
