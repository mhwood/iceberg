C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_EXCHANGE_TILE ( myThid, myIter )

C     ==================================================================
c     MITberg V2.0 ICEBERG EXCHANGE TILE
c     ==================================================================
C
C     o Exchange icebergs between tiles when using EXCH2
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
#ifdef ALLOW_EXCH2
#include "W2_EXCH2_SIZE.h"
#include "W2_EXCH2_TOPOLOGY.h"
#include "W2_EXCH2_PARAMS.h"
#endif /* ALLOW_EXCH2 */

C     Routine arguements
      INTEGER myThid

C     Local arguments
      INTEGER ib_n
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER myIter

#ifdef ALLOW_USE_MPI

       _RL half_RL
C     This number is 1,2,3,4 for N,S,E,W or 0 for no boundary
       INTEGER ib_boundary_flag
       INTEGER targetTile, myTileId
       INTEGER targetProc, sourceProc
       _RL new_iT, new_jT, new_i, new_j, varOut
      INTEGER mpiRC
      INTEGER mpiGridSpec(2)
      INTEGER ierr, status(MPI_STATUS_SIZE)
      INTEGER exch_list_loc(NUMBER_OF_BERGS, 2)
      INTEGER pid
      _RL ib_i_recv, ib_j_recv, ib_x_recv, ib_y_recv
      _RL ib_wth_recv, ib_lth_recv, ib_thk_recv
      _RL ib_dft_recv, ib_fbd_recv, ib_uvel_recv, ib_vvel_recv
      _RL ib_source_recv, ib_scale_recv, calve_slab_counter_recv
      INTEGER ib_Tile_recv, ib_Flag_recv, ib_Id_recv

#ifdef ALLOW_EXCH2
      INTEGER targetIlo, targetIhi, targetJlo, targetJhi
      INTEGER sourceIlo, sourceIhi, sourceJlo, sourceJhi
      INTEGER iStride, jStride
      INTEGER ppi(2), ppj(2), oi, oj, tN
      INTEGER itb, jtb, isb, jsb
#endif /* ALLOW_EXCH2 */

#ifdef ICEBERG_DEBUG_ON
       IF (ib_exchange_tile_debug_level.ge.1) THEN
       WRITE(msgBuf,'(A)') '|--- ICEBERG EXCHANGE TILE BEGIN DEBUG'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF
#endif

      IF (ib_Tot.GT.0) THEN

       half_RL = 0.5D0

C      The target proc is the tile that will receive an iceberg
C      if it changes tiles. This is set to -1 initially
C      and will be set to the target proc if the iceberg sent somewhere
       targetProc = -1

C      Initialize the exchange list
       exch_list_loc(:,:) = -1

       DO ib_n=1,ib_Tot

       IF (mpiMyId.EQ.ib_Tile(ib_n)) THEN

#ifdef ICEBERG_DEBUG_ON
       IF (ib_exchange_tile_debug_level.ge.2) THEN
       WRITE(msgBuf,'(A,I5,A)') '   |--- Checking whether iceberg ',
     &  ib_n, ' is located on the boundary '
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF
#endif        

         ib_boundary_flag = 0
         
C Get the local i and j indices of the iceberg
C      CALL ICEBERG_FIND_IJ ( ib_n, ib_iT, ib_jT, myIter, myThid )

C check to see if we are on the northern, southern, eastern or western
C boundary of the domain
         IF (ib_i(ib_n).LT.half_RL) THEN
           ib_boundary_flag = 4 ! western boundary
         ELSEIF (ib_i(ib_n).GT.sNx+half_RL) THEN
           ib_boundary_flag = 3 ! eastern boundary 
         ELSEIF (ib_j(ib_n).LT.half_RL) THEN
           ib_boundary_flag = 2 ! southern boundary
         ELSEIF (ib_j(ib_n).GT.sNy+half_RL) THEN
           ib_boundary_flag = 1 ! northern boundary
         ENDIF

#ifdef ALLOW_EXCH2
C With exch2, we use routines to check which tile corresponds to 
C boundary identified by the flag
         myTileId = W2_myTileList(1,1)
         targetTile = exch2_neighbourId(ib_boundary_flag,myTileId)
         targetProc=W2_tileProc(targetTile)-1
#else
C Without exch2, we use the mpi functions
C For now, we have assumed that there is no multithreadding,
C so that sNx = 1 and sNy = 1
         IF (ib_boundary_flag.EQ.1) THEN
           targetProc = tilePidN(1,1)
         ELSEIF (ib_boundary_flag.EQ.2) THEN
           targetProc = tilePidS(1,1)
         ELSEIF (ib_boundary_flag.EQ.3) THEN
           targetProc = tilePidE(1,1) 
         ELSEIF (ib_boundary_flag.EQ.4) THEN
           targetProc = tilePidW(1,1)
         ELSE
           targetProc = -1
         ENDIF
#endif


#ifdef ICEBERG_DEBUG_ON
       IF (ib_exchange_tile_debug_level.ge.3) THEN
       WRITE(msgBuf,'(A,I5,A,F20.10,A,F20.10,A,I5)')
     &  '     |--- Bounday flag for iceberg ', ib_n,
     &  ' at i=', ib_i(ib_n), ' j=', ib_j(ib_n),
     & ' is ', ib_boundary_flag
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A,I5)')
     &  '     |--- Sanity check. I am proc ', mpiMyId
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        IF (ib_boundary_flag.NE.0) THEN
         WRITE(msgBuf,'(A,I5,A,I5)')
     &  '         |--> Moving iceberg ', ib_n,
     &  ' to proc tile ', targetProc
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        ELSEIF (ib_boundary_flag.EQ.0) THEN
         WRITE(msgBuf,'(A,I5)')
     &  '         |--> No exchange needed for iceberg ', ib_n
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        ENDIF
       ENDIF  
#endif


C If the iceberg is on a boundary, we need to exchange it
         IF (ib_boundary_flag.NE.0) THEN

C        Keep track of source and target procs
         exch_list_loc(ib_n, 2) = targetProc
         exch_list_loc(ib_n, 1) = mpiMyId

#ifdef ALLOW_EXCH2
C With exch2, we need to get the target tile coordinates
C usinf the exch2 routines
         CALL MPI_CART_COORDS( mpiComm, targetProc, 2,
     &    mpiGridSpec, mpiRC )

         tN = exch2_opposingSend(ib_boundary_flag,myTileId)
         ppi(1)     =exch2_pij(1,ib_boundary_flag,myTileId)
         ppi(2)     =exch2_pij(2,ib_boundary_flag,myTileId)
         ppj(1)     =exch2_pij(3,ib_boundary_flag,myTileId)
         ppj(2)     =exch2_pij(4,ib_boundary_flag,myTileId)
         oi        =exch2_oi(ib_boundary_flag,myTileId)
         oj        =exch2_oj(ib_boundary_flag,myTileId)

          CALL EXCH2_GET_SCAL_BOUNDS(
     I              'T ', OLx, .TRUE.,
     I              targetTile, tN,
     O              targetIlo, targetIhi, targetJlo, targetJhi,
     O              iStride, jStride,
     I              myThid )

         itb = exch2_tBasex(targetTile)
         jtb = exch2_tBasey(targetTile)
         isb = exch2_tBasex(myTileId)
         jsb = exch2_tBasey(myTileId)
         sourceIlo=ppi(1)*(targetIlo+itb)+ppi(2)*(targetJlo+jtb)+oi-isb
         sourceJlo=ppj(1)*(targetIlo+itb)+ppj(2)*(targetJlo+jtb)+oj-jsb
         sourceIhi=ppi(1)*(targetIhi+itb)+ppi(2)*(targetJhi+jtb)+oi-isb
         sourceJhi=ppj(1)*(targetIhi+itb)+ppj(2)*(targetJhi+jtb)+oj-jsb

#ifdef ICEBERG_DEBUG_ON
      IF (ib_exchange_tile_debug_level.ge.4) THEN
         WRITE(msgBuf,'(A,I8,A,I8,A,4(A,I4))')
     &    '         |-- Tile', myTileId,' (pr=',mpiMyId,')',
     &    ' sends pts i=',sourceIlo,':',sourceIhi,
     &             ', j=',sourceJlo,':',sourceJhi
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(26X,4(A,I4),A,I8,A,I8,A)')
     &    '    to pts i=',targetIlo,':',targetIhi,
     &             ', j=',targetJlo,':',targetJhi,
     &    ' in tile ',targetTile,' (pr=',targetProc,')'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif /* ICEBERG_DEBUG_ON */
         

C       If the i's are equal, then it's a vertical exchange
         IF ((sourceIlo.eq.targetIlo).and.
     &     (sourceIhi.eq.targetIhi)) THEN
          new_iT = ib_i(ib_n)
          new_jT = ((targetJhi-targetJlo)/(sourceJhi-sourceJlo))*
     &     (ib_j(ib_n)-sourceJlo) + targetJlo  
          new_i = new_iT 
          new_j = new_jT 
C       If the j's are equal, then it's a horizontal exchange
         ELSEIF ((sourceJlo.eq.targetJlo).and.
     &          (sourceJhi.eq.targetJhi)) THEN
         new_iT = ((targetIhi-targetIlo)/(sourceIhi-sourceIlo))*
     &     (ib_i(ib_n)-sourceIlo) + targetIlo
         new_jT = ib_j(ib_n)
         new_i = new_iT 
         new_j = new_jT 
C       Otherwise, we throw an error
          ELSE
          STOP 'ICEBERG EXCHANGE TILE NOT YET IMPLEMENTED FOR FACES'
          ENDIF

#else /* ALLOW_EXCH2 */
C Without exch2, we just assume the cardinal directions

       IF (ib_boundary_flag.EQ.1) THEN
         new_i = ib_i(ib_n)
         new_j = ib_j(ib_n) - sNy
       ELSEIF (ib_boundary_flag.EQ.2) THEN
         new_i = ib_i(ib_n)
         new_j = ib_j(ib_n) + sNy
       ELSEIF (ib_boundary_flag.EQ.3) THEN
         new_i = ib_i(ib_n) - sNx
         new_j = ib_j(ib_n)
       ELSEIF (ib_boundary_flag.EQ.4) THEN
         new_i = ib_i(ib_n) + sNx
         new_j = ib_j(ib_n)
       ELSE
         new_i = ib_i(ib_n)
         new_j = ib_j(ib_n)
       ENDIF
#endif /* ALLOW_EXCH2 */

C-        Update the iceberg information for the new proc
          ib_i(ib_n) = new_i
          ib_j(ib_n) = new_j
          ib_Tile(ib_n) = targetProc

#ifdef ICEBERG_DEBUG_ON
      IF (ib_exchange_tile_debug_level.ge.4) THEN
        WRITE(msgBuf,'(A,F20.10,A,F20.10)')
     &    '         |-- New Location in tile: i = ', new_i,
     &    ' j = ', new_j
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A,I5)')
     &    '         |-- New tile: ', ib_Tile(ib_n)
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif /* ICEBERG_DEBUG_ON */

        ENDIF ! End of if iceberg is on a boundary

        ENDIF ! mpiMyId.EQ.ib_Tile(ib_n)

        ENDDO ! End of loop over icebergs


C- Next, we need to tell the target tile that it has a new iceberg
C- This is a little tricky to ensure everyone is communicating correctly
C The strategy here is to use a global exchange list
C Proc 0 will be the communicator
C It will receive the exchange lists from all procs
C and then send the information to the source/target proc pairs

C First, everyone needs to send their exch2 list to proc 0
         IF (mpiMyId.NE.0) then
            CALL MPI_SEND( exch_list_loc, 2*NUMBER_OF_BERGS, 
     &                     MPI_INTEGER,0, 1, MPI_COMM_MODEL, ierr)
         ELSEIF (mpiMyId.EQ.0) THEN
C- Proc 0 receives the exchange list from all procs
            DO pid=0, nPx*nPy-1
               IF (pid.GT.0) THEN
               CALL MPI_RECV( exch_list_loc, 2*NUMBER_OF_BERGS, 
     &                     MPI_INTEGER,pid, 1, MPI_COMM_MODEL,
     &                     status, ierr)
               ENDIF

               DO ib_n=1,NUMBER_OF_BERGS
                  IF (exch_list_loc(ib_n,1).NE.-1) THEN
                  exchange_list(ib_n,1) = exch_list_loc(ib_n,1)
                  exchange_list(ib_n,2) = exch_list_loc(ib_n,2)
                  ENDIF
               ENDDO ! ib_n=1,NUMBER_OF_BERGS

            ENDDO ! pid=1, nPx*nPy-1
         ENDIF ! mpiMyId.EQ.0

C- Now that proc 0 has the full exchange list, it can send the full list to everyone
            IF (mpiMyId.EQ.0) then

            DO pid=1, nPx*nPy-1
            CALL MPI_SEND(exchange_list, 2*NUMBER_OF_BERGS, 
     &                     MPI_INTEGER,pid, 1, MPI_COMM_MODEL, ierr)
            ENDDO ! pid=0, nPx*nPy-1


         ELSEIF (mpiMyId.NE.0) THEN
C- Proc 0 receives the exchange list from all procs

               CALL MPI_RECV(exchange_list, 2*NUMBER_OF_BERGS, 
     &                     MPI_INTEGER, 0, 1, MPI_COMM_MODEL,
     &                     status, ierr)

         ENDIF ! mpiMyId.EQ.0

C Sanity check: loop through and print out where the exchange_list is ne -1
#ifdef ICEBERG_DEBUG_ON
         IF (ib_exchange_tile_debug_level.ge.3) THEN
         WRITE(msgBuf,'(A)') '  |--- Exchange list for icebergs:'
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         DO ib_n=1,NUMBER_OF_BERGS
            IF (exchange_list(ib_n,1).NE.-1) THEN
              WRITE(msgBuf,'(A,I5,A,I5,A,I5)')
     &  '      |--- Iceberg ', ib_n,
     &  ' is being exchanged from proc ', exchange_list(ib_n,1),
     &  ' to proc ', exchange_list(ib_n,2)
              CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
            ENDIF ! exch_list_loc(ib_n,1).NE.-1
         ENDDO ! ib_n=1,NUMBER_OF_BERGS
         ENDIF ! ib_exchange_tile_debug_level.ge.3
#endif /* ICEBERG_DEBUG_ON */
         
C- Now that everyone has the full exchange list, we can update the iceberg information
            DO ib_n=1,ib_Tot
               IF (exchange_list(ib_n,1).NE.-1) THEN
                 targetProc = exchange_list(ib_n,2)
                 sourceProc = exchange_list(ib_n,1)
                   IF (mpiMyId.EQ.sourceProc) THEN

#ifdef ICEBERG_DEBUG_ON
         IF (ib_exchange_tile_debug_level.ge.4) THEN
                     WRITE(msgBuf,'(A,I5,A,I5)')
     &  '       |-- Sending iceberg info from : ',sourceProc,
     &  ' to target proc: ', targetProc
                     CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid ) 

            CALL MPI_SEND( ib_id(ib_n), 1, MPI_INTEGER,
     &                     targetProc, 1, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_Tile(ib_n), 1, MPI_INTEGER,
     &                     targetProc, 2, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_i(ib_n), 1, MPI_REAL8,
     &                     targetProc, 3, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_j(ib_n), 1, MPI_REAL8,
     &                     targetProc, 4, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_x(ib_n), 1, MPI_REAL8,
     &                     targetProc, 5, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_y(ib_n), 1, MPI_REAL8,
     &                     targetProc, 6, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_wth(ib_n), 1, MPI_REAL8,
     &                     targetProc, 7, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_lth(ib_n), 1, MPI_REAL8,
     &                     targetProc, 8, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_thk(ib_n), 1, MPI_REAL8,
     &                     targetProc, 9, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_dft(ib_n), 1, MPI_REAL8,
     &                     targetProc, 10, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_fbd(ib_n), 1, MPI_REAL8,
     &                     targetProc, 11, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_uvel(ib_n), 1, MPI_REAL8,
     &                     targetProc, 12, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_vvel(ib_n), 1, MPI_REAL8,
     &                     targetProc, 13, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ibflag(ib_n), 1, MPI_INTEGER,
     &                     targetProc, 14, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_source(ib_n), 1, MPI_REAL8,
     &                     targetProc, 15, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( ib_scale(ib_n), 1, MPI_REAL8,
     &                     targetProc, 16, MPI_COMM_MODEL, ierr )
            CALL MPI_SEND( calve_slab_counter(ib_n), 1, MPI_REAL8,
     &                     targetProc, 17, MPI_COMM_MODEL, ierr )
         ENDIF 
#endif /* ICEBERG_DEBUG_ON */

                     ib_Tile_recv = ib_Tile(ib_n)
                     ib_i_recv = ib_i(ib_n)
                     ib_j_recv = ib_j(ib_n)

                   ENDIF ! mpiMyId.EQ.sourceProc
                   IF (mpiMyId.EQ.targetProc) THEN

                     ib_Id_recv = -1
                     ib_Tile_recv = -1
                     ib_i_recv = -1.0D0
                     ib_j_recv = -1.0D0
                     ib_x_recv = -1.0D0
                     ib_y_recv = -1.0D0
                     ib_wth_recv = -1.0D0
                     ib_lth_recv = -1.0D0
                     ib_thk_recv = -1.0D0
                     ib_dft_recv = -1.0D0
                     ib_fbd_recv = -1.0D0
                     ib_uvel_recv = -1.0D0
                     ib_vvel_recv = -1.0D0
                     ib_Flag_recv = -1
                     ib_source_recv = -1.0D0
                     ib_scale_recv = -1.0D0
                     calve_slab_counter_recv = -1.0D0


#ifdef ICEBERG_DEBUG_ON
         IF (ib_exchange_tile_debug_level.ge.4) THEN                     
                      WRITE(msgBuf,'(A,I5,A,I5)')
     &  '     |-- Receiving iceberg info from : ',sourceProc,  
     &  ' on target proc: ', targetProc
                      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         ENDIF 
#endif /* ICEBERG_DEBUG_ON */

            CALL MPI_RECV( ib_Id_recv, 1, MPI_INTEGER,
     &              sourceProc, 1, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_Tile_recv, 1, MPI_INTEGER,
     &              sourceProc, 2, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_i_recv, 1, MPI_REAL8,
     &              sourceProc, 3, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_j_recv, 1, MPI_REAL8,
     &              sourceProc, 4, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_x_recv, 1, MPI_REAL8,
     &              sourceProc, 5, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_y_recv, 1, MPI_REAL8,
     &              sourceProc, 6, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_wth_recv, 1, MPI_REAL8,
     &              sourceProc, 7, MPI_COMM_MODEL, status, ierr )      
            CALL MPI_RECV( ib_lth_recv, 1, MPI_REAL8,
     &              sourceProc, 8, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_thk_recv, 1, MPI_REAL8,
     &              sourceProc, 9, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_dft_recv, 1, MPI_REAL8,
     &              sourceProc, 10, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_fbd_recv, 1, MPI_REAL8,
     &              sourceProc, 11, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_uvel_recv, 1, MPI_REAL8,
     &              sourceProc, 12, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_vvel_recv, 1, MPI_REAL8,
     &              sourceProc, 13, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_Flag_recv, 1, MPI_INTEGER,
     &              sourceProc, 14, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_source_recv, 1, MPI_REAL8,
     &              sourceProc, 15, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( ib_scale_recv, 1, MPI_REAL8,
     &              sourceProc, 16, MPI_COMM_MODEL, status, ierr )
            CALL MPI_RECV( calve_slab_counter_recv, 1, MPI_REAL8,
     &              sourceProc, 17, MPI_COMM_MODEL, status, ierr )
   
#ifdef ICEBERG_DEBUG_ON
         IF (ib_exchange_tile_debug_level.ge.4) THEN  
                     WRITE(msgBuf,'(A,I5,A,F20.10,A,F20.10)')
     &  '     |-- Iceberg received: tile ', ib_Tile_recv,
     &  ' at location i=1 ', ib_i_recv,
     &  ' j=1 ', ib_j_recv
                     CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         ENDIF 
#endif /* ICEBERG_DEBUG_ON */

                     ib_Id(ib_n) = ib_Id_recv
                     ib_Tile(ib_n) = ib_Tile_recv
                     ib_i(ib_n) = ib_i_recv
                     ib_j(ib_n) = ib_j_recv
                     ib_x(ib_n) = ib_x_recv
                     ib_y(ib_n) = ib_y_recv
                     ib_wth(ib_n) = ib_wth_recv
                     ib_lth(ib_n) = ib_lth_recv
                     ib_thk(ib_n) = ib_thk_recv
                     ib_dft(ib_n) = ib_dft_recv
                     ib_fbd(ib_n) = ib_fbd_recv
                     ib_uvel(ib_n) = ib_uvel_recv
                     ib_vvel(ib_n) = ib_vvel_recv
                     ibflag(ib_n) = ib_Flag_recv
                     ib_source(ib_n) = ib_source_recv
                     ib_scale(ib_n) = ib_scale_recv
                     calve_slab_counter(ib_n) = calve_slab_counter_recv

                     ENDIF ! mpiMyId.EQ.targetProc

               ENDIF ! exchange_list(ib_n,1).NE.-1
            ENDDO ! ib_n=1,ib_Tot

C After everything, clear the exchange lists
                exchange_list(:,:) = -1
                exch_list_loc(:,:) = -1

#ifdef ALLOW_EXCH2
C Here, we need to check if the iceberg is still within the domain
C If it is not, we set the flag to 3 (out of bounds)

#else /* ALLOW_EXCH2 */
C This is only needed if we are not using exch2

      DO ib_n=1,ib_Tot
      IF (ib_i(ib_n).LT.half_RL.OR.ib_i(ib_n).GT.(sNx*nPx)-half_RL)
     &        ibFlag(ib_n) = 3
        IF (ib_j(ib_n).LT.half_RL.OR.ib_j(ib_n).GT.(sNy*nPy)-half_RL)
     &        ibFlag(ib_n) = 3
      ENDDO ! End of loop over icebergs

#endif /* ALLOW_EXCH2 */

      ENDIF ! Checking if there are icebergs

#else /* ALLOW_USE_MPI */

#ifdef ICEBERG_DEBUG_ON
       IF (ib_exchange_tile_debug_level.ge.4) THEN
       WRITE(msgBuf,'(A)') '  |- ALLOW_USE_MPI is not defined'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       ENDIF
#endif

#endif /* ALLOW_USE_MPI */

#ifdef ICEBERG_DEBUG_ON
       IF (ib_exchange_tile_debug_level.ge.1) THEN
       WRITE(msgBuf,'(A)') '|--- ICEBERG EXCHANGE TILE END DEBUG'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
       ENDIF
#endif

      RETURN
      END

