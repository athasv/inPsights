
c this "module" is only an interface module, a collection of
c routines related to the jastrow term,
c that delegates calls to the appropriate implementations
c according to "jastype". AL, 3/2004

c $Id: jastrow_m.f,v 1.1.1.1 2007/04/25 13:42:20 luechow Exp $

c $Log: jastrow_m.f,v $
c Revision 1.1.1.1  2007/04/25 13:42:20  luechow
c QMC program amolqc. rewritten in 2006. AL
c
c Revision 1.3  2005/03/11 13:33:12  luechow
c adding 'linscal' routines using sparse matrix algorithms with umfpack lib
c
c Revision 1.1  2005/02/16 12:42:49  luechow
c new generic Jastrow module allowing to select specific Jastrow implementations
c using new parameter 'jastype'
c

c TODO:
c jastype should be moved here!
c try removing references to modules params and wf

      MODULE jastrow

      use wfdata
      use jastrowSM
      use jastrowDTN
      use jastrowIC
      use Utils, only: readFileParallel
      !use JASTROW_SM_PERFORMANCE_ALL
      use RdataUpdateModule

      implicit none
      private

      integer :: mJasInitMode = 0

      public :: jasinput, jasoutput, jas_shortoutput, jasChangeType, jasCalcWDerivs,
     .          jasCalc, jasCalcInit, jasCalcUpdate, getJastrowParamCnt, getJastrowParamVector,
     .          putJastrowParamVector,jasCalcWithUk, jasSetInitMode, jasInitMode,
     .          jasCalcInitWithUk, jasCalcUpdateWithUk

      CONTAINS

c=======================================================================


      subroutine jasSetInitMode(i)
         integer, intent(in) :: i
         mJasInitMode = i
      end subroutine jasSetInitMode


      integer function jasInitMode()
         jasInitMode = mJasInitMode
      end function jasInitMode


c     -----------------------------
      subroutine jasinput(lines,nl)
c     -----------------------------

c     jasinput reads Jastrow related input from 'lines'

      character(len=*), intent(in) :: lines(:)! lines array
      integer, intent(in)          :: nl      ! actual # of lines

      if (jastype(1:2)=='sm') then
         ! Schmidt-Moskowitz type
         if (trim(jastype)=='sm') then
            call jasinput_sm(lines,nl)
         else
            call jasinput_sm_new(lines,nl)
         endif
!      else if (jastype(1:4) == 'adsm') then
!         print *, 'ad schmidt moskowitz called'
!         call adsm_set_number_of_electrons(ne)
!         call adsm_set_atom_positions(cx, cy, cz, ncenter)
!         call adsm_set_same_atom_array(sa, nscenter)
!         call adsm_read_wf_file_by_unit_number(iu)

!      else if (jastype(1:3)=='exp') then
!         call jasinput_exp(iu)
      else if (jastype(1:2) == 'ic' .or. jastype(1:2) == 'de') then
         call jasinput_ic(lines,nl)
      else if (jastype(1:3) == 'dtn') then
         !!!! new assert here to replace use_ecp!!!
         !if (use_ecp) call abortp('(jasinput):EL_k with non-local ECP is not implimented for dtn Jastrow')
         call jasinput_dtn(lines,nl)
      else if (jastype(1:2) /= 'no') then
         call abortp('(jasinput):unknown jastype')
      endif

      end subroutine jasinput



c=======================================================================


c     ------------------------
      subroutine jasoutput(iu)
c     ------------------------

      integer, intent(inout) :: iu

c     jasoutput writes Jastrow related terms to file unit 'iu'

      if (jastype(1:2)=='sm') then
         if (len_trim(jastype)==2) then
            call jasoutput_sm(iu)
         else
            call jasoutput_sm_new(iu)
         end if
!      else if (jastype(1:3)=='exp') then
!         call jasoutput_exp()
      else if(jastype(1:2) == 'ic') then
         call jasoutput_ic_new(iu)
      else if (jastype(1:3) == 'dtn') then
         call jasoutput_dtn_new(iu)
      else if (jastype(1:2) /= 'no') then
         call abortp('(jasoutput):unknown jastype')
      endif

      end subroutine jasoutput


c=======================================================================


c     ------------------------------
      subroutine jas_shortoutput(iu)
c     ------------------------------

      integer, intent(inout) :: iu

c     jasoutput writes Jastrow related terms to file unit 'iu'

      if (.not.MASTER) return
      if (jastype(1:2)=='sm') then
         if (len_trim(jastype)==2) then
            call jas_shortoutput_sm(iu)
         else
            call jas_shortoutput_sm_new(iu)
         end if
!      else if (jastype(1:3)=='exp') then
!         call jasoutput_exp()
      else if(jastype(1:2) == 'ic') then
         call jas_shortoutput_ic(iu)
      else if (jastype(1:3) == 'dtn') then
         call jas_shortoutput_dtn(iu)
      else if (jastype(1:2) /= 'no') then
         call abortp('(jasoutput):unknown jastype')
      endif

      end subroutine jas_shortoutput


c=======================================================================


c     ----------------------------------
      subroutine jasChangeType(lines,nl)
c     ----------------------------------

c     ! change Jastrow type during calculation
c     ! useful for optimization

      character(len=120), intent(in) :: lines(:)
      integer, intent(in)           :: nl
      character(len=120)            :: newLines(500), jasLines(500)

      integer iflag, io, in, nLines, njas, idx
      character(len=9) :: jt
      character(len=40) :: paramsWF
      character(len=120) :: errMsg
      logical fileExists
      logical inputok

      inputok = .false.

      call getstra(lines,nl,'new_jastrow=',jt,iflag)
      if (iflag == 0) then
         inputok=.true.
         if (logmode >= 2) then
            write(iul,'(4a/)') ' changing Jastrow type from ',trim(jastype),' to ',trim(jt)
         end if

         useAOJasTerms = .false.
         if (iflag == 0 .and. jt /= jastype) then
            if (jt(1:2)=='sm') then
               call jasChangeType_sm(jt)
!           else if (jastype(1:3)=='exp') then
!              call jasReset_exp()
            else if (jt(1:2) == 'ic' .or. jt(1:2) == 'de') then
               call jasChangeType_ic(jt)
            else if (jt(1:3) == 'dtn') then
               call jasChangeType_dtn()
            else if (jt(1:2) /= 'no') then
               call abortp('(jasChangeType): unknown jastype')
            end if
         end if

         call getstra(lines,nl,'params=',paramsWF,iflag)
         if (iflag == 0) then
            if (MASTER) then
               inquire(file=paramsWF,exist=fileExists)
               if (.not.fileExists) then
                  errMsg = 'change_jastrow: params file '//trim(paramsWF)// ' not found'
                  call abortp(errMsg)
               end if
            end if

            call readFileParallel(mytid,paramsWF,newLines,nLines)
            idx = 1
            call getNextBlock(newLines,nLines,idx,'$jastrow','$end','!',500,jasLines,njas)
            call jasinput(jasLines,njas)
         end if
         if (logmode >= 2) call jas_shortoutput(iul)

      else if (finda(lines,nl,'add_aniso_terms')) then
         inputok=.true.
         if (logmode >= 2) then
            write(iul,*)
            write(iul,*) ' * * *  adding anisotropic terms to Jastrow  * * *'
            write(iul,*)
         end if

         if (jastype(1:2)=='ic') then
            call jas_addAnisoTerms_ic(lines,nl)
         else
            call abortp("$change_jastrow: add_aniso_terms implemented only for ic Jastrow")
         end if
         if (logmode >= 2) call jas_shortoutput(iul)

      end if
      if (finda(lines,nl,'diff_ee_cusp')) then
c       Use different CUSP condition for spin like electron pair
c       -> 1/Psi * dPsi / dr = 1/4 instead of 1/2
         inputok=.true.
         if (logmode >= 2) then
            write(iul,*)
            write(iul,*) ' * * *  adding different ee cusp for spin like ee pairs  * * *'
            write(iul,*)
         end if

         if (jastype(1:2)=='sm') then
            call jas_diffeecusp_sm(.TRUE.)
         else if (jastype(1:2)=='ic' .or. jastype(1:2)=='de') then
            call jas_diffeecusp_ic(.TRUE.)
         else
            call abortp("$change_jastrow: different ee cusp for spin like ee pairs only for ic,de,sm Jastrow")
         end if
      else if(finda(lines,nl,'same_ee_cusp')) then
         inputok=.true.
         if (jastype(1:2)=='sm') then
            call jas_diffeecusp_sm(.FALSE.)
         else if (jastype(1:2)=='ic' .or. jastype(1:2)=='de') then
            call jas_diffeecusp_ic(.FALSE.)
         else
            call abortp("$change_jastrow: same ee cusp for spin like ee pairs only for ic,de,sm Jastrow")
         end if
      end if
      if (inputok .eqv. .false.) then
         call abortp("$change_jastrow: new_jastrow, add_aniso_terms, same_ee_cusp or diff_ee_cusp required")
      end if

      end subroutine jasChangeType


c=======================================================================


c     ------------------------------------------------------------------
      subroutine jasCalcWDerivs(ie,x,y,z,rai,rij,optType,
     .                          u,ugrad,ulapl,ulapli,nn)
c     ------------------------------------------------------------------

c Calculate exponent of Jastrow factor U and its derivatives

      integer, intent(in), optional :: nn ! current index of nElecConfigs
      integer, intent(in) :: ie ! ==0: assume all electron at new positions
                                ! > 0: assume only electron ie has new position
      real*8, intent(in) :: x(:), y(:), z(:)   ! electron positions
      real*8, intent(in) :: rai(:,:),    ! r_{ai} electron-nucl. (e-n)
     .                                           ! distance
     .                        rij(:,:)     ! r_{ij} elec-elec (e-e)
                                                 ! distance
      character(len=*)   ::  optType             ! parameter optimization?
      real*8, intent(out) :: u,                  ! U
     .                         ugrad(:),         ! \nabla U
     .                         ulapl,            ! laplacian U
     .                         ulapli(:)         ! laplacian_i U

      if (jastype(1:2) == 'no') then
         u = 0.d0
         ugrad = 0
         ulapl = 0
         ulapli = 0
         return
      endif

      if (ie == 0) then
         if (jastype(1:2) == 'sm') then
            call jassmall(x,y,z,rai,rij,optType,u,ugrad,ulapl,ulapli)
!         else if(jastype(1:4) == 'adsm') then
!            call adsm_ad_jastrow_all(x,y,z,u,ugrad,ulapl,ulapli,ne)
         else if (jastype(1:2) == 'ic') then
            call jasicall(x, y, z, rai, rij, optType,
     .                    u, ugrad, ulapl, ulapli, nn=nn)
         else if (jastype(1:4) == 'dtna') then
            call jasdtnall_naiv(x, y, z, rai, rij, optType,
     .                          u, ugrad, ulapl, ulapli)
         else if (jastype(1:4) == 'dtng') then
            call jasgeneric_naiv(x, y, z, rai, rij, optType,
     .                           u, ugrad, ulapl, ulapli)
         else if (jastype(1:3) == 'dtn') then
            call jasdtnall(x, y, z, rai, rij, optType,
     .                     u, ugrad, ulapl, ulapli)
         else
            call abortp('(jascalc):unknown jastype')
         endif


!      else if (ie > 0 .and. ie <= ne) then
!         if (jastype == 'sm') then
!            call jassmone(ie,x,y,z,rai,rij,u,ugrad,ulapl,ulapli)
!         else
!            call abortp('(jascalc):unknown jastype')
!         endif
      else
         call abortp('(jascalc): wrong ie')
      endif

      end subroutine jasCalcWDerivs

c===================================================================

c     ---------------------------------------
      subroutine jasCalc(init,ie,rai,rij,u)
c     ---------------------------------------

c jasp calculates U only, without derivatives

      logical, intent(in) :: init
      integer, intent(in)   :: ie
      real*8, intent(in)  :: rai(:,:),rij(:,:)
      real*8, intent(out) :: u

      if (jastype(1:2) == 'sm') then
         call jassmp(init,ie,rai,rij,u)
      else if (jastype(1:2) == 'ic') then
         call jasicp(init, ie, rai, rij, u)
      else if (jastype(1:3) == 'dtn') then
         call jasdtnp(init, ie, rai, rij, u)
      else if (jastype(1:2) == 'no') then
         u = 0.d0
      else
         call abortp('(jasCalc): not yet implemented')
      endif

      end subroutine jasCalc



c     ---------------------------
      subroutine jasCalcInit(Rdu)
c     ---------------------------

c jasCalcInit calculates U only, without derivatives
C initialize auxiliary data for one-electron updates.
c this version uses RdataUpdate to keep track of auxiliary data for efficient updates

      type(RdataUpdate), intent(inout) :: Rdu             ! data structure for electron update calculations
      integer iMode

      iMode = jasInitMode()
      if (jastype(1:2) == 'sm') then
         call jassmInit(Rdu,iMode)
      else if (jastype(1:2) == 'ic') then
         call jasicInit(Rdu,iMode)
      else if (jastype(1:2) == 'no') then
         Rdu%U = 0.d0
      else
         call abortp('(jasCalcUpdate): not yet implemented')
      endif

      end subroutine jasCalcInit



c     ---------------------------------
      subroutine jasCalcInitWithUk(Rdu)
c     ---------------------------------

c jasCalcInitWithUk calculates U only, without derivatives, with parameter derivs Uk
C initialize auxiliary data for one-electron updates, also for Uk updates
c this version uses RdataUpdate to keep track of auxiliary data for efficient updates

      type(RdataUpdate), intent(inout) :: Rdu             ! data structure for electron update calculations
      integer iMode

      if (jastype(1:2) == 'sm') then
         call jassmInitWithUk(Rdu)
      else if (jastype(1:2) == 'ic') then
         call jasicInitWithUk(Rdu)
      else if (jastype(1:2) == 'no') then
         Rdu%U = 0.d0
      else
         call abortp('(jasCalcUpdate): not yet implemented')
      endif

      end subroutine jasCalcInitWithUk


c     --------------------------------
      subroutine jasCalcUpdate(Rdu,ie)
c     --------------------------------

c jasCalcUpdate calculates U only, without derivatives
C one-electron updates only!
c this version uses RdataUpdate to keep track of auxiliary data for efficient updates

      type(RdataUpdate), intent(inout) :: Rdu     ! data structure for electron update calculations
      integer, intent(in)              :: ie      ! update for electron ie

      if (jastype(1:2) == 'sm') then
         call jassmUpdate(Rdu,ie)
      else if (jastype(1:2) == 'ic') then
         call jasicUpdate(Rdu,ie)
      else if (jastype(1:2) == 'no') then
         Rdu%U = 0.d0
      else
         call abortp('(jasCalcUpdate): not yet implemented')
      endif

      end subroutine jasCalcUpdate


c     --------------------------------------
      subroutine jasCalcUpdateWithUk(Rdu,ie)
c     --------------------------------------

c jasCalcUpdateWith calculates U only, without derivatives, with parameter derivatives Uk
C one-electron updates only!
c this version uses RdataUpdate to keep track of auxiliary data for efficient updates

      type(RdataUpdate), intent(inout) :: Rdu     ! data structure for electron update calculations
      integer, intent(in)              :: ie      ! update for electron ie

      if (jastype(1:2) == 'sm') then
         call jassmUpdateWithUk(Rdu,ie)
      else if (jastype(1:2) == 'ic') then
         call jasicUpdateWithUk(Rdu,ie)
      else if (jastype(1:2) == 'no') then
         Rdu%U = 0.d0
      else
         call abortp('(jasCalcUpdate): not yet implemented')
      endif

      end subroutine jasCalcUpdateWithUk


c===================================================================

c     ---------------------------------------
      subroutine jasCalcWithUk(init,ie, x, y, z, rai,rij,u,uk)
c     ---------------------------------------

c jasp calculates U only, without derivatives

      logical, intent(in) :: init
      integer, intent(in)   :: ie
      real*8, intent(in)  :: rai(:,:),rij(:,:)
      real*8, intent(out) :: u
      real*8, intent(out) :: uk(:)
      real*8, intent(in)  :: x(:), y(:), z(:)
      real*8 ::  jud(3*ne), julapl, julapli(ne) ! dummy

      if (jastype(1:2) == 'sm') then
         call jassmallOnlyUk(x,y,z,rai,rij,"none",u,uk)
      else if (jastype(1:2) == 'ic') then
         call jasicpWithUk(init, ie, rai, rij, u, uk)
      else if (jastype(1:3) == 'dtn') then
         call jasdtnp(init, ie, rai, rij, u)
      else if (jastype(1:2) == 'no') then
         u = 0.d0
      else
         call abortp('(jasCalc): not yet implemented')
      endif

      end subroutine jasCalcWithUk



c     ------------------------------------------------------
      subroutine getJastrowParamCnt(optMode,npJ1,npJ2,npJnl)
c     ------------------------------------------------------
      integer, intent(in)    ::  optMode       ! optimization mode
      integer, intent(inout) :: npJ1     ! one-electron linear
      integer, intent(inout) :: npJ2     ! two-electron linear
      integer, intent(inout) :: npJnl    ! nonlinear

      if (jastype(1:2) == 'sm') then
         call getVectorLenSM(optMode,npJ1,npJ2,npJnl)
      else if (jastype(1:2) == 'ic') then
         call getVectorLenIC(optMode,npJ1,npJ2,npJnl)
      else if (jastype(1:3) == 'dtn') then
         call getVectorLenDTN(optMode,npJ1,npJ2,npJnl)
      else
         call abortp('(getJastrowParamCnt): unknown jastype')
      endif
      end subroutine getJastrowParamCnt

c====================================================================


c     ---------------------------------------------------------
      subroutine getJastrowParamVector(optMode,p)
c     ---------------------------------------------------------
      integer, intent(in) ::  optMode       ! optimization mode
      real*8, intent(inout) :: p(:)         ! parameter vector
      if (jastype(1:2) == 'sm') then
         call getVectorSM(optMode,p)
      else if (jastype(1:2) == 'ic') then
         call getVectorIC(optMode, p)
      else if (jastype(1:3) == 'dtn') then
         call getVectorDTN(optMode, p)
      else
         call abortp('(getJastrowParamVector): unknown jastype')
      endif
      end subroutine getJastrowParamVector

c====================================================================


c     -------------------------------------------
      subroutine putJastrowParamVector(optMode,p)
c     -------------------------------------------
      integer, intent(in)   ::  optMode       ! optimization mode
      real*8, intent(in) :: p(:)              ! parameter vector
      if (jastype(1:2) == 'sm') then
         call putVectorSM(optMode,p)
      else if (jastype(1:2) == 'ic') then
         call putVectorIC(optMode, p)
      else if (jastype(1:3) == 'dtn') then
         call putVectorDTN(optMode, p)
      else
         call abortp('(putvector): unknown jastype')
      endif
      end subroutine putJastrowParamvector

      END MODULE jastrow
