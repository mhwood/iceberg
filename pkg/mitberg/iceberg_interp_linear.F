C
#include "ICEBERG_OPTIONS.h"

C     ==================================================================
C     MITberg V1.0 BILINEAR INTERPOLATION SCHEME 
C     ==================================================================
C
C     o Bilinear scheme to interpolate ocean and atmospheric
C       varibales to iceberg position as given by its indexed 
C       ib_i, ib_j location.
C
C     ==================================================================

      SUBROUTINE ICEBERG_INTERP_LINEAR_3D ( 
     I                                   ib_iT, ib_jT, k, varIN, 
     O                                   varOUT,
     I                                   varType, 
     I                                   bi, bj, myThid )

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "GRID.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "ICEBERG.h"
C#include "SEAICE.h"

C     == Routine arguments
      INTEGER i, j, bi, bj, myThid
      _RL varIN (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nr, nSx,nSy)
      _RL varOUT
      _RL ib_iT, ib_jT

C     == local variables ==
      INTEGER i1, j1, i2, j2
      INTEGER k, varType
      _RL ddx, ddy     

c     varIN   field from which to interpolate 
c     varOUT  varaible interpolated using bilinear scheme (1 value)
c     varType type of varible
c               0 = T or S (Tracer)
c               1 = uvel
c               2 = vvel

c     ddx  :: trailing decimals for x-direction
c     ddy  :: trailing decimals for y-direction
c     k       vertical level

      varOUT = 0.   ! clear any previous values

C--   find x-index according to grid-location of variable
      IF ( MOD(varType,2).EQ.0. ) THEN
        i1 = INT(ib_iT)
        ddx = ib_iT - DFLOAT(i1)
      ELSE
        i1 = NINT(ib_iT)
        ddx = 0.5 + ib_iT - DFLOAT(i1)
      ENDIF
C--   find y-index according to grid-location of variable
      IF ( MOD(varType,4).LE.1. ) THEN
        j1 = INT(ib_jT)
        ddy = ib_jT - DFLOAT(j1)
      ELSE
        j1 = NINT(ib_jT)
        ddy = 0.5 + ib_jT - DFLOAT(j1)
      ENDIF
C--  Find adjacent cell for interpolation
      i2 = i1 + 1
      j2 = j1 + 1

#ifdef ALLOW_EXCH2
      IF (i1.GE.510) i2 = i1 - 1  ! Stop issues with overlap when using cube-sphere 
      IF (j1.GE.510) j2 = j1 - 1
#endif

C--   Bilinear interpolation (Press et al. 2007)
        varOUT =   ( (1.-ddx)*(1.-ddy)*varIN(i1,j1,k,bi,bj)
     &             +     ddx * ddy    *varIN(i2,j2,k,bi,bj) )
     &           + (     ddx *(1.-ddy)*varIN(i2,j1,k,bi,bj)
     &             + (1.-ddx)* ddy    *varIN(i1,j2,k,bi,bj) )

      RETURN
      END

C -------------------------------------------------------------

      SUBROUTINE ICEBERG_INTERP_LINEAR_2D (
     I                                     ib_iT, ib_jT, varIN,
     O                                     varOUT,
     I                                     varType, 
     I                                     bi, bj, myThid )


C    Interpolating 2D field (SIheff etc)

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "GRID.h"
#include "PARAMS.h"
#include "DYNVARS.h"
#include "ICEBERG.h"
c#include "SEAICE.h"

C     == Routine arguments
      INTEGER i, j, bi, bj, myThid
      _RL varIN (1-OLx:sNx+OLx,1-OLy:sNy+OLy,nSx,nSy)
      _RL varOUT
      _RL ib_iT, ib_jT

C     == local variables ==
      INTEGER i1, j1, i2, j2
      INTEGER varType
      _RL ddx, ddy

C     == Definitions ==
c     varIN     variable field to interpolate from
c     varOUT    varaible interpolated using bilinear scheme (1 value)
c     ddx       trailing decimals for x-direction
c     ddy       trailing decimals for y-direction
c     varType type of varible
c               0 = SIarea or SIheff, TRACER
c               1 = SIUice
c               2 = SIVice
   
      varOUT = 0.   ! clear any previous values

C--   find x-index according to grid-location of variable
      IF ( MOD(varType,2).EQ.0 ) THEN
        i1 = INT(ib_iT)
        ddx = ib_iT - DFLOAT(i1)
      ELSE
        i1 = NINT(ib_iT)
        ddx = 0.5 _d 0 + ib_iT- DFLOAT(i1)
      ENDIF
C--   find y-index according to grid-location of variable
      IF ( MOD(varType,4).LE.1 ) THEN
        j1 = INT(ib_jT)
        ddy = ib_jT- DFLOAT(j1)
      ELSE
        j1 = NINT(ib_jT)
        ddy = 0.5 _d 0 + ib_jT - DFLOAT(j1)
      ENDIF
C--  Find adjacent cell for interpolation
      i2 = i1 + 1
      j2 = j1 + 1

      IF (i1.GE.510) i2 = i1 - 1  ! Stop issues with overlap when using cube-sphere 
      IF (j1.GE.510) j2 = j1 - 1

C--   Bilinear interpolation (Press et al. 2007)
        varOUT =   ( (1.-ddx)*(1.-ddy)*varIN(i1,j1,bi,bj)
     &             +     ddx * ddy    *varIN(i2,j2,bi,bj) )
     &           + (     ddx *(1.-ddy)*varIN(i2,j1,bi,bj)
     &             + (1.-ddx)* ddy    *varIN(i1,j2,bi,bj) )

      RETURN
      END
