c
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_READ_PICKUP( myThid  )

C     ==================================================================
C     MITberg V1.0 READ ICEBERG PICKUP FILE(S)
C     ==================================================================
C
C     o Reads iceberg pickup files:
C       pickup_iceberg.XXXXXXXXXX.data :: binary (NUMBER_OF_BERGSx13) real*8
C
C     ==================================================================

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"
#include "GRID.h"
#include "FFIELDS.h"
#include "DYNVARS.h"

c     routine arguements
      INTEGER myThid

C     Local arguements
      CHARACTER mystring*10
      CHARACTER ib_name*30
      CHARACTER ib_name2*30
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER aop, reason
      INTEGER n
      INTEGER mUnit
      _RL pickupIceberg (NUMBER_OF_BERGS,15)
      INTEGER IBpickupSize
 
      _BEGIN_MASTER(myThid)

      If (useIcebergPickup.AND.niter0.NE.0.) THEN

       pickupIceberg(:,:) = 0. _d 0
       IBpickupSize = NUMBER_OF_BERGS*15*8

C--   READ pickup_iceberg.XXXXXXXXXX       
       WRITE (mystring,'(I10.10)') niter0
       ib_name = 'pickup_iceberg.' // mystring // '.data'
       _BARRIER
       WRITE(msgBuf,'(2A)') 'ICEBERG: READING PICKUP FILE: ', ib_name
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
C-     Assign a free unit number as the I/O channel for this subroutine
       CALL MDSFINDUNIT( mUnit, myThid )
C-     Open file and read in to array pickupIceberg
       OPEN ( unit=mUnit, file=ib_name, form='unformatted', 
     &                    access='direct',recl=IBpickupSize)
       READ ( mUnit, rec=1 ) pickupIceberg
       CLOSE ( mUnit )
       _BARRIER

 
C--  Distribute data to appropriate arrays
       ib_id(:) = INT ( pickupIceberg(:,1) )
       ib_tile(:) = INT ( pickupIceberg(:,2) )
       ib_i(:) = pickupIceberg(:,3)
       ib_j(:) = pickupIceberg(:,4) 
       ib_wth(:) = pickupIceberg(:,5) 
       ib_lth(:) = pickupIceberg(:,6)
       ib_thk(:) = pickupIceberg(:,7) 
       ib_dft(:) = pickupIceberg(:,8) 
       ib_fbd(:) = pickupIceberg(:,9) 
       ib_uVel(:) = pickupIceberg(:,10) 
       ib_vVel(:) = pickupIceberg(:,11)
       ibFlag(:) = INT ( pickupIceberg(:,12) )
       ib_source(:) = pickupIceberg(:,13) 
       ib_scale(:) =  pickupIceberg(:,14)
       calve_slab_counter(:) = pickupIceberg(:,15)

C-     Find total number of icebergs in the system
       n=1
       aop=1
       DO WHILE (aop.EQ.1)
        If (pickupIceberg(n,12).EQ.0) THEN
         ib_Tot = n-1
         aop = 2
        ELSE
         n=n+1
        ENDIF
       ENDDO
 
      ELSE ! if useIcebergPickup = FALSE
       WRITE(msgBuf,'(A)') 'ICEBERG: useIcebergPickup = FALSE'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A)') 'ICEBERG: No iceberg pickup file loaded'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF ! // useIcebergPickup.AND.niter0.NE.0 


C     Write summary of data read from pickup (to STDOUT)
      WRITE(msgBuf,'(A, I7)')
     &      '------ SUMMARY OF ICEBERG DATA READ FROM PICKUP ------'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      DO n=1,ib_Tot
       WRITE(msgBuf,'(2I6, 9F9.2, I6, 3F9.2)')
     &   ib_id(n), ib_tile(n),
     &   ib_i(n), ib_j(n),
     &   ib_wth(n), ib_lth(n),
     &   ib_thk(n), ib_dft(n),ib_fbd(n),
     &   ib_uVel(n), ib_vVel(n),
     &   ibflag(n), ib_source(n),
     &   ib_scale(n), calve_slab_counter(n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDDO

      WRITE(msgBuf,'(A, I10)')
     &       'ICEBERG: Total number of icebergs particles: ', ib_Tot
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )

      WRITE(msgBuf,'(A)') '------ END ICEBERG PICKUP SUMMARY ------'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )



      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

      RETURN
      END
