C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_EXCHANGE_FACE ( myThid )

C     ==================================================================
c     MITberg V1.0 ICEBERG EXCHANGE FACE
c     ==================================================================
C
C     o Exchange iceberg information between cube-sphere faces (CS510)
C       grid configuration
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

C     Routine arguements
      INTEGER myThid
      _RL ib_i_org
      _RL ib_uvel_org, ib_vvel_org

C     Local arguments
      INTEGER ib_n
      CHARACTER*(MAX_LEN_MBUF) msgBuf



      IF (ib_Tot.GT.0) THEN
#ifdef ICEBERG_DIAG_ON      
       WRITE(msgBuf,'(A)') 'ICEBERG EXCHANGE FACE CALLED'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

       DO ib_n=1,ib_Tot

        ib_uvel_org = ib_uVel(ib_n)
        ib_vvel_org = ib_vVel(ib_n)

C
C ---- FACE 1 ----
C
C Face 1 --> Face 3 (Atlantic east to Arctic)
        IF (ib_j(ib_n).GT.510.0.AND.ib_face(ib_n).EQ.1) THEN
         ib_face(ib_n) = 3
         ib_i_org = ib_i(ib_n)
         ib_i(ib_n) = ABS(510. - ib_j(ib_n)) + 1.
         ib_j(ib_n) = 510. - ib_i_org

         ib_uVel(ib_n) = ib_vVel(ib_n)
         ib_vVel(ib_n) = ib_uvel_org * (-1.0)
        ENDIF

C Face 1 --> Face 5 (Atlantic East to Atlantic West)
        IF (ib_i(ib_n).LT.1.0.AND.ib_face(ib_n).EQ.1) THEN
         ib_face(ib_n) = 5
         ib_i_org = ib_i(ib_n)
         ib_i(ib_n) = 510. - ib_j(ib_n)
         ib_j(ib_n) = 510. - ABS(1. - ib_i_org)

         ib_uVel(ib_n) = ib_vVel(ib_n) * (-1.0)
         ib_vVel(ib_n) = ib_uvel_org
        ENDIF

C
C ---- FACE 3 ----
C
C Face 3 --> Face 1 (Arctic to Atlantic East)
        IF (ib_i(ib_n).LT.1.0.AND.ib_face(ib_n).EQ.3) THEN
         PRINT*, 'face exchange 3 --> 1', ib_n
         ib_face(ib_n) = 1
         ib_i_org = ib_i(ib_n)
         ib_i(ib_n) = 510. - ib_j(ib_n)
         ib_j(ib_n) = 510. - ABS(1. - ib_i_org)

         ib_uVel(ib_n) = ib_vVel(ib_n) * (-1.0)
         ib_vVel(ib_n) = ib_uvel_org
        ENDIF

c face 3 to face 4 (pacific ocean)
C   INCOMPLETE

C Face 3 --> Face 5 (Arctic to Atlantic West)
        IF (ib_j(ib_n).GT.510..AND.ib_face(ib_n).EQ.3) THEN
         PRINT*, 'face exchange 3 --> 5', ib_n
         ib_face(ib_n) = 5
         ib_i_org = ib_i(ib_n)
         ib_i(ib_n) = ABS(510. - ib_j(ib_n)) + 1.
         ib_j(ib_n) = 510. - ib_i_org

         ib_uVel(ib_n) = ib_vVel(ib_n)
         ib_vVel(ib_n) = ib_uvel_org * (-1.0)
        ENDIF

C
C ---- FACE 5 ----
C
C Face 5 --> Face 1 (Atlantic West to Atlantic East)
        IF (ib_j(ib_n).GT.510.0.AND.ib_face(ib_n).EQ.5) THEN
         PRINT*, 'face exchange 5 --> 1', ib_n
         ib_face(ib_n) = 1
         ib_i_org = ib_i(ib_n)
         ib_i(ib_n) = ABS(510. - ib_j(ib_n)) + 1.
         ib_j(ib_n) = 510. - ib_i_org

         ib_uVel(ib_n) = ib_vVel(ib_n)
         ib_vVel(ib_n) = ib_uvel_org * (-1.0)
        ENDIF

C Face 5 --> Face 3 (Arctic to Atlantic West)
        IF (ib_i(ib_n).LT.1.0.AND.ib_face(ib_n).EQ.5) THEN
         PRINT*, 'face exchange 5 --> 3', ib_n
         ib_face(ib_n) = 3
         ib_i_org = ib_i(ib_n)
         ib_i(ib_n) = 510. - ib_j(ib_n)
         ib_j(ib_n) = 510. - ABS(1. - ib_i_org)

         ib_uVel(ib_n) = ib_vVel(ib_n) * (-1.0)
         ib_vVel(ib_n) = ib_uvel_org
        ENDIF


      ENDDO
C------------------------------------------------------------
C------------------------------------------------------------

      ENDIF  ! ib_Tot > 0


      RETURN
      END

