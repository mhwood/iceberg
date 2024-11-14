C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_MODEL ( myTime, myIter, myThid)

C     =================================================================
C
C                                 MITberg V1.0 
C                                 ------------
C
C                     A Dynamic-Thermodynamic Iceberg Model
C                                 for MITgcm
C
C                 www.geo.umass.edu/faculty/condron/MITberg.htm
C
C                         Developed by Dr Alan Condron 
C                     University of Massachusetts Amherst
C                           acondron@geo.umass.edu
C
C     ==================================================================
C

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "GRID.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "ICEBERG.h"
#ifdef ALLOW_EXCH2
#include "W2_EXCH2_SIZE.h"
#include "W2_EXCH2_TOPOLOGY.h"
#include "W2_OPTIONS.h"
#include "W2_EXCH2_PARAMS.h"
#endif /* ALLOW_EXCH2 */

 
C     == Global arguments ==
C     myIter    :: Iteration number
C     myThid    :: Thread number for this instance of the routine.
      INTEGER bi, bj
      INTEGER myThid
      INTEGER myIter
      _RL myTime


c     == Local arguements ==
      INTEGER ib_n
      _RL ib_iT, ib_jT
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER proc_id, num_procs
      INTEGER ierr, status(MPI_STATUS_SIZE)


#ifdef ICEBERG_DIAG_ON
      WRITE(msgBuf,'(A)') 'ICEBERG MODEL CALLED'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

C     MPI: FIND PROCESS ID and HOW MANY PROCESSES STARTED
      call MPI_COMM_RANK (MPI_COMM_WORLD, proc_id, ierr)
      call MPI_COMM_SIZE (MPI_COMM_WORLD, num_procs, ierr)

      DO bj = myByLo(myThid),myByHi(myThid)
       DO bi = myBxLo(myThid),myBxHi(myThid)

        IF (ib_Tot.GT.0) THEN                          ! if icebergs in system
         DO ib_n=1,ib_Tot
          CALL ICEBERG_FIND_TILE (ib_n, myIter, myThid)! Find iceberg tile ID

          IF (proc_id.EQ.ib_Tile(ib_n)) THEN           ! Execute specific tiles
           CALL ICEBERG_FIND_IJ (ib_n, ib_iT, ib_jT,   ! find local i,j
     &                                myIter, myThid)
#ifdef ALLOW_ICEBERG_THERMO
C--   THERMODYNAMICS PACKAGE
           IF (ibFlag(ib_n).NE.3) 
     &     CALL ICEBERG_THERM (ib_iT, ib_jT, ib_n, bi, bj, 
     &                         myIter, myThid)
#endif

#ifdef ALLOW_ICEBERG_ADVECTION
C--   ICEBERG ADVECTION SCHEME
           IF (ibFlag(ib_n).NE.3)
     &     CALL ICEBERG_ADV (ib_iT, ib_jT, ib_n, bi, bj, myThid)
#endif

          ENDIF       
         ENDDO   ! ib_n

        ENDIF   ! if ib_Tot > 0


#ifdef ALLOW_ICESHEET_RUNOFF
        CALL ICEBERG_ICESHEET_RUNOFF (bi, bj, myThid)
#endif


        _BARRIER

       ENDDO   ! bj
      ENDDO   ! bi



#ifdef ALLOW_ICEBERG_CALVING
C--   CALVE ICEBERGS
        CALL ICEBERG_CALVE ( myIter, myThid )
#endif


C--   EXCHANGE ICEBERG BETWEEN TILES AND FACES (if MPI)
      IF (num_procs.GT.1) THEN
#ifdef ALLOW_EXCH2
C      Between cube-sphere faces (e.g 1 - 6)
       CALL ICEBERG_EXCHANGE_FACE ( myThid )
#endif
C      Between tiles 
       CALL ICEBERG_EXCHANGE_TILE ( myThid )
      ENDIF

C--   REMOVE MELTED ICEBERGS
      CALL ICEBERG_REMOVE ( myIter, myThid )

      RETURN
      END
