C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_OUTPUT( myTime, myIter, myThid )

C     ==================================================================
C     MITberg V1.0 WRITE ICEBERG OUTPUT
C     ==================================================================
C
C     o This routine write (1) Snapshot of iceberg data at user-defined
C       interval. Data is binary (real8, NUMBER_OF_BERGSx15). (2) time average of
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
      CHARACTER(10) iterStr
      CHARACTER*(MAX_LEN_MBUF) mystring
      CHARACTER(:), allocatable :: ib_name
      CHARACTER*(MAX_LEN_MBUF) suff
      LOGICAL  DIFFERENT_MULTIPLE
      EXTERNAL DIFFERENT_MULTIPLE
      CHARACTER*(MAX_LEN_MBUF * 2) msgBuf
      INTEGER i, j, k, bi, bj
      LOGICAL dumpFiles
      INTEGER mUnit
      _RL IcebergOutput(NUMBER_OF_BERGS,15)
      INTEGER IBOutSize

#ifdef ALLOW_PROFILE_OUTPUT
      _RL profileOutput(NUMBER_OF_BERGS,2)
      character(:), allocatable :: pf_name
      INTEGER PfOutSize
      INTEGER ib_n
#endif

#ifdef WRITE_ICEBERG_DATA
C----------------------------------------------------------------
C    PART I: Write out iceberg locations, velocity, etc
C----------------------------------------------------------------
      IF (useSingleCpuIO) THEN
C   Find out if I'm the master thread (and mpi process 0 IF useSingleCpuIO):
       iAmDoingIO = MASTER_CPU_IO(myThid)

C   Calculate size of IcebergOutput (real*8)
       IBOutSize = 8*NUMBER_OF_BERGS*15

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
         ib_name = trim(ib_iceberg_filename) // '.' // 
     &     trim(mystring) // '.bin'
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
         IcebergOutput(:,3) = ib_i(:)       ! i-loc on global grid
         IcebergOutput(:,4) = ib_j(:)       ! j-loc on global grid
         IcebergOutput(:,5) = ib_wth(:)     ! width (m)
         IcebergOutput(:,6) = ib_lth(:)     ! length (m)
         IcebergOutput(:,7) = ib_thk(:)     ! thickness (m)
         IcebergOutput(:,8) = ib_dft(:)     ! draft (m)
         IcebergOutput(:,9) = ib_fbd(:)     ! freeboard (m)
         IcebergOutput(:,10) = ib_uVel(:)   ! uvel (ms-1)
         IcebergOutput(:,11) = ib_vVel(:)   ! vvel (ms-1)
         IcebergOutput(:,12) = ibFlag(:)    ! flag (0,1,2)
         IcebergOutput(:,13) = ib_source(:) ! calving source ID
         IcebergOutput(:,14) = ib_scale(:)  ! #bergs 1 iceberg equals
         IcebergOutput(:,15) = calve_slab_counter(:) ! calve slab counter

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
C           Meltwater from icebergs
            IcebergMWater_Tave(i,j,1,bi,bj)=
     &            IcebergMWater_Tave(i,j,1,bi,bj)
     &         + (IcebergMeltWater(i,j,bi,bj) 
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
!            CALL TIMEAVE_NORMALIZE(IcebergMWater_Tave,
!      &          Iceberg_TimeAveCounter,
!      &          1,bi,bj,myThid)
!           ENDDO
!          ENDDO

C        Write files
         WRITE(suff,'(I10.10)') myIter
         _BARRIER
         CALL WRITE_FLD_XY_RL('ibFWflx.',suff,    ! meltwater from icebergs
     &        IcebergMWater_Tave,myIter,myThid)
         _BARRIER

! C        Reset averages to zero
!          DO bj = myByLo(myThid), myByHi(myThid)
!           DO bi = myBxLo(myThid), myBxHi(myThid)
!            CALL TIMEAVE_RESET(IcebergMWater_Tave,1,bi,bj,myThid)
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
         ENDDO
        ENDDO
       ENDDO
      ENDDO

C----------------------------------------------------------------
C    PART IV: Output melt profiles
C----------------------------------------------------------------

C MW implemented profiles for freshwater flux in the ICEBERG.h file
C This array is size (num bergs, Nr) 
#ifdef ALLOW_PROFILE_OUTPUT

      IF (.not.useSingleCpuIO) THEN
            WRITE(msgBuf,'(A)')
     &  'SingleCpuIO needed for iceberg_output.F.... STOP'
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
            STOP
      ENDIF

C   Find out if I'm the master thread (and mpi process 0 IF useSingleCpuIO):
          iAmDoingIO = MASTER_CPU_IO(myThid)

C----------------------------------------------------------------
C    Melt Profiles

C   Calculate size of the profile output (real*8)
          PfOutSize = 8*NUMBER_OF_BERGS*Nr

C   Check if its time to write output
            IF ( (myIter .NE. nIter0).and.
     &        (ib_melt_profile_period.ne.0.0) ) THEN
            dumpFiles = .FALSE.
            dumpFiles =
     &    DIFFERENT_MULTIPLE(ib_melt_profile_period,myTime,deltaT)
#ifdef ALLOW_CAL
            IF ( useCAL ) THEN
            CALL CAL_TIME2DUMP( ib_melt_profile_period, deltaT,
     U                        dumpFiles,
     I                        myTime, myIter, myThid )
            ENDIF
#endif
            ENDIF

C     If its time to write out then:
            IF (dumpFiles) THEN
            WRITE(iterStr, '(I10.10)') myIter
            pf_name = trim(ib_melt_profile_filename) // '.' // 
     &       iterStr // '.bin'
            _BARRIER
            WRITE(msgBuf,'(2A)') 'ICEBERG: WRITING ', pf_name
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C     If the period is positive, then divide by the number of counts
C     Otherwise, its a snapshot
C     Note that the iceberg_submerged_melt routine takes care of the sum
          IF ((ib_melt_profile_period.gt.0.0).and.
     &       (iceberg_MeltProfileCount(1).gt.0)) THEN
           DO k=1,Nr
            DO ib_n=1,NUMBER_OF_BERGS
              iceberg_MeltProfile(ib_n,k) = 
     &        iceberg_MeltProfile(ib_n,k) /
     &        iceberg_MeltProfileCount(ib_n)
            ENDDO
           ENDDO
          ENDIF

C-    Assign a free unit number as the I/O channel for this subroutine
            CALL MDSFINDUNIT( mUnit, myThid )
            IF ( iAmDoingIO ) THEN  ! Only Master thread does writing

            OPEN ( unit=mUnit, file=pf_name, status='replace',
     &           form='unformatted', access='direct', recl=PfOutSize)
            WRITE( mUnit, rec=1) (iceberg_MeltProfile)
            CLOSE ( mUnit )
            _BARRIER
            ENDIF

C     After outputting, restart averaging if using it
          IF ((ib_melt_profile_period.gt.0.0)) THEN
           DO k=1,Nr
            DO ib_n=1,NUMBER_OF_BERGS
              iceberg_MeltProfile(ib_n,k) = 0.0
              iceberg_MeltProfileCount(ib_n) = 0
            ENDDO
           ENDDO
          ENDIF

            ENDIF  ! end dump melt profile files

C----------------------------------------------------------------
C    SOLAR MELT PROFILES

C   Calculate size of the profile output (real*8)
      PfOutSize = 8*NUMBER_OF_BERGS

C   Check if its time to write output
            IF (myIter .NE. nIter0) THEN
            dumpFiles = .FALSE.
            dumpFiles =
     &    DIFFERENT_MULTIPLE(ib_solar_melt_period,myTime,deltaT)
#ifdef ALLOW_CAL
            IF ( useCAL ) THEN
            CALL CAL_TIME2DUMP( ib_solar_melt_period, deltaT,
     U                        dumpFiles,
     I                        myTime, myIter, myThid )
            ENDIF
#endif
            ENDIF

C     If its time to write out then:
            IF (dumpFiles) THEN
            WRITE(iterStr, '(I10.10)') myIter
            pf_name = trim(ib_solar_melt_filename) // '.' // 
     &       iterStr // '.bin'
            _BARRIER
            WRITE(msgBuf,'(2A)') 'ICEBERG: WRITING ', pf_name
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C     If the period is positive, then divide by the number of counts
C     Otherwise, its a snapshot
C     Note that the iceberg_surface_melt routine takes care of the sum
          IF ((ib_solar_melt_period.gt.0.0).and.
     &       (iceberg_SolarMeltCount(1).gt.0)) THEN
            DO ib_n=1,NUMBER_OF_BERGS
                  iceberg_SolarMelt(ib_n) = 
     &             iceberg_SolarMelt(ib_n)/iceberg_SolarMeltCount(ib_n)
            ENDDO
          ENDIF

C-    Assign a free unit number as the I/O channel for this subroutine
            CALL MDSFINDUNIT( mUnit, myThid )
            IF ( iAmDoingIO ) THEN  ! Only Master thread does writing

            OPEN ( unit=mUnit, file=pf_name, status='replace',
     &           form='unformatted', access='direct', recl=PfOutSize)
            WRITE( mUnit, rec=1) (iceberg_SolarMelt)
            CLOSE ( mUnit )
            _BARRIER
            ENDIF

C     After outputting, restart averaging if using it
          IF ((ib_solar_melt_period.gt.0.0)) THEN
            DO ib_n=1,NUMBER_OF_BERGS
              iceberg_SolarMelt(ib_n) = 0.0
              iceberg_SolarMeltCount(ib_n) = 0
           ENDDO
          ENDIF

      ENDIF ! dump solar files

C----------------------------------------------------------------
C    ATMOSPHERIC MELT VALUES

C   Calculate size of the profile output (real*8)
      PfOutSize = 8*NUMBER_OF_BERGS

C   Check if its time to write output
            IF (myIter .NE. nIter0) THEN
            dumpFiles = .FALSE.
            dumpFiles =
     &    DIFFERENT_MULTIPLE(ib_atm_melt_period,myTime,deltaT)
#ifdef ALLOW_CAL
            IF ( useCAL ) THEN
            CALL CAL_TIME2DUMP( ib_atm_melt_period, deltaT,
     U                        dumpFiles,
     I                        myTime, myIter, myThid )
            ENDIF
#endif
            ENDIF

C     If its time to write out then:
            IF (dumpFiles) THEN
            WRITE(iterStr, '(I10.10)') myIter
            pf_name =  trim(ib_atm_melt_filename) // '.' // 
     &       iterStr // '.bin'
            _BARRIER
            WRITE(msgBuf,'(2A)') 'ICEBERG: WRITING ', pf_name
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C     If the period is positive, compute the average
C     Otherwise, its a snapshot
C     Note that the iceberg_surface_melt routine takes care of the sum
          IF ((ib_atm_melt_period.gt.0.0).and.
     &       (iceberg_AtmMeltCount(1).gt.0)) THEN
            DO ib_n=1,NUMBER_OF_BERGS
                  iceberg_AtmMelt(ib_n) = 
     &             iceberg_AtmMelt(ib_n)/iceberg_AtmMeltCount(ib_n)
            ENDDO
          ENDIF

C-    Assign a free unit number as the I/O channel for this subroutine
            CALL MDSFINDUNIT( mUnit, myThid )
            IF ( iAmDoingIO ) THEN  ! Only Master thread does writing

            OPEN ( unit=mUnit, file=pf_name, status='replace',
     &           form='unformatted', access='direct', recl=PfOutSize)
            WRITE( mUnit, rec=1) (iceberg_AtmMelt)
            CLOSE ( mUnit )
            _BARRIER
            ENDIF

C     After outputting, restart averaging if using it
          IF ((ib_atm_melt_period.gt.0.0)) THEN
            DO ib_n=1,NUMBER_OF_BERGS
              iceberg_AtmMelt(ib_n) = 0.0
              iceberg_AtmMeltCount(ib_n) = 0
           ENDDO
          ENDIF

            ENDIF  ! end dump atm melt Files

C----------------------------------------------------------------
C    WAVE MELT VALUES

C   Calculate size of the profile output (real*8)
      PfOutSize = 8*NUMBER_OF_BERGS

C   Check if its time to write output
            IF (myIter .NE. nIter0) THEN
            dumpFiles = .FALSE.
            dumpFiles =
     &    DIFFERENT_MULTIPLE(ib_wave_melt_period,myTime,deltaT)
#ifdef ALLOW_CAL
            IF ( useCAL ) THEN
            CALL CAL_TIME2DUMP( ib_wave_melt_period, deltaT,
     U                        dumpFiles,
     I                        myTime, myIter, myThid )
            ENDIF
#endif
            ENDIF

C     If its time to write out then:
            IF (dumpFiles) THEN
            WRITE(iterStr, '(I10.10)') myIter
            pf_name = trim(ib_wave_melt_filename) // '.' // 
     &       iterStr // '.bin'
            _BARRIER
            WRITE(msgBuf,'(2A)') 'ICEBERG: WRITING ', pf_name
            CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C     If the period is positive, compute the average
C     Otherwise, its a snapshot
C     Note that the iceberg_surface_melt routine takes care of the sum

          IF ((ib_wave_melt_period.gt.0.0).and.
     &       (iceberg_WaveMeltCount(1).gt.0)) THEN
            DO ib_n=1,NUMBER_OF_BERGS
                  iceberg_WaveMelt(ib_n) = 
     &             iceberg_WaveMelt(ib_n)/iceberg_WaveMeltCount(ib_n)
            ENDDO
          ENDIF

C-    Assign a free unit number as the I/O channel for this subroutine
            CALL MDSFINDUNIT( mUnit, myThid )
            IF ( iAmDoingIO ) THEN  ! Only Master thread does writing

            OPEN ( unit=mUnit, file=pf_name, status='replace',
     &           form='unformatted', access='direct', recl=PfOutSize)
            WRITE( mUnit, rec=1) (iceberg_WaveMelt)
            CLOSE ( mUnit )
            _BARRIER
            ENDIF

C     After outputting, restart averaging if using it
          IF ((ib_wave_melt_period.gt.0.0)) THEN
            DO ib_n=1,NUMBER_OF_BERGS
              iceberg_WaveMelt(ib_n) = 0.0
              iceberg_WaveMeltCount(ib_n) = 0
           ENDDO
          ENDIF

            ENDIF  ! end dump wave melt Files

#endif /* ALLOW_PROFILE_OUTPUT */

      RETURN
      END


! C----&------------------------------------------------------------------xxxxxxx|
! C----&------------------------------------------------------------------xxxxxxx|

!        SUBROUTINE CREATE_IB_FILENAME_VEC(filename)
! c       Creating filenames for all binary files.
!       IMPLICIT NONE
! #include "SIZE.h"
! #include "EEPARAMS.h"
! #include "EESUPPORT.h"
! #include "DIAGNOSTICS_VEC.h"
! #include "PARAMS.h"

! C     !INPUT PARAMETERS:
!        integer vec_id, myIter
!        character*50 filename
!        character*8 fldNm
!        character*2 dir


! C     !LOCAL VARIABLES:
!        integer i
!        character*10 str_iter
!        integer len, count, mask_count

! C----&------------------------------------------------------------------xxxxxxx|
! C----&------------------------------------------------------------------xxxxxxx|


! C       Counting number of valid characters to trim trailing whitespaces
!         count = 0
!         DO i=1, len(ib_melt_profile_filename)
!           IF (ib_melt_profile_filename(i:i) .ne. ' ') then
!             count = count + 1
!           ENDIF
!         ENDDO

!         mask_count = 0
!         DO i=1, len(vec_fnames(vec_id))
!           IF (vec_fnames(vec_id)(i:i) .ne. ' ') then
!             mask_count = mask_count + 1
!           ENDIF
!         ENDDO

!          IF (vec_iters_per_file(vec_id).eq.0) then
!           write(filename, "(5A)") vec_fnames(vec_id)(1:mask_count-4), 
!      &                            "_",fldNm(1:count),".bin"
!          ELSE
!           write(str_iter, "(I10.10)") vec_time_levels(vec_id,2)
!            write(filename, "(7A)") vec_fnames(vec_id)(1:mask_count-4), 
!      &                   "_",fldNm(1:count),".",str_iter,".bin"
!          ENDIF

!        END
! C----&------------------------------------------------------------------xxxxxxx|
! C----&------------------------------------------------------------------xxxxxxx|
