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
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER proc_id, num_procs
#ifdef ALLOW_USE_MPI
      INTEGER ierr, status(MPI_STATUS_SIZE)
#endif

#ifdef ALLOW_USE_MPI
      num_procs=nPy*nPx
      proc_id=mpiMyId
#else
      num_procs=1
      proc_id=0
#endif


#ifdef ICEBERG_DEBUG_ON
      IF (ib_model_debug_level.ge.1) THEN
      WRITE(msgBuf,'(A,A)') '|------------------------------',
     &  '--------------------------------------------------|'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A,I5,A,I5)')
     & '|- ICEBERG MODEL CALLED ON PROC = ',
     &  proc_id, ' at ITERATION = ', myIter
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A,A)') '|------------------------------',
     &  '--------------------------------------------------|'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDIF
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

C          Dpm't do this here every time because icebergs can be double counted            
C          CALL ICEBERG_FIND_TILE (ib_n, myIter, myThid)! Find iceberg tile ID

          IF (proc_id.EQ.ib_Tile(ib_n)) THEN           ! Execute specific tiles
C           CALL ICEBERG_FIND_IJ (ib_n, ib_iT, ib_jT,   ! find local i,j
C     &                                myIter, myThid)

#ifdef ICEBERG_DEBUG_ON
      IF (ib_model_debug_level.gt.2) THEN
       WRITE(msgBuf,'(A,I5)')
     &  '|- Running ICEBERG_MODEL for ib_n=', ib_n
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      WRITE(msgBuf,'(A,F10.5,A,F10.5)')
     &  '    - Local indices ib_i =',
     &  ib_i(ib_n),'  ib_j(ib_n) = ', ib_j(ib_n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      WRITE(msgBuf,'(A,F10.5,A,F10.5)')
     &  '    - Global indices ib_i = ',
     &  ib_i(ib_n),'   ib_j = ', ib_j(ib_n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif /* ICEBERG_DEBUG_ON */

#ifdef ALLOW_ICEBERG_SURFACE_MELT
C--   SURFACE MELT ROUTINES
      IF ((ibFlag(ib_n).NE.3).and.(ib_thk(ib_n).gt.0)) 
     &     CALL ICEBERG_SURFACE_MELT (ib_n, 
     &                        ib_n, bi, bj,  myIter, myThid)
#endif

#ifdef ICEBERG_DEBUG_ON
      IF (ib_model_debug_level.gt.3) THEN
       WRITE(msgBuf,'(A,I5)')
     &  '|- After melting, ibFlag = ', ibFlag(ib_n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif /* ICEBERG_DEBUG_ON */

#ifdef ICEBERG_DEBUG_ON
      IF (ib_model_debug_level.gt.3) THEN
       WRITE(msgBuf,'(A,F20.10,A,F20.10)')
     &  '|- Before advecting, ib_i= ', ib_i(ib_n),
     &  ' ib_j = ', ib_j(ib_n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif /* ICEBERG_DEBUG_ON */

#ifdef ALLOW_ICEBERG_ADVECTION
C--   ICEBERG ADVECTION SCHEME
           IF ((ibFlag(ib_n).NE.3).and.(ib_thk(ib_n).gt.0))
     &     CALL ICEBERG_ADVECTION (ib_n, 
     &                             bi, bj, myThid, myIter)
#endif

#ifdef ICEBERG_DEBUG_ON
      IF (ib_model_debug_level.gt.3) THEN
       WRITE(msgBuf,'(A,F20.10,A,F20.10)')
     &  '|- After advecting, ib_i= ', ib_i(ib_n),
     &  ' ib_j = ', ib_j(ib_n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif /* ICEBERG_DEBUG_ON */

          ENDIF  ! Execute specific tiles
         ENDDO   ! ib_n

        ENDIF   ! if ib_Tot > 0

       ENDDO   ! bj
      ENDDO   ! bi

C Now that everyone has moved around and melted, we can
C check the tiles to see if anyone has changed tiles
      CALL ICEBERG_EXCHANGE_TILE ( myThid, myIter )

C Once existing icebergs are happy, we can add new ones      
#ifdef ALLOW_ICEBERG_CALVING
C--   CALVE ICEBERGS
        CALL ICEBERG_CALVE ( myTime, myIter, myThid )
#endif

C After calving, we can make sure the head node knows about all
C of the icebergs in the system
#ifdef ALLOW_USE_MPI
C--   EXCHANGE ICEBERG BETWEEN TILES (if MPI)
      IF (num_procs.GT.1) THEN
C      Between tiles 
       CALL ICEBERG_EXCHANGE_TILE_INFO ( myThid )
      ENDIF
#endif

C Finally, we can remove any icebergs that have melted
C--   REMOVE MELTED ICEBERGS
      CALL ICEBERG_REMOVE ( myIter, myThid )

#ifdef ICEBERG_DEBUG_ON
      IF (ib_model_debug_level.ge.1) THEN
      
      WRITE(msgBuf,'(A)') '|- END ICEBERG MODEL'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A,A)') '|------------------------------',
     &  '--------------------------------------------------|'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

      RETURN
      END
