c
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_INIT_FIXED( myThid  )

C     ==================================================================
C     MITberg V1.0 ICEBERG_INIT_FIXED
C     ==================================================================
C
C     o Initializes the calving locations and the calving schedule
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
#ifdef ALLOW_EXF
# include "EXF_OPTIONS.h"
# include "EXF_FIELDS.h"
# include "EXF_PARAM.h"
#endif

C     == routine arguments ==
C     myThid - thread number for this instance of the routine.
      INTEGER myThid

C     Local arguements
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER n, i
      CHARACTER(3) locString
      CHARACTER(21) filename
      INTEGER ib_n, k

#ifdef ALLOW_ICEBERG_CALVING
C--   Calving schedule params     
      INTEGER mUnit
      INTEGER scheduleSize
      INTEGER j, nn
      _RL schedule(SCHEDULE_LEN,4)
      INTEGER iUnit, aop, reason
      CHARACTER(38) schedule_filename
#endif

      DO ib_n=1,NUMBER_OF_BERGS
         DO k=1,Nr
            iceberg_MeltProfile(ib_n,k) = 0.0
         ENDDO
        iceberg_SolarMelt(ib_n)=0.0
        iceberg_AtmMelt(ib_n)=0.0
        iceberg_MeltProfileCount(ib_n) = 0
        iceberg_SolarMeltCount(ib_n) = 0
        iceberg_AtmMeltCount(ib_n) = 0
      ENDDO


#ifdef ALLOW_ICEBERG_CALVING
C
C--   Load calving schedule

        scheduleSize = SCHEDULE_LEN*4*8
        
C       Initialize the calving schedule to 0
        DO i=1,CALVE_LOCS
         DO n = 1,SCHEDULE_LEN
          DO j = 1,4
          IcebergCalvingSchedule(n,j,i) = 0.0
          ENDDO
         ENDDO
        ENDDO

C     This block is moved here when we are using the calving schedule
      IF (CalvingFile .EQ. ' ') THEN
        WRITE(msgBuf,'(A)') 
     &   'ICEBERG: No CalvingFile provided... STOPPING'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        STOP
       ENDIF

       aop=1
       WRITE(msgBuf,'(2A)') 'ICEBERG: Reading ', CalvingFile
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

       OPEN(223, file=CalvingFile, STATUS = 'OLD')
       nn=1 ! Set counter to 1
       aop = 1
       DO WHILE (aop.EQ.1)
        READ(223,'(F6.1, F7.1, F7.1)', IOSTAT=reason), 
     &  CalvingLocations (nn,1), ! tag source of iceberg
     &  CalvingLocations (nn,2),
     &  CalvingLocations (nn,3)

#ifdef ICEBERG_DIAG_ON
       WRITE(msgBuf,'(A,F5.1,A,F5.1,A,F5.1)') 'ICEBERG: ID: ',
     &  CalvingLocations (nn,1),' row: ', CalvingLocations (nn,2),
     &    ' col: ',CalvingLocations (nn,3)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

        IF (reason > 0)  THEN
         WRITE(msgBuf,'(2A)') 'reason>0: could not read iceberg
     &                         location file ... something wrong'
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         STOP
        ELSEIF (reason < 0) THEN
#ifdef ICEBERG_DIAG_ON
         WRITE(msgBuf,'(2A)') 
     &     'ICEBERG: Finished reading: ', CalvingFile
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
         aop=2
        ELSE
         nn = nn + 1
         IF (nn.gt.CALVE_LOCS) THEN
         aop=2
        ENDIF
        ENDIF
       ENDDO
       CLOSE (223)

#ifdef ICEBERG_DIAG_ON
C     Now read in the schedules for each location
      WRITE(msgBuf,'(A)') 'ICEBERG: READING Calving Schedules'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
       
       DO i=1,CALVE_LOCS

C      User defines a calving schedule
       WRITE (locString,'(I3.3)') i
       schedule_filename =
     &   'calving_schedules/calving_schedule_' // locString
C-     Assign a free unit number as the I/O channel for this subroutine
       CALL MDSFINDUNIT( mUnit, myThid )
       OPEN ( unit=mUnit, file=schedule_filename, form='unformatted', 
     &                    access='direct',recl=scheduleSize)
       READ ( mUnit, rec=1 ) schedule
       CLOSE ( mUnit )

       IcebergCalvingSchedule(:,1,i) = schedule(:,1)
       IcebergCalvingSchedule(:,2,i) = schedule(:,2)
       IcebergCalvingSchedule(:,3,i) = schedule(:,3)
       IcebergCalvingSchedule(:,4,i) = schedule(:,4)

#ifdef ICEBERG_DIAG_ON
         WRITE(msgBuf,'(2A)')
     &     'ICEBERG: Finished reading: ', schedule_filename
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

#ifdef ICEBERG_DIAG_ON
      WRITE(msgBuf,'(A,A,A)')
     &      '------ SUMMARY OF ',schedule_filename,' ------'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      DO n=1,SCHEDULE_LEN
       WRITE(msgBuf,'(F10.1, F10.1, F10.1, F10.1)'),
     &  IcebergCalvingSchedule(n,1,i),
     &  IcebergCalvingSchedule(n,2,i),
     &  IcebergCalvingSchedule(n,3,i),
     &  IcebergCalvingSchedule(n,4,i)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDDO
#endif

      ENDDO ! Loop through the calving locations

       _BARRIER     

#endif /* ALLOW_ICEBERG_CALVING */
      
      RETURN
      END
