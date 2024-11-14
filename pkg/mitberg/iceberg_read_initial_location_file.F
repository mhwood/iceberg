c
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_READ_INITIAL_lOCATION_FILE ( myThid  )

C     ==================================================================
C     MITberg V1.0 READ INITIAL ICEBERG LOCATIONS FROM FILE
C     ==================================================================
C
C     o If niter0 = 0 and filename is given for 'IcebergLocationFile' 
C       then read in the position, size and velocity of known icebergs
C
C     o File strucutre should be:
C        ID | face | i | j | width | thk | u-vel | v-vel
C
C     ==================================================================

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "ICEBERG.h"
#include "ICEBERG_PARAMS.h"
#include "GRID.h"
#include "FFIELDS.h"
#include "DYNVARS.h"

c     routine arguements
      INTEGER myThid

C     Local arguements
      CHARACTER mystring*10
      CHARACTER ib_name*30
      CHARACTER ib_name2*30
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER aop, reason
      INTEGER n
      INTEGER mUnit
 
      _BEGIN_MASTER(myThid)

C    Read initial iceberg locations from file
      WRITE(msgBuf,'(2A)') 'ICEBERG: Reading initial iceberg 
     & locations from file: ', IcebergLocationFile
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      CALL MDSFINDUNIT( mUnit, myThid )
      OPEN( mUnit, file=IcebergLocationFile, STATUS = 'OLD')
      n = 1 ! Set iceberg counter to 1
      aop = 1
      DO WHILE (aop.EQ.1)
       READ ( mUnit,'(I6, I3, 6F9.2)', IOSTAT = reason),
     &  ib_id(n), ib_face(n), 
     &  ib_i(n), ib_j(n), 
     &  ib_wth(n), ib_thk(n),
     &  ib_uVel(n), ib_vVel(n)
       ib_scale(n) = 1  ! Set iceberg scaling to 1
       IF (reason > 0)  THEN
        WRITE(msgBuf,'(A)') 'ERROR: IcebergLocationFile does not exist'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                             SQUEEZE_RIGHT, myThid )
        STOP
       ELSEIF (reason < 0) THEN
        WRITE(msgBuf,'(2A)') 
     &  'ICEBERG: FINISHED READING: ', IcebergLocationFile
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                             SQUEEZE_RIGHT, myThid )
        aop=2
       ELSE
        n = n+1
       ENDIF
      ENDDO
      CLOSE ( mUnit )
      _BARRIER

      ib_Tot = n-1    ! TOTAL NUMBER OF ICEBERGS
      WRITE(msgBuf,'(A, I7)') 'ICEBERG: TOTAL NUMBER ICEBERGS: ',ib_Tot
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )

C     Write summary of data loaded to STDOUT
      WRITE(msgBuf,'(A, I7)') '------ SUMMARY OF ICEBERG DATA ------'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      DO n=1,ib_Tot
       WRITE(msgBuf,'(I6, I3, 6F9.2)')
     &   ib_id(n), ib_face(n),
     &   ib_i(n), ib_j(n),
     &   ib_wth(n), ib_thk(n),
     &   ib_uVel(n), ib_vVel(n)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDDO
      WRITE(msgBuf,'(A)') '------ END ICEBERG SUMMARY ------'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )

#ifndef ALLOW_ICEBERG_CALVING
      IF (IcebergLocationFile.EQ.' ') THEN
       WRITE(msgBuf,'(A)')
     & 'ICEBERG: No IcebergLocationFile found and 
     &  iceberg calving is turned off. NO icebergs will be 
     &  simulated in the model... STOPPING!'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      STOP
      ENDIF
#endif

      _END_MASTER(myThid)
C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

      RETURN
      END
