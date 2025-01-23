C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_WRITE_PICKUP ( 
     I                                myTime, myIter, myThid )

C     ==================================================================
C     MITberg V1.0 ICEBERG_WRITE_PICKUP
C     ==================================================================
C
C     o Write iceberg pickup files. Write time is sychronized 
C       to the main model restart frequency (pChkptFreq)
C
C      =================================================================

      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "GRID.h"
#include "FFIELDS.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"
#ifdef ALLOW_EXF
# include "EXF_OPTIONS.h"
# include "EXF_FIELDS.h"
# include "EXF_PARAM.h"
#endif


C     == routine arguments ==
C     myIter    :: Iteration number
C     myThid    :: Thread number for this instance of the routine.
C     ib_write_freq   Frequency (s) to write iceberg data (set in data.iceberg)
C     pChkptFreq      Frequency (s) to write pickup (same as main model)
      INTEGER myThid
      INTEGER myIter
      _RL myTime
      LOGICAL iAmDoingIO
      LOGICAL MASTER_CPU_IO

C     == local arguments ==
      CHARACTER(10) mystring
      CHARACTER(30) ib_name2
      CHARACTER(30) ib_name3
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      LOGICAL  DIFFERENT_MULTIPLE
      EXTERNAL DIFFERENT_MULTIPLE
      LOGICAL dumpFiles
      INTEGER n, nn 
      INTEGER mUnit
      _RL pickupIceberg (NUMBER_OF_BERGS,15)
      INTEGER IBpickupSize

      IF (useSingleCpuIO) THEN

C   Find out if I'm the master thread (and mpi process 0 IF useSingleCpuIO):
       iAmDoingIO = MASTER_CPU_IO(myThid)
      
C    Calculate size of pickups (real*8)
       IBpickupSize = NUMBER_OF_BERGS*15*8

C    Check if its time to write pickup file
      IF ( myIter .NE. nIter0 ) THEN
       dumpFiles = .FALSE.
       dumpFiles =
     &     DIFFERENT_MULTIPLE(pChkptFreq,myTime,deltaT)
#ifdef ALLOW_CAL
       IF ( useCAL ) THEN
        CALL CAL_TIME2DUMP( pChkptFreq, deltaT,
     U                        dumpFiles,
     I                        myTime, myIter, myThid )
       ENDIF
#endif
      ENDIF

      IF (dumpFiles) THEN
C    Clear icebergPickup and calvePickup
       pickupIceberg(:,:) = 0. _d 0 

C    Gather together data for icebergPickup
       pickupIceberg(:,1) = ib_id(:)
       pickupIceberg(:,2) = ib_tile(:)
       pickupIceberg(:,3) = ib_i(:)
       pickupIceberg(:,4) = ib_j(:)
       pickupIceberg(:,5) = ib_wth(:)
       pickupIceberg(:,6) = ib_lth(:)
       pickupIceberg(:,7) = ib_thk(:)
       pickupIceberg(:,8) = ib_dft(:)
       pickupIceberg(:,9) = ib_fbd(:)
       pickupIceberg(:,10) = ib_uVel(:)
       pickupIceberg(:,11) = ib_vVel(:)
       pickupIceberg(:,12) = ibFlag(:)
       pickupIceberg(:,13) = ib_source(:)
       pickupIceberg(:,14) = ib_scale(:)
       pickupIceberg(:,15) = calve_slab_counter(:) 

C--  First write pickup_iceberg : 
       IF (ib_Tot.GT.0) THEN
        WRITE (mystring,'(I10.10)') myIter
        ib_name2 = 'pickup_iceberg.' // mystring // '.data'
        _BARRIER
        WRITE(msgBuf,'(2A)') 'ICEBERG: WRITING PICKUP FILE ', ib_name2
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, I6)') 
     &       'ICEBERG: Total number of iceberg particles: ',
     &       ib_Tot   
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C-     Assign a free unit number as the I/O channel for this subroutine
        CALL MDSFINDUNIT( mUnit, myThid )

        IF ( iAmDoingIO ) THEN  ! Only Master thread does writing
         OPEN ( unit=mUnit, file=ib_name2, status='replace',
     &          form='unformatted', access='direct',recl=IBpickupSize)
         WRITE( mUnit, rec=1 ) (pickupIceberg)
         CLOSE ( mUnit )
         _BARRIER
        ENDIF

       ENDIF  ! End ib_n > 0
  
      ENDIF  ! /* dumpFiles (pickup) */

C------------------------------------------------------------
C------------------------------------------------------------
      ELSE  ! End of   (useSingleCpuIO) 
C      Another option required at some point, but if not SingleIO then stop
       WRITE(msgBuf,'(2A)') 
     &  'ICEBERG: SingleCpuIO needed for iceberg_write_pickup.F',
     &  '.... STOPPING!!'      
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       STOP
      ENDIF

      RETURN
      END

