C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_REMOVE (
     I                          myIter, myThid)

C     ==================================================================
c     MITberg V1.0 ICEBERG REMOVAL 
c     ==================================================================
C
C     o Remove icebergs that have melted from the system
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
#include "EXCH.h"

C     routine arguements
      INTEGER myThid
      INTEGER myIter

C     local arguements
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER ib_n
      INTEGER tmp_list_I(NUMBER_OF_BERGS,2)
      _RL tmp_list(NUMBER_OF_BERGS,13)
      INTEGER pos


C    Clear data in arrays
      tmp_list_I(:,:) = 0
      tmp_list(:,:) = 0. _d 0
c      _BEGIN_MASTER(myThid)


C      Find active icebergs
        pos = 1  ! reset counter


      IF (ib_Tot.GT.0) THEN

        DO ib_n=1,ib_Tot
         IF (ibFlag(ib_n).NE.3) THEN
          tmp_list_I(pos,1) = ib_id(ib_n)
          tmp_list_I(pos,2) = ibFlag(ib_n)
          tmp_list(pos,1) = ib_tile(ib_n)
          tmp_list(pos,2) = ib_i(ib_n)
          tmp_list(pos,3) = ib_j(ib_n)
          tmp_list(pos,4) = ib_wth(ib_n)
          tmp_list(pos,5) = ib_lth(ib_n)
          tmp_list(pos,6) = ib_thk(ib_n)
          tmp_list(pos,7) = ib_dft(ib_n)
          tmp_list(pos,8) = ib_fbd(ib_n)
          tmp_list(pos,9) = ib_uVel(ib_n)
          tmp_list(pos,10) = ib_vVel(ib_n)
          tmp_list(pos,11) = ib_source(ib_n)
          tmp_list(pos,12) = ib_scale(ib_n)
          tmp_list(pos,13) = calve_slab_counter(ib_n)
          pos = pos+1       ! increment counter
         ENDIF
       ENDDO
       
       ib_Tot = pos-1       ! update number of icebergs

C      clear arrays
          ib_id(:) = 0
          ibFlag(:) = 0
          ib_tile(:) = 0. _d 0
          ib_i(:)  = 0. _d 0
          ib_j(:)  = 0. _d 0
          ib_wth(:) = 0. _d 0
          ib_lth(:) = 0. _d 0
          ib_thk(:) = 0. _d 0
          ib_dft(:) = 0. _d 0
          ib_fbd(:) = 0. _d 0
          ib_uVel(:) = 0. _d 0
          ib_vVel(:) = 0. _d 0
          ib_source(:) = 0. _d 0
          ib_scale(:)  = 0. _d 0
          calve_slab_counter(:) = 0. _d 0

C      Now update arrays with all active icebergs
         
        DO ib_n=1,ib_Tot
          ib_id(ib_n) =   tmp_list_I(ib_n,1)
          ibFlag(ib_n) =  tmp_list_I(ib_n,2)
          ib_tile(ib_n)  = tmp_list(ib_n,1)
          ib_i(ib_n)  =   tmp_list(ib_n,2)
          ib_j(ib_n)  =   tmp_list(ib_n,3)
          ib_wth(ib_n) =  tmp_list(ib_n,4)
          ib_lth(ib_n) =  tmp_list(ib_n,5)
          ib_thk(ib_n) =  tmp_list(ib_n,6)
          ib_dft(ib_n) =  tmp_list(ib_n,7)
          ib_fbd(ib_n) =  tmp_list(ib_n,8)
          ib_uVel(ib_n) = tmp_list(ib_n,9)
          ib_vVel(ib_n) = tmp_list(ib_n,10)
          ib_source(ib_n)=tmp_list(ib_n,11)
          ib_scale(ib_n)= tmp_list(ib_n,12)
          calve_slab_counter(ib_n) = tmp_list(ib_n,13)
        ENDDO 

      ENDIF   ! end ib_Tot > 0


C-----------------------------------------------------------------------

c      _END_MASTER(myThid)
c      _BARRIER

      return
      
      END
 
