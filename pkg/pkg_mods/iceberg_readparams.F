C
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_READPARMS( myThid  )
C
C     ==================================================================
C     MITberg V1.0 ICEBERG_READPARMS
C     ==================================================================
C
C     o  Set default values for NAMELIST ICEBERG_PARM01
C
C     o  Read info from data.iceberg
C
C     ==================================================================

      IMPLICIT NONE

#include "SIZE.h"
#include "EEPARAMS.h"
#include "PARAMS.h"
#include "ICEBERG_SIZE.h"
#include "ICEBERG_PARAMS.h"
#include "GRID.h"
#include "FFIELDS.h"
#include "DYNVARS.h"

c     routine arguements
      INTEGER myThid
      INTEGER i, j, k, bi, bj

C     Local arguements
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit, aop, reason
      INTEGER ioUnit
      INTEGER n
      INTEGER tmpTime
      _RL ib_V(100)
      INTEGER nn
      _RL IcebergListA_pickup (15,51)
      _RL ib_num_tmp, sum_tmp
      INTEGER iii, iflag2
      _RL TmpIceVol(10,1)
      
      NAMELIST /ICEBERG_PARM01/ 
     &  ib_write_freq,
     &  ib_Tice,
     &  max_no_bergs,
     &  ib_rho,
     &  rho_w,
     &  rho_a,
     &  rho_si,
     &  ibLthWthRatio,
     &  Cwv,
     &  Cav,
     &  Civ,
     &  Cwh,
     &  Cah,
     &  deltaT_ice,
     &  ibMeltT,
     &  ibMeltS,
     &  min_size,
     &  TotIceVol,
     &  IceInc,
     &  IcebergGroup,
     &  CalvingFile,
     &  IcebergSizeFile,
     &  IcebergLocationFile, 
     &  useIcebergPickup,
     &  IDoffset,
     &  ibMaxV,
     &  IcebergTaveFreq,
     &  IbBounceCoast,
     &  ScourDepth,  
     &  submergedMeltBackgroundVelFloor,
     &  ib_debug_level

       NAMELIST /ICEBERG_PARM02/
     &   MwScale,
     &   ibuWindScale,
     &   ibvWindScale,   
     &   ibTairScale,
     &   ibTwaterScale,
     &   ibMaxWind, 
     &   ibFreshwaterScale

      NAMELIST /ICEBERG_DIAGS/
     &   ib_iceberg_filename,
     &   ib_melt_profile_filename,
     &   ib_solar_melt_filename,
     &   ib_atm_melt_filename,
     &   ib_wave_melt_filename,
     &   ib_melt_profile_period,
     &   ib_solar_melt_period,
     &   ib_atm_melt_period,
     &   ib_wave_melt_period

C     == end of interface ==

      _BEGIN_MASTER(myThid)

C     Set default values for NAMELIST ICEBERG_PARM01
      ib_write_freq   = 86400.
      ib_Tice         =  -4.
      max_no_bergs    = 20.
      ib_rho          = 910.
      rho_w           = 1025.
      rho_a           = 1.25
      rho_si          = 910.
      ibLthWthRatio   = 1.62
      Cwv             = 1.0
      Cav             = 0.5
      Civ             = 1.0
      Cwh             = 0.0012
      Cah             = 0.0055
      deltaT_ice      = 10
      ibMeltT         = 0. _d 0
      ibMeltS         = 0. _d 0
      min_size        = 1.
      TotIceVol       = 0. _d 0
      IceInc          = 0. _d 0
      IceIncTot       = 0. _d 0 
      IcebergGroup(:) = 1.
      CalvingFile     = ' '
      IcebergLocationFile = ' '
      IcebergSizeFile = ' '
      IDoffset        = 0
      ibMaxV          = 5.
      ib_V(:)         = 0. _d 0
      IcebergTaveFreq = 0. _d 0
      ibBounceCoast   = 0
      TairIncRate     = 0. _d 0
      ScourDepth      = 0. _d 0
      submergedMeltBackgroundVelFloor = 0.001
      useIcebergPickup = .FALSE.
      ib_debug_level  = 1


C     Defaults for namelist ICEBERG_PARM02
      MwScale           = 1.
      ibuWindScale      = 1.
      ibvWindScale      = 1.
      ibTairScale       = 0. _d 0
      ibTwaterScale     = 0. _d 0
      ibMaxWind         = 50.
      ibFreshwaterScale = 1.

C     Defaults for namelist ICEBERG_DIAGS
      ib_iceberg_filename = ' '
      ib_melt_profile_filename = ' '
      ib_solar_melt_filename = ' '
      ib_atm_melt_filename = ' '
      ib_melt_profile_period = 0.0
      ib_solar_melt_period = 0.0
      ib_atm_melt_period = 0.0
      

C     Other defaults
      reason                = 0  


C
C--  Read data.iceberg
C
      WRITE(msgBuf,'(A)') 
     &  'ICEBERG: reading data.iceberg'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      CALL OPEN_COPY_DATA_FILE(
     I                          'data.iceberg', 'ICEBERG_READPARMS',
     O                          iUnit,
     I                          myThid )

      READ(UNIT=iUnit,NML=ICEBERG_PARM01)
      WRITE(msgBuf,'(A)')
     &     'ICEBERG:finished reading ICEBERG_PARM01'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      
C----
 
      WRITE(msgBuf,'(A)'), 'ICEBERG: Summary of parameters selected:'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, F11.1)'), 'rho_w ', rho_w
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'rho_a ', rho_a
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'rho_si ', rho_si
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'Cav ', Cav
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'Civ ', Civ
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'Cwh ', Cwh
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'Cah ', Cah
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F8.1)'), 'deltaT_ice ', deltaT_ice
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'ibMeltT ', ibMeltT
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'ibMeltS ', ibMeltS
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, E20.3)'), 'IceInc ', IceInc
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, I5)'), 'Num. calving loc', CALVE_LOCS
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, I8)'), 'IDoffset ', IDoffset
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'Max iceberg velocity ',  ibMaxV
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, F11.1)'), 'ibLthWthRatio ', ibLthWthRatio
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(A, I5)'), 'Deflect from coasts ', ibBounceCoast
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
#ifdef ALLOW_ICEBERG_CALVING
      WRITE(msgBuf,'(2A)'), 'Iceberg calving file ',CalvingFile
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
#else
      WRITE(msgBuf,'(2A)'), 'Iceberg Location File ',IcebergLocationFile
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
      WRITE(msgBuf,'(2A)'), 'Iceberg Size File ',IcebergSizeFile
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)
#endif
      WRITE(msgBuf,'(A, F12.3)'), 'ScourDepth ', ScourDepth
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

 
      READ(UNIT=iUnit,NML=ICEBERG_PARM02)
      WRITE(msgBuf,'(A)')
     &     'ICEBERG: finished reading ICEBERG_PARM02'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      READ(UNIT=iUnit,NML=ICEBERG_DIAGS)
      
      WRITE(msgBuf,'(A)')
     &     'ICEBERG:finished reading ICEBERG_DIAGS'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, A)'), 'ib_iceberg_filename ', 
     &  trim(ib_iceberg_filename) 
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, A)'), 'ib_melt_profile_filename ', 
     &  trim(ib_melt_profile_filename) 
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, F11.1)'), 'ib_melt_profile_period ', 
     &  ib_melt_profile_period
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, A)'), 'ib_solar_melt_filename ', 
     &  trim(ib_solar_melt_filename) 
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, F11.1)'), 'ib_solar_melt_period ', 
     &  ib_solar_melt_period
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, A)'), 'ib_atm_melt_filename ', 
     &  trim(ib_atm_melt_filename) 
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, F11.1)'), 'ib_atm_melt_period ', 
     &  ib_atm_melt_period
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, A)'), 'ib_wave_melt_filename ', 
     &  trim(ib_wave_melt_filename) 
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      WRITE(msgBuf,'(A, F11.1)'), 'ib_wave_melt_period ', 
     &  ib_wave_melt_period
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT , myThid)

      CLOSE(iUnit)


C ---------------------------------------------------------------------

      _END_MASTER(myThid)

C--   Everyone else must wait for the parameters to be loaded
      _BARRIER

      RETURN
      END
