C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_ROLL (
     I                          ib_n,       
     I                          myIter, myThid)

C     ==================================================================
c     MITberg V2.0 ICEBERG ROLL 
c     ==================================================================
C
C     o Roll icebergs that are unstable
C
C     ==================================================================

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "EESUPPORT.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"

C     routine arguements
      INTEGER ib_n
      INTEGER myThid
      INTEGER myIter

C     local arguements
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      _RL gamma
      _RL stability_criteria
      _RL tmp

#ifdef ALLOW_ICEBERG_TO_ROLL

C        Version 1 used the stability criteria from Weeks and Mellor 1978
C        stability_criteria = 0.7

C        Version 2 uses the stability criteria from Wagner et al 2017
         gamma = ib_rho/rho_w
         stability_criteria = (6*gamma*(1-gamma))**0.5

C Roll in the length direction first, if needed
       IF (ib_lth(ib_n)/ib_thk(ib_n).LT.stability_criteria) THEN
            tmp = ib_lth(ib_n)
            ib_lth(ib_n) = ib_thk(ib_n)
            ib_thk(ib_n) = tmp
       ENDIF   
       
C Then roll in the width direction, if needed
      IF (ib_wth(ib_n)/ib_thk(ib_n).LT.stability_criteria) THEN
            tmp = ib_wth(ib_n)
            ib_wth(ib_n) = ib_thk(ib_n)
            ib_thk(ib_n) = tmp
      ENDIF

C Finally, update the other iceberg dimensions
       ib_dft(ib_n) = (ib_rho/rho_w)*ib_thk(ib_n)   ! updated iceberg draft (m)
       ib_fbd(ib_n) = ib_thk(ib_n) - ib_dft(ib_n)   ! update freeboard (m)

CMW This was the previous code in version V1.0 when
C length was a function of thickness
C        weeks_stab = 0.7 
C        IF (ib_lth/ib_thk(ib_n).LT.weeks_stab) THEN
C         ib_thk(ib_n) = ib_lth
C         ib_lth = (ib_vol1/(ib_thk(ib_n)/ibLthWthRatio))**0.5
C         ib_wth(ib_n) = ib_lth/ibLthWthRatio
C         ib_dft = (ib_rho/rho_w)*ib_thk(ib_n)   ! updated iceberg draft (m)
C         ib_fbd = ib_thk(ib_n) - ib_dft         ! update freeboard (m)
C        ENDIF

#endif 


C-----------------------------------------------------------------------

      return
      
      END
 
