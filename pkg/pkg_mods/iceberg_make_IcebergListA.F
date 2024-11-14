c
#include "ICEBERG_OPTIONS.h"

      SUBROUTINE ICEBERG_CREATE_LISTA( myThid  )

C     ==================================================================
C     MITberg V1.0 ICEBERG_CREATE_LISTA
C     ==================================================================
C
C     o Reads iceberg size distribution (from file). 
C
C     o Reads iceberg calving locations (from file)
C
C     o Creates IcebergListA, a table of the volume of ice to calve at 
C      each calving margin each yera, the number of icebergs of each size 
C      catagory to calve and the total number of icebergs at each calving
C      margin to release each year. 
C
C     o This subroutine is only called when either:
C       i) The model starts from intial conditions (niter = 0 )
C       ii) 1 year has passed 
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
      CHARACTER ib_name*25
      CHARACTER*(MAX_LEN_MBUF) msgBuf
      INTEGER iUnit, aop, reason
      INTEGER ib_n, n
      INTEGER nn
      _RL ib_num_tmp, sum_tmp
      INTEGER iii, iflag2
      _RL TmpIceVol(10,1)
      INTEGER fixice      
      _RL IceFracLiqLoc
      _RL gg

C
C--   Load iceberg size catagory table (based on data of Bigg et al. 1997)
C
C     10 rows x 4 columns (10,4)
C     |  calving size | icebergs in size cat (%) | width | thk |
C     There are 10 size catagories

       WRITE(msgBuf,'(A)') 'ICEBERG: READING Iceberg Size File'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       
C      User can define iceberg size distribution, otherwise 
C      the model will look for iceberg_size_dist.txt
       IF (IcebergSizeFile .EQ. ' ') THEN
        OPEN(223, file='iceberg_size_dist.txt', STATUS = 'OLD')
       ELSE
        OPEN(223, file=IcebergSizeFile, STATUS = 'OLD')
       ENDIF

       DO n = 1,10
        READ(223,'(F4.1, F9.1, F11.1, F11.1)'),
     &  IcebergSizeTable(n,1),
     &  IcebergSizeTable(n,2),
     &  IcebergSizeTable(n,3),
     &  IcebergSizeTable(n,4)
       ENDDO
       CLOSE (223)

         WRITE(msgBuf,'(2A)')
     &     'ICEBERG: Finished reading: ', IcebergSizeFile
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      WRITE(msgBuf,'(A)')
     &      '------ SUMMARY OF IcebergSizeFile ------'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      DO n=1,10
       WRITE(msgBuf,'(F4.1, F9.1, F11.1, F11.1)'),
     &  IcebergSizeTable(n,1),
     &  IcebergSizeTable(n,2),
     &  IcebergSizeTable(n,3),
     &  IcebergSizeTable(n,4)
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDDO

       _BARRIER
C
C--   READ INITIAL ICEBERG CALVING LOCATIONS (NOT ICEBERG PICKUP)
C
#ifdef USE_POLLARD_ICE_FLUX
      WRITE(msgBuf,'(A)') '****************************************'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)') 'ICEBERG: Using Pollard Ice Sheet discharge'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif

       IF (CalvingFile .EQ. ' ') THEN
        WRITE(msgBuf,'(A)') 
     &   'ICEBERG: No CalvingFile provided... STOPPING'
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        STOP
       ENDIF

       aop=1
       WRITE(msgBuf,'(2A)') 'ICEBERG: Reading ', CalvingFile
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

       OPEN(223, file=CalvingFile, STATUS = 'OLD')
       nn=1 ! Set counter to 1
       aop = 1
       DO WHILE (aop.EQ.1)
        READ(223,'(F6.1, F7.1, F7.1, I4, F13.4)', IOSTAT=reason), 
     &  CalvingLocations (nn,1), ! tag source of iceberg
     &  CalvingLocations (nn,2),
     &  CalvingLocations (nn,3),
     &  ibCalvingFace (nn),    ! For cube-sphere (1-6)
     &  CalvingLocations(nn,4) ! discharge from each glacier
C     Note that discharge from glacier is a fraction(%)
C     the total ice volume
C     In the scheme "POLLARD" the numbers read in are actual ice fluxes
C     in m3/s. These are then convered to m3/yr and the TotIceVol calculated
        IF (reason > 0)  THEN
         WRITE(msgBuf,'(2A)') 'reason>0: could not read iceberg
     &                         location file ... something wrong'
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         STOP
        ELSEIF (reason < 0) THEN
         WRITE(msgBuf,'(2A)') 
     &     'ICEBERG: Finished reading: ', CalvingFile
         CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         aop=2
        ELSE
         nn = nn + 1
        ENDIF
       ENDDO
       CLOSE (223)

#ifdef USE_POLLARD_ICE_FLUX
C  In this scheme the numbers read into CalvingLocations(nn,4) are 
C  initially the actual ice fluxes (in m3/s). They are convered to a percent
c  of the TotIceVol and then TotIceVol is converted from m3/s to m3/yr

      TotIceVol = sum(CalvingLocations(:,4)) 

      DO n = 1,NumCalvingLoc
       CalvingLocations(n,4) = CalvingLocations(n,4) / TotIceVol
      ENDDO

      TotIceVol = TotIceVol * 60.0*60.0*24.0*365.25 ! m3/s -> m3/yr

      WRITE(msgBuf,'(A, E20.3)')
     &       'ICEBERG: TotIceVol (m3/yr): ',  TotIceVol
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      WRITE(msgBuf,'(A)') '--------- Summary of ice flux data --------'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

      DO n=1,NumCalvingLoc
       WRITE(msgBuf,'(F6.1, F7.1, F7.1, F15.5)'),
     &  CalvingLocations (n,1), ! tag source of iceberg
     &  CalvingLocations (n,2),
     &  CalvingLocations (n,3),
     &  CalvingLocations(n,4) ! Percent discharge from each glacier
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                           SQUEEZE_RIGHT, myThid )
      ENDDO

      WRITE(msgBuf,'(A)') '****************************************'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
#endif
      _BARRIER

C    CREATE ORGINAL IcebergListA 
C    max. number of calving locations  = 50
C    Strucutre :  13 x numCalveLoc + 1 
C                 final column is ib_scale
C
C      COLUMN N=1  (glacier 1)                       COL N+1   COL.(NumCalveLoc+1)
C      | 1 | tot ice vol drained by glacier (km3/yr)      |           0  
C      | 2 | num bergs (size cat. 1)                      |        ib_scale
C     \|/ \|/
C      |11 | num bergs (size cat 10)                      |        ib_scale
C      |12 | Tot num of bergs to calve (sum 2-11)         |           0
C      |13 | Iceberg calving freq. (seconds)              |           0

       WRITE(msgBuf,'(A)') 'ICEBERG: CREATING IcebergListA'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

       IcebergListA (:,:) = 0. _d 0
C      Now set final column to "ib_scale". default is 1 (i.e 1 model iceberg
C      equals 1 actual iceberg).
       IcebergListA (:,NumCalvingLoc+1) = 1. 

       IF (IceInc.GT.0.0.AND.niter0.NE.0) THEN 
C       Calc. total volume ice to release (m3/yr-1) 
        TotIceVol = TotIceVol + IceInc 
        WRITE(msgBuf,'(A, E20.5)')
     &       'ICEBERG: Total ice discharge (m3/yr): ', TotIceVol
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, E20.5)') 
     &  'ICEBERG: Ice discharge increase rate (m3.yr-2)[IceInc] ',IceInc
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
        WRITE(msgBuf,'(A, E20.5)')     
     &  'ICEBERG: IceIncTot ' , IceIncTot
        CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
       ENDIF

       IF (IceFracLiq.LT.0.0.OR.IceFracLiq.GT.1.0) THEN
        WRITE(msgBuf,'(A, F11.1)'),
     &  'Warning: IceFracLiq is out of range.... STOPPING!',
     &  IceFracLiq
        CALL PRINT_ERROR( msgBuf , myThid)
        STOP
       ENDIF

       IF (IceFracLiq.EQ.1.0) THEN
C       If FracLiq = 1 then there are no calved icebergs (100% runoff at glacier)
C       However, for this to work the model needs to think there are icebergs!
        IceFracLiqLoc = 0. _d 0 
       ELSE
        IceFracLiqLoc = IceFracLiq
       ENDIF

       DO n = 1,NumCalvingLoc
C      Calculate volume of ice (as icebergs) to calve at each calving margin
C      Note: IceFracLiq scales the total volume of ice to allow meltwater
C      release at cavling margins to be both liquid and icebergs
C      (units are km3.yr-1). IceFracLiqLoc is a local copy of IceFracLiq

        IcebergListA (1,n) = TotIceVol * (1.-IceFracLiqLoc) 
     &                                 * 1e-9 * CalvingLocations(n,4)

C--     Determine number of icebergs to calve from each of the 10 size class
C       (iterative method)
        iflag2 = 0
        DO iii = 100000,1,-1  ! Assume upto 100000 icebergs can be calved at each site
         IF (iflag2.EQ.0) THEN
          DO nn = 1,10
           IcebergListA (nn+1,n) = (IcebergSizeTable(nn,2)/100.)       ! Frac. of total at size
     &                          * iii                                  ! guess iceberg no. 
     &                          * (IcebergSizeTable(nn,3)              ! width 
     &                          * IcebergSizeTable(nn,3)*ibLthWthRatio ! length
     &                          * IcebergSizeTable(nn,4))              ! thickness
          ENDDO
          sum_tmp = SUM(IcebergListA (2:11,n)) 
          IF (sum_tmp.LT.IcebergListA (1,n)*1e9) THEN
           iflag2 = 1
           ib_num_tmp = REAL(iii + 1)   ! We have found the correct number of icebergs
           IF (ib_num_tmp.GE.100000) THEN
            WRITE(msgBuf,'(A, F11.1, F11.1, F11.1)'),
     &      'Warning: Number of icebergs not correct...STOPPING!',
     &      ib_num_tmp, 
     &      sum_tmp,
     &      IcebergListA (1,n)*1e9
            CALL PRINT_ERROR( msgBuf , myThid)
            STOP
           ENDIF
          ENDIF  
         ENDIF 
        ENDDO 

C--     Now populate IcebergListA with actual iceberg values
        DO nn = 1,10
         IcebergListA (nn+1,n) = CEILING (ib_num_tmp 
     &                             * (IcebergSizeTable(nn,2)/100.))
         
#ifdef GROUP_SMALL_ICEBERGS
C--  Group smaller icebergs as one iceberg, based on IcebergGroup (10,1)
C    This avoids having to simulate 100000s of individual icebergs 
C    IcebergGroup is set in data.iceberg
         IcebergListA(nn+1,n) = CEILING (IcebergListA (nn+1,n) / 
     &                                        IcebergGroup (nn))
C     Alter to get correct ice
         IcebergListA(nn+1,NumCalvingLoc+1) = IcebergGroup (nn)
#else 
         IcebergListA(nn+1,NumCalvingLoc+1) = 1.0
#endif
        ENDDO
        IcebergListA (12,n) = SUM (IcebergListA (2:11,n))   ! Tot no. bergs to calve
                                                            !  (per year)     
        IcebergListA (13,n) = CEILING (TotCalvePeriod       ! Calving interval
     &                        / SUM (IcebergListA (2:11,n)))! (seconds)
       ENDDO  ! /* NumCalvingLoc */
  
C   Double check ice volume being released is correct, if not STOP
       DO fixice=1,6  ! There are 5 attempts to fix
        DO nn=1,10
         TmpIceVol(nn,1)= SUM(IcebergListA (nn+1,1:NumCalvingLoc))
         TmpIceVol(nn,1) = TmpIceVol(nn,1) * IcebergGroup (nn)
         TmpIceVol(nn,1) = TmpIceVol(nn,1) * (IcebergSizeTable(nn,3)   ! width
     &                          * IcebergSizeTable(nn,3)*ibLthWthRatio ! length
     &                          * IcebergSizeTable(nn,4))              ! Thick
        ENDDO

        IF (sum(TmpIceVol)/(TotIceVol
     &         *(1.-IceFracLiqLoc)).LT.0.98) THEN
         DO n=1,NumCalvingLoc
          IcebergListA (11,n) = IcebergListA(11,n) + 1
          IF (IcebergListA (11,n).LE.0) IcebergListA (11,n) = 0
          IcebergListA (12,n) = SUM (IcebergListA (2:11,n))   ! Tot no. bergs to calve
          IcebergListA (13,n) = CEILING (TotCalvePeriod       ! Calving interval
     &                          / SUM (IcebergListA (2:11,n)))! (seconds)
         ENDDO
         IF (fixice.EQ.6) THEN
          WRITE(msgBuf,'(A)')
     &    'ICEBERG: STOP: Total ice volume calved is too small!'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
          WRITE(msgBuf,'(A, E20.3, A, E20.3)')
     &     'TmpIceVol=', sum(TmpIceVol), 'TotIceVol=', TotIceVol 
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
         
          STOP
         ENDIF

        ELSEIF (sum(TmpIceVol)/(TotIceVol
     &             *(1.-IceFracLiqLoc)).GT.1.1) THEN
         DO n=1,NumCalvingLoc
          IcebergListA (11,n) = IcebergListA(11,n) - 1
          IF (IcebergListA (11,n).LE.0) IcebergListA (11,n) = 0
          IcebergListA (12,n) = SUM (IcebergListA (2:11,n))   ! Tot no. bergs to calve
          IcebergListA (13,n) = CEILING (TotCalvePeriod       ! Calving interval
     &                          / SUM (IcebergListA (2:11,n)))! (seconds)
         ENDDO
         IF (fixice.EQ.6) THEN
          WRITE(msgBuf,'(A)') 
     &    'Total ice volume = too large (after 5 attempts) - STOPPING!'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
          WRITE(msgBuf,'(A, E20.3, A, E20.3)')
     &     'TmpIceVol=', sum(TmpIceVol), 'TotIceVol=', TotIceVol
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
          STOP
         ENDIF

        ELSE


         IF (fixice.EQ.6) THEN 
          WRITE(msgBuf,'(A)') '-----------------------'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
          WRITE(msgBuf,'(A, E20.3)') 
     &       'ICEBERG: volume to calve is correct: ',  sum(TmpIceVol)
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
          WRITE(msgBuf,'(A)') '-----------------------'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

         ENDIF

        ENDIF

       ENDDO

C    Make a copy of IcebergListA to be used after calving has cycled 
C    through 1 year
       IcebergListA_org = IcebergListA
       WRITE(msgBuf,'(A)') 'ICEBERG: Successfully made IcebergListA'
       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C    Print a copy of IcebergListA to STDOUT
c     WRITE(msgBuf,'(A)') '--------- Summary of IcebergistA ---------'
c          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
c     &                    SQUEEZE_RIGHT, myThid )

c      gg=NumCalvingLoc+1
c      DO nn=1,13
c       WRITE(msgBuf,'(ggF5.1)') IcebergListA (nn,1:gg)
c       CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
c     &                           SQUEEZE_RIGHT, myThid )
c      ENDDO

      DO n=1,NumCalvingLoc
       IF (IcebergListA (12,n).LT.1) THEN
        WRITE(msgBuf,'(A, I5)'),
     &  'Warning: There are no icebergs to release at calving site ', n
        CALL PRINT_ERROR( msgBuf , myThid)
        STOP
       ENDIF
      ENDDO

      WRITE(msgBuf,'(A)') '--------- End of IcebergistA ---------'
          CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )

C ---------------------------------------------------------------------
C MWPRINT
      WRITE(msgBuf,'(A)') '-----------------------' 
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A)')
     &      'MWPRINT: IcebergListA'
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      DO n=1,NumCalvingLoc
      WRITE(msgBuf,'(F8.1, F8.1, F8.1, F8.1, F8.1, F8.1, F8.1)'),
     &   IcebergListA (1,n), IcebergListA (2,n), IcebergListA (3,n),
     &   IcebergListA (4,n), IcebergListA (5,n), IcebergListA (6,n),
     &   IcebergListA (7,n)
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      WRITE(msgBuf,'(A, F8.1, F8.1, F8.1, F8.1, F8.1, F8.1)'),
     &   '       ', IcebergListA (8,n), IcebergListA (9,n),
     &   IcebergListA (10,n), IcebergListA (11,n), 
     &   IcebergListA (12,n), IcebergListA (13,n)
      CALL PRINT_MESSAGE( msgBuf, standardMessageUnit,
     &                    SQUEEZE_RIGHT, myThid )
      ENDDO

      RETURN
      END
