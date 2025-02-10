#include "ICEBERG_OPTIONS.h"

CBOP
C Note: MW copied and edited this code from the iceplume package
C     !ROUTINE: ICEBERG_SUBMERGED_MELT
C     !INTERFACE:
      SUBROUTINE ICEBERG_SUBMERGED_MELT(myTime, myIter, myThid )

C     !DESCRIPTION: \bv
C     *==========================================================*
C     | SUBROUTINE ICEBERG_CALC
C     | o Calculate melt rates and tendencies due to melting of
C     |   iceberg an iceberg
C     *==========================================================*

C     | Outward (pos) = leaving the ocean, inward (neg) = entering ocean.
C     | Freshwater (kg/m2/s): inward (negative) freshwater flux implies 
C     | glacier melting due to outward (positive) heat flux (W/m^2)

C     \ev
C     !USES:
      IMPLICIT NONE
C     === Global variables ===
#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "PARAMS.h"
#include "GRID.h"
#include "DYNVARS.h"
#include "FFIELDS.h"

#ifdef ALLOW_ICEBERG
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"
#endif 

#ifdef ALLOW_PTRACERS
#include "PTRACERS_SIZE.h"
#include "PTRACERS_PARAMS.h"
#include "PTRACERS_START.h"
#include "PTRACERS_FIELDS.h"
#endif

C     !INPUT/OUTPUT PARAMETERS:
C     == Routine arguments ==
      _RL myTime
      INTEGER myIter
      INTEGER myThid
      INTEGER ib_n
      _RL ib_iT
      _RL ib_jT
      CHARACTER*(MAX_LEN_MBUF) msgBuf

#ifdef ALLOW_ICEBERG
#ifdef ALLOW_ICEBERG_SUBMERGED_MELT

C     !LOCAL VARIABLES:
C     == Local variables ==
C     I,J,K,bi,bj  :: loop indices
C     msgBuf       :: Informational/error message buffer
C     sProf, tProf, uProf, vProf :: salt, pot. temperature and
C                            uVel and vVel profiles
C     ptrProf  :: ambient ptracer profile
C     eps5     :: for thermodynamics (see pkg icefront)
C     negSum, posSum :: sum of negative and positive contributions to the plume volume
C     posNegRatio    :: ratio of the above
C     wVelCell       :: vertical velocity component at cell centres
C     hVelCell_tangential :: horizontal velocity component at cell centres
C     meanVel :: ice tangental velocity
C     rho_shelfice :: 917. kg/m3
C     secInday :: number of seconds in a day 
C     GlacierFront_is_NorthSouth :: 1 for the glacier oriented NorthSouth
C                                :: 0 for EastWest, default is -9999

      INTEGER bi, bj
      INTEGER J, K, I

      _RL eps5
      _RL negSum, posSum, posNegRatio
      _RL wVelCell, meanVel
      _RL mBasal, mMeanW, mMeanL
      _RL mWidth(Nr), mLength(Nr)
      _RL lengthCheck
      _RL totalFWflux
      _RL sw_temp, sw_ptmp
      _RL secInday
      external SW_TEMP
      external SW_PTMP

      PARAMETER(secInday=86400.0D0)

      _RL Fwflux3D            (1:sNx,1:sNy,Nr)
      _RL HeatFlux3D          (1:sNx,1:sNy,Nr)

      _RL iceDepth
      INTEGER icedepthK

      _RL ib_vol1, ib_vol0
      _RL weeks_stab
      INTEGER meltFlag
      
      _RL ICEBERGlatentHeat
      _RL ICEBERGHeatCapacity_Cp
      PARAMETER(ICEBERGlatentHeat       =  334.0 _d 3)
      PARAMETER(ICEBERGHeatCapacity_Cp  = 2000.0 _d 0)

      INTEGER proc_id, ierr, num_procs

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_MELT_DYE
      _RL ptrProf(1:sNx,1:sNy,Nr)
      INTEGER iTracer
      PARAMETER(iTracer  = 1)
#endif /* ALLOW_MELT_DYE */
#endif /* ALLOW_PTRACERS */

#ifdef ICEBERG_DIAG_ON
      IF (ib_debug_level.ge.1) THEN
      WRITE(msgBuf,'(A)') 'ICEBERG SUBMERGED MELT CALLED'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

      eps5 = mass2rUnit/HeatCapacity_Cp

      call MPI_COMM_RANK (MPI_COMM_WORLD, proc_id, ierr)

C -----------------------------------------
C Enter into loops
      DO bj=myByLo(myThid),myByHi(myThid)
       DO bi=myBxLo(myThid),myBxHi(myThid)

C Initialize tendencies for melting
        DO k=1,Nr
         DO j=1,sNy
          DO i=1,sNx
C Initialize tendencies for melting
           ICEBERGBG_TendT(i,j,k,bi,bj)=0. _d 0
           ICEBERGBG_TendS(i,j,k,bi,bj)=0. _d 0
C Initialize the 3D fluxes of heat and fw
           Fwflux3D(i,j,k)=0. _d 0
           Heatflux3D(i,j,k)=0. _d 0
          ENDDO
         ENDDO
C Initialize the vertical profiles
         mWidth(k)   = 0.D0
         mLength(k)   = 0.D0
#ifdef ALLOW_PTRACERS
#ifdef ALLOW_MELT_DYE
C       Fill in the ptracer profile before the big iceberg loop
C       because additional quantities will be added for each berg
C       each time through the big loop
         ptrProf(i,j,k) = pTracer(i,j,k,bi,bj,iTracer)
#endif /* ALLOW_MELT_DYE */
#endif /* ALLOW_PTRACERS */
        ENDDO

CMW: In iceplume, this loops through all i's and j's
C    With the icebergs, we know their locations so we can 
C    just loop through the list of locations
      IF (ib_Tot.GT.0) THEN                          ! if icebergs in system
       DO ib_n=1,ib_Tot
        
          IF (proc_id.EQ.ib_Tile(ib_n)) THEN           ! Only execute if the berh is on this tile

      IF ((ibFlag(ib_n).NE.3).and.(ib_thk(ib_n).gt.0)) THEN ! Check iceberg is not melted
        I = INT(ib_i(ib_n))
        J = INT(ib_j(ib_n))

C Vertical extent of domain
          iceDepth = ib_dft(ib_n)
          iceDepthK = 0

CMW: Using the value in the cell for now
C    Should update to include the interpolation schemes
           DO K = 1,Nr
          prProf(ib_n,k) = ABS(rC(k))*rhoConst*gravity*1.0E-6 ! Pressure (dbar)
          sProf(ib_n,K)  = salt(I,J,K,bi,bj)         ! Salinity
          ptProf(ib_n,K) = theta(I,J,K,bi,bj)        ! Potential Temperature
          tProf(ib_n,k)  = 
     &    SW_TEMP(sProf(ib_n,k),ptProf(ib_n,k),prProf(ib_n,k),0. _d 0) ! Temperature

C           Velocities
            vProf(ib_n,k) = ABS(vVel(I,J,K,bi,bj))          ! v velocity
            uProf(ib_n,K) = ABS(uVel(I,J,K,bi,bj))          ! u Velocity
            wProf(ib_n,K) = ABS(wVel(I,J,K,bi,bj))          ! w Velocity

            IF (ib_dft(ib_n).gt.ABS(rF(k+1))) THEN
                  delta_z(ib_n,k) = drF(K)
            ELSEIF (ib_dft(ib_n).lt.ABS(rF(k))) THEN
                  delta_z(ib_n,k) = 0.D0
                  IF (iceDepthK.eq.0) iceDepthK=K
            ELSE
                  delta_z(ib_n,k) = ib_dft(ib_n)-ABS(rF(k))
                  iceDepthK = K
            ENDIF

            mProf(ib_n,k)   = 0.D0
            FwFlux(ib_n,k)  = 0.D0
            
           ENDDO

C------------------------------------
C       Sanity check the deltaz is consistent
      lengthCheck = 0.0
      DO k=1,Nr
            lengthCheck = lengthCheck+delta_z(ib_n,k)
      ENDDO
      WRITE(msgBuf,'(A,F20.10,A,F20.10)') 
     &     ' Delta z sanity check:',lengthCheck,' == ',
     &     ib_dft(ib_n)
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )

C If we still cannot find the bottom cell

          IF ( iceDepthK .EQ. 0 ) THEN
             WRITE(msgBuf,'(2A)')
     &       'Unable to identify index of cell',
     &       'at iceberg location.',
     &       'This may be because this is a partial cell.'
             CALL PRINT_ERROR( msgBuf, myThid )
             STOP 'ABNORMAL END: S/R ICEBERG_CALC IV'
          ENDIF

C-------- Calculate melt rates ----------------------------

           DO K = 1,Nr

C Check to see if we are deeper than the bottom of the iceberg
            IF ( K .GT. iceDepthK ) THEN
C If so, there is no melting             
             mProf(ib_n,k)   = 0.D0
             FwFlux(ib_n,k)  = 0.D0
            ELSE !k le iceDepthK
           
CMW: In iceplume, we compute the additions to FW and Heat fluxes based
C    on one side of the glacier. Here, we do it on all 4 sides of the
C    iceberg using the geometry of the iceberg               

C Compute the melt rates on all sides
C Considering the iceberg to just be in one cell

C Front and back
             IF ( K .LT. Nr ) THEN
              wVelCell = (ABS(wVel(I,J,K,bi,bj))
     &                 +ABS(wVel(I,J,K+1,bi,bj))) / twoRL
             ELSE
              wVelCell = ABS(wVel(I,J,K,bi,bj)) / twoRL
             ENDIF

              meanVel = ((wVelCell**twoRL)
     &                  +(ABS(uVel(I,J,K,bi,bj))**twoRL))**HalfRL

             CALL ICEBERG_MELTRATE(
     I            tProf(ib_n,k),sProf(ib_n,k),meanVel,rC(k),
     O            mWidth(k) )

          IF (isnan(mWidth(k))) THEN
           WRITE(msgBuf,'(A, F11.1, F11.1, F11.1, F11.1, F11.1)'), 
     &     'NaN from ICEBERG_MELRRATE ... STOPPING!', 
     &      tProf(ib_n,k),sProf(ib_n,k),meanVel,rC(k), mWidth(k) 
           CALL PRINT_ERROR( msgBuf , myThid)
           STOP
          ENDIF

#ifdef ICEBERG_DIAG_ON
      IF (ib_debug_level.ge.5) THEN
      WRITE(msgBuf,'(A,I2,A,F20.10,A)') 
     &     '       Zonal melt rate at k = ',k,': ',
     &     mWidth(k),' m/s'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

C Left and right
              meanVel = ((wVelCell**twoRL)
     &                  +(ABS(vVel(I,J,K,bi,bj))**twoRL))**HalfRL

             CALL ICEBERG_MELTRATE(
     I            tProf(ib_n,k),sProf(ib_n,k),meanVel,rC(k),
     O            mLength(k) )

           IF (isnan(mLength(k))) THEN
           WRITE(msgBuf,'(A, F11.1, F11.1, F11.1, F11.1, F11.1)'),
     &     'NaN from ICEBERG_MELRRATE ... STOPPING!',
     &      tProf(ib_n,k),sProf(ib_n,k),meanVel,rC(k), mLength(k)
           CALL PRINT_ERROR( msgBuf , myThid)
           STOP
          ENDIF

#ifdef ICEBERG_DIAG_ON
      IF (ib_debug_level.ge.5) THEN
      WRITE(msgBuf,'(A,I2,A,F20.10,A)') 
     &     '       Meridional melt rate at k = ',k,': ',
     &     mLength(k),' m/s'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      ENDIF
#endif


      IF (ib_melt_profile_period.ne.0.0) THEN
            IF (ib_melt_profile_period.gt.0.0) THEN
C     If the period is positive, compute the average
C     Note: division done on output
      iceberg_MeltProfile(ib_n,k) = iceberg_MeltProfile(ib_n,k)
     &                    + 0.5*(mLength(k) + mWidth(k))
            iceberg_MeltProfileCount(ib_n) = 
     &       iceberg_MeltProfileCount(ib_n)+1
            ELSE
C     Otherwise, its a snapshot
      iceberg_MeltProfile(ib_n,k) = 0.5*(mLength(k) + mWidth(k))
            ENDIF
      ENDIF


C And bottom
      IF (k.eq.iceDepthK) THEN
            meanVel = ((ABS(uVel(I,J,K,bi,bj))**twoRL)
     &                 +(ABS(vVel(I,J,K,bi,bj))**twoRL))**HalfRL
            CALL ICEBERG_MELTRATE(
     I            tProf(ib_n,k),sProf(ib_n,k),meanVel,rC(k),
     O            mBasal )

         IF (isnan(mBasal)) THEN
           WRITE(msgBuf,'(A, F11.1, F11.1, F11.1, F11.1, F11.1)'),
     &     'NaN from ICEBERG_MELRRATE ... STOPPING!',
     &      tProf(ib_n,k),sProf(ib_n,k),meanVel,rC(k), mBasal
           CALL PRINT_ERROR( msgBuf , myThid)
           STOP
          ENDIF
      

#ifdef ICEBERG_DIAG_ON
      IF (ib_debug_level.ge.5) THEN
      WRITE(msgBuf,'(A,I2,A,F20.10,A)') 
     &     '       Basal melt rate at k = ',k,': ',
     &     mBasal,' m/s'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

      ENDIF ! if at the bottom of the berg to compute basal melt

            ENDIF ! are we above the bottom of the iceberg?
  
           ENDDO !the big k-loop

C--------------------------------------------------------------
C-- Volume Change
C   Now, use the melt rates to change the volume of the berg
C   Keep track of the freshwater fluxes with each melting

C-- Compute the volume before melting
      ib_vol0 = ib_thk(ib_n) * ib_lth(ib_n) * ib_wth(ib_n)

C--  Compute the mean melt front and back of the berg
C--  which will be used for resizing
      mMeanW = 0.0
      totalFWflux = 0.0
      DO K = 1,Nr
         mMeanW = mMeanW + mWidth(k)*delta_z(ib_n, K)*ib_wth(ib_n)
C-- Add melted water to the total freshwater flux
C     m3/s = m/s * m * m * (kg/m3 / kg/m3)
      FwFlux(ib_n,k) = FwFlux(ib_n,k) 
C     left and right sides
     &   + 2*mWidth(k)
     &   * ib_wth(ib_n)*delta_z(ib_n,k)
     &     *ib_rho/rho_w
      ENDDO
C the melt is distributed over the whole thickness, so
C we have thickness on the bottom, not just draft
      mMeanW = mMeanW / (ib_thk(ib_n)*ib_wth(ib_n))

C-- Recalculate size of iceberg (front and back) due to melting
C   This is done before width so we don't double count
      ib_lth(ib_n) =  ib_lth(ib_n)
     &                -2*mMeanW*deltaT  

C--  Compute the mean melt on the berg
C--  which will be used for resizing
      mMeanL = 0.0
      IF (ib_lth(ib_n).gt.0) THEN
      DO K = 1,Nr
         mMeanL = mMeanL + mLength(k)*delta_z(ib_n, K)*ib_lth(ib_n)
C-- Add melted water to the total freshwater flux
C     m3/s = m/s * m * m * (kg/m3 / kg/m3)
      FwFlux(ib_n,k) = FwFlux(ib_n,k) 
C     front and back sides
     &   + 2*mLength(k)
     &   * ib_lth(ib_n)*delta_z(ib_n,k)
     &   * ib_rho/rho_w
      ENDDO
      mMeanL = mMeanL / (ib_thk(ib_n)*ib_lth(ib_n))
      ENDIF

C-- Recalculate size of iceberg (left and right) due to melting
      ib_wth(ib_n) =  ib_wth(ib_n)
     &                -2*mMeanL*deltaT

C-- Add melted basal water to the total freshwater flux     
      FwFlux(ib_n,iceDepthK) = FwFlux(ib_n,iceDepthK) 
     &   + mBasal
     &   * ib_lth(ib_n)*ib_wth(ib_n)
     &   * ib_rho/rho_w

      IF (ib_lth(ib_n).gt.0) THEN
C-   Resize from the bottom
      ib_thk(ib_n) =  ib_thk(ib_n)
     &                -mBasal*deltaT
      ENDIF

C-    Compute the total freshwater flux for a sanity check below
      DO K = 1,Nr
         totalFWflux = totalFWflux + FwFlux(ib_n,k)*deltaT
      ENDDO


#ifdef ALLOW_PTRACERS
#ifdef ALLOW_MELT_DYE
C-- When using melt dye, compute modifications to the 
C   ptracer prof that results from the freshwater flux
C   at the location of this berg
      DO K = 1,Nr
       IF (hFacC(I,J,K,bi,bj).gt.0) THEN
       ptrProf(I,J,K) = ptrProf(I,J,K) + FwFlux(ib_n,k)*deltaT/
     & (drF(k)*rA(I,J,bi,bj)*hFacC(I,J,K,bi,bj))
       ENDIF
      ENDDO
#endif /* ALLOW_MELT_DYE */
#endif /* ALLOW_PTRACERS */

#ifdef ICEBERG_DIAG_ON
      IF (ib_debug_level.ge.2) THEN
      WRITE(msgBuf,'(A,I5,A,F10.5,A,F10.5,A,F10.5,A)') 
     &     'At iter=',myIter,
     &     ', before melting icebergs shape = (',ib_wth(ib_n),
     &     ',',ib_lth(ib_n),',',ib_thk(ib_n),')'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A,F20.5,A)') 
     &     '          and volume = ',ib_vol0,' m3'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      ENDIF
#endif

C--   calculate volume of iceberg (after melt)
      ib_vol1 = ib_thk(ib_n) * ib_lth(ib_n) * ib_wth(ib_n)  ! Updated iceberg volume
      ib_dft = (ib_rho/rho_w) * ib_thk(ib_n)              ! Updated iceberg draft (m)
      ib_fbd = ib_thk(ib_n) - ib_dft                      ! Update freeboard (m)

C     Start flagging melted icebergs by setting meltFlag eq 1 if melted
       IF (ib_vol1.LT.0.) meltFlag = 1  ! negative dimensions = iceberg melted
       IF (ib_lth(ib_n).LE.min_size .OR. ib_wth(ib_n).LE.min_size
     &      .OR. ib_thk(ib_n).LE.min_size) meltFlag = 1

#ifdef ALLOW_ICEBERG_TO_ROLL
      IF (meltFlag.NE.1) THEN
       CALL ICEBERG_ROLL (ib_n,myIter, myThid)
       IF (ib_lth(ib_n).LE.min_size .OR. ib_wth(ib_n).LE.min_size
     &    .OR. ib_thk(ib_n).LE.min_size) meltFlag = 1
      ENDIF
#endif 

#ifdef ICEBERG_DIAG_ON
      IF (ib_debug_level.ge.3) THEN
      WRITE(msgBuf,'(A,I5,A,F10.5,A,F10.5,A,F10.5,A)') 
     &     'At iter=',myIter,
     &     ', after melting icebergs shape = (',ib_wth(ib_n),
     &     ',',ib_lth(ib_n),',',ib_thk(ib_n),')'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A,F20.5,A)') 
     &     '          and volume = ',ib_vol1,' m3'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
C-- the total FW flux should be the same as the change in volume
C-- after accounting for the differences in ice and water density
      WRITE(msgBuf,'(A,F20.5,A,F20.5,A,F20.5)') 
     &     ' Sanity check volume change = ',ib_vol0-ib_vol1,
     &     ' == ',totalFWflux*rho_w/ib_rho
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                     SQUEEZE_RIGHT, myThid )
      ENDIF
#endif



! C--------------------------------------------------------------
! C-- Tendencies - this part needs to be checked
! C   Now, using the volumes of freshwater flux, compute
! C   tendencies of freshwater and heat

! C     mass2rUnit :: units conversion factor (surface forcing),
! C                :: from mass per unit area [kg/m2] to vertical r-coordinate unit.
! C                :: z-coord: = 1/rhoConst ( [kg/m2] / rho = [m] )

! C          FwFlux is m3/sec
! C          We need kg/m3/sec
! C          Multiply by rho to get kg/s = (m3/s)*(kg/m3)
! C          Then, divide by grid cell area to get tendency in the cell?
! C     Sign convention: inward (negative) fresh water flux implies glacier
! C     melting due to outward (positive) heat flux.

!       DO K = 1,Nr 
! C           kg/m2/s
!             Fwflux3D(I,J,k) = -FwFlux(ib_n,k)*rhoConst/rA(i,j,bi,bj)

! C           W/m2
!             heatflux(ib_n,k) = FwFlux(ib_n,k)*ICEBERGlatentHeat
!             HeatFlux3D(I,J,k) = HeatFlux(ib_n,k)

! #ifdef ALLOW_ICEBERG_MELTWATER
! C     Only apply meltwater to tendencies if this effect is turned on

! C     Compute tendencies (as for pkg/icefront)
! C     J/s/m2 * degC.m3/J = degC/s.m ; 
!          ICEBERGBG_TendT(I,J,K,bi,bj) =   
!      &        ICEBERGBG_TendT(I,J,K,bi,bj) - HeatFlux3D(I,J,K)*eps5

! C     kg/s/m2 m3/kg g/kg = g/kg/s.m
!          ICEBERGBG_TendS(I,J,K,bi,bj) =   
!      &   ICEBERGBG_TendS(I,J,K,bi,bj)
!      &        - FWFlux3D(I,J,K)*mass2rUnit * sProf(ib_n,k)
! #endif /* ALLOW_ICEBERG_MELTWATER */

!       ENDDO

          ENDIF ! Check iceberg is not melted
          ENDIF ! Execute specific tiles
         ENDDO ! loop through icebergs in system
      ENDIF ! if icebergs in system


C-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ 

#ifdef ALLOW_PTRACERS
#ifdef ALLOW_MELT_DYE
      DO k=1,Nr
      DO j=1,sNy
      DO i=1,sNx
C       Now that were done with everything, write the
C       dye fields back to the main pTracer field
        pTracer(i,j,k,bi,bj,iTracer) = ptrProf(i,j,k)
      ENDDO
      ENDDO
      ENDDO
#endif /* ALLOW_MELT_DYE */
#endif /* ALLOW_PTRACERS */

C     end bi/bj-loops
       ENDDO
      ENDDO

#endif /* ALLOW_ICEBERG_SUBMERGED_MELT */
#endif /* ALLOW_ICEBERG */

      RETURN
      END



