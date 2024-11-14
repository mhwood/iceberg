C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_EXCHANGE_TILE ( myThid )

C     ==================================================================
c     MITberg V1.0 ICEBERG EXCHANGE TILE
c     ==================================================================
C
C     o Exchange iceberg information between MITgcm tiles using MPI
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

C     Routine arguements
      INTEGER myThid

C     Local arguments
      INTEGER ib_n
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      _RL ib_i_org
      _RL ib_uvel_org, ib_vvel_org

C     MPI Stuff
      INTEGER proc_id, ierr, status(MPI_STATUS_SIZE)
      _RL message(12)

      IF (ib_Tot.GT.0) THEN

#ifdef ICEBERG_DIAG_ON
       WRITE(msgBuf,'(A)') 'ICEBERG EXCHANGE TILE CALLED'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A, I7)') 'Total number of icebergs: ', ib_Tot
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
#endif


       DO ib_n=1,ib_Tot
#ifndef ALLOW_EXCH2
        ib_face(ib_n) = 0
#endif


        CALL MPI_COMM_RANK (MPI_COMM_WORLD, proc_id, ierr)
        message(:)=777.7

        IF (proc_id.EQ.ib_Tile(ib_n)) THEN
         message(1) = ib_id(ib_n)
         message(2) = ib_face(ib_n)
         message(3) = ib_i(ib_n)
         message(4) = ib_j(ib_n)
         message(5) = ib_wth(ib_n)
         message(6) = ib_thk(ib_n)
         message(7) = ib_uVel(ib_n)
         message(8) = ib_vVel(ib_n)
         message(9) = ibFlag(ib_n)
         message(10) = calve_slab_counter(ib_n)
         message(11) = ib_scale(ib_n)
         message(12) = ib_source(ib_n)
        ENDIF

c     Broadcast to ALL processors
#ifdef ICEBERG_TILE_DIAG_ON
        WRITE(msgBuf,'(A)')
     &      '----------------'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, I7)')
     &      'iceberg number: ' , ib_n
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, I7)')
     &   'Processor ID:', proc_id
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
         WRITE(msgBuf,'(A, I7)')
     &    'Broadcasting message from tile', ib_Tile(ib_n)
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )

#endif

        CALL MPI_BCAST(message, 12, MPI_REAL8, ib_Tile(ib_n),
     &  MPI_COMM_WORLD, ierr)

c      Update of iceberg location on tiles
        ib_id(ib_n)   = message(1)
        ib_face(ib_n) = message(2)
        ib_i(ib_n)    = message(3)
        ib_j(ib_n)    = message(4)  
        ib_wth(ib_n)  = message(5)
        ib_thk(ib_n)  = message(6)
        ib_uVel(ib_n) = message(7)
        ib_vVel(ib_n) = message(8)
        ibFlag(ib_n) = message(9)
        calve_slab_counter(ib_n) = message(10)
        ib_scale(ib_n)=message(11)
        ib_source(ib_n) = message(12)


#ifdef ICEBERG_TILE_DIAG_ON
        WRITE(msgBuf,'(A)')
     &    'Received Data: '
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(12F9.2)')
     &   message
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
#endif
       ENDDO


C------------------------------------------------------------
C------------------------------------------------------------

      ENDIF  ! ib_Tot > 0


      RETURN
      END

