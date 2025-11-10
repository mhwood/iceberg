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
      INTEGER ib_n, ib_Tot_all, ib_counter
      INTEGER fld, ib_Tot_local
      CHARACTER*(MAX_LEN_MBUF) msgBuf

C     Make temporary arrays to hold iceberg info
      _RL ib_i_tmp(NUMBER_OF_BERGS), ib_j_tmp(NUMBER_OF_BERGS)
      _RL ib_x_tmp(NUMBER_OF_BERGS), ib_y_tmp(NUMBER_OF_BERGS)
      _RL ib_wth_tmp(NUMBER_OF_BERGS), ib_lth_tmp(NUMBER_OF_BERGS)
      _RL ib_thk_tmp(NUMBER_OF_BERGS)
      _RL ib_dft_tmp(NUMBER_OF_BERGS), ib_fbd_tmp(NUMBER_OF_BERGS)
      _RL ib_uvel_tmp(NUMBER_OF_BERGS), ib_vvel_tmp(NUMBER_OF_BERGS)
      _RL ib_source_tmp(NUMBER_OF_BERGS)
      _RL ib_scale_tmp(NUMBER_OF_BERGS)
      _RL calve_slab_counter_tmp(NUMBER_OF_BERGS)
      INTEGER ib_Tile_tmp(NUMBER_OF_BERGS)
      INTEGER ib_Flag_tmp(NUMBER_OF_BERGS)
      INTEGER ib_Id_tmp(NUMBER_OF_BERGS)

C     MPI Stuff
      INTEGER proc_id, ierr, status(MPI_STATUS_SIZE), pid
      _RL message(NUMBER_OF_BERGS,17)
      _RL message2(NUMBER_OF_BERGS,17)

C     Zero out the temporary arrays
      ib_i_tmp(:) = 0.0D0
      ib_j_tmp(:) = 0.0D0
      ib_x_tmp(:) = 0.0D0
      ib_y_tmp(:) = 0.0D0
      ib_wth_tmp(:) = 0.0D0
      ib_lth_tmp(:) = 0.0D0
      ib_thk_tmp(:) = 0.0D0
      ib_dft_tmp(:) = 0.0D0
      ib_fbd_tmp(:) = 0.0D0
      ib_uvel_tmp(:) = 0.0D0
      ib_vvel_tmp(:) = 0.0D0
      ib_source_tmp(:) = 0.0D0
      ib_scale_tmp(:) = 0.0D0
      calve_slab_counter_tmp(:) = 0.0D0
      ib_Tile_tmp(:) = 0
      ib_Flag_tmp(:) = 0
      ib_Id_tmp(:) = 0


C ---------------------------------------------------------------------
C   First, everyone needs to inform proc 0 of their iceberg counts
C ---------------------------------------------------------------------

      ib_Tot_local = 0
      DO ib_n=1,ib_Tot
        IF (ib_tile(ib_n).eq.mpiMyId) THEN
          ib_Tot_local = ib_Tot_local + 1
        ENDIF
      END DO ! ib_n=1,ib_Tot

C     Everyone informs proc 0 of their iceberg counts
      IF (mpiMyId.NE.0) THEN
C     First, we need to get the total counts of icebergs across all tiles
      CALL MPI_SEND(ib_Tot_local, 1, MPI_INTEGER, 0, 0,
     &                  MPI_COMM_MODEL, ierr)

C     print out how many icebergs this proc has

        ELSE ! mpiMyId.EQ.0  

      ib_Tot_global(1) = ib_Tot_local ! Proc 0's iceberg count
      ib_Tot_all = ib_Tot_local
C     Proc 0 receives iceberg information from other tiles
         DO pid=1, nPx*nPy-1

         CALL MPI_RECV(ib_Tot_global(pid+1), 1, MPI_INTEGER, pid,
     &              0, MPI_COMM_MODEL, status, ierr)
            ib_Tot_all = ib_Tot_all + ib_Tot_global(pid+1)

            END DO ! pid=1, nPx*nPy-1

      ENDIF ! mpiMyId.EQ.0

C     Broadcast the total iceberg count to all procs
      CALL MPI_BCAST(ib_Tot_all, 1, MPI_INTEGER, 0,
     &               MPI_COMM_MODEL, ierr)

C    Broadcast the ib_Tot_global array to all procs
      CALL MPI_BCAST(ib_Tot_global, nPx*nPy, MPI_INTEGER, 0,
     &               MPI_COMM_MODEL, ierr)

#ifdef ICEBERG_DEBUG_ON
            IF (ib_exchange_info_debug_level.ge.2) THEN
            DO fld=0,nPx*nPy-1
            WRITE(msgBuf,'(A,I5,A,I5,A,I5)') '|- PROC ', mpiMyId,
     &    ' RECEIVED ICEBERG COUNT OF ', ib_Tot_global(fld+1),
     &    ' FROM PROC ', fld
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
            ENDDO
            ENDIF 
#endif

C     Now everyone knows the total number of icebergs
      ib_Tot = ib_Tot_all

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

C      Fill in the temporary arrays with the proc 0 info
       ib_counter = 1
       IF (mpiMyId.EQ.0) THEN
        DO ib_n=1,ib_Tot
            IF ((ib_Tile(ib_n).eq.0.0).and.
     &           (ib_source(ib_n).gt.0.0)) THEN
                  ib_Id_tmp(ib_counter)    = ib_id(ib_n)
                  ib_Tile_tmp(ib_counter)  = ib_Tile(ib_n)
                  ib_i_tmp(ib_counter)     = ib_i(ib_n)
                  ib_j_tmp(ib_counter)     = ib_j(ib_n)
                  ib_x_tmp(ib_counter)     = ib_x(ib_n)
                  ib_y_tmp(ib_counter)     = ib_y(ib_n)
                  ib_wth_tmp(ib_counter)   = ib_wth(ib_n)
                  ib_lth_tmp(ib_counter)   = ib_lth(ib_n)
                  ib_thk_tmp(ib_counter)   = ib_thk(ib_n)
                  ib_dft_tmp(ib_counter)   = ib_dft(ib_n)
                  ib_fbd_tmp(ib_counter)   = ib_fbd(ib_n)
                  ib_uvel_tmp(ib_counter)  = ib_uVel(ib_n)
                  ib_vvel_tmp(ib_counter)  = ib_vVel(ib_n)
                  ib_Flag_tmp(ib_counter)  = ibFlag(ib_n)
                  ib_source_tmp(ib_counter)= ib_source(ib_n)
                  ib_scale_tmp(ib_counter) = ib_scale(ib_n)
                  calve_slab_counter_tmp(ib_counter) =
     &                     calve_slab_counter(ib_n)
                  ib_counter = ib_counter + 1
            ENDIF 
        END DO ! ib_n=1,ib_Tot
      ENDIF ! mpiMyId.EQ.0

!         IF (ib_exchange_info_debug_level.ge.2) THEN
!         WRITE(msgBuf,'(A,A,I5,A)') '|- TEMPORARY SUMMARY OF ICEBERG', 
!      &  ' INFO KNOWN BY PROC',mpiMyId,':'
!         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &      SQUEEZE_RIGHT, myThid )
! C      Print the full iceberg information on proc 0
!       DO ib_n=1,ib_Tot
!       WRITE(msgBuf,'(A,I7,A,F10.5,A,I5,A,F10.5,A,
!      &               F10.5,A,F20.5,A,F20.5)')
!      &   '|   - Iceberg ID: ', ib_id_tmp(ib_n),
!      &   ' Source: ', ib_source_tmp(ib_n),
!      &   ' Tile: ', ib_Tile_tmp(ib_n),
!      &   ' i: ', ib_i_tmp(ib_n),
!      &   ' j: ', ib_j_tmp(ib_n),
!      &   ' x: ', ib_x_tmp(ib_n),
!      &   ' y: ', ib_y_tmp(ib_n)
!          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &                           SQUEEZE_RIGHT, myThid )
!       ENDDO
!       ENDIF

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
                  ib_id_tmp(ib_counter)   = message(ib_n,1)
                  ib_Tile_tmp(ib_counter) = message(ib_n,2)
                  ib_i_tmp(ib_counter)    = message(ib_n,3)
                  ib_j_tmp(ib_counter)    = message(ib_n,4)
                  ib_x_tmp(ib_counter)    = message(ib_n,5)
                  ib_y_tmp(ib_counter)    = message(ib_n,6)  
                  ib_wth_tmp(ib_counter)  = message(ib_n,7)
                  ib_lth_tmp(ib_counter)  = message(ib_n,8)
                  ib_thk_tmp(ib_counter)  = message(ib_n,9)
                  ib_dft_tmp(ib_counter)  = message(ib_n,10)
                  ib_fbd_tmp(ib_counter)  = message(ib_n,11)
                  ib_uVel_tmp(ib_counter) = message(ib_n,12)
                  ib_vVel_tmp(ib_counter) = message(ib_n,13)
                  ib_Flag_tmp(ib_counter)  = message(ib_n,14)
                  ib_source_tmp(ib_counter) = message(ib_n,15)
                  ib_scale_tmp(ib_counter) = message(ib_n,16)
                  calve_slab_counter_tmp(ib_counter) = message(ib_n,17)
                  ib_counter = ib_counter + 1
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


!         IF (ib_exchange_info_debug_level.ge.2) THEN
!         WRITE(msgBuf,'(A,A,I5,A)') '|- TEMPORARY SUMMARY OF ICEBERG', 
!      &  ' INFO KNOWN BY PROC',mpiMyId,':'
!         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &      SQUEEZE_RIGHT, myThid )
! C      Print the full iceberg information on proc 0
!       DO ib_n=1,ib_Tot
!       WRITE(msgBuf,'(A,I7,A,F10.5,A,I5,A,F10.5,A,
!      &               F10.5,A,F20.5,A,F20.5)')
!      &   '|   - Iceberg ID: ', ib_id_tmp(ib_n),
!      &   ' Source: ', ib_source_tmp(ib_n),
!      &   ' Tile: ', ib_Tile_tmp(ib_n),
!      &   ' i: ', ib_i_tmp(ib_n),
!      &   ' j: ', ib_j_tmp(ib_n),
!      &   ' x: ', ib_x_tmp(ib_n),
!      &   ' y: ', ib_y_tmp(ib_n)
!          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
!      &                           SQUEEZE_RIGHT, myThid )
!       ENDDO
!       ENDIF
       
C ---------------------------------------------------------------------
C Now, proc 0 has all the iceberg information for outputting
C and we're going to send it back to the other tiles
C ---------------------------------------------------------------------
         IF (mpiMyId.EQ.0) THEN

            message2(:,:) = 0.0D0 ! Initialize the message array

            message2(:,1) = ib_id_tmp(:) ! First column is iceberg ID
            message2(:,2) = ib_Tile_tmp(:) ! Second column is tile ID
            message2(:,3) = ib_i_tmp(:) ! Third column is iceberg i index
            message2(:,4) = ib_j_tmp(:) ! Fourth column is iceberg j index
            message2(:,5) = ib_x_tmp(:) ! Fifth column is iceberg x position
            message2(:,6) = ib_y_tmp(:) ! Sixth column is iceberg y position
            message2(:,7) = ib_wth_tmp(:) ! Seventh column is iceberg width
            message2(:,8) = ib_lth_tmp(:) ! Eighth column is iceberg length
            message2(:,9) = ib_thk_tmp(:) ! Ninth column is iceberg thickness
            message2(:,10) = ib_dft_tmp(:) ! Tenth column is iceberg draft
            message2(:,11) = ib_fbd_tmp(:) ! Eleventh column is iceberg freeboard
            message2(:,12) = ib_uVel_tmp(:) ! Twelfth column is iceberg u velocity
            message2(:,13) = ib_vVel_tmp(:) ! Thirteenth column is iceberg v velocity
            message2(:,14) = ib_Flag_tmp(:) ! Fourteenth column is iceberg flag
            message2(:,15) = ib_source_tmp(:) ! Fifteenth column is iceberg source
            message2(:,16) = ib_scale_tmp(:) ! Sixteenth column is iceberg scale
            message2(:,17) = calve_slab_counter_tmp(:) ! Seventeenth column is slab counter

         DO ib_n=1,ib_Tot
                  ib_id(ib_n)   = message2(ib_n,1)
                  ib_Tile(ib_n) = message2(ib_n,2)
                  ib_i(ib_n)    = message2(ib_n,3)
                  ib_j(ib_n)    = message2(ib_n,4)
                  ib_x(ib_n)    = message2(ib_n,5)
                  ib_y(ib_n)    = message2(ib_n,6)  
                  ib_wth(ib_n)  = message2(ib_n,7)
                  ib_lth(ib_n)  = message2(ib_n,8)
                  ib_thk(ib_n)  = message2(ib_n,9)
                  ib_dft(ib_n)  = message2(ib_n,10)
                  ib_fbd(ib_n)  = message2(ib_n,11)
                  ib_uVel(ib_n) = message2(ib_n,12)
                  ib_vVel(ib_n) = message2(ib_n,13)
                  ibFlag(ib_n)  = message2(ib_n,14)
                  ib_source(ib_n) = message2(ib_n,15)
                  ib_scale(ib_n) = message2(ib_n,16)
                  calve_slab_counter(ib_n) = message2(ib_n,17)
          END DO ! ib_n=1,ib_Tot
      
             DO pid=1, nPx*nPy-1
            CALL MPI_SEND(message2, NUMBER_OF_BERGS*17, MPI_REAL8, pid,
     &                  1, MPI_COMM_MODEL, ierr)
            END DO ! pid=1, nPx*nPy-1

         ELSE ! mpiMyId.NE.0

             CALL MPI_RECV(message2, NUMBER_OF_BERGS*17, MPI_REAL8, 0,
     &              1, MPI_COMM_MODEL, status, ierr)

C        Organize the received iceberg information
         DO ib_n=1,ib_Tot
                  ib_id(ib_n)   = message2(ib_n,1)
                  ib_Tile(ib_n) = message2(ib_n,2)
                  ib_i(ib_n)    = message2(ib_n,3)
                  ib_j(ib_n)    = message2(ib_n,4)
                  ib_x(ib_n)    = message2(ib_n,5)
                  ib_y(ib_n)    = message2(ib_n,6)  
                  ib_wth(ib_n)  = message2(ib_n,7)
                  ib_lth(ib_n)  = message2(ib_n,8)
                  ib_thk(ib_n)  = message2(ib_n,9)
                  ib_dft(ib_n)  = message2(ib_n,10)
                  ib_fbd(ib_n)  = message2(ib_n,11)
                  ib_uVel(ib_n) = message2(ib_n,12)
                  ib_vVel(ib_n) = message2(ib_n,13)
                  ibFlag(ib_n)  = message2(ib_n,14)
                  ib_source(ib_n) = message2(ib_n,15)
                  ib_scale(ib_n) = message2(ib_n,16)
                  calve_slab_counter(ib_n) = message2(ib_n,17)
          END DO ! ib_n=1,ib_Tot

        ENDIF ! mpiMyId.EQ.0





#ifdef ICEBERG_DEBUG_ON
      
C      IF (mpiMyId.EQ.0) THEN
        IF (ib_exchange_info_debug_level.ge.2) THEN
        WRITE(msgBuf,'(A,A,I5,A)') '|- SUMMARY OF ICEBERG', 
     &  ' INFO KNOWN BY PROC',mpiMyId,':'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &      SQUEEZE_RIGHT, myThid )
C      Print the full iceberg information on proc 0
      DO ib_n=1,ib_Tot
      WRITE(msgBuf,'(A,I7,A,F10.5,A,I5,A,F10.5,A,
     &               F10.5,A,F20.5,A,F20.5)')
     &   '|   - Iceberg ID: ', ib_id(ib_n),
     &   ' Source: ', ib_source(ib_n),
     &   ' Tile: ', ib_Tile(ib_n),
     &   ' i: ', ib_i(ib_n),
     &   ' j: ', ib_j(ib_n),
     &   ' x: ', ib_x(ib_n),
     &   ' y: ', ib_y(ib_n)
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDDO
      ENDIF

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

