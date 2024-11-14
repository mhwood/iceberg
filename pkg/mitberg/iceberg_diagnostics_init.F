C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_DIAGNOSTICS_INIT( myThid )

C     ==================================================================
C     MITberg V1.0 SUBROUTINE ICEBERG_DIAGNOSTICS_INIT
C     ==================================================================
C     o Routine to initialize list of all available diagnostics
C       for ICEBERG package
C
C     ==================================================================

      IMPLICIT NONE

C     === Global variables ===
#include "EEPARAMS.h"
#include "SIZE.h"
c#ifdef ALLOW_SEAICE
c#include "SEAICE_SIZE.h"
c#include "SEAICE_PARAMS.h"
c#include "SEAICE_TRACER.h"
#include "ICEBERG.h"
c#endif
C     === Routine arguments ===
      INTEGER myThid

#ifdef ALLOW_DIAGNOSTICS
C     === Local variables ===
C     diagNum   :: diagnostics number in the (long) list of available diag.
C     diagName  :: local short name (8c) of a diagnostics
C     diagCode  :: local parser field with characteristics of the diagnostics
C              cf head of S/R DIAGNOSTICS_INIT_EARLY or DIAGNOSTICS_MAIN_INIT
C     diagUnits :: local string (16c): physical units of a diagnostic field
C     diagTitle :: local string (80c): description of field in diagnostic
      INTEGER       diagNum
      CHARACTER*8   diagName
      CHARACTER*16  diagCode
      CHARACTER*16  diagUnits
      CHARACTER*(80) diagTitle

      INTEGER       numArea
      CHARACTER*9   flxUnits
      CHARACTER*15  locName

C---+----1----+----2----+----3----+----4----+----5----+----6----+----7-|--+----|

c
      diagName  = 'ibFWflx'
      diagTitle = 'Fresh water flux to from icebergs'
      diagUnits = 'kg.m^-2.s^-1    '
      diagCode  = 'SM      U1      '
#ifdef USE_OLD2008
      CALL DIAGNOSTICS_ADD2LIST( diagNum,
     I    diagName, diagCode, diagUnits, diagTitle, myThid )
#else
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I     diagName, diagCode, diagUnits, diagTitle, 0, myThid )
#endif

      diagName  = 'ibFWrun'
      diagTitle = 'Fresh water runoff from calved iceberg (at coast)'
      diagUnits = 'kg.m^-2.s^-1    '
      diagCode  = 'SM      U1      '
#ifdef USE_OLD2008
      CALL DIAGNOSTICS_ADD2LIST( diagNum,
     I    diagName, diagCode, diagUnits, diagTitle, myThid )
#else
      CALL DIAGNOSTICS_ADDTOLIST( diagNum,
     I     diagName, diagCode, diagUnits, diagTitle, 0, myThid )
#endif
 
#endif 

      RETURN
      END
