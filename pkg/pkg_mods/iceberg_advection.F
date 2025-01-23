C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_ADVECTION (ib_iT, ib_jT, 
     &       ib_n, bi, bj, myThid )

C     ==================================================================
C     MITberg V1.0 ICEBERG ADVECTION SCHEME
C     ==================================================================
C
C     o Calculate iceberg advection by solving the iceberg 
C       equation of motion: M x A = Fc + Fw + Fa + Fr +Fp +Fi
C       where:
C       Fc = Coriolis force
c       Fw = Force water
c       Fa = Force air
c       Fr = Wave radiation force
C       Fp = Pressure gradient force 
c       Fi = Force sea ice
c
c    o Iceberg equation of motion solved with Forward Euler method
C      The number of iceberg timesteps to every one model tracer
C      timestep (deltaT_ice) is set in data.iceberg. Default is 10 
C      timesteps.
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
c
#ifdef ALLOW_SEAICE
#include "SEAICE_SIZE.h"
#include "SEAICE.h"
#endif
c
#ifdef ALLOW_EXF
# include "EXF_FIELDS.h"
#endif

C     Routine arguements
      INTEGER i, j, bi, bj, myThid
      INTEGER ib_n

C     Local arguments
      INTEGER deltaTiceberg
      INTEGER ib_tstep
      _RL dist_i
      _RL dist_j
      _RL ib_iT
      _RL ib_jT
      INTEGER i1, j1
      INTEGER k

#ifdef ALLOW_ICEBERG_ADVECTION

C     Ocean velocities
#ifdef ALLOW_ICEBERG_MULTILEVEL
      _RL uvel_w(Nr)
      _RL vvel_w(Nr)
      _RL uvel_w_mean
      _RL vvel_w_mean
#else
C     Single level icebergs (use surface ocean velocity)
      _RL uvel_w
      _RL vvel_w
#endif
      _RL uvel_w_r
      _RL vvel_w_r
      _RL Vel_w
      _RL Vel_w_r

C     Atmospheric velocities
      _RL uvel_a
      _RL vvel_a
      _RL uvel_a_r
      _RL vvel_a_r
      _RL Vel_a
      _RL Vel_a_r

C     Seaice velocities
      _RL uvel_si
      _RL vvel_si
      _RL uvel_si_r
      _RL vvel_si_r
      _RL Vel_si_r

      _RL ib_dft
      _RL ib_fbd
      _RL ib_SIheff
      _RL ib_SIarea

C    Forces
      _RL ib_FU
      _RL ib_FV
      _RL ib_FwU
      _RL ib_FwV
#ifdef ALLOW_ICEBERG_MULTILEVEL
      _RL ib_FwU_z(Nr)
      _RL ib_FwV_z(Nr)
#endif
      _RL ib_FaU
      _RL ib_FaV
      _RL ib_FiU
      _RL ib_FiV
      _RL ib_FcU
      _RL ib_FcV
      _RL ib_FpU
      _RL ib_FpV
      _RL ib_FrU
      _RL ib_FrV
 
C     Wave radiation coefficients
      _RL Lw
      _RL Lc
      _RL Lt
      _RL Cr 
      _RL Wamp
      _RL Wh

C     Pressure gradient
      _RL grad_u
      _RL grad_v

C     Length of iceberg perpendicular to the flow
      _RL ib_perpL_x
      _RL ib_perpL_y
      _RL angle

C     Sail area
      _RL sail_area_x
      _RL sail_area_y

C     I/O variables passed to subroutines
      _RL varOUT
      _RL varOUTu
      _RL varOUTv
      
      _RL ib_mass

C     Coriolis force
      _RL ib_cori
      _RL hemis
      _RL ib_lat

C     Grounding
      _RL ib_R_low
      INTEGER collide
   
C     Grid
      _RL ib_dxC
      _RL ib_dyC

C     Multi-level ocean advection
      _RL thkR
      INTEGER ib_nlvl
      _RL ib_nlvl_rl
      _RL ib_RL
      _RL ib_keel
      INTEGER keel_loop
      INTEGER SAIL_LEVEL
      _RL cumDepth(Nr+1)

C     Misc
      CHARACTER*(MAX_LEN_MBUF) msgBuf


C ***************************************************
c     dist_i      distance moved in x-direction 
c     dist_j      distance moved in y-direction
c
c     ib_iT       x position of iceberg (on tile)
c     ib_jT       y position of iceberg (on tile)
c     i1          integer of ib_iT
c     j1          integer of ib_jT

c     uvel_w   zonal ocean velocity at iceberg (m s-1)
c     vvel_w   meridional ocean velocity at iceberg (m s-1)
c     Vel_w    absolute ocean velocity at iceberg (m s-1)
c     uvel_a   zonal wind speed at iceberg (m s-1)
c     vvel_a   meridional wind speed at iceberg (m s-1)
c     Vel_a    absolute wind velocity at iceberg (m s-1)
c     uvel_si  seaice zonal speed at iceberg (m s-1)
c     vvel_si  seaice meridional speed at iceberg (m s-1)
C   
C     uvel_w_r   relative u velocity (ocean minus iceberg vel) (m.s-1)
C     vvel_w_r   relative v velocity (ocean minus iceberg vel) (m.s-1)
C     uvel_a_r   relative u velocity (wind minus iceberg vel) (m.s-1)
C     vvel_a_r   relative v velocity (wind minus iceberg vel) (m.s-1)
C     uvel_si_r  relative u velocity (seaice minus iceberg vel) (m.s-1)
C     vvel_si_r  relative v velocity (seaice minus iceberg vel) (m.s-1)
C     Vel_w_r    abs. relative ocean velocity at iceberg (m s-1)
C     Vel_a_r    abs. relative wind velocity at iceberg (m s-1)
C     Vel_si_r   abs. relative seaice velocity at iceberg (m s-1)
C
c     ib_dft    iceberg draught based on density of iceberg and water (m)
C     ib_fbd    iceberg freeboard i.e height of iceberg above water (m)
c     ib_SIheff local (interpolated) height of sea ice at iceberg (m)
c     ib_SIarea local (interpolated) concentration of sea ice at iceberg (0-1)
c     ib_cori   local (interpolated) coriolis parameter at iceberg (rad s-1)

c     ib_mass   mass of iceberg (kg)

C     ib_FU     Total drag force (U direction) (kg m s-2)
C     ib_FV     Total drag force (V direction) (kg m s-2)
c     ib_FwU    water drag force (U Direction) (kg m s-2)
c     ib_FwV    water drag force (V Direction) (kg m s-2)
c     ib_FwU_z  water drag force (U Direction) (kg m s-2) at each vertical level
c     ib_FwV_z  water drag force (V Direction) (kg m s-2) at each vertical level
c     ib_FaU    atmosperhic drag (U Direction) (kg m s-2)
c     ib_FaV    atmosperhic drag (V Direction) (kg m s-2)
c     ib_FiU    sea ice drag (U Direction) (kg m s-2)
c     ib_FiV    sea ice drag (V Direction) (kg m s-2)
c     ib_FrU    wave radiation drag (U Direction) (kg m s-2)
c     ib_FrV    wave radiation drag (V Direction) (kg m s-2)
C     ib_FcU    coriolis force (U direction) (kg m s-2)
C     ib_FcV    coriolis force (V direction) (kg m s-2)
C     ib_FpU    pressure gradient (U direction) (kg m s-2)
C     ib_FpV    pressure gradient (V direction) (kg m s-2)

C     Lw     empirical wave length
C     Cr     variable wave length coefficient
C     Wamp   wave amplitude (m). It is half of wave height
C     Wh     wave height (m)

C     grad_u  sea surface slope (x direction) at iceberg (m/m)
C     grad_v  sea surface slope (y direction) at iceberg (m/m)

C     ib_perpL_x  length of iceberg perpendicular to x-axis
C     ib_perpL_y  length of iceberg perpendicular to y-axis
C     angle   inverse tangent (atan2) of vvel_w, uvel_w for drag calculation
C     sail_area_x area of iceberg above water (x-axis)
C     sail_area_y area of iceberg above water (y-axis)

C     I/O variables
c     varOUT   tmp var passed from interpolation scheme
c     varOUTu  tmp var passed back from collision scheme (U direction)
c     varOUTv  tmp var passed back from collision scheme (V direction)
c     collide  passed from collision scheme. Set to 1 if collision 

C     ib_R_low interpolated depth of water at iceberg location (m)
C     ib_dxC   interpolated spacing of dx at iceberg 
C     ib_dyC   interpolated spacing of dy at iceberg

C     thkR     Vertical thickness of each layer of water iceberg penetrates
C     ib_nlvl  Number of vertical levels of water column iceberg penetrates
C     ib_nlvl_rl real*4 of ib_nlvl
C     ib_RL    ratio of number of levels iceberg penetrates to 8 levels of
C              barker et al (2004) keel model which the polynomial ib_keel
C              is derived from.
C     ib_keel  Second order polynomial fit to the top 8 levels of the 
C              keel model of Barker et al (2004).
C     SAIL_LEVEL integer of number of levels above water (2 is assumed)
C
C ***************************************************************************


#ifdef ICEBERG_DIAG_ON
      WRITE(msgBuf,'(A)') 'ICEBERG DYNAMICS ROUTINE CALLED'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif


      i1 = INT(ib_iT)
      j1 = INT(ib_jT)

      ib_dft = (ib_rho/rho_w)*ib_thk(ib_n)  ! Iceberg draft (m)
      ib_fbd = ib_thk(ib_n) - ib_dft        ! Iceberg freeboard (m)\

C     Calculate cumulative depth
      cumDepth(1)= 0.
      DO k = 1,Nr
       cumDepth(k+1) = delR(k) + cumDepth(k)
      ENDDO

C     Check to see if iceberg is grounded
C     If true then DO NOT advect iceberg
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, R_low, varOUT,
     &                             0, bi, bj, myThid )
      ib_R_low = varOUT

#ifdef ALLOW_SCOURING
C     Allow icebergs to plow through the sediment
      IF (ib_dft.GE.(ABS(ib_R_low))+ScourDepth) THEN
#else
      IF (ib_dft.GE.ABS(ib_R_low)) THEN
#endif
       ib_FU = 0. _d 0       ! Set force to zero
       ib_FV = 0. _d 0
       ib_uVel(ib_n) = 0. _d 0  ! Set velocity to zero 
       ib_vVel(ib_n) = 0. _d 0
       ibFlag(ib_n) = 2  ! Flag 2 when grounded on sea floor
      ELSE 


C     -----------------------------------------------------------    
C     !!!! Only do the advection loop if iceberg is floating !!!!
C     -----------------------------------------------------------

C     Calculate iceberg mass (kg)
#ifdef USE_ICEBERG_KEEL_MODEL
      ib_mass = 0. _d 0        ! iceberg mass is calculated later based on shape
                               ! of keel at each level and sail.
#else
      ib_mass =   ib_thk(ib_n) 
     &          * ib_lth(ib_n)
     &          * ib_wth(ib_n)
     &          * ib_rho
#endif


C
C--  INTERPOLATE VARIABLES TO ICEBERG POSITION
C    -----------------------------------------
C
C    OCEAN VELOCITY 
#ifdef ALLOW_ICEBERG_MULTILEVEL
C      Calculate number of levels iceberg penetrates.
        DO k = 1,Nr-1
         IF (ib_dft.GE.cumDepth(k)
     &      .AND.ib_dft.LT.cumDepth(k+1)) ib_nlvl = k
        ENDDO

C      Set force/velocity at each vertical level to Zero to be safe
        ib_FwU_z(:)  = 0. _d 0
        ib_FwV_z(:)  = 0. _d 0
        uvel_w(:) = 0. _d 0
        vvel_w(:) = 0. _d 0
        uvel_w_mean = 0. _d 0
        vvel_w_mean = 0. _d 0

C      Get ocean velocity at each level
        DO k = 1,ib_nlvl
         CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, k, uVel, varOUT,
     &                             1, bi, bj, myThid )
         uvel_w(k) = varOUT

         CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, k, vVel, varOUT,
     &                             2, bi, bj, myThid )
         vvel_w(k) = varOUT

        ENDDO
         Vel_w = sqrt(uvel_w(1) * uvel_w(1)   ! absolute surface ocean
     &                 + vvel_w(1) * vvel_w(1))  ! velocity (m.s-1)


#else

C     Single-level (surface) ocean advection

      CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, 1, uVel, varOUT, 
     &                             1, bi, bj, myThid )
      uvel_w = varOUT   
      CALL ICEBERG_INTERP_LINEAR_3D ( ib_iT, ib_jT, 1, vVel, varOUT,
     &                             2, bi, bj, myThid )
      vvel_w = varOUT

      Vel_w = sqrt(uvel_w * uvel_w
     &              + vvel_w * vvel_w)  ! absolute ocean velocity

#endif

C--   INTERPOLATE WIND
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, uWind, varOUT,
     &                             1, bi, bj, myThid )
      uvel_a = varOUT
      uvel_a = uvel_a * ibuWindScale
      IF (uvel_a.GT.ibMaxWind) uvel_a = ibMaxWind
      IF (uvel_a.LT.ibMaxWind*(-1.)) uvel_a = ibMaxWind*(-1.) 

      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, vWind, varOUT,
     &                             2, bi, bj, myThid )
      vvel_a = varOUT
      vvel_a = vvel_a * ibvWindScale
      IF (vvel_a.GT.ibMaxWind) vvel_a = ibMaxWind
      IF (vvel_a.LT.ibMaxWind*(-1.)) vvel_a = ibMaxWind*(-1.)

      Vel_a = sqrt(uvel_a*uvel_a
     &                +vvel_a*vvel_a)   ! absolute wind velocity


#ifdef ALLOW_SEAICE
C--  INTERPOLATE SEA ICE
      IF ( useSEAICE ) THEN
       CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, UICE, varOUT,
     &                             1, bi, bj, myThid )
       uvel_si = varOUT
       CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, VICE, varOUT,
     &                             2, bi, bj, myThid )
       vvel_si = varOUT
       CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, HEFF, varOUT,
     &                                 0, bi, bj, myThid )
       ib_SIheff = varOUT
       CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, AREA, varOUT,
     &                                 0, bi, bj, myThid )
       ib_SIarea = varOUT

       IF (ib_SIarea.LT.0.15) ib_SIheff = 0. _d 0  
      ELSE
       ib_SIheff = 0. _d 0  
       ib_SIarea = 0. _d 0
      ENDIF
#else
       ib_SIheff = 0. _d 0 ! Set seaice height & area to zero if sea ice 
       ib_SIarea = 0. _d 0 ! package switched off
#endif

 
C     Interpolate coriolis force to iceberg location
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, fCori, varOUT,
     &                             0, bi, bj, myThid )
      ib_cori = varOUT

C     Determine iceberg latitude
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, yc, varOUT,
     &                                   0, bi, bj, myThid )
      ib_lat = varOUT


C     Interpolate grid spacing to iceberg
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, dxC, varOUT,
     &                             0, bi, bj, myThid )
      ib_dxC = varOUT
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, dyC, varOUT,
     &                             0, bi, bj, myThid )
      ib_dyC = varOUT

C     Interpolate ocean water depth to iceberg location
      CALL ICEBERG_INTERP_LINEAR_2D ( ib_iT, ib_jT, R_low, varOUT,
     &                             0, bi, bj, myThid )
      ib_R_low = varOUT



C
C--   Determine length of iceberg perpendicular to the x- and y-
C     axis to accuarely calculate drag. Assume iceberg orientated 
C     to direction of iceberg movement.

        angle = ATAN2 (ib_uVel(ib_n), ib_vVel(ib_n))

        IF (angle.LT.0.) angle = 2. * PI + angle

        ib_perpL_x =   ABS (ib_wth(ib_n) * COS (angle))
     &               + ABS (ib_lth(ib_n) * SIN (angle))
        ib_perpL_y =   ABS (ib_lth(ib_n) * COS (angle))
     &               + ABS (ib_wth(ib_n) * SIN (angle))


C
C-- ============ Main loop ======================
C

      DO ib_tstep=1,INT(deltaT_ice)  ! Do loop X-times
                                     ! for every 1 tracer advection timestep

C
C--  DRAG FORCES
C
C     The drag forces are a sum of the forces acting on vertical walls
C     (form drag) and horizontal surfaces (skin drag) determined by 
C     the general relationship:
C
C     Fx = 0.5 * rho(x) * C(xv) * Area(v) + C(xh) * Area(h) * |Vx - Vi| * (Vx - Vi)
C
C     where subscript x denotes a, w and i for atmos, ocean (water), seaice
C     and v and h denote vertical (form drag on side wall) and horizontal 
C     (skin drag on the bottom) drag coefficients. There is no horizontal
C     drag for seaice.
C


C
C--  WATER DRAG FORCE 
C    ----------------
C
C     o The thickness of seaice is considered in draught 
C       at the surface so that there is no water drag where the sea
C       ice exists in the model (Martin and Adcroft, 2010)
C
C     o For the bottom of the iceberg we consider 
C       horizontal drag (Martin and Adcroft, 2010)
C           
C     o Icebergs travel with long axis (length) parallel to direction
C       of the water velocity
C 


#ifdef ALLOW_ICEBERG_MULTILEVEL 
C
C--  MULTILEVEL OCEAN DRAG
C    ---------------------
C
C    Consider ocean drag force at EVERY LEVEL in the ocean model
C    that an iceberg penetrates. This is designed to give 
C    a more realistic advection pattern, compared to the purely
C    surface ocean advection that is typically used in models.
C
C    Note: multi-level icebergs are assumed tabular unless 
C          the keel model option is switched on.
C          if keel model is used then icebergs below smaller with depth

C      
C    Calculate drag force at each vertical level
C
      DO k = 1,ib_nlvl

       uvel_w_r = uvel_w(k) - ib_uVel(ib_n)  ! relative vel (u-dir)
       vvel_w_r = vvel_w(k) - ib_vVel(ib_n)  ! relative vel (v-dir)a
       Vel_w_r  = sqrt ( uvel_w_r * uvel_w_r          ! abs. rel. vel.
     &                         + vvel_w_r * vvel_w_r )! of ocean.

#ifdef USE_ICEBERG_KEEL_MODEL
C 
C-- ICEBERG KEEL MODEL
C   ------------------
C
C
C     Calculate shape of iceberg keel (ib_keel) based on second order polynomial
C     fit to the top 8 levels of the keel model of barker et al. 2004) 
C
C     ib_keel is a fractional value of the absolute length at each depth.
C     Multiply ib_keel by ib_perpL to get an actual size (meters)
C     at each level in the model. The keel above and below water
C     has the general shape: 
C
C              ***           <- wind forcing  (two layer sail)
C             *****          <- wind forcing
C     ------*********------  - water level
C          ***********       <--
C           *********        <--  
C            *******         <--   Water
C             *****          <--  Forcing 
C              ***           <--  
C               *            <--

C     The keel model will give a reduction in surface area over
C     the standard tabular shape below the waterline. The keel
C     area is ~77% of a tabular shape. This also alters 
C     the mass of the iceberg. Note that this option will also
C     change the shape of the iceberg above the waterline to 
C     a two-layer sail that decreases in size with height.


      IF (ib_thk(ib_n).GT.30.) THEN
C      Keel model only used when iceberg thickness > 30m 
C      to avoid prescribing unrealistic keel shapes. 
C      Below 30m thickness icebergs are assumed tabular

        ib_nlvl_rl = ib_nlvl * 1.    ! real*4 of ib_nlvl
        ib_RL = k * (8./ib_nlvl_rl) 
        ib_keel = -0.025 * ib_RL**2 + 0.164 * ib_RL + 0.78 ! Formula for keel size

      ELSE
C--   Tabular icebergs when thk < 30 m 
        ib_keel = 1.
      ENDIF
#endif  /* end keel model */


#ifdef USE_TABULAR_ICEBERGS
C--   Assume tabular shape
       ib_keel = 1. 
#endif


C--   Calculate drag at each vertical level
C
C     (1) for levels that iceberg penetrates entirely: 
        IF (k.NE.ib_nlvl) THEN  
         thkR = delR(k)

C       consider sea ice in top layer only
         IF (k.EQ.1.AND.ib_SIheff.LT.thkR) thkR = thkR - ib_SIheff 
         IF (thkR.LE.0.) THEN
          WRITE(msgBuf,'(A)') 'thkR too small! in iceberg_adv.F'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                              SQUEEZE_RIGHT, myThid )
          STOP
         ENDIF

         ib_FwU_z(k)  = 0.5  * rho_w
     &                * Cwv * ib_perpL_x * ib_keel * thkR 
     &                * Vel_w_r * uvel_w_r

         ib_FwV_z(k)  = 0.5 * rho_w
     &                * Cwv * ib_perpL_y * ib_keel * thkR
     &                * Vel_w_r * vvel_w_r

        ELSE
C
C    (2) now at bottom level of iceberg which only partially
C        penetrates the vertical cell, so we only calculate drag force on the
C        part of the iceberg that penetrates this cell. We also now consider
C        the influence of drag in the horizontal direction, i.e. along
C        the bottom of the iceberg.
C        
         thkR = ib_dft - cumDepth(k)          ! Thickness of iceberg in bottom cell

         IF (k.EQ.1.AND.ib_SIheff.LT.thkR)    ! account for sea ice 
     &     thkR = thkR - ib_SIheff

         IF (thkR.LE.0.) THEN
          WRITE(msgBuf,'(A)') 'thkR too small! in iceberg_adv.F'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                              SQUEEZE_RIGHT, myThid )
          STOP
         ENDIF

         ib_FwU_z(k)  = 0.5  * rho_w
     &                * (Cwv * ib_perpL_x * ib_keel * thkR
     &                +  Cwh * ib_wth(ib_n) * ib_keel 
     &                  * ib_lth(ib_n) * ib_keel)     
     &                * Vel_w_r * uvel_w_r

         ib_FwV_z(k)  = 0.5  * rho_w
     &                * (Cwv * ib_perpL_y * ib_keel * thkR
     &                +  Cwh * ib_wth(ib_n) * ib_keel 
     &                  * ib_lth(ib_n) * ib_keel)   
     &                * Vel_w_r * vvel_w_r


       ENDIF


#ifdef USE_ICEBERG_KEEL_MODEL
C        continue to calculate iceberg mass
        IF (ib_tstep.EQ.1) THEN
         ib_mass = ib_mass + (ib_wth(ib_n) * ib_keel
     &                      * ib_lth(ib_n) * ib_keel
     &                      * thkR * ib_rho)
        ENDIF
#endif

       ENDDO

C
C    (3) Sum drag forces in the vertical to get total water 
C        drag on the iceberg
C
       ib_FwU = sum (ib_FwU_z(1:ib_nlvl))
       ib_FwV = sum (ib_FwV_z(1:ib_nlvl))


#else

C
C     Single-level (surface) ocean drag force
C     ---------------------------------------
C
C
       uvel_w_r = uvel_w - ib_uVel(ib_n)
       vvel_w_r = vvel_w - ib_vVel(ib_n)
       Vel_w_r  = ABS (sqrt ( uvel_w_r * uvel_w_r   
     &                         + vvel_w_r * vvel_w_r ))

       ib_FwU = 0.5 * rho_w 
     &        * (Cwv * ib_perpL_x * (ib_dft - ib_SIheff)  ! vert. drag
     &           +  Cwh * ib_wth(ib_n) * ib_lth(ib_n))          ! horz. drag
     &        * Vel_w_r * uvel_w_r

       ib_FwV = 0.5 * rho_w 
     &        * (Cwv * ib_perpL_y * (ib_dft - ib_SIheff)
     &           +  Cwh * ib_wth(ib_n) * ib_lth(ib_n))
     &        * Vel_w_r * vvel_w_r


#endif  /* multi-level */



C
C--  AIR DRAG FORCE
C    --------------
C
C     calculate relative velocities
       uvel_a_r = uvel_a - ib_uVel(ib_n)  ! u-dir
       vvel_a_r = vvel_a - ib_vVel(ib_n)  ! v-dir
       Vel_a_r  = sqrt ( uvel_a_r * uvel_a_r   ! absolute
     &                         + vvel_a_r * vvel_a_r )

#ifdef USE_ICEBERG_KEEL_MODEL 
C       Reduce length of ib_perpL to be consistent with keel model
C       and icebergs having their maximum length below the waterline.
C       We use the polynomial fit to the Barker et al (2004) keel data
C       and assume a two layer model for the portion of the
C       iceberg ABOVE water. The top (bottom) layers have lengths 
C       61% (78%) of the maximum length below the water line.


        ib_FaU = 0. _d 0
        ib_FaV = 0. _d 0 

        DO keel_loop  = 1,2
         IF (keel_loop.EQ.1) THEN 
          ib_keel = 0.61
         ELSE 
          ib_keel =0.78
         ENDIF

C       Consider air drag if icebeg length > 50m,
C       based on CIS model (Kubat et al., 2005)
         IF (ib_lth(ib_n).GT.50) THEN
         ib_FaU = ib_FaU +
     &            (0.5 * rho_a
     &             * Cav * ib_perpL_x * ib_keel * ib_fbd * 0.5  
     &             * Vel_a_r * uvel_a_r)

         ib_FaV = ib_FaV +   
     &            (0.5 * rho_a
     &             * Cav * ib_perpL_y * ib_keel * ib_fbd * 0.5
     &             * Vel_a_r * vvel_a_r)
         ELSE
          ib_FaU = 0. _d 0
          ib_FaV = 0. _d 0
         ENDIF

C        add mass
         IF (ib_tstep.EQ.1) ib_mass = ib_mass + (ib_wth(ib_n) * ib_keel
     &                                          * ib_lth(ib_n) * ib_keel
     &                                          * ib_fbd * 0.5 * ib_rho)
        ENDDO

#endif  /* USE_KEEL_MODEL */

#ifdef USE_ICEBERG_SAIL_MODEL 
C
C     SAIL MODEL
C     ----------
C
C     Option to estimate air drag using empirical Sail Area model
C     based on Canadian Hydraulics Centre (CHC) iceberg model (Barker et al 2004)
C     Icebergs have a pinnacle shape typical of those observed at the Grand Banks.
C     Using this scheme reduces wind drag on an iceberg.
C
C       Sail area = Ao * L + Bo
C
C     where Ao = 28.194 m and Bo = -1420.2 m2 based on constants from
C     Barker et al. 2004). If sail area is less than Zero
C     (at approx. lengths of 50 m) then air drag is ignored.
C 

        sail_area_x = 28.194 * ib_perpL_x - 1420.2
        sail_area_y = 28.194 * ib_perpL_y - 1420.2

        IF (sail_area_x.GT.0.) THEN
        ib_FaU =  0.5 * rho_a * Cav
     &           * sail_area_x
     &           * Vel_a_r * uvel_a_r
        ELSE
         ib_FaU = 0. _d 0
        ENDIF

        IF (sail_area_y.GT.0.) THEN
        ib_FaV =  0.5 * rho_a * Cav
     &           * sail_area_y
     &           * Vel_a_r * vvel_a_r

        ELSE
         ib_FaV = 0. _d 0
        ENDIF

C        Continue to add mass
         IF (ib_tstep.EQ.1) ib_mass = ib_mass + (ib_wth(ib_n) * ib_lth(ib_n)
     &                                           * ib_fbd * ib_rho)
#endif

#ifdef USE_TABULAR_ICEBERGS
        ib_FaU = 0.5 * rho_a 
     &         * (Cav * ib_perpL_x * ib_fbd       ! vert. wind drag
     &           +  Cah * ib_wth(ib_n) * ib_lth(ib_n))  ! horz. wind drag
     &         * Vel_a_r * uvel_a_r


        ib_FaV = 0.5 * rho_a 
     &         * (Cav * ib_perpL_y * ib_fbd
     &            +  Cah * ib_wth(ib_n) * ib_lth(ib_n))   
     &         * Vel_a_r * vvel_a_r
#endif


C
C-- WAVE RADIAITON FORCE 
C   --------------------
C
C   Fr = 1/2 * Rho_W * Cr * g * min(Wamp, ib_fbd)^2 * Lw * (vel_a / |vel_a|)
C     where Cr is wave coefficient, g is gravity, Wamp is wave amplitude,
C     Lw is iceberg length normal to incident wave direction 
C
C     Equation is modified from Savage et al. (2001)
C     to include dependence of wave height to sea ice.
C
C   o Wave direction is the same direction as air velocity
C
C   o Wave height (in meters) is given as: Wh=0.02025 * |vel_a - vel_w|^2 
C     based on the quadratic fit of wave height to wind speed from 
C     data in the marine Beaufort Scale (Bigg et al 1997)
C     For example, a 30 ms-1 wind --> ~9m wave height and ampliutde of 4.5m 
C     As with Martin and Adcroft (2010) we only consider wind speed 
C     relative to the ocean.
C     Wave height also depends on sea ice area so that increased ice
C     cover dampens the influence of wave drag. We modify the 
C     equation in the same way as wave erosion is treated in iceberg_therm.F 
C
C   o If wave height .GT. freeboard height then the freeboard height 
C     is taken as the wave height. This stops small icebergs being subjected
C     to unrealistically large forces (Modified from Martin and Adcroft, 2010).

C   o Apply variable wave coefficient (Cr) to dampen wave radiation
C     when the ratio of iceberg length to wavelength becomes small, and
C     to stop wave radiation becoming the dominant driving force
C     (Martin and Adcroft (2010); Carrieres et al. 2001).
C     Fig. 6. of Carrieis et al (2001) shows that Cr has a typical value of
C     0.06, but that small ratios of ib_lth/Lw (<0.25) will result in 
C     Cr becoming less than 0.06. Note that plotting Cr against ib_lth/Lw
C     will reproduce fig.6. of Carrieres et al (2001).
C

#ifdef ALLOW_WAVE_ADVECTION

      Lw = 0.32 * abs(Vel_a - Vel_w)**2          ! wave length
      Lc = 0.125 * Lw
      Lt = 0.250 * Lw 

      Cr = MAX(0.0,((ib_lth(ib_n)-Lc)/(Lt-Lc)))
      Cr = 0.06 * min (Cr,1.0)

      Wh = 0.02025 * abs(Vel_a - Vel_w)**2     ! wave height
     &     * (1 + cos (pi*ib_SIarea**3)) * 0.5       ! wave-seaice dependency 

      IF(Wh.GT.ib_fbd) Wh = ib_fbd                   ! If wave height > ib_fbd
                                                     ! take freeboard as
                                                     ! max. wave height
      IF (uvel_a.NE.0.) THEN
       ib_FrU = 0.5 * rho_w * Cr * gravity
     &              * Wh * Wh * ib_perpL_x 
     &              * ( uvel_a/abs(uvel_a) ) 
      ELSE
       ib_FrU = 0. _d 0   ! No wave force if wind speed is zero
      ENDIF

      IF (vvel_a.NE.0.) THEN
       ib_FrV = 0.5 * rho_w * Cr * gravity
     &              * Wh * Wh * ib_perpL_y
     &              * ( vvel_a/abs(vvel_a) ) 
      ELSE
       ib_FrV = 0. _d 0   ! No wave force if wind speed is zero
      ENDIF

#else
      ib_FrU = 0. _d 0
      ib_FrV = 0. _d 0

#endif

#ifdef ALLOW_SEAICE      
C
C--  SEA ICE DRAG
C    ------------
C    N.B  SIarea <0.15 does not exert force on the iceberg
C    ((Lichey and Hellmer, 2001) as it is assumed to open water. This is
C    acheived by setting SIheff = 0 when SIarea<0.15. This criteria is set i
C    earlier when Sea ice fields are loaded. Also, when SIarea > 0.9 
C    like (Lichey and Hellmer, 2001) we assume that all other forcings 
C    are set to zero and that icebergs are 'locked' in the sea ice
C    and drift with the pack ice. 
C

      IF ( useSEAICE ) THEN
C     calculate relative velocities
       uvel_si_r = uvel_si - ib_uVel(ib_n)  ! u-dir
       vvel_si_r = vvel_si - ib_vVel(ib_n)  ! v-dir
       Vel_si_r  = ABS (sqrt ( uvel_si_r * uvel_si_r   ! absolute
     &                         + vvel_si_r * vvel_si_r ))

       IF (ib_SIheff.GT.ib_fbd) ib_SIheff = ib_fbd

       ib_FiU = 0.5 * rho_si * Civ 
     &         * (ib_perpL_x * ib_SIheff)
     &         * Vel_si_r * uvel_si_r

       ib_FiV = 0.5 * rho_si * Civ 
     &         * (ib_perpL_y * ib_SIheff)
     &         * Vel_si_r * vvel_si_r

      ELSE
       ib_FiU = 0. _d 0
       ib_FiV = 0. _d 0
       uvel_si = 0. _d 0
       vvel_si = 0. _d 0
      ENDIF
#else
       ib_FiU = 0. _d 0
       ib_FiV = 0. _d 0
       uvel_si = 0. _d 0
       vvel_si = 0. _d 0
#endif


#ifdef ICEBERG_USE_ADDED_MASS
C    Consider mass added to iceberg due to water that the iceberg
C    drags along with it, as used in Canadian Hydraulics Center 
C    iceberg model (Kubut et al. 2005)
      IF (ib_tstep.EQ.1) ib_mass = ib_mass * 1.5     
#endif



C
C-- CORIOLIS FORCE
C   --------------
      IF (ib_lat.GE.0.) THEN  
       hemis = -1.0 ! Deflect right in N.hemisphere
      ELSE
       hemis =  1.0 ! Deflect left in S.hemisphere
      ENDIF
   
      ib_FcU  =  ib_mass * ib_cori 
     &         * ib_vVel(ib_n)

      ib_FcV  =  ib_mass * ib_cori
     &         * ib_uVel(ib_n)
     &         * hemis   



C
C--  PRESSURE GRADIENT FORCE
C    -----------------------
C
      IF ( implicitFreeSurface ) THEN
C      Fp = -M x g x grad
C      where grad is the sea surface sloop from the free surface model
C      Note that the PGF causes icebergs to move down slope. 
C      The minus sign is excluded in the equation below because 
C      gravity has a positive sign in the model.

       grad_u = (etaN(i1,j1,bi,bj) - etaN(i1+1,j1,bi,bj))
     &         / dxg(i1,j1,bi,bj)     

       grad_v = (etaN(i1,j1,bi,bj) - etaN(i1,j1+1,bi,bj))
     &         / dyg(i1,j1,bi,bj)

       ib_FpU = ib_mass * gravity * grad_u
       ib_FpV = ib_mass * gravity * grad_v

      ELSE
       WRITE(msgBuf,'(A)') 'implicitFreeSurface must eq TRUE to
     &                      calculate PGF on iceberg'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       STOP
      ENDIF

C
C--  SUM FORCES ACTING ON ICEBERG
C    ----------------------------

       ib_FU =  ib_FwU  ! water drag
     &        + ib_FaU  ! air drag
     &        + ib_FrU  ! wave radiation drag
     &        + ib_FiU  ! ice drag
     &        + ib_FpU  ! pressure gradient force
     &        + ib_FcU  ! coriolis force

       ib_FV =   ib_FwV
     &         + ib_FaV
     &         + ib_FrV 
     &         + ib_FiV
     &         + ib_FpV
     &         + ib_FcV


#ifdef USE_LAGRANGIAN_FLOAT
C    Only water drag acts on the iceberg 
       ib_FU = ib_FwU
       ib_FV = ib_FwV
#endif

C
C--  COLLISION WITH COASTLINES
C    -------------------------
C
      IF (ibBounceCoast.EQ.1) THEN   ! Default is 0 (off). Override in data.iceberg
       CALL ICEBERG_COASTLINE  (ib_iT, ib_jT, ib_n, ib_R_low, 
     &                         varOUTu, varOUTv, collide,
     &                         bi, bj, myThid )

       IF (collide.EQ.1) THEN
        ib_FU = varOUTu   
        ib_FV = varOUTv 
       ENDIF
      ENDIF 


C
C--  CONVERT FORCE (kg m s-2) TO ACCELERATION (m s-2)
C    ------------------------------------------------
C
        ib_FU = ib_FU/ib_mass
        ib_FV = ib_FV/ib_mass

C
C--  ICEBERG ADVECTION
C    -----------------
        dist_i = (ib_uVel(ib_n) * (deltaT/deltaT_ice)
     &             + 0.5 * ib_FU *(deltaT/deltaT_ice)**2)
     &            / ib_dxC

        dist_j = (ib_vVel(ib_n) * (deltaT/deltaT_ice)
     &             + 0.5 * ib_FV *(deltaT/deltaT_ice)**2)
     &            / ib_dyC
        ib_uVel(ib_n) = ib_uVel(ib_n) + ib_FU * (deltaT/deltaT_ice)
        ib_vVel(ib_n) = ib_vVel(ib_n) + ib_FV * (deltaT/deltaT_ice)


C   Small icebergs drift with ocean
       IF (ib_thk(ib_n).LT.3.OR.ib_wth(ib_n).LT.3.) THEN
#ifdef ALLOW_ICEBERG_MULTILEVEL
         ib_uVel(ib_n) =  uvel_w(1)
         ib_vVel(ib_n) =  vvel_w(1)
#else
         ib_uVel(ib_n) =  uvel_w
         ib_vVel(ib_n) =  vvel_w
#endif
         dist_i = (ib_uVel(ib_n) * (deltaT/deltaT_ice))
     &           / ib_dxC
         dist_j = (ib_vVel(ib_n) * (deltaT/deltaT_ice))
     &           / ib_dyC
       ENDIF

#ifdef ALLOW_SEAICE
#ifdef ICEBERGS_DRIFT_WITH_SEAICE  
      IF ( useSEAICE ) THEN
C     Icebergs in thick sea ice drift with the pack-ice
C     based on Lichey and Hellmer (2001)
       IF (ib_SIarea.GE.0.90) THEN
        ib_uVel(ib_n) = uvel_si 
        ib_vVel(ib_n) = vvel_si
        dist_i = (ib_uVel(ib_n) * (deltaT/deltaT_ice))
     &           / ib_dxC
        dist_j = (ib_vVel(ib_n) * (deltaT/deltaT_ice))
     &           / ib_dyC
        ibFlag(ib_n) = 1 ! Flag 1 for drifting with sea ice
       ENDIF
      ENDIF
#endif
#endif

#ifdef CAP_ICEBERG_VELOCITY
C   If max. speed exceeded then iceberg velocity set to ocean
       IF (ABS(ib_uVel(ib_n)).GT.ibMaxV.OR.
     &  ABS(ib_vVel(ib_n)).GT.ibMaxV) THEN
#ifdef ALLOW_ICEBERG_MULTILEVEL
        ib_uVel(ib_n) = uvel_w(1)
        ib_vVel(ib_n) = vvel_w(1)
#else
        ib_uVel(ib_n) = uvel_w
        ib_vVel(ib_n) = vvel_w
#endif
        dist_i = (ib_uVel(ib_n) * (deltaT/deltaT_ice))
     &           / ib_dxC
        dist_j = (ib_vVel(ib_n) * (deltaT/deltaT_ice))
     &           / ib_dyC
       ENDIF
#endif


C
C-- MOVE ICEBERG ON MODEL GRID
C
       ib_i(ib_n) = ib_i(ib_n) + dist_i
       ib_j(ib_n) = ib_j(ib_n) + dist_j

C   Icebergs at edge of model grid are flagged as melted

        IF (ib_i(ib_n).LT.2.OR.ib_i(ib_n).GT.(sNx*nPx)-1)
     &        ibFlag(ib_n) = 3
        IF (ib_j(ib_n).LT.2.OR.ib_j(ib_n).GT.(sNy*nPy)-1)
     &        ibFlag(ib_n) = 3

      ENDDO   ! Here we end the main loop and forward timestepping


      ENDIF   ! end of advection (only iceberg not grounded will moved)

#endif /* ALLOW_ICEBERG_ADVECTION */

      RETURN
      END
