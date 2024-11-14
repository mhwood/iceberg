c
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_THERM ( ib_iT,ib_jT, ib_n, bi, bj, 
     &                            myIter, myThid)

C     ==================================================================
C     MITberg v1.0 ICEBERG THERMODYNAMIC SCHEME
C     ==================================================================
C
C     o Melting is calcuated by summing the different melt
C       terms influencing an iceberg (UNITS ARE M.S^-1)
C
C       Msolar     = surface solar radiation melt -> reduce thk
C       Mforced_w  = forced convection (in water) -> reduce lth, wth, thk
C       Mforced_a  = forced convection (in air) -> reduce lth, wth, thk
C       Mlat       = lateral melt (buoy. vert. convection) -> reduce lth & wth
C       Mwave      = melting due to wave erosion -> reduce lth & wth
C       Mslab      = deterioration due to calving from overhanging slabs
C
C     o Iceberg deterioration can be modeled using either the Canadian 
C       Ice Services (CIS) mechanics scheme or Bigg et al. 1997
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
#ifdef ALLOW_SEAICE
c#ifndef USE_OLD2008
#include "SEAICE_SIZE.h"
#include "SEAICE.h"
#include "SEAICE_PARAMS.h"
c#endif
#endif
#ifdef ALLOW_EXF
# include "EXF_OPTIONS.h"
# include "EXF_FIELDS.h"
# include "EXF_PARAM.h"
#endif

C     Routine arguements
C     myTime - Simulation time
C     myIter - Simulation timestep number
C     myThid - Thread no. that called this routine.
      INTEGER myIter, myThid
      _RL myTime
      INTEGER i, j, bi, bj
      INTEGER ib_n
      _RL ib_iT
      _RL ib_jT
      INTEGER k


C     Local arguements
C     number of surface interface layer
      INTEGER kSurface
      _RL LiqRunoff

C    tmp
      _RL ib_wth_org
      _RL ib_lth_org
      _RL ib_thk_org
      _RL weeks_stab
      _RL IceFracLiqLoc

      INTEGER i1, j1
      _RL ib_vol0
      _RL ib_vol1
      _RL ib_mass
      _RL ib_lth
      _RL ib_Mforced_w
      _RL ib_Mforced_a
      _RL ib_Mlat
      _RL ib_Mwave
      _RL ib_Msolar
      _RL ib_Mslab
      _RL IceMelt
      _RL ib_precip
      INTEGER meltFlag

      _RL ib_dsw
      _RL ib_dlw
      _RL ib_tot_dsr
      _RL ib_Ta
      _RL TairInc
      _RL ib_albedo
      _RL ib_fbd
      _RL fbd_ratio
      _RL r_fbd_ratio
      _RL thk_wth_ratio

      _RL Gamma_Ice
      _RL ib_Re
      _RL ib_Pr
      _RL ib_Nu
      _RL kv_w 
      _RL kv_a
      _RL k_w
      _RL k_a
      _RL kf_w
      _RL kf_a
      _RL Tf
      _RL Tfp
      _RL ib_dT 
      _RL hflx_forced_a
      _RL hflx_forced_w

      _RL Rslab
      _RL Lslab
      _RL Vslab
      _RL Ss
      _RL calve_slab_freq
      _RL Wh
      _RL Wp
      _RL Rr

      _RL ib_MTb
      _RL ib_MTv
      _RL ib_dft

      _RL ib_Vel
#ifdef ALLOW_ICEBERG_MULTILEVEL
      _RL uvel_w(Nr)
      _RL vvel_w(Nr)
      _RL uvel_w_mean
      _RL vvel_w_mean
      _RL thkR
      INTEGER ib_nlvl
#else
      _RL uvel_w
      _RL vvel_w
#endif
      _RL Vel_w
      _RL uvel_a
      _RL vvel_a
      _RL Vel_a

      _RL ib_Tw
      _RL ib_Tw_tmp
      _RL ib_Sal

      _RL ib_SIarea

      _RL varOUT

C     Grounding
      _RL ib_R_low
      _RL cumDepth(Nr+1)

C     Misc
      CHARACTER*(MAX_LEN_MBUF) msgBuf

#ifdef ALLOW_DIAGNOSTICS
      _RL DIAGarray     (1:sNx,1:sNy)
      LOGICAL  DIAGNOSTICS_IS_ON
      EXTERNAL DIAGNOSTICS_IS_ON
#endif

C     i1           :: Integer of ib_iT
C     j1           :: Integer of ib_jT
c     ib_Mforced_w :: forced melt (below waterline) (m s-1)
c     ib_Mforced_a :: forced melt (above waterline) (m s-1)
c     ib_Mlat      :: Buoyant/Lateral melt rate (m s-1)
c     ib_Mwave     :: Wave erosion(m s-1) 
C     ib_Msolar    :: melt from solar radiaiton (m s-1) 
C     ib_Mslab     :: melt from calving of overhanging slab (m3)
C     meltFlag     :: flag melted icebergs for removal, local version of ibFlag
C                     0 = okay, 1 = melted 
C
C     ib_Re        :: Reynolds no. [ratio of inertial forces to viscous forces]
C                                  (dimensionless)
C     ib_Pr        :: Prandtl no. [ratio kinematic visc. to thermal diff.]
C                                  (dimensionless)
C     ib_Nu        :: Nusselt no. [ratio convective to conductive heat transfer]
C                                  (dimensionless)
C
C     kv_w         :: Kinematic viscosity water (1.83x10^-6 m2.s-1 at 0 degC)
C     kv_a         :: Kinematic viscosity air   (1.46x10^-5 m2.s-1 at 10 degC)
C     kf_w         :: thermal conductivity water (0.563 J.s-1.m-1.K-1 at 0 degC)
C     kf_a         :: thermal conductivity air (0.0249 J.s-1.m-1.K-1 at 10 degC)
C     k_w          :: thermal diffusivity water (1.37x10^-7 m2.s-1 at 0 degC)
C     k_a          :: thermal diffusivity air (2.16x10^-5 m2.s-1 at 10 degC)

C     hflx_forced_a:: forced convection heat flux (J.s-1)
C     hflx_forced_w:: forced convection heat flux (J.s-1)

C     Tf           :: Freezing point of seawater (deg. C)
C     Tfp          :: Freezing point temperature around iceberg (deg. C)
C
C     ib_MTb       :: Total basal melt volume (m3)
C     ib_MTv       :: Total lateral melt volume (m3)
C
C     ib_dft       :: iceberg draft (m)
C
C     ib_dsw       :: Local downward shortwave radiation at iceberg (W m-2)
C     ib_dlw       :: Local downward longwave radiation at iceberg (W m-2)
C     ib_tot_dsr   :: Local total downward solar radiation (W m-2)
C     ib_Ta        :: Local air temperature at iceberg (degree C)
C     TairInc      :: Local increase in air temperature at iceberg (deg. C
C                     since start of simulation)
C     ib_albedo    :: local iceberg albedo (changes with Tair) (no units)

C     Gamma_Ice    :: Latent heat of melting/fusion of ice (3.33 x 10^5 J/kg)
C     ib_fbd       :: iceberg freeboard (m)
C     fbd_ratio    :: ratio of subaerial to subaqueous portion (ib_rho/rho_w)
C     r_fbd_ratio  :: reciprical of fbd_ratio (dimensionless)
C     thk_wth_ratio:: ib_thk/ib_wth (dimensionless) 
C
C     Rslab        :: thickness of overhanging slab (m)
C     Lslab        :: critical length overhanging slab breaks (m)
C     Vslab        :: volume of calved ice slab (m3)
C     Ss           :: Sea state (using Beaufort scale [1-12])
C     Wh           :: wave height (m) 
C     Wp           :: Wave period (seconds)
C     Rr           :: roughness height of ice surface (m)
C     calve_slab_freq :: frequency at which overhanging slab (s)
C                        
C     ib_Vel       :: Iceberg absolute velocity (ms-1)
C     uvel_w    :: Local U water velocity at iceberg (ms-1)
C     vvel_w    :: Local V water velocity at iceberg (ms-1)
C     Vel_w     :: Local absolute water velicity at iceberg (ms-1)
c     uvel_a    :: Local wind U vel at iceberg (m s-1)
c     vvel_a    :: Local wind V vel at iceberg (m s-1)
c     Vel_a     :: absolute local wind velocity at iceberg (m s-1)
C
C     ib_Tw        :: Local water temperature at iceberg (deg. C)
C     ib_Tw_tmp    :: temporary storage of Tw at depth (deg. C)
C     ib_Sal       :: Local salinity at iceberg
C     ib_precip    :: Local precipitation at iceberg (ms^-1)
C     ib_vol0      :: iceberg volume prior to melting (m3)
C     ib_vol1      :: iceberg volume after melt (m3)
C
C     IceMelt      :: Meltwater volume released to ocean from each iceberg (m3.s-1)
C                     This is added to IcebergMeltWater
C     IcebergMeltWater :: Water released from ALL icebergs to the ocean 
C                     at each timestep. Units: kg.m^-2.s^-1.
C     IcebergLiqRunoff :: Freshwater runoff to ocean at calving margins (global array)
C                         Units: kg.m^-2.s^-1
C     LiqRunoff        :: Runoff at individual calving margin (units: m^3.s^-1)
C     thkR     Vertical thickness of each layer of water iceberg penetrates
C     ib_nlvl  Number of vertical levels of water column iceberg penetrates
C     ib_R_low Depth of ocean (m) at iceberg location
C
C   ***************************************************************************

#ifdef USE_BIGG_MELT      
      WRITE(msgBuf,'(A)') 'Bigg et al. melt scheme incomplete'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      STOP
#endif

#ifdef ICEBERG_DIAG_ON
      WRITE(msgBuf,'(A)') 'ICEBERG THERMODYNAMICS CALLED'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

      IF (TairIncRate.GT.0.) THEN
C     Calculate Air Temperature offset at icebergs
C     Use this to artificially increase air temperature
C     at each iceberg at each timestep. The rate of increase is based on 
C     the value of TwaterIncRate set in data.iceberg which is the 
C     air temperature increase (in deg. C) per year. This is
C     then scaled to seconds and multiplied by the timestep and 
C     iteration number (myIter)

      TairInc = (TairIncRate/(60.*60.*24.*365.25)) * 
     &           deltaT * myIter 
#ifdef ICEBERG_DIAG_ON
      WRITE(msgBuf,'(A,E20.6, I7)') 'ICEBERG: TairInc: ', TairInc,
     & myIter
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
      ENDIF


C     Calculate cumulative depth
      cumDepth(1)= 0.
      DO k = 1,Nr
       cumDepth(k+1) = delR(k) + cumDepth(k)
      ENDDO


      if ( buoyancyRelation .eq. 'OCEANICP' ) then
       kSurface        = Nr
      else
       kSurface        = 1
      endif

      ib_Mforced_w = 0. _d 0
      ib_Mforced_a = 0. _d 0
      ib_Mlat   = 0. _d 0
      ib_Mwave  = 0. _d 0
      IceMelt = 0. _d 0
      Vslab = 0. _d 0     
      meltFlag = 0

      Gamma_Ice = 3.33E5     ! latent heat melting ice   (J.kg-1)
      kv_w = 1.83E-6         ! kinematic viscosity water (m2.s-1)
      kv_a = 1.46E-5         ! kinematic viscosity air   (m2.s-1)
      kf_w = 0.563           ! thermal conductivity water(J.s-1.m-1.K-1)
      kf_a = 0.0249          ! thermal conductivity air  (J.s-1.m-1.K-1)
      k_w = 1.37E-7          ! thermal diffusivity water (m2.s-1)
      k_a = 2.16E-5          ! thermal diffusivity air (m2.s-1)


      ib_lth = ib_wth(ib_n) * ibLthWthRatio ! ~1:1.62 width:length ratio 
      ib_dft = (ib_rho/rho_w)*ib_thk(ib_n)  ! Iceberg draft (m)
      ib_fbd = ib_thk(ib_n) - ib_dft        ! Iceberg freeboard (m)
      ib_vol0 = ib_thk(ib_n) * ib_wth(ib_n) * ib_lth   ! Volume of iceberg (prior to any melt)

      IF (ibFlag(ib_n).EQ.-1) THEN
C     If iceberg has just calved then adjust its thickness to stop
C     it exceeding water depth, and then repartition width and length 
C     to conserve volume. 5 meters of clearance with sea floor is prescribed
       CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, R_low, varOUT,
     &                             0, bi, bj, myThid )
       ib_R_low = ABS(varOUT)                                  ! Water depth (m)

       IF (ib_dft.GT.ib_R_low) THEN
#ifdef ALLOW_SCOURING
C       iceberg keels can penetrate in to sediment up to 10m
C       and iceberg will still drift
C        ib_dft = ib_R_low + 9.5       
#endif
        ib_dft = ib_R_low - 5.          ! update draft (5 m clearance)
        IF (ib_dft.LE.0.) THEN
         WRITE(msgBuf,'(A,F11.1,F11.1,F11.1,F11.1,I5,F11.1,I5)'),
     &   'Iceberg released over land... STOPPING!',
     &    ib_dft, ib_R_low,ib_iT,ib_jT,
     &    ib_i(ib_n),ib_j(ib_n),ib_id(ib_n)
         STOP
        ENDIF
        ib_thk(ib_n) = (ib_dft*rho_w)/ib_rho
        ib_fbd = ib_thk(ib_n) - ib_dft        ! Iceberg freeboard (m)
        ib_wth(ib_n) = (ib_vol0/(ibLthWthRatio*ib_thk(ib_n)))**(1./2.) ! Conserve volume
        ib_lth = ib_wth(ib_n) * ibLthWthRatio
        ib_vol0 = ib_thk(ib_n) * ib_wth(ib_n) * ib_lth
       ENDIF
      ENDIF

      fbd_ratio = ib_rho/rho_w   ! ratio of subaerial to subaqueous
      r_fbd_ratio = 1./fbd_ratio ! ratio of subaqueous to subaerial
       
C     Store original dimensions
      ib_lth_org = ib_lth
      ib_wth_org = ib_wth(ib_n)
      ib_thk_org = ib_thk(ib_n)

      ib_Vel = sqrt (ib_uVel(ib_n) * ib_uVel(ib_n)   ! abs. iceberg velocity
     &             + ib_vVel(ib_n) * ib_vVel(ib_n))  ! (m s-1)

C--  Interpolate variables to iceberg location
C
C     ocean velocity (ms-1)

#ifdef ALLOW_ICEBERG_MULTILEVEL

      uvel_w_mean = 0.
      vvel_w_mean = 0.
      ib_Tw = 0.

C     Calculate number of levels iceberg penetrates.
      DO k = 1,Nr-1
       IF (ib_dft.GT.cumDepth(k)
     &      .AND.ib_dft.LT.cumDepth(k+1)) ib_nlvl = k
      ENDDO

C     Calculate mean ocean velocity and water temperature at iceberg
      DO k = 1,ib_nlvl

       CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, k, uVel, varOUT,
     &                             1, bi, bj, myThid )
       uvel_w(k) = varOUT
       CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, k, vVel, varOUT,
     &                             2, bi, bj, myThid )
       vvel_w(k) = varOUT

       CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, k, theta, varOUT,
     &                             0, bi, bj, myThid )
       ib_Tw_tmp = varOUT
       ib_Tw_tmp= ib_Tw_tmp + ibTwaterScale  

       IF (k.NE.ib_nlvl) THEN
        thkR = delR(k)
       ELSE
        thkR = ib_dft - cumDepth(k)          ! Thickness of ice in bottom cell
        IF (thkR.LT.0.) THEN
          WRITE(msgBuf,'(A,F11.1)'),
     &     'thkR < 0 in thermo', thkR
          CALL PRINT_ERROR( msgBuf , myThid)
          STOP 
        ENDIF
       ENDIF

        uvel_w_mean = uvel_w_mean + (uvel_w(k) * thkR)
        vvel_w_mean = vvel_w_mean + (vvel_w(k) * thkR)
        ib_Tw = ib_Tw + (ib_Tw_tmp * thkR)
      ENDDO

      uvel_w_mean = uvel_w_mean / ib_dft      ! average uvel_w
      vvel_w_mean = vvel_w_mean / ib_dft      ! average vvel_w
      Vel_w = sqrt (uvel_w_mean * uvel_w_mean     ! abs. velocity of iceberg
     &               + vvel_w_mean * vvel_w_mean) 
                                                 

      ib_Tw = ib_Tw / ib_dft                        ! Tw averaged over
                                                    ! iceberg draft

#else
C     Single level (surface) iceberg advection

      CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, 1, uVel, varOUT,
     &                             1, bi, bj, myThid )
      uvel_w = varOUT

      CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, 1, vVel, varOUT,
     &                             2, bi, bj, myThid )
      vvel_w = varOUT

      Vel_w = sqrt (uvel_w * uvel_w
     &               + vvel_w * vvel_w)  

C     SST 
      CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, 1, Theta, varOUT,
     &                             0, bi, bj, myThid )
      ib_Tw = varOUT
      ib_Tw = ib_Tw + ibTwaterScale

#endif /* end of multi-level/single-level */

C     Wind 
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, uWind, varOUT,
     &                             1, bi, bj, myThid )
      uvel_a = varOUT
      uvel_a = uvel_a * ibuWindScale

      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, vWind, varOUT,
     &                             2, bi, bj, myThid )
      vvel_a = varOUT
      vvel_a = vvel_a * ibvWindScale

      Vel_a = sqrt (uvel_a * uvel_a
     &               + vvel_a * vvel_a)

C     Salinity
      CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, 1, Salt, varOUT,
     &                             0, bi, bj, myThid )
      ib_Sal = varOUT

#ifdef ALLOW_SEAICE
      IF (useSEAICE) THEN
C      Sea ice area
       CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, AREA, varOUT,
     &                                 0, bi, bj, myThid )
       ib_SIarea = varOUT
      ELSE
      ib_SIarea = 0. _d 0
      ENDIF
#else
      ib_SIarea = 0. _d 0
#endif

C     Air temperature
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, atemp, varOUT,
     &                                 0, bi, bj, myThid )
      ib_Ta = varOUT - 273.15  ! convert from Kelvin to Celsius
      ib_Ta = ib_Ta + ibTairScale + TairInc

C     Precipitation
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, PRECIP, varOUT,
     &                                 0, bi, bj, myThid )
      ib_precip = varOUT       ! ms-1

#ifdef ALLOW_DOWNWARD_RADIATION
C     Downward shortwave
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, swdown, varOUT,
     &                                 0, bi, bj, myThid )
      ib_dsw = varOUT

C     Downward longwave
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, lwdown, varOUT,
     &                                 0, bi, bj, myThid )
      ib_dlw = varOUT
    
      ib_tot_dsr = ib_dsw + ib_dlw  ! total downward solar radiation
#else
      WRITE(msgBuf,'(A)'),
     & 'Downard solar radiation must be supplied in data.exf'
         CALL PRINT_ERROR( msgBuf , myThid)
      STOP
#endif

C
C-- ICEBERG MELT EQUATIONS
C   ----------------------
C
C
C--  1) SUBAERIAL (above waterline) MELTING
C    --------------------------------------
C
C    SOLAR RADIATION
C
C     Calculate rate of surface melting (m s-1)
C     Iceberg albedo is assumed to be same as wet seaice ~0.7. 
C     This melting reduces the iceberg thickness.   

#ifdef ALLOW_SEAICE
      IF (useSEAICE) THEN
       ib_albedo = SEAICE_wetIceAlb    
      ELSE 
       ib_albedo = 0.7
      ENDIF
#else
      ib_albedo = 0.7
#endif

      IF (ib_Ta.GT.0.) THEN 
       ib_Msolar = (ib_tot_dsr/(ib_rho * Gamma_Ice) 
     &             * (1-ib_albedo))    ! Units: ms-1 
     &             * deltaT            ! m per timestep
      ELSE 
       ib_Msolar = 0.
      ENDIF
      IF (ib_Msolar.LT.0.) ib_Msolar = 0. _d 0


C
C    FORCED CONVECTION MELT/SENSIBLE HEAT MELTING (above water)
C     Melting due to forced convection is generated by turbulence
C     created by the relative motion of the air passing the iceberg.
C     Melt is windspeed and temperature dependant.
C
#ifdef USE_CIS_MELT
C     The following equation is based on Savage et al (2001).

      IF (ib_Ta.GT.0.) THEN       ! if air temperature above freezing
       ib_Re = ABS(ib_Vel - Vel_a) * ib_lth     ! Reynolds no.
     &             / kv_a                          ! (dimensionless) 
C      where kv_a is the kinematic viscosity of air
       ib_Pr = kv_a / k_a                          ! Prandlt number
C      where k_a is the thermal diffusivity of air
       ib_Nu = 0.058 * (ib_Re**0.8) * (ib_Pr**0.4) ! Nusselt number
                                                   ! (dimensionless)
       hflx_forced_a = ib_Nu * kf_a                ! heat flux 
     &               * (ib_Ta - ib_Tice)
     &                 / ib_lth 
c      where kf_a is thermal conductivity of air (0.0243 J.s-1.m-1.K-1)
       ib_Mforced_a = ( hflx_forced_a / (ib_rho * Gamma_Ice) )
     &                * deltaT          ! ms-1 to m per timestep 
      ELSE
       ib_Mforced_a = 0.
      ENDIF
      IF (ib_Mforced_a.LT.0.) ib_Mforced_a = 0. _d 0
#endif  

C
C--  2)SUBAQUEOUS (underwater) MELTING
C    ---------------------------------
C
C    FORCED CONVECTION/SENSIBLE HEAT MELTING (underwater)
C    (Also called Basal turbulent melting or 'sensible heat exchange')
C
C     Melting due to forced convection is generated by turbulence
C     created by the relative motion of the water passing the iceberg.
C     so that the magnitude of the melting is related to the relative
C     speed of the iceberg against the water and the difference in
C     temperature between the iceberg (-4C) and the ocean water temperature.
C     This melt is essentially melt from sensible heating.
C    
C     Note that both CIS and BIGG give very simialr results
C
#ifdef USE_CIS_MELT      
      ib_Re =  ABS(ib_Vel - Vel_w) * ib_lth   ! ratio of inertial forces to
     &          / kv_w                        ! viscous forces (Reynolds no.)
                                              ! (dimensionless)
      ib_Pr = kv_w / k_w                      ! Prandlt number
                                              ! kinematic visc/therm. diff.
                                              ! (dimensionless)
      ib_Nu = 0.058 * ib_Re**0.8 * ib_Pr**0.4 ! Nusselt number
                                              ! (dimensionless)
      hflx_forced_w = ib_Nu * kf_w            ! Heat Flux 
     &              * (ib_Tw - ib_Tice) 
     &              / ib_lth
      ib_Mforced_w = ( hflx_forced_w / (ib_rho * Gamma_Ice) ) 
     &               * deltaT                 ! ms-1 -> m per timestep
#endif

#ifdef USE_BIGG_MELT
      ib_Mforced_w = 0.58 * (ABS(ib_Vel - Vel_w)**0.8) 
     &             * ((ib_Tw - ib_Tice) / ib_lth**0.2)
      ib_Mforced_w = ib_Mforced_w 
     &                * (1./(60.*60.*24.))  ! m day-1 -> ms-1
     &                * deltaT              ! m per timestep
#endif
      if (ib_Mforced_w.LT.0.) ib_Mforced_w = 0. _d 0


C--  SIDE (LATERAL)/ MELTING DUE TO BUOYANT VERTICAL CONVECTION 
C    Melt along the side walls of an iceberg due to the temperature difference
C    between ice and water. The melt rate is quite small, but
C    empirically estimated. The CIS equation (Kubat et al 2007) i
C    takes into account changes in the freezing point of seawater due to salinity:
C
C    Mlat = 7.62e-03 x ib_dT + 1.3e-03 x ib_dT^2
C
C    where ib_dT is the difference between freezing point temperature at 
C    iceberg (Tfp) and ocean model water temperature (ib_Tw).
C    Note that Tfp is not the freezing point of seawater (Tf), but differs
C    beacuse freshwater mixes with seawater along where the iceberg
C    is melting (Josberger et al 1977 [in Hubat et al. 2007]).
C
C    Setting ALLOW_ICEBERG_MULTILEVEL uses a mean value of ib_Tw 
C    based on average temperature of water the iceberg penetrates.
C
C    Salinity must be given as the last 2 digit of PSU (e.g. 33, not 1033)
C
C    CIS and BIGG are very similar
C
#ifdef USE_CIS_MELT
      Tf = -0.036 - (0.0499 * ib_Sal)       ! freezing point of seawater
     &            - (0.0001128 * ib_Sal**2) ! (deg. C) 
      Tfp = Tf * exp(-0.19 * (ib_Tw - Tf))  ! freezing point temperature
                                            ! (deg. C)
      ib_dT = ib_Tw - Tfp                  
      ib_Mlat = (7.62e-03 * ib_dT + 1.3e-03 * (ib_dT**2))
     &                               * (1./(60.*60.*24.))  ! m day-1 -> ms-1
     &                               * deltaT              ! m per timestep
#endif

#ifdef USE_BIGG_MELT
      ib_Mlat = (7.62e-03 * ib_Tw + 1.29e-03 * (ib_Tw**2))
     &                               * (1./(60.*60.*24.))  ! m day-1 -> ms-1
     &                               * deltaT              ! m per timestep
#endif
      IF (ib_Mlat.LT.0.) ib_Mlat = 0. _d 0


C
C--  WAVE EROSION 
C
C    Reduction in iceberg volume due to wave erosion is assumed to be
C    directly proportional to the sea state (Ss) - given by a fit to the
C    Beaufort Scale (from 0 to 12) - and the SST.
C
C    Wave erosion decreases with increased sea-ice coverage as
C    sea ice damps waves and reduces the wind fetch 
C
C    Note that CIS scheme gives less melt for low wind speeds
C    but higher melt rates at higher wind speed.
C
#ifdef USE_CIS_MELT
        Wh = 0.010125 * abs(Vel_a - Vel_w)**2       ! wave height (m)
     &       * (1+cos(pi * ib_SIarea**3))           ! wave-ice dependency 
        Wh = min(Wh, ib_fbd)                        ! If wave height > ib_fbd
                                                    ! use freeboard height
        Rr = 0.01    ! Ice roughness (m)
        Wp = 10.0    ! Wave period (s) based on observations in El-Tahan et al.,1987
       
        IF (Wh.GT.0.) THEN
         ib_Mwave = 0.000146 * (Rr/Wh)**0.2 
     &             * (Wh/Wp) * abs(ib_Tw -Tf)       ! ms-1
         ib_Mwave = ib_Mwave * deltaT               ! m per timestep
        ELSE
         ib_Mwave = 0. _d 0 
        ENDIF

c        IF (isnan(ib_Mwave)) THEN
c         WRITE(msgBuf,'(A, F11.1, F11.1, I5, 9F11.1)'),
c     &   'NaN in ibMwave (iceberg_therm.F) ... STOP1!',
c     &   ib_wth(ib_n), ib_Mwave, 
c     &   ib_n, Vel_a, Vel_w, ib_SIarea, Wh, Wp, ib_Tw, Tf, Rr, ib_fbd
c         CALL PRINT_ERROR( msgBuf , myThid)
c         STOP
c        ENDIF

#endif

#ifdef USE_BIGG_MELT
C    Following code from Martin and Adcroft, (2010).
C    Note: calving of overhanging slabs not need with this mechanism 
        Ss = (3./2.) * ABS(Vel_a - Vel_w)**0.5    ! sea state 
     &         + (1./10.) * ABS(Vel_a - Vel_w)

        ib_Mwave = ((1./12.) * Ss * (1. + cos(pi*ib_SIarea**3.)) 
     &                * (ib_Tw + 2.)) 
     &                * (1./(60.*60.*24.))          ! m day-1 -> ms-1
     &                * deltaT                      ! m per timestep
#endif

        ib_Mwave = ib_Mwave * MwScale   
        IF (ib_Mwave.LT.0.) ib_Mwave = 0. _d 0

C
C--   SNOW FALL
C     If snow is falling on iceberg then assume water equivilant 
C     is converted to ice. This increases vertical thickness and 
C     is useful for paleoclimate simulations.
C     Iceberg cannot grow thicker than sea floor depth
      IF (ib_Ta.LE.0.AND.ib_precip.GT.0.) THEN
       ib_thk(ib_n) = ib_thk(ib_n) 
     &        + (ib_precip * (rho_w/ib_rho) * deltaT)  ! m per timestep
      ENDIF


C
C ------------------------------------------------------------------
C
C--  Recalculate size of iceberg after melting
C   
      ib_thk(ib_n) =  ib_thk(ib_n)
     &                - (ib_Msolar              ! surface (solar)
     &                + ib_Mforced_w            ! basal (forced conv. water)
     &                + ib_Mforced_a)           ! surface (forced conv. air)

      ib_lth =        ib_lth
     &                - (ib_Mlat * fbd_ratio       ! lateral/buoyant       
     &                + ib_Mwave * fbd_ratio       ! wave
     &                + ib_Mforced_a * r_fbd_ratio ! side (forced conv. air) 
     &                + ib_Mforced_w * fbd_ratio)  ! side (forced conv. water)

      ib_wth(ib_n)  =  ib_lth / ibLthWthRatio      ! suffers same fate as length

C--   calculate volume of iceberg (after melt)
      ib_vol1 = ib_thk(ib_n) * ib_lth * ib_wth(ib_n)  ! Updated iceberg volume
      ib_dft = (ib_rho/rho_w) * ib_thk(ib_n)          ! updated iceberg draft (m)
      ib_fbd = ib_thk(ib_n) - ib_dft                  ! update freeboard (m)

C     Start flagging melted icebergs by setting meltFlag eq 1 if melted
      IF (ib_vol1.LT.0.) meltFlag = 1  ! negative dimensions = iceberg melted
      IF (ib_lth.LE.min_size .OR. ib_wth(ib_n).LE.min_size
     &      .OR. ib_thk(ib_n).LE.min_size) meltFlag = 1

#ifdef ALLOW_ICEBERG_TO_ROLL
      IF (meltFlag.NE.1) THEN
       weeks_stab = 0.7 
       IF (ib_lth/ib_thk(ib_n).LT.weeks_stab) THEN
        ib_thk(ib_n) = ib_lth
        ib_lth = (ib_vol1/(ib_thk(ib_n)/ibLthWthRatio))**0.5
        ib_wth(ib_n) = ib_lth/ibLthWthRatio
        ib_dft = (ib_rho/rho_w)*ib_thk(ib_n)   ! updated iceberg draft (m)
        ib_fbd = ib_thk(ib_n) - ib_dft         ! update freeboard (m)
       ENDIF
       IF (ib_lth.LE.min_size .OR. ib_wth(ib_n).LE.min_size
     &    .OR. ib_thk(ib_n).LE.min_size) meltFlag = 1
      ENDIF
#endif 

#ifdef USE_CIS_MELT
#ifdef ALLOW_OVERHANGING_SLABS
C
C      CREATE AND MELT/CALVE OVERHANGING SLABS
C      ------------------------------------------
C      Waterline wave erosion leads to overhanging slabs.
C      When the overhang reaches a critical length (Fl) it fractures
C      and the slab calves off (Savage et al. 2001; Kubat et al. 2005).
C   
C       Rslab    : thickness of overhanging slab (m)
C       Lslab    : critical length overhanging slab breaks (m)
C       Vslab    : volume of calved ice slab (m3)
C
C      Estimate the calving interval based on polynomial fit to 
C      observed calving rates at different SSTs (data based on
C      Table 1 of Kubat et al. (2007). Higher SSTs increases calving freq.

      IF (meltFlag.NE.1..AND.ib_thk(ib_n).GE.50.) THEN
       calve_slab_freq = 954.3 * ib_Tw**2 - 24582 
     &                   * ib_Tw + 182231.          ! Units: seconds 
       calve_slab_freq = min(calve_slab_freq, 24582.) ! max. calving frequency
 
       IF (calve_slab_counter(ib_n).GE.calve_slab_freq) THEN ! time to calve!

        calve_slab_counter(ib_n) =  0. _d 0          ! reset counter
        Wh = 0.010125 * abs(Vel_a - Vel_w)**2        ! wave height (m)
     &       * (1+cos(pi * ib_SIarea**3))   
        Wh = min (Wh, ib_fbd)                        ! Stop wave height > fbd            

        Rslab = 0.196 * ib_lth                       ! thickness of overhang (m)
        Rslab = min (Rslab, ib_thk(ib_n))
        Lslab = 0.33 * (37.5 * Wh + Rslab**2)**0.5   ! Critical slab length(m)
        Lslab = min (Lslab, ib_lth)
        Vslab = 0.64 * ib_lth * Lslab * Rslab        ! Volume of calved ice 
        IF (Vslab.GE.ib_vol1) THEN
         WRITE(msgBuf,'(A)') 'Volume of slab cannot be > vol. iceberg'
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                                   SQUEEZE_RIGHT, myThid )
         STOP
        ENDIF 
        IF (Vslab.LT.0) THEN
         WRITE(msgBuf,'(A)') 'Volume of slab is less than Zero'
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                                   SQUEEZE_RIGHT, myThid )
         STOP
        ENDIF
       
#ifdef ALLOW_BERGY_BITS
C       Calved overhangs become new iceberg 'bergy bits' rather
C       than melting in-situ
C       This option does not work yet
#endif

C       Update volume        
        ib_vol1 = ib_vol1 - Vslab  
        IF (ib_vol1.LT.0) meltFlag = 1  ! Flag if melted

C       Resize after break-off of overhang 
        thk_wth_ratio = ib_thk(ib_n) / ib_wth(ib_n)
        ib_wth(ib_n) = (ib_vol1/(ibLthWthRatio*thk_wth_ratio))**(1./3.)
        ib_thk(ib_n) = ib_wth(ib_n) * thk_wth_ratio
        ib_lth = ib_wth(ib_n) * ibLthWthRatio
        ib_dft = (ib_rho/rho_w)*ib_thk(ib_n)   ! updated iceberg draft (m)
        ib_fbd = ib_thk(ib_n) - ib_dft         ! update freeboard (m)


C       check iceberg size again 
        IF (ib_lth.LE.min_size .OR. ib_wth(ib_n).LE.min_size
     &      .OR. ib_thk(ib_n).LE.min_size) meltFlag = 1

       ENDIF   ! end of overhanging slab
      ENDIF   ! end of if meltFlag.NE.1
     
C     Increment counter (if iceberg GE 50m thick) 
      IF (ib_thk(ib_n).GE.50) THEN
       calve_slab_counter(ib_n) = calve_slab_counter(ib_n) + deltaT
      ELSE 
       calve_slab_counter(ib_n) = 0. _d 0
      ENDIF

#endif
#endif

#ifdef ALLOW_ICEBERG_MELTWATER
C     --------------------------------------
C         FRESHWATER RELEASE TO OCEAN
C     --------------------------------------

      i1 = INT(ib_iT)
      j1 = INT(ib_jT)

C     Add freshwater to ocean, but only if
C     1) new iceberg volume is >  0
C     2) new iceberg volume < intial iceberg volume 
C     If vol1 > vol0 then iceberg has become thicker due to precip
C     building the ice at the surface
      If (ib_vol1.GT.0.AND.ib_vol1.LT.ib_vol0) THEN
       IceMelt = ib_vol0 - ib_vol1     ! m^3 per timestep)
       IceMelt = IceMelt / deltaT      ! meltwater volume per second (m^3 s-1)
      ELSE
       IceMelt = 0. _d 0               ! safety check     
      ENDIF

      IF (meltFlag.EQ.1) THEN 
       IceMelt = ib_vol0! OR if iceberg has melted then add ib_vol0 to ocean
       IceMelt = IceMelt / deltaT
      ENDIF

C     Convert to kg.m^-2.s^-1 
      IceMelt = IceMelt * (ib_rho/rhoConstFresh) ! Convert ice to liq. meltwater volume
      IceMelt = IceMelt / rA(i1,j1,bi,bj)  ! divide area of cell (--> m.s^-1)
      IceMelt = IceMelt * rhoConstFresh  ! x density freshwater --> kg.m^-2.s^-1
#ifdef GROUP_SMALL_ICEBERGS
      IF (ib_scale(ib_n).GT.1) IceMelt = IceMelt * ib_scale(ib_n)  ! scale for grouped icebergs
#endif
C     Add iceberg meltwater to global iceberg meltwater field (units: kg.m^-2.s^-1)
      IcebergMeltWater(i1,j1,bi,bj) = IcebergMeltWater(i1,j1,bi,bj) 
     &                                + (IceMelt * ibFreshwaterScale)


      IF (IceFracLiq.GT.0.0) THEN     
C     Add freshwater runoff at calving margin to global meltwater field
C     to simulate liquid runoff from glaciers/icestreams. This is done by
C     assuming that a calved iceberg melts instantly.
       IF (ibFlag(ib_n).EQ.-1) THEN                     ! only if iceberg has just calved
        LiqRunoff = ((ib_vol0/(1.-IceFracLiq)) - ib_vol0)  ! volume of liquid (m^3)
        LiqRunoff = LiqRunoff * (ib_rho/rhoConstFresh)  ! Convert ice to liq. meltwater volume
        LiqRunoff = LiqRunoff / deltaT                  ! Scale by timestep
#ifdef GROUP_SMALL_ICEBERGS
        LiqRunoff = LiqRunoff  * ib_scale(ib_n)         ! scale for grouped icebergs
#endif
        LiqRunoff = LiqRunoff / rA(i1,j1,bi,bj)         ! scale by area (m3 --> m)
        LiqRunoff = LiqRunoff * rhoConstFresh           ! m * (kg/m3) --> kg.m^-2
C       Add coastal runoff at calving margins to global field (units: kg.m^-2.s^-1)
        IcebergLiqRunoff (i1,j1,bi,bj) = IcebergLiqRunoff(i1,j1,bi,bj)  
     &                              + (LiqRunoff * ibFreshwaterScale)
       ENDIF
      ENDIF 
      IF (ibFlag(ib_n).EQ.-1) ibFlag(ib_n) = 0  ! Iceberg no longer just calved 

C     --------------------------------------
C             END FRESHWATER RELEASE 
C     --------------------------------------
#endif

C     FLAG MELTED ICEBERGS FOR REMOVAL
      IF (meltFlag.EQ.1) ibFlag (ib_n) = 3

      RETURN
      END
