C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_COASTLINE (
     I                              ib_iT, ib_jT, ib_n, ib_R_low,
     O                              varOUTu, varOUTv, collide,
     I                              bi, bj, myThid )

C     =================================================================
C     MITberg V1.0 ICEBERG COASTLINE COLLISION
C     =================================================================
C
C     o  If adjacent cell to iceberg is land then icebergs can only
C        move parallel (or away) from the coastline.
C
C     o  The following index points are used
C
C                i1,j2
C        i0,j1 | i1,j1 | i2,j1
C                i1,j0
C
C     o  For example, if iceberg is moving towards i1,j2 and i1,j2 is 
C        land then ib_vVel will be set to zero to stop it getting 
C        closer to the land. 
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

C     Routine arguements
      INTEGER bi, bj, myThid
      INTEGER ib_n 
      _RL ib_iT
      _RL ib_jT
      _RL ib_R_low
  
C     Local arguments
      _RL varOUTu
      _RL varOUTv
      INTEGER collide
      INTEGER i1, j1, i0, j0, i2, j2
 
C     varOUTu and varOUTv used to set advection force to 0
C     if land is found in adjacent grid cell

c      Print*, 'ICEBERG COLLISION CALLED'

      i1 = INT(ib_iT)
      j1 = INT(ib_jT)
      i0 = i1-1
      i2 = i1+1
      j0 = j1-1
      j2 = j1+1

      collide = 0  ! Flag for collision  1=land 

C     Iceberg moving North and land to North -> stop northward movement 
      IF (ib_dft(ib_n).GE.ABS(R_low(i1,j2,bi,bj))
     &    .AND.ib_vVel(ib_n).GT.0.) THEN
       ib_vVel (ib_n) = 0.
       varOUTv = 0. 
       collide = 1
      ENDIF

C     Iceberg moving East
      IF (ib_dft(ib_n).GE.ABS(R_low(i2,j1,bi,bj))
     &   .AND.ib_uVel(ib_n).GT.0.) THEN
       ib_uVel (ib_n) = 0.
       varOUTu = 0.
       collide = 1
      ENDIF

C     Iceberg moving South
      IF (ib_dft(ib_n).GE.ABS(R_low(i1,j0,bi,bj))
     &   .AND.ib_vVel(ib_n).LT.0.) THEN
       ib_vVel (ib_n) = 0.
       varOUTv = 0.
       collide = 1
      ENDIF

C     Iceberg moving West
      IF (ib_dft(ib_n).GE.ABS(R_low(i0,j1,bi,bj))
     & .AND.ib_uVel(ib_n).LT.0.) THEN
       ib_uVel (ib_n) = 0.
       varOUTu = 0.
       collide = 1
      ENDIF
      
      RETURN
      END
