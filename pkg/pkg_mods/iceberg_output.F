C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_OUTPUT( myTime, myIter, myThid )

C     ==================================================================
C     MITberg V1.0 WRITE ICEBERG OUTPUT
C     ==================================================================
C
C     o This routine write (1) Snapshot of iceberg data at user-defined
C       interval. Data is binary (real8, 15000x12). (2) time average of
C       freshwater release to ocean from icebergs (Units: kg.m^-2.s^-1)
C
C     ==================================================================

      IMPLICIT NONE

C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "ICEBERG.h"
#include "ICEBERG_TAVE.h"
#include "ICEBERG_PARAMS.h"

C     == Routine arguments ==
C     myTime :: my time in simulation ( s )
C     myIter :: my Iteration number
C     myThid :: my Thread Id number
      _RL     myTime
      INTEGER myIter
      INTEGER myThid
      LOGICAL iAmDoingIO
      LOGICAL MASTER_CPU_IO

C     == Local variables ==
C     IcebergOutput :: store all iceberg data for writing out
      CHARACTER(10) mystring
      CHARACTER(31) ib_name
      CHARACTER*(MAX_LEN_MBUF) suff
      LOGICAL  DIFFERENT_MULTIPLE
      EXTERNAL DIFFERENT_MULTIPLE
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER i, j, k, bi, bj
      LOGICAL dumpFiles
      INTEGER mUnit
      _RL IcebergOutput(15000,12)
      INTEGER IBOutSize
#ifdef ALLOW_CALVING_OUTPUT
      _RL CalvingOutput(15000,2)
      CHARACTER(10) mystring2
      CHARACTER(17) cv_name
      INTEGER CVOutSize
      INTEGER nnc
#endif

#ifdef WRITE_ICEBERG_DATA
C----------------------------------------------------------------
C    PART I: Write out iceberg locations, velcity, etc
C----------------------------------------------------------------
      IF (useSingleCpuIO) THEN
C   Find out if I'm the master thread (and mpi process 0 IF useSingleCpuIO):
       iAmDoingIO = MASTER_CPU_IO(myThid)

C   Calculate size of IcebergOutput (real*8)
       IBOutSize = 8*15000*12

C   Clear output array
       IcebergOutput(:,:) = 0. _d 0

C   Check if its time to write output
       IF ( myIter .NE. nIter0 ) THEN
        dumpFiles = .FALSE.
        dumpFiles =
     &       DIFFERENT_MULTIPLE(ib_write_freq,myTime,deltaT)
#ifdef ALLOW_CAL
        IF ( useCAL ) THEN
          CALL CAL_TIME2DUMP( ib_write_freq, deltaT,
     U                        dumpFiles,
     I                        myTime, myIter, myThid )
        ENDIF
#endif
       ENDIF

C     If its time to write out then:
       IF (dumpFiles) THEN
        IF (ib_Tot.GT.0) THEN
         WRITE (mystring,'(I10.10)') myIter
         ib_name = 'diags/iceberg/iceberg' // mystring
         _BARRIER
         WRITE(msgBuf,'(2A)') 'ICEBERG: WRITING ', ib_name
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         WRITE(msgBuf,'(A,I10)')'ICEBERG: Total number of particles: ', 
     &    ib_Tot
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
C     Gather iceberg data in to one array for writing
         IcebergOutput(:,1) = ib_id(:)      ! id
         IcebergOutput(:,2) = ib_tile(:)    ! tile 
         IcebergOutput(:,3) = ib_face(:)    ! face (cube sphere)
         IcebergOutput(:,4) = ib_i(:)       ! i-loc on global grid
         IcebergOutput(:,5) = ib_j(:)       ! j-loc on global grid
         IcebergOutput(:,6) = ib_wth(:)     ! width (m)
         IcebergOutput(:,7) = ib_thk(:)     ! thickness (m)
         IcebergOutput(:,8) = ib_uVel(:)    ! uvel (ms-1)
         IcebergOutput(:,9) = ib_vVel(:)    ! vvel (ms-1)
         IcebergOutput(:,10) = ibFlag(:)    ! FLAG (0,1,2)
         IcebergOutput(:,11) = ib_scale(:)  ! #bergs 1 iceberg equals
         IcebergOutput(:,12) = ib_source(:) ! cavlving source ID

C-    Assign a free unit number as the I/O channel for this subroutine
         CALL MDSFINDUNIT( mUnit, myThid )
         IF ( iAmDoingIO ) THEN  ! Only Master thread does writing
          OPEN ( unit=mUnit, file=ib_name, status='replace',
     &           form='unformatted', access='direct',recl=IBOutSize)
          WRITE( mUnit, rec=1) (IcebergOutput)
          CLOSE ( mUnit )
          _BARRIER
         ENDIF

        ENDIF  ! End ib_n > 0
       ENDIF  ! end dump Files

      ELSE 
C      ifnot useSingleCpuIO then stop
       WRITE(msgBuf,'(A)')
     &  'SingleCpuIO needed for iceberg_output.F.... STOP'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       STOP
C      Another option is needed at some point
      ENDIF

#endif

C----------------------------------------------------------------
C    PART II: Iceberg time averaging for freshwater release
C----------------------------------------------------------------
#ifdef ALLOW_DIAGNOSTICS
      IF ( useDiagnostics ) THEN
       
       IF ( IcebergTaveFreq .GT. 0 ) THEN
C--    Time-accumulations
        DO bj = myByLo(myThid), myByHi(myThid)
         DO bi = myBxLo(myThid), myBxHi(myThid)
          DO j=1,sNy
           DO i=1,sNx
C           Meltwater runoff from icebergs
            IcebergMWater_Tave(i,j,1,bi,bj)=
     &            IcebergMWater_Tave(i,j,1,bi,bj)
     &         + (IcebergMeltWater(i,j,bi,bj) 
     &         *  deltaT)
C           Meltwater runoff at calving margin
            IcebergLRunoff_Tave(i,j,1,bi,bj)=
     &            IcebergLRunoff_Tave(i,j,1,bi,bj)
     &         + (IcebergLiqRunoff(i,j,bi,bj)
     &         *  deltaT)
           ENDDO
          ENDDO

C         Increment counter
          Iceberg_TimeAveCounter(1,bi,bj) = 
     &                    Iceberg_TimeAveCounter(1,bi,bj)
     &                  + deltaT
         ENDDO
        ENDDO

C       Dump files and restart average computation if needed
        dumpFiles = .FALSE.
        IF ( myIter .NE. nIter0 ) THEN
         dumpFiles =
     &        DIFFERENT_MULTIPLE(IcebergTaveFreq,myTime,deltaT)

#ifdef ALLOW_CAL
         IF ( useCAL ) THEN
          CALL CAL_TIME2DUMP( IcebergTaveFreq, deltaT,
     U                        dumpFiles,
     I                        myTime, myIter, myThid )
         ENDIF
#endif
        ENDIF

        IF (dumpFiles) THEN  ! If time to dump files:
C        Normalize by integrated time
!          DO bj = myByLo(myThid), myByHi(myThid)
!           DO bi = myBxLo(myThid), myBxHi(myThid)
! #ifdef USE_OLD2008
!            CALL TIMEAVE_NORMALIZ(IcebergMWater_Tave,
!      &          Iceberg_TimeAveCounter,
!      &          1,bi,bj,myThid)
!            CALL TIMEAVE_NORMALIZ(IcebergLRunoff_Tave,
!      &          Iceberg_TimeAveCounter,
!      &          1,bi,bj,myThid)
! #else
!            CALL TIMEAVE_NORMALIZE(IcebergMWater_Tave,
!      &          Iceberg_TimeAveCounter,
!      &          1,bi,bj,myThid)
!            CALL TIMEAVE_NORMALIZE(IcebergLRunoff_Tave,
!      &          Iceberg_TimeAveCounter,
!      &          1,bi,bj,myThid)
! #endif
!           ENDDO
!          ENDDO

C        Write files
         WRITE(suff,'(I10.10)') myIter
         _BARRIER
         CALL WRITE_FLD_XY_RL('ibFWflx.',suff,    ! meltwater from icebergs
     &        IcebergMWater_Tave,myIter,myThid)
         IF (TotRunoffVol.GT.0.) THEN
          CALL WRITE_FLD_XY_RL('ibFWrun.',suff,   ! runoff at calving margins
     &        IcebergLRunoff_Tave,myIter,myThid)
         ENDIF
         _BARRIER

! C        Reset averages to zero
!          DO bj = myByLo(myThid), myByHi(myThid)
!           DO bi = myBxLo(myThid), myBxHi(myThid)
!            CALL TIMEAVE_RESET(IcebergMWater_Tave,1,bi,bj,myThid)
!            CALL TIMEAVE_RESET(IcebergLRunoff_Tave,1,bi,bj,myThid)
!            Iceberg_TimeAveCounter(1,bi,bj) = 0. _d 0
!           ENDDO
!          ENDDO

        ENDIF ! /* dumpFiles */

       ENDIF ! /* IcebergTaveFreq .GT. 0 */
      ENDIF ! /* useDiagnostics */
#endif /* ALLOW_DIAGNOSTICS */

C     Clear values to avoid time accumulation
      DO bj = myByLo(myThid), myByHi(myThid)
       DO bi = myBxLo(myThid), myBxHi(myThid)
        DO j=1-OLy,sNy+OLy
         DO i=1-OLx,sNx+OLx
          IcebergMeltWater(i,j,bi,bj) =  0. _d 0
          IcebergLiqRunoff(i,j,bi,bj) =  0. _d 0
         ENDDO
        ENDDO
       ENDDO
      ENDDO

C----------------------------------------------------------------
C    PART III: Output calving list
C----------------------------------------------------------------

C MW implemented a variable called CalvingList
C This list is size (15000,2) where the 15000 refers to all icebergs
C which were calved and the 2 columns are the iceberg Id,
C and the iteration number. The idea is to be able to track who
C calved and when
#ifdef ALLOW_CALVING_OUTPUT

      IF (useSingleCpuIO) THEN
C   Find out if I'm the master thread (and mpi process 0 IF useSingleCpuIO):
          iAmDoingIO = MASTER_CPU_IO(myThid)

C   Calculate size of IcebergOutput (real*8)
            CVOutSize = 8*15000*5

C   Check if its time to write output
            IF ( myIter .NE. nIter0 ) THEN
            dumpFiles = .FALSE.
            dumpFiles =
     &       DIFFERENT_MULTIPLE(ib_write_freq,myTime,deltaT)
#ifdef ALLOW_CAL
            IF ( useCAL ) THEN
            CALL CAL_TIME2DUMP( ib_write_freq, deltaT,
     U                        dumpFiles,
     I                        myTime, myIter, myThid )
            ENDIF
#endif
            ENDIF

C     If its time to write out then:
            IF (dumpFiles) THEN
            WRITE (mystring2,'(I10.10)') myIter
            cv_name = 'CALVED.' // mystring2
            _BARRIER
            WRITE(msgBuf,'(2A)') 'ICEBERG: WRITING ', cv_name
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         WRITE(msgBuf,'(A,I10)')'ICEBERG: Total number of calved: ', 
     &    cv_Tot
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
! C     Gather calving data in to one array for writing
            ! CalvingOutput(:,1) = CalvingList(:,1) ! id
            ! CalvingOutput(:,2) = CalvingList(:,2) ! iteration number
     
C ---------------------------------------------------------------------
C MWPRINT
      WRITE(msgBuf,'(A)') '-----------------------' 
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)')
     &      'MWPRINT: CalvingList'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      DO nnc=1,cv_Tot
      WRITE(msgBuf,'(F8.1, F8.1)')
     &   CalvingList (nnc, 1), CalvingList (nnc, 2)
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDDO

C-    Assign a free unit number as the I/O channel for this subroutine
            CALL MDSFINDUNIT( mUnit, myThid )
            IF ( iAmDoingIO ) THEN  ! Only Master thread does writing
            OPEN ( unit=mUnit, file=cv_name, status='replace',
     &           form='unformatted', access='direct', recl=CVOutSize)
            WRITE( mUnit, rec=1) (CalvingList)
            CLOSE ( mUnit )
            _BARRIER
            ENDIF

C     Reset the calving list
      DO nnc=1,cv_Tot
            CalvingList(nnc,1) = 0
            CalvingList(nnc,2) = 0
            CalvingList(nnc,3) = 0
            CalvingList(nnc,4) = 0
            CalvingList(nnc,5) = 0
      ENDDO

C     Reset the calving counter
      cv_Tot = 0

            ENDIF  ! end dump Files


      ELSE 
C      ifnot useSingleCpuIO then stop
            WRITE(msgBuf,'(A)')
     &  'SingleCpuIO needed for iceberg_output.F.... STOP'
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
            STOP
C      Another option is needed at some point
      ENDIF

#endif /* ALLOW_CALVING_OUTPUT */

      RETURN
      END
