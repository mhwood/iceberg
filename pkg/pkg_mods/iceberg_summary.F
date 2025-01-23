C
#include "ICEBERG_OPTIONS.h"
C
      SUBROUTINE ICEBERG_SUMMARY( myThid )

C     ==================================================================
C     MITberg V1.0 SUBROUTINE ICEBERG_SUMMARY
C     ==================================================================
C
C     o Write summary to STDOUT of iceberg parameters selected
C
C     ==================================================================

C     !USES:
      IMPLICIT NONE
C     == global variables ==
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "ICEBERG.h"

C     == routine arguments ==
C     myThid  - thread number for this instance of the routine.
      INTEGER myThid

C     == local variables ==
      CHARACTER*(MAX_LEN_MBUF) msgBuf


      _BEGIN_MASTER(myThid)

      WRITE(msgBuf,'(A)')
     &' '
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A)')
     &'// ======================================================='
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A)')
     &'// ICEBERG COMPILE FLAG SUMMARY'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

#ifdef ALLOW_ICEBERG_CALVING
      WRITE(msgBuf,'(A)') '    - ALLOW_ICEBERG_CALVING'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

#ifdef GROUP_SMALL_ICEBERGS
      WRITE(msgBuf,'(A)') '    - GROUP_SMALL_ICEBERGS'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

#ifdef USE_LAGRANGIAN_FLOAT
      WRITE(msgBuf,'(A)') '    - USE_LAGRANGIAN_FLOAT'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

#ifdef CAP_ICEBERG_VELOCITY
      WRITE(msgBuf,'(A)') '    - CAP_ICEBERG_VELOCITY'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif


#ifdef ALLOW_ICEBERG_ADVECTION
      WRITE(msgBuf,'(A)') '    - ALLOW_ICEBERG_ADVECTION'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#ifdef ALLOW_ICEBERG_MULTILEVEL
        WRITE(msgBuf,'(A)') '    - ALLOW_ICEBERG_MULTILEVEL'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#ifdef USE_ICEBERG_KEEL_MODEL
        WRITE(msgBuf,'(A)') '    - USE_ICEBERG_KEEL_MODEL'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
#else
        WRITE(msgBuf,'(A)') 'Single-level ocean advection'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

#ifdef USE_TABULAR_ICEBERGS
        WRITE(msgBuf,'(A)') '    - USE_TABULAR_ICEBERGS'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#ifdef USE_ICEBERG_KEEL_MODEL
        WRITE(msgBuf,'(A)') 'Keel model cannot be used with 
     &  tabular icebergs'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        STOP
#endif
#endif

#ifndef ALLOW_ICEBERG_MULTILEVEL
#ifdef USE_ICEBERG_KEEL_MODEL
        WRITE(msgBuf,'(A)') '    - Keel model cannot be used with 
     &  single level advection'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        STOP
#endif
#endif

#ifdef ALLOW_ICEBERG_TO_ROLL
        WRITE(msgBuf,'(A)') '    - ALLOW_ICEBERG_TO_ROLL'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

#ifdef ALLOW_SEAICE
#ifdef ICEBERGS_DRIFT_WITH_SEAICE
        WRITE(msgBuf,'(A)') '    - ICEBERGS_DRIFT_WITH_SEAICE'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#else
        WRITE(msgBuf,'(A)') '    - Icebergs do not drift with sea ice'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
#endif


#ifdef ALLOW_WAVE_ADVECTION
        WRITE(msgBuf,'(A)') '    - ALLOW_WAVE_ADVECTION'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#else
        WRITE(msgBuf,'(A)') '    - Wave forcing is OFF'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
#endif

#ifdef ICEBERG_USE_ADDED_MASS
        WRITE(msgBuf,'(A)') '    - ICEBERG_USE_ADDED_MASS'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

C Thermodynamic settings
#ifdef ALLOW_ICEBERG_THERMO
      WRITE(msgBuf,'(A)') '    - ALLOW_ICEBERG_SURFACE_MELT'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#ifdef USE_CIS_MELT
      WRITE(msgBuf,'(A)') '    - Using CIS deterioration model'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
#ifdef USE_BIGG_MELT
      WRITE(msgBuf,'(A)') '    - USE_BIGG_MELT - incomplete'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      STOP
#endif
#ifdef ALLOW_OVERHANGING_SLABS
      WRITE(msgBuf,'(A)') '    - ALLOW_OVERHANGING_SLABS'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#else
      WRITE(msgBuf,'(A)') '    - ALLOW_OVERHANGING_SLABS - DISABLED'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
#endif

#ifdef ALLOW_ICEBERG_MELTWATER
      WRITE(msgBuf,'(A)') '    - ALLOW_ICEBERG_MELTWATER'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#else
      WRITE(msgBuf,'(A)') 'Iceberg meltwater NOT released to the ocean'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

#ifdef WRITE_ICEBERG_DATA
      WRITE(msgBuf,'(A)') '    - WRITE_ICEBERG_DATA'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

      WRITE(msgBuf,'(A)')
     &'// ======================================================='
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A)')

      _END_MASTER(myThid)
      _BARRIER

      RETURN
      END
