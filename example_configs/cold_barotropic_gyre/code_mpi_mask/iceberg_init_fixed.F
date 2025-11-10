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
#ifdef ALLOW_USE_MPI
        exchange_list(ib_n,1) = -1
        exchange_list(ib_n,2) = -1
#endif /* ALLOW_USE_MPI */
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

C      Read in the calving locations from file
      CALL IDENTIFY_CALVING_LOCATIONS(myThid)

#ifdef ICEBERG_DEBUG_ON
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

#ifdef ICEBERG_DEBUG_ON
         WRITE(msgBuf,'(2A)')
     &     'ICEBERG: Finished reading: ', schedule_filename
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

#ifdef ICEBERG_DEBUG_ON
      WRITE(msgBuf,'(A,A,A)')
     &      '------ SUMMARY OF ',schedule_filename,' ------'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      DO n=1,SCHEDULE_LEN
       WRITE(msgBuf,'(F10.1, F10.1, F10.1, F10.1)')
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







C----&------------------------------------------------------------------xxxxxxx|
C----&------------------------------------------------------------------xxxxxxx|
CBOP
C !ROUTINE: IDENTIFY_CALVING_LOCATIONS

C !INTERFACE:
      SUBROUTINE IDENTIFY_CALVING_LOCATIONS(myThid)

C     !DESCRIPTION:
C     Locate vector mask points within each subtile

      IMPLICIT NONE
#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "PARAMS.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"

C     !INPUT PARAMETERS:
      INTEGER myThid

C     !LOCAL VARIABLES:     
      INTEGER counter, i, j, bi, bj
      INTEGER, PARAMETER :: debug = 0
      CHARACTER*(MAX_LEN_MBUF) msgBuf

#ifdef ALLOW_ICEBERG_MASK
      _RL calving_mask(1-Olx:sNx+Olx,1-Oly:sNy+Oly, nSx, nSy)
#endif

#ifdef ALLOW_USE_MPI
      _RL CalvingLocations_local(CALVE_LOCS,4)
      _RL CalvingLocations_rcv(CALVE_LOCS,4)
      INTEGER ierror
      INTEGER status(MPI_STATUS_SIZE)
      INTEGER pid
      INTEGER loc_id
      INTEGER calve_id
#else 
      INTEGER, PARAMETER :: mpiMyId = 0
#endif /* ALLOW_USE_MPI */

      INTEGER nn, aop, reason


CEOP
C----&------------------------------------------------------------------xxxxxxx|
CBOC

#ifdef ICEBERG_DEBUG_ON
      WRITE(msgBuf,'(A)') "  BEGIN CALVING_LOCATIONS DEBUG "
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
#endif

C     This block is moved here when we are using the calving schedule
      IF (CalvingFile .EQ. ' ') THEN
        WRITE(msgBuf,'(A)') 
     &   'ICEBERG: No CalvingFile provided... STOPPING'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        STOP
       ENDIF

#ifndef ALLOW_ICEBERG_MASK

       aop=1
       WRITE(msgBuf,'(2A)') 'ICEBERG: Reading ', CalvingFile
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

       OPEN(223, file=CalvingFile, STATUS = 'OLD')
       nn=1 ! Set counter to 1
       aop = 1
       DO WHILE (aop.EQ.1)
        READ(223,'(F6.1, F7.1, F7.1, F7.1)', IOSTAT=reason), 
     &  CalvingLocations (nn,1), ! tag source of iceberg
     &  CalvingLocations (nn,2), ! tile
     &  CalvingLocations (nn,3), ! i-position
     &  CalvingLocations (nn,4)  ! j-position

        IF (reason .EQ. 0) THEN
          CalvingLocations(nn,1) = FLOOR(CalvingLocations(nn,1))
          CalvingLocations(nn,2) = FLOOR(CalvingLocations(nn,2))
          CalvingLocations(nn,3) = FLOOR(CalvingLocations(nn,3))
          CalvingLocations(nn,4) = FLOOR(CalvingLocations(nn,4))
        ENDIF

#ifdef ICEBERG_DEBUG_ON
       WRITE(msgBuf,'(A,F5.1,A,F5.1,A,F5.1,A,F5.1)') 'ICEBERG: ID: ',
     &  CalvingLocations (nn,1), ' tile: ',  
     &  CalvingLocations (nn,2),' row: ', CalvingLocations (nn,3),
     &    ' col: ',CalvingLocations (nn,4)
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
#ifdef ICEBERG_DEBUG_ON
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

#else

C     Initialize local calving locations array to zero
      DO loc_id=1,CALVE_LOCS
       CalvingLocations_local(loc_id,1) = -1.0
       CalvingLocations_local(loc_id,2) = -1.0
       CalvingLocations_local(loc_id,3) = -1.0
       CalvingLocations_local(loc_id,4) = -1.0
      ENDDO

C     Initialize the receive calving locations array to zero
      DO loc_id=1,CALVE_LOCS
       CalvingLocations_rcv(loc_id,1) = -1.0
       CalvingLocations_rcv(loc_id,2) = -1.0
       CalvingLocations_rcv(loc_id,3) = -1.0
       CalvingLocations_rcv(loc_id,4) = -1.0
      ENDDO

C     When using a mask file, identify the local points for this processor
C     that are included in the mask
C     
        CALL READ_REC_XY_RL( CalvingFile,
     &                       calving_mask, 1, 0, myThid )

      calve_id = 0
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
         DO j=1,sNy
           DO i=1,sNx

             if (calving_mask(i,j,bi,bj) .ge. 1.0 ) then

C              Save the index location for this processor in the
C              calving locations array
               calve_id = INT(calving_mask(i,j,bi,bj))
               CalvingLocations_local(calve_id,1) = 
     &                            calving_mask(i,j,bi,bj)
               CalvingLocations_local(calve_id,2) = mpiMyId
               CalvingLocations_local(calve_id,3) = i
               CalvingLocations_local(calve_id,4) = j

        if (ib_model_debug_level .ge. 5) then
        WRITE(msgBuf,'(A,I5,A,I5,A,I5,A,I5,A,I5,A)') 
     &      "calving_mask(",
     &      calve_id,",:) = (",i,',',j,",",bi,",",bj,")"
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &        SQUEEZE_RIGHT, myThid )
        endif

             end if
            ENDDO
          ENDDO
        ENDDO
      ENDDO

C     Fill in the global calving locations with the location one
C     identified on this processor
      DO loc_id=1,CALVE_LOCS
         CalvingLocations(loc_id,1) = 
     &          CalvingLocations_local(loc_id,1)
         CalvingLocations(loc_id,2) = 
     &          CalvingLocations_local(loc_id,2)
         CalvingLocations(loc_id,3) = 
     &          CalvingLocations_local(loc_id,3)
         CalvingLocations(loc_id,4) = 
     &          CalvingLocations_local(loc_id,4)
      ENDDO



#ifdef ALLOW_USE_MPI

C Here I am going to exchange the calving locations so that
C I can sanity check that were reading them in correctly
C Since each processor only needs to knows about its own locations,
C this probably isn't necessary for the model to run correctly

C ---- Here procs>0 send locations to process pid=0,
      
        IF (mpiMyId .gt. 0) then
          if (ib_model_debug_level .ge. 7) then
          WRITE(msgBuf,'(A,I5,A)') 'mpiMyId = ',mpiMyId,
     &     '>0  => Calling MPI_SEND'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
          endif
            call MPI_SEND(CalvingLocations,
     &                     CALVE_LOCS*8, MPI_REAL,0, 0, 
     &                      MPI_COMM_MODEL, ierror)
        ENDIF

C ---- Here proc 0 receives locations from all other procs

        IF (mpiMyId .eq. 0) then
          if (ib_model_debug_level .ge. 7) then
          WRITE(msgBuf,'(A)')  'mpiMyId=0  => Calling MPI_RECV'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
          endif

          DO pid=1, nPx*nPy-1
            call MPI_RECV(CalvingLocations_rcv,
     &        CALVE_LOCS*8, MPI_REAL, pid, 0,
     &        MPI_COMM_MODEL, status, ierror)

            DO loc_id=1,CALVE_LOCS
              IF (CalvingLocations_rcv(loc_id,1) .gt. 0.0) then
                CalvingLocations(loc_id,1) = 
     &          CalvingLocations_rcv(loc_id,1)
                CalvingLocations(loc_id,2) = 
     &          CalvingLocations_rcv(loc_id,2)
                CalvingLocations(loc_id,3) = 
     &          CalvingLocations_rcv(loc_id,3)
                CalvingLocations(loc_id,4) = 
     &          CalvingLocations_rcv(loc_id,4)
              ENDIF
            ENDDO

          ENDDO
         ENDIF

#endif /* ALLOW_USE_MPI */

#ifdef ICEBERG_DEBUG_ON
      WRITE(msgBuf,'(A)') 'ICEBERG: CALVING LOCATIONS SUMMARY'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      DO i=1,CALVE_LOCS
       WRITE(msgBuf,'(A,F5.1,A,F5.1,A,F5.1,A,F5.1)')
     &  'ICEBERG: ID: ',
     &  CalvingLocations (i,1), ' tile: ',  
     &  CalvingLocations (i,2),' row: ', CalvingLocations (i,3),
     &    ' col: ',CalvingLocations (i,4)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDDO
#endif


#ifdef ICEBERG_DEBUG_ON
      WRITE(msgBuf,'(A)') "  END CALVING_LOCATIONS DEBUG "
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
#endif

      END

#endif /* ALLOW_ICEBERG_MASK */

CEOC
C----&------------------------------------------------------------------xxxxxxx|
C----&------------------------------------------------------------------xxxxxxx|

