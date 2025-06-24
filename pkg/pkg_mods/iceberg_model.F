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
#include "ICEBERG_PARAMS.h"

 
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
#ifdef ALLOW_USE_MPI
      INTEGER ierr, status(MPI_STATUS_SIZE)
#endif


#ifdef ICEBERG_DIAG_ON
      IF (ib_debug_level.ge.3) THEN
      WRITE(msgBuf,'(A)') 'ICEBERG MODEL CALLED'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

#ifdef ALLOW_USE_MPI
C     MPI: FIND PROCESS ID and HOW MANY PROCESSES STARTED
      call MPI_COMM_RANK (MPI_COMM_WORLD, proc_id, ierr)
      call MPI_COMM_SIZE (MPI_COMM_WORLD, num_procs, ierr)
#else
      num_procs=1
      proc_id=0
#endif


#ifdef ALLOW_ICEBERG_SUBMERGED_MELT
C-- If using MW 3D melt, then call ICEBERG_SUBMERGED_MELT
C-- otherwise, just use the surface melt below
C-- This is done outside the tile loop below because each berg 
C-- contributes to FW and Heat flux inside ICEBERG_SUBMERGED_MELT
      CALL ICEBERG_SUBMERGED_MELT (myTime, myIter, myThid)
#endif

      DO bj = myByLo(myThid),myByHi(myThid)
       DO bi = myBxLo(myThid),myBxHi(myThid)

        IF (ib_Tot.GT.0) THEN                          ! if icebergs in system
         DO ib_n=1,ib_Tot
          CALL ICEBERG_FIND_TILE (ib_n, myIter, myThid)! Find iceberg tile ID

          IF (proc_id.EQ.ib_Tile(ib_n)) THEN           ! Execute specific tiles
           CALL ICEBERG_FIND_IJ (ib_n, ib_iT, ib_jT,   ! find local i,j
     &                                myIter, myThid)


#ifdef ALLOW_ICEBERG_SURFACE_MELT
C--   SURFACE MELT ROUTINES
      IF ((ibFlag(ib_n).NE.3).and.(ib_thk(ib_n).gt.0)) 
     &     CALL ICEBERG_SURFACE_MELT (ib_iT, ib_jT, ib_n, bi, bj, 
     &                         myIter, myThid)
#endif

#ifdef ALLOW_ICEBERG_ADVECTION
C--   ICEBERG ADVECTION SCHEME
           IF ((ibFlag(ib_n).NE.3).and.(ib_thk(ib_n).gt.0))
     &     CALL ICEBERG_ADVECTION (ib_iT, ib_jT, 
     &                             ib_n, bi, bj, myThid)
#endif

          ENDIF  ! Execute specific tiles
         ENDDO   ! ib_n

        ENDIF   ! if ib_Tot > 0

        _BARRIER

       ENDDO   ! bj
      ENDDO   ! bi

#ifdef ALLOW_ICEBERG_CALVING
C--   CALVE ICEBERGS
        CALL ICEBERG_CALVE ( myTime, myIter, myThid )
#endif

#ifdef ALLOW_USE_MPI
C--   EXCHANGE ICEBERG BETWEEN TILES (if MPI)
      IF (num_procs.GT.1) THEN
C      Between tiles 
       CALL ICEBERG_EXCHANGE_TILE ( myThid )
      ENDIF
#endif

C--   REMOVE MELTED ICEBERGS
      CALL ICEBERG_REMOVE ( myIter, myThid )

      RETURN
      END
