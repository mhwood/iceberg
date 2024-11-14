c
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_READ_PICKUP( myThid  )

C     ==================================================================
C     MITberg V1.0 READ ICEBERG PICKUP FILE(S)
C     ==================================================================
C
C     o Reads iceberg pickup files:
C       pickup_iceberg.XXXXXXXXXX.data :: binary (NUMBER_OF_BERGSx13) real*8
C       pickup_calving.XXXXXXXXXX.data :: binary (15xCALVE_LOCS) real*8
C 
C     o calving pickup is only read if #define ALLOW_ICEBERG_CALVING
C       is set in code/ICEBERG_OPTIONS.h
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
      _RL IcebergListA_pickup (15,51)
      INTEGER mUnit
      _RL pickupIceberg (NUMBER_OF_BERGS,13)
      INTEGER IBpickupSize

#ifdef ALLOW_ICEBERG_CALVING
      _RL pickupCalve(15,CALVE_LOCS)
      INTEGER CVpickupSize
#endif     
 
      _BEGIN_MASTER(myThid)

      If (useIcebergPickup.AND.niter0.NE.0.) THEN

#ifdef ReadBinaryIcebergPickup
       pickupIceberg(:,:) = 0. _d 0
       IBpickupSize = NUMBER_OF_BERGS*13*8

#ifndef ALLOW_CALVING_SCHEDULE
#ifdef ALLOW_ICEBERG_CALVING
       pickupCalve(:,:)   = 0. _d 0
       CVpickupSize = 15*CALVE_LOCS*8
#endif
#endif

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
       ib_face(:) = INT ( pickupIceberg(:,3) )
       calve_slab_counter(:) = pickupIceberg(:,4)
       ib_i(:) = pickupIceberg(:,5)
       ib_j(:) = pickupIceberg(:,6) 
       ib_wth(:) = pickupIceberg(:,7) 
       ib_thk(:) = pickupIceberg(:,8) 
       ib_uVel(:) = pickupIceberg(:,9) 
       ib_vVel(:) = pickupIceberg(:,10)
       ibFlag(:) = INT ( pickupIceberg(:,11) )
       ib_scale(:) =  pickupIceberg(:,12)
       ib_source(:) = pickupIceberg(:,13) 

#ifndef ALLOW_CALVING_SCHEDULE
#ifdef ALLOW_ICEBERG_CALVING
C--   NOW READ pickup_calving.XXXXXXXXXX
       WRITE (mystring,'(I10.10)') niter0
       ib_name = 'pickup_calving.' // mystring // '.data'
       _BARRIER
       WRITE(msgBuf,'(2A)') 'ICEBERG: READING PICKUP CALVING FILE: ',
     &                       ib_name
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
C-     Assign a free unit number as the I/O channel for this subroutine
       CALL MDSFINDUNIT( mUnit, myThid )
C-     Open file and read in to array pickupIceberg
       OPEN ( unit=mUnit, file=ib_name, form='unformatted',
     &                    access='direct',recl=CVpickupSize)
       READ ( mUnit, rec=1 ) pickupCalve
       CLOSE ( mUnit )
       _BARRIER

       IcebergListA(:,:) = 0. _d 0
       DO n = 1,13
        IcebergListA(n,:) = pickupCalve(n,:)
       ENDDO
       ib_calve_counter(:) = pickupCalve(14,:) 
       CalveStart = pickupCalve(15,1) 

C-    Total ice discharge (from pickup) to add to TotIceVol
       IF (IceInc.GT.0.0) THEN
        IceIncTot = pickupCalve(15,2) 
        TotIceVol = TotIceVol + IceIncTot  
        WRITE(msgBuf,'(A, E20.5)')
     &       'ICEBERG: TotIceVol read from pickup: ', TotIceVol
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, E20.5)')
     &  'ICEBERG: IceIncTot (read from iceberg pickup file): ',IceIncTot
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       ENDIF

C-    Total runoff discharge (from pickup) to add to TotRunoffVol
       IF (RunoffInc.GT.0.0) THEN
        RunoffIncTot = pickupCalve(15,3) 
        TotRunoffVol = TotRunoffVol + RunoffIncTot
        WRITE(msgBuf,'(A, E20.5)')
     &       'ICEBERG: TotRunoffVol read from pickup: ', TotRunoffVol
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, E20.5)')
     &  'ICEBERG: RunoffIncTot (read from pickup file): ',  RunoffIncTot
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       ENDIF
#endif
#endif


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

#else

C    Original pickup files were written out as ascii
C    This routine can be used to read in these older pickup files
C    THis code will eventually be removed!
      WRITE(msgBuf,'(A)') 'ICEBERG MODEL WANTS TO READ OLD 
     &      ASCII PICKUP CODE!!!'
      WRITE(msgBuf,'(A)') 'Model will stop here. Edit code to continue'
      STOP
       WRITE (mystring,'(I10.10)') niter0
       ib_name = 'pickup_iceberg.' // mystring
       _BARRIER
       WRITE(msgBuf,'(2A)') 'ICEBERG: READING ASCII PICKUP FILE: ', 
     &                       ib_name
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
C-     Assign a free unit number as the I/O channel for this subroutine
       CALL MDSFINDUNIT( mUnit, myThid )
       OPEN( mUnit, file=ib_name, STATUS = 'OLD')
       n = 1 ! Set iceberg counter to 1
       aop = 1
       DO WHILE (aop.EQ.1)
        READ ( mUnit,'(I6, I5, I3, F11.0, F8.2,
     &               F8.2, F11.1, F11.1, F8.3, F8.3, I3, F8.0, F6.1)',
     &                                             IOSTAT = reason),
     &    ib_id(n), ib_tile(n), ib_face(n), calve_slab_counter(n),
     &    ib_i(n), ib_j(n), ib_wth(n), ib_thk(n), ib_uVel(n),
     &    ib_vVel(n), ibFlag(n), ib_scale(n), ib_source(n)
        IF (reason > 0)  THEN
         WRITE(msgBuf,'(A)') 'reason>0: pickup does not exist'
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         STOP
        ELSEIF (reason < 0) THEN
         WRITE(msgBuf,'(2A)') 'ICEBERG: FINISHED READING: ', ib_name
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         aop=2
        ELSE
         n=n+1
        ENDIF
       ENDDO
       CLOSE ( mUnit )
       _BARRIER 

       ib_Tot=n-1    ! TOTAL NUMBER OF ICEBERGS
       WRITE(msgBuf,'(A, I7)') 'ICEBERG: TOTAL NUMBER ICEBERGS: ',ib_Tot
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C--   Read additional pickup information from IcebergListA_pickup
       WRITE (mystring,'(I10.10)') niter0
       ib_name2 = 'pickup_IcebergListA.' // mystring
       _BARRIER

       WRITE(msgBuf,'(2A)') 'ICEBERG: READING: ', ib_name2
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       CALL MDSFINDUNIT( mUnit, myThid )
       OPEN( mUnit, file=ib_name2, STATUS = 'OLD')
       DO n = 1,15
        READ ( mUnit, '(51F14.1)'), IcebergListA_pickup (n,:)
       ENDDO
       CLOSE ( mUnit)
       _BARRIER

C      Update IcebergListA
       IcebergListA(:,:) = 0.0
       DO n = 1,13
        IcebergListA(n,1:51) = IcebergListA_pickup(n,:)
       ENDDO

       ib_calve_counter(1:51) = IcebergListA_pickup(14,:)
       CalveStart = IcebergListA_pickup(15,1)
       
       IF (IceInc.GT.0.0) THEN
        IceIncTot = IcebergListA_pickup(15,2) ! Ice discharge to add to TotIceVol
        TotIceVol = TotIceVol + IceIncTot
       ENDIF
#endif

#ifndef ALLOW_CALVING_SCHEDULE
#ifdef ALLOW_ICEBERG_CALVING
       WRITE(msgBuf,'(A)') 'ICEBERG: Have we started calving yet? '
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       WRITE(msgBuf,'(A, F14.3, A, F14.3, A, F14.3)') 
     &   'ICEBERG: CalveStart', CalveStart, 
     &   ' CalveDelay:', CalveDelay, 
     &   ' TotCalvePeriod:', TotCalvePeriod
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       IF (CalveStart.GT.CalveDelay.AND.
     &       CalveStart.LT.CalveDelay+TotCalvePeriod) THEN
               WRITE(msgBuf,'(A)') 'YES calving has begun'
               CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                                   SQUEEZE_RIGHT, myThid )
       ELSE
               WRITE(msgBuf,'(A)') 'No calving at this time'
               CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                                  SQUEEZE_RIGHT, myThid )
       ENDIF
#endif
#endif
 
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
       WRITE(msgBuf,'(3I6, 6F9.2)')
     &   ib_id(n), ib_tile(n), ib_face(n),
     &   ib_i(n), ib_j(n),
     &   ib_wth(n), ib_thk(n),
     &   ib_uVel(n), ib_vVel(n)
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
