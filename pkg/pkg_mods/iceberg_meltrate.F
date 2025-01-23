C Note: MW copied this code from the iceplume package and modified for iceberg

      SUBROUTINE ICEBERG_MELTRATE(
     I           temperature, salinity, velocity, depth,
     O           meltrate )

      IMPLICIT NONE

C Global variables
#include "ICEBERG_OPTIONS.h"
#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "GRID.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"

C Local variables

      _RL temperature
      _RL salinity
      _RL velocity
      _RL meltrate
      _RL depth
      _RL absVelocity
      _RL a,b,c, tb, sb, mdot
      _RL secInday
      
      _RL lambda1
      _RL lambda2
      _RL lambda3
      _RL gamS
      _RL gamT
      _RL cd
      _RL iceTemp
      _RL c_i
      _RL ICEBERGlatentHeat
      _RL ICEBERGHeatCapacity_Cp

       secInday = 86400 . _d 0 

       lambda1= -0.0573D0
       lambda2= 0.0832D0
       lambda3= 0.000761D0
       GamT   = 0.022
       GamS   = 0.00062
       Cd     = 0.0025
       iceTemp  = 0.0
       c_i    = 2009.D0
       ICEBERGlatentHeat       =  334.0 _d 3

#ifdef ALLOW_ICEBERG

C Routine can't cope with zero velocity. Unlikely to occur anyway with currents,
C waves, convection etc. This isn't very physical, but will do for now.
      IF ( velocity .LT. submergedMeltBackgroundVelFloor )
     & velocity = submergedMeltBackgroundVelFloor

      absVelocity = abs(velocity)

C Calculate melt rate from 3 equation formualtion (as for plume models)

C     Equations for Sb, Tb and mdot

      a = lambda1*(GamT*HeatCapacity_Cp-GamS*c_i)

      b = GamS*c_i*(lambda1*salinity-lambda2-lambda3*depth+
     &         iceTemp-(ICEBERGlatentHeat/c_i))
     &        -GamT*HeatCapacity_Cp*(temperature-lambda2-lambda3*depth)

      c = GamS*salinity*(c_i*(lambda2+lambda3*depth-iceTemp)
     &       +ICEBERGlatentHeat)

      Sb   = (oneRL/(twoRL*a))*(-b-((b**twoRL-4.*a*c)**HalfRL)) !Sb
      Tb   = lambda1*Sb+lambda2+lambda3*depth !Tb
      mdot = GamS*(Cd**HalfRL)*absVelocity*(salinity-Sb)/Sb ! mdot

C mdot has been divided by density relative to Yun's eqs.
!       mdotcheck = (HeatCapacity_Cp*GamT*(Cd**HalfRL)*absVelocity*
!      &            (temperature-Tb)) / 
!      &            (ICEBERGlatentHeat + c_i*(iceTemp-Tb))
!       PRINT *, mdot, mdotcheck

C Meltrate is in m d^-1
C       meltrate = secInday*mdot

C Meltrate is in m s^-1
      meltrate = mdot

#endif /* ALLOW_ICEBERG */

      RETURN
      END
