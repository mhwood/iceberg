C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_EXCHANGE_TILE_INFO ( myThid )

C     ==================================================================
c     MITberg V1.0 ICEBERG EXCHANGE TILE INFO
c     ==================================================================
C
C     o Exchange iceberg information between MITgcm tiles using MPI
C
C     o Proc 0 now keeps track of all icebergs
C     o Other proces don't need to know about other tiles 
C     o Proc 0 will output iceberg information
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
#include "ICEBERG_PARAMS.h"


C     Routine arguements
      INTEGER myThid

#ifdef ALLOW_USE_MPI

C     Local arguments
      INTEGER ib_n
      INTEGER fld
      CHARACTER*(MAX_LEN_MBUF) msgBuf

C     MPI Stuff
      INTEGER proc_id, ierr, status(MPI_STATUS_SIZE), pid
      _RL message(NUMBER_OF_BERGS,17)


      IF (ib_Tot.GT.0) THEN

#ifdef ICEBERG_DEBUG_ON
       IF (ib_exchange_info_debug_level.ge.1) THEN
       WRITE(msgBuf,'(A,A)') '|- ICEBERG EXCHANGE TILE INFO',
     & ' BEGIN DEBUG'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A, I7)') '|- Total number of icebergs: ', ib_Tot
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF
#endif

C ---------------------------------------------------------------------
C   All procs need to update proc 0 with their iceberg
C   information for outputting
C ---------------------------------------------------------------------

C       IF we're not on proc 0, then bundle iceberg information
C       in order to send it to proc 0         
        IF (mpiMyId.NE.0) THEN

         message(:,:) = 0.0D0 ! Initialize the message array

         message(:,1) = ib_id(:) ! First column is iceberg ID
         message(:,2) = ib_Tile(:) ! Second column is tile ID
         message(:,3) = ib_i(:) ! Third column is iceberg i index
         message(:,4) = ib_j(:) ! Fourth column is iceberg j index
         message(:,5) = ib_x(:) ! Fifth column is iceberg x position
         message(:,6) = ib_y(:) ! Sixth column is iceberg y position
         message(:,7) = ib_wth(:) ! Seventh column is iceberg width
         message(:,8) = ib_lth(:) ! Eighth column is iceberg length
         message(:,9) = ib_thk(:) ! Ninth column is iceberg thickness
         message(:,10) = ib_dft(:) ! Tenth column is iceberg draft
         message(:,11) = ib_fbd(:) ! Eleventh column is iceberg freeboard
         message(:,12) = ib_uVel(:) ! Twelfth column is iceberg u velocity
         message(:,13) = ib_vVel(:) ! Thirteenth column is iceberg v velocity
         message(:,14) = ibFlag(:) ! Fourteenth column is iceberg flag
         message(:,15) = ib_source(:) ! Fifteenth column is iceberg source
         message(:,16) = ib_scale(:) ! Sixteenth column is iceberg scale
         message(:,17) = calve_slab_counter(:) ! Seventeenth column is slab counter


#ifdef ICEBERG_DEBUG_ON
       IF (ib_exchange_info_debug_level.ge.3) THEN
        WRITE(msgBuf,'(A, I7, A)')
     &   '|- Sending info from proc ', mpiMyId, ' to proc 0'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF
#endif

          CALL MPI_SEND(message, NUMBER_OF_BERGS*17, MPI_REAL8, 0, 1,
     &                  MPI_COMM_MODEL, ierr)

        ELSE ! mpiMyId.EQ.0  

C     Proc 0 receives iceberg information from other tiles
         DO pid=1, nPx*nPy-1

         CALL MPI_RECV(message, NUMBER_OF_BERGS*17, MPI_REAL8, pid,
     &              1, MPI_COMM_MODEL, status, ierr)

! #ifdef ICEBERG_DEBUG_ON
!         WRITE(msgBuf,'(A)')
!      &    'Received Data: '
!         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &                           SQUEEZE_RIGHT, myThid )
!       DO ib_n=1,ib_Tot
!        WRITE(msgBuf,'(17F20.10)')
!      &   message(ib_n,:)
!        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &                           SQUEEZE_RIGHT, myThid )
!       ENDDO
! #endif

C        Organize the received iceberg information
         DO ib_n=1,ib_Tot
C       Check if the iceberg is on this tile
C       If it is, it will have the right info for proc 0
            IF (pid.EQ.INT(message(ib_n,2))) THEN
                  ib_id(ib_n)   = message(ib_n,1)
                  ib_Tile(ib_n) = message(ib_n,2)
                  ib_i(ib_n)    = message(ib_n,3)
                  ib_j(ib_n)    = message(ib_n,4)
                  ib_x(ib_n)    = message(ib_n,5)
                  ib_y(ib_n)    = message(ib_n,6)  
                  ib_wth(ib_n)  = message(ib_n,7)
                  ib_lth(ib_n)  = message(ib_n,8)
                  ib_thk(ib_n)  = message(ib_n,9)
                  ib_dft(ib_n)  = message(ib_n,10)
                  ib_fbd(ib_n)  = message(ib_n,11)
                  ib_uVel(ib_n) = message(ib_n,12)
                  ib_vVel(ib_n) = message(ib_n,13)
                  ibFlag(ib_n)  = message(ib_n,14)
                  ib_source(ib_n) = message(ib_n,15)
                  ib_scale(ib_n) = message(ib_n,16)
                  calve_slab_counter(ib_n) = message(ib_n,17)
            ENDIF
         END DO ! ib_n=1,ib_Tot

#ifdef ICEBERG_DEBUG_ON
      IF (ib_exchange_info_debug_level.ge.3) THEN
         WRITE(msgBuf,'(A, I7)')
     &    '|- Receiving message from proc', pid
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDIF

#endif
         
         END DO ! pid=1, nPx*nPy-1



       ENDIF ! mpiMyId.NE.0      

#ifdef ICEBERG_DEBUG_ON
      
C      IF (mpiMyId.EQ.0) THEN
        IF (ib_exchange_info_debug_level.ge.2) THEN
        WRITE(msgBuf,'(A,A,I5,A)') '|- SUMMARY OF ICEBERG', 
     &  ' INFO KNOWN BY PROC',mpiMyId,':'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &      SQUEEZE_RIGHT, myThid )
C      Print the full iceberg information on proc 0
      DO ib_n=1,ib_Tot
         WRITE(msgBuf,'(A,I7,A,I5,A,F10.5,A,F10.5,A,F20.5,A,F20.5)')
     &   '|   - Iceberg ID: ', ib_id(ib_n),
     &   ' Tile: ', ib_Tile(ib_n),
     &   ' i: ', ib_i(ib_n),
     &   ' j: ', ib_j(ib_n),
     &   ' x: ', ib_x(ib_n),
     &   ' y: ', ib_y(ib_n)
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDDO
      ENDIF
C      ENDIF



       IF (ib_exchange_info_debug_level.ge.1) THEN
       WRITE(msgBuf,'(A,A)') '|- ICEBERG EXCHANGE TILE INFO',
     & ' END DEBUG'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF

#endif /* ICEBERG_DEBUG_ON */

       ENDIF  ! (ib_Tot.GT.0)


#endif /* ALLOW_USE_MPI */

      RETURN
      END

