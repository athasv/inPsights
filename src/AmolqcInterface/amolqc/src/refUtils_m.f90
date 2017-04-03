module refUtilsModule

   !!! TODO: die vier refDiff subroutinen sollten alle zu einer zusammengefuehrt werden
   !!! vermutlich ist das ohne Geschwindigkeitsverlust moeglich!!
   !!! RefDiffPerm hat nur zusaetzlich die die Permutationen, ist nur ein if-Block! (??!)

   ! this module stores reference electron configurations
   ! reference positions (e.g. local maxima of psi**2) can be added (append or insert)
   ! and are internally sorted according to different criteria
   ! as output, .ref-files are generated containing the sorted reference configurations
   ! this module creates an abstract base class (referenceContainer) and a "create" method
   ! that creates the actual class. Only the base class methods need to be used in applications
   ! (polymorphic objects)
   ! The basis data structure is a list of list of reference electron configurations, requiring
   ! two indices for access
   !
   ! parallelism: this container should be kept on the MASTER (only)
   !   collect data (GATHER) on the MASTER and use insert/append for all gathered data
   !   no combining/merging is done in this module! use local statistics only!

   use global, only: getNElec,iul,MASTER,ne,logmode
   use wfdata
   use hungarian, only: munkres
   use findCoreModule
   use elocaldata, only: elxDrift,elyDrift,elzDrift,elPhi,elU,elEloc,elVPot
   use elocal, only: eloc
   use eConfigsModule
   use ReferenceADT
   use Utils, only: int_isInSortedList

   implicit none

   private
   public    :: calcElocRef, calcEigenRef, calcRefDifference, calcRefDiffPerm

   integer, parameter :: SIMPLE=0, SPINPERM=1, ALLPERM=2                          ! modes for determining reference differences
   integer, parameter :: NONE=0, IGNOREREF=1, EXCLUDEATOMS=2, EXCLUDEINDICES=3    ! modes of excluding distances


contains


   subroutine calcElocRef(r,f,EL,vpot,fgrad)
   !---------------------------------------!
      type(reference), intent(inout) :: r
      real*8, intent(out)            :: f
      real*8, intent(out)            :: EL          ! E_loc
      real*8, intent(out)            :: vpot
      real*8, intent(out)            :: fgrad(:,:)  ! grad(-ln(psi**2)
      type(EConfigArray) :: eca

      call assert(associated(r%x) .and. size(r%x)==getNElec(),'(reference_calcEloc): reference not allocated')
      call assert(size(fgrad(:,1))==getNElec(),'(reference_calcEloc): size mismatch')
      call assert(size(fgrad(1,:))==3,'(reference_calcEloc): size mismatch 2')

      call eca%new(size(r%x),1)
      call eca%set(1,r%x,r%y,r%z)
      call eloc(0,eca,'none')

      f = - 2.d0*(log(abs(elPhi(1))) + elU(1))
      EL = elEloc(1)
      vpot = elVpot(1)
      fgrad(:,1) = -2.d0*elxDrift(:,1)
      fgrad(:,2) = -2.d0*elyDrift(:,1)
      fgrad(:,3) = -2.d0*elzDrift(:,1)
      !!write(iul,*) 'calcEloc:',EL,vpot
      !!write(iul,'(10f12.5)') self%eca%eca(1)%x(:)
      !!write(iul,'(10f12.5)') self%eca%eca(1)%y(:)
      !!write(iul,'(10f12.5)') self%eca%eca(1)%z(:)
      !!write(iul,'(10f12.7)') fgrad(:,1)
      !!write(iul,'(10f12.7)') fgrad(:,2)
      !!write(iul,'(10f12.7)') fgrad(:,3)
      call eca%destroy()
   end subroutine calcElocRef


   subroutine calcEigenRef(r,eval,evec,verb,hh,nucThresh)
   !----------------------------------------------------!
      ! returns eigenvalues and eigenvectors
      ! expects unassociated pointers, returns arrays
      type(reference), intent(in)       :: r
      real*8, pointer, intent(out)      :: eval(:)
      real*8, pointer, intent(out)      :: evec(:,:)
      integer, intent(in)               :: verb
      real*8, intent(in), optional      :: hh
      real*8, intent(in), optional      :: nucThresh
      real*8                         :: f,EL,vpot,thresh,h
      real*8                         :: fgrad(getNElec(),3)
      real*8                         :: x(getNElec()), y(getNElec()), z(getNElec())
      real*8, allocatable            :: hesse(:,:),hesseabs(:,:),hesseloss(:,:)
      real*8                         :: hmean,fac,maxloss,minloss
      integer                        :: naNuc, nbNuc    ! alpha, beta elecs at nucleus (not varied)
      integer                        :: aNucElec(getNNuc()), bNucElec(getNNuc()) ! nuc a -> elec i (at nuc)
      integer i,j,n,na,ierr
      type(reference)           :: r1

      if (present(hh)) then
         h = hh
      else
         h = 1.d-3
      end if
      if (present(nucThresh)) then
         thresh = nucThresh
      else
         thresh = 2.d-2
      end if

      if (associated(eval)) deallocate(eval)
      if (associated(evec)) deallocate(evec)

      r1 = r
      call calcElocRef(r1,f,EL,vpot,fgrad)
      r1%f = f
      if (verb>=3) then
         write(iul,'(/a)') ' - - - diagonalization step - - -'
         call r1%writeRef(iul)
         write(iul,*) ' with EL=',EL,' vpot=',vpot,' and fgrad:'
         do i=1,size(fgrad,1)
            write(iul,'(i4,3f13.5)') i,fgrad(i,1:3)
         end do
      end if

      call findNucElecs(thresh,r1%x,r1%y,r1%z,naNuc,aNucElec,nbNuc,bNucElec)
      n = 3*(getNElec() - naNuc - nbNuc)
      if (verb>=3) then
         write(iul,*) ' n = ',n
      end if
      allocate(hesse(n,n),hesseabs(n,n),hesseloss(n,n),eval(n),evec(n,n))
      hesse = 0; hesseabs = 0; hesseloss = 0

      na = getNAlpha()
      ! symmetric two-point rule
      fac = 1.d0
      call calcHesseContrib(h,1.d0)
      hesseabs = abs(hesse)
      call calcHesseContrib(-h,-1.d0)
      hesseloss = abs(hesse) / hesseabs
      maxloss = -log10(minval(hesseloss))
      minloss = -log10(maxval(hesseloss))
      if (verb >= 3) write(iul,'(a,f8.2,a,f8.2)') ' maxloss = ',maxloss,' minloss = ',minloss

      hesse = hesse / (2.d0*h)

      ! strictly symmetrize hessian
      do i=1,n
         do j=i,n
            if (verb >= 4) write(iul,'(2i3,2f12.7)') i,j,hesse(i,j),abs(hesse(i,j)-hesse(j,i))
            hmean = 0.5d0*(hesse(i,j) + hesse(j,i))
            hesse(i,j) = hmean
            hesse(j,i) = hmean
         end do
      end do
      call sdiag(hesse,n,n,eval,n,evec,n,n,n,ierr)
      if (ierr /= 0) call abortp('(reference_eigen): diagonalization failed')
      deallocate(hesse,hesseabs,hesseloss)
      call r1%destroy()

   contains

      subroutine calcHesseContrib(hh,fac)
         real*8, intent(in) :: hh,fac
         integer i,ii
         i = 0
         !!write(iul,*) 'DBG:',hh,fac
         do ii=naNuc+1,na
            i = i + 1
            r1%x(ii) = r1%x(ii) + hh
            call calcHesseTerm(i,fac)
            r1%x(ii) = r1%x(ii) - hh
            i = i + 1
            r1%y(ii) = r1%y(ii) + hh
            call calcHesseTerm(i,fac)
            r1%y(ii) = r1%y(ii) - hh
            i = i + 1
            r1%z(ii) = r1%z(ii) + hh
            call calcHesseTerm(i,fac)
            r1%z(ii) = r1%z(ii) - hh
         end do
         do ii=na+nbNuc+1,getNElec()
            i = i + 1
            r1%x(ii) = r1%x(ii) + hh
            call calcHesseTerm(i,fac)
            r1%x(ii) = r1%x(ii) - hh
            i = i + 1
            r1%y(ii) = r1%y(ii) + hh
            call calcHesseTerm(i,fac)
            r1%y(ii) = r1%y(ii) - hh
            i = i + 1
            r1%z(ii) = r1%z(ii) + hh
            call calcHesseTerm(i,fac)
            r1%z(ii) = r1%z(ii) - hh
         end do
         call assert(i==n,'(calcEigenRef): internal error 2')
      end subroutine calcHesseContrib

      subroutine calcHesseTerm(i,fac)
         integer, intent(in) :: i
         real*8, intent(in)  :: fac
         real*8 f
         integer j0,jj
         call calcElocRef(r1,f,EL,vpot,fgrad)
         j0 = 0
         do jj=naNuc+1,na
            do j=1,3
               hesse(i,j0+j) = hesse(i,j0+j) + fac*fgrad(jj,j)
               !!write(iul,*) i,j0+j,jj,fac,fgrad(jj,j),hesse(i,j0+j)
            end do
            j0 = j0 + 3
         end do
         do jj=na+nbNuc+1,getNElec()
            do j=1,3
               hesse(i,j0+j) = hesse(i,j0+j) + fac*fgrad(jj,j)
               !!write(iul,*) i,j0+j,jj,fac,fgrad(jj,j),hesse(i,j0+j)
            end do
            j0 = j0 + 3
         end do
         call assert(j0==n,'(calcEigenRef): internal error 1')
      end subroutine calcHesseTerm

   end subroutine calcEigenRef


   subroutine calcRefDifference(r1,r2,mode,meanDist,maxDist,irev,exclist,exclmode,permidx)
   !-------------------------------------------------------------------------------------!
      ! calculate the difference between the two electron arrangements r1 and r2 possibly with permutations of r2
      ! return meanDist and maxDist, allowing to ignore certain distances as defined by the final args
      type(reference), intent(in)                :: r1
      type(reference), intent(in)                :: r2
      integer, intent(in)                        :: mode     ! 0: mean elec dist
                                                             ! 1: mean elec dist with alpha-alpha, beta-beta permutation
                                                             ! 2: mean elec dist with permutation of all electrons
      real*8, intent(out)                        :: meanDist ! mean distance
      real*8, intent(out)                        :: maxDist  ! maximum distance
      integer, pointer, intent(in),optional      :: irev(:)  ! ignored ref electrons vector
      integer, intent(in), optional              :: exclist(:)  ! list of excluded positions
      integer, intent(in), optional              :: exclmode  ! 0: list contains excluded atom pairs
                                                              ! 1: list contains excluded atom indices
      integer, intent(out), optional             :: permidx(:)  ! permutation as index-array
                                                               ! j=permidx(i) means: r2(j) is close to r1(i)
      integer :: idxa(nalpha),idxb(nbeta),idx(ne)
      integer :: idxab(nalpha),idxba(nbeta)
      real    :: dista,distb,distba,distab
      real    :: dmata(nalpha,nalpha),dmatb(nbeta,nbeta)
      real    :: dmatab(nalpha,nbeta),dmatba(nbeta,nalpha)
      real    :: dmat(ne,ne)                  !! alternative to dmata/b; save memory with allocate
      real*8  :: xtmp(ne),ytmp(ne),ztmp(ne),distmean,distmax
      integer :: i,j,nElec,ns
      integer :: excludeMode

      if (present(exclist)) then
         if (present(exclmode)) then
            if (exclmode==1) then
               excludeMode = EXCLUDEINDICES
            else
               excludeMode = EXCLUDEATOMS
            endif
         else
            excludeMode = EXCLUDEATOMS
         endif
      else if (present(irev)) then
         excludeMode = IGNOREREF
      else
         excludeMode = NONE
      end if

      select case (mode)
      case (SIMPLE)
         idx(1:ne) = (/ (i,i=1,ne) /)
         call calcMaxAndMeanDist(excludeMode,distmean,distmax)
      case (SPINPERM)
         forall(i=1:nalpha,j=1:nalpha)
            dmata(i,j) = sqrt( (r1%x(i)-r2%x(j))**2 + (r1%y(i)-r2%y(j))**2 + (r1%z(i)-r2%z(j))**2 )
         end forall
         forall(i=nalpha+1:ne,j=nalpha+1:ne)
            dmatb(i-nalpha,j-nalpha) = sqrt( (r1%x(i)-r2%x(j))**2 + (r1%y(i)-r2%y(j))**2 + (r1%z(i)-r2%z(j))**2 )
         end forall
         call munkres(1, dmata, nalpha, nalpha, idxa, dista)
         call munkres(1, dmatb, nbeta, nbeta, idxb, distb)

         idx(1:nalpha) = idxa
         idx(nalpha+1:ne) = idxb + nalpha
         call calcMaxAndMeanDist(excludeMode,distmean,distmax)
      case (ALLPERM)
         forall (i=1:ne,j=1:ne)
            dmat(i,j) = sqrt( (r1%x(i)-r2%x(j))**2 + (r1%y(i)-r2%y(j))**2 + (r1%z(i)-r2%z(j))**2 )
         end forall
         call munkres(1, dmat, ne, ne, idx, dista)
         call calcMaxAndMeanDist(excludeMode,distmean,distmax)
      case default
         call abortp("calcRefDifference: illegal mode")
      end select

      meanDist = distmean
      maxDist   = distmax
      if (present(permidx)) then
         call assert(size(permidx)==ne,"calcRefDifference: permidx argument has illegal size")
         permidx = idx
      end if

   contains

      subroutine calcMaxAndMeanDist(emode,mdist,dmax)
         integer, intent(in)   :: emode          ! decides which elec positions to exclude for mean and max
         real*8, intent(inout) :: mdist,dmax     ! mean distance and max distance
         real*8 d,dsum,r(3)
         integer i,ii,nsum,rIdx
         logical isInExclList
         dsum = 0
         dmax = 0
         select case (emode)
            case (NONE)
               do i=1,ne
                  d = sqrt( (r1%x(i)-r2%x(idx(i)))**2 + (r1%y(i)-r2%y(idx(i)))**2 + (r1%z(i)-r2%z(idx(i)))**2 )
                  dsum = dsum + d
                  dmax = max(dmax,d)
               end do
               mdist = dsum / ne
            case (IGNOREREF)
               ii = 1     ! idx in irev
               do i=1,ne
                  if (ii <= size(irev)) then
                     if (i==irev(ii)) then
                        ii = ii+1
                        cycle
                     end if
                  end if
                  d = sqrt( (r1%x(i)-r2%x(idx(i)))**2 + (r1%y(i)-r2%y(idx(i)))**2 + (r1%z(i)-r2%z(idx(i)))**2 )
                  dsum = dsum + d
                  dmax = max(dmax,d)
               end do
               mdist = dsum / (ne-size(irev))
            case (EXCLUDEATOMS)
               nsum = 0
               do i=1,ne
                  r = (/ r2%x(idx(i)), r2%y(idx(i)), r2%z(idx(i)) /)
                  call atoms_whatPosition(atoms,r,resultTypeCode=rIdx)
                  isInExclList = int_isInSortedList(exclist,rIdx)
                  if (isInExclList) cycle
                  d = sqrt( (r1%x(i)-r2%x(idx(i)))**2 + (r1%y(i)-r2%y(idx(i)))**2 + (r1%z(i)-r2%z(idx(i)))**2 )
                  dsum = dsum + d
                  nsum = nsum + 1
                  dmax = max(dmax,d)
               end do
               mdist = dsum / nsum
            case (EXCLUDEINDICES)
               nsum = 0
               do i=1,ne
                  r = (/ r2%x(idx(i)), r2%y(idx(i)), r2%z(idx(i)) /)
                  call atoms_whatPosition(atoms,r,resultIndexCode=rIdx)
                  isInExclList = int_isInSortedList(exclist,rIdx)
                  if (isInExclList) cycle
                  d = sqrt( (r1%x(i)-r2%x(idx(i)))**2 + (r1%y(i)-r2%y(idx(i)))**2 + (r1%z(i)-r2%z(idx(i)))**2 )
                  dsum = dsum + d
                  nsum = nsum + 1
                  dmax = max(dmax,d)
               end do
               mdist = dsum / nsum
            case default
               call abortp("calcRefDifference: illegal emode")
         end select
      end subroutine calcMaxAndMeanDist

   end subroutine calcRefDifference

   subroutine calcRefDiffPerm(r1,r2,mode,meanDist,maxDist,irev,exclist,exclmode)
      ! very similar to calcRefDifference, but r2 is permuted according to assignment (r2 is therefore inout)
      ! calculate the difference between the two electron arrangements r1 and r2 possibly with permutations of r2
      ! and permute r2 such as to realize the calculated distance
      ! optionally return the differences, possibly ignoring certain distances as defined by the last args
      type(reference), intent(in)                :: r1
      type(reference), intent(inout)             :: r2
      integer, intent(in)                        :: mode     ! 0: mean elec dist
                                                             ! 1: mean elec dist with alpha-alpha, beta-beta permutation
                                                             ! 2: mean elec dist with permutation of all electrons
      real*8, intent(out), optional              :: meanDist ! mean distance
      real*8, intent(out), optional              :: maxDist  ! maximum distance
      integer, pointer, intent(in),optional      :: irev(:)  ! ignored ref electrons vector
      integer, intent(in), optional              :: exclist(:)  ! list of excluded positions
      integer, intent(in), optional              :: exclmode  ! 0: list contains excluded atom pairs
                                                              ! 1: list contains excluded atom indices
      integer :: idxa(nalpha),idxb(nbeta),idx(ne)
      integer :: idxab(nalpha),idxba(nbeta)
      real    :: dista,distb,distba,distab
      real    :: dmata(nalpha,nalpha),dmatb(nbeta,nbeta)
      real    :: dmatab(nalpha,nbeta),dmatba(nbeta,nalpha)
      real    :: dmat(ne,ne)                  !! alternative to dmata/b; save memory with allocate
      real*8  :: xtmp(ne),ytmp(ne),ztmp(ne),distmean,distmax
      integer :: i,j,nElec,ns
      integer :: excludeMode

      if (present(exclist)) then
         if (present(exclmode)) then
            if (exclmode==1) then
               excludeMode = EXCLUDEINDICES
            else
               excludeMode = EXCLUDEATOMS
            endif
         else
            excludeMode = EXCLUDEATOMS
         endif
      else if (present(irev)) then
         excludeMode = IGNOREREF
      else
         excludeMode = NONE
      end if

      select case (mode)
      case (SIMPLE)
         idx(1:ne) = (/ (i,i=1,ne) /)
         if (present(meanDist).or.present(maxDist)) call calcMaxAndMeanDist(excludeMode,distmean,distmax)
      case (SPINPERM)
         forall(i=1:nalpha,j=1:nalpha)
            dmata(i,j) = sqrt( (r1%x(i)-r2%x(j))**2 + (r1%y(i)-r2%y(j))**2 + (r1%z(i)-r2%z(j))**2 )
         end forall
         forall(i=nalpha+1:ne,j=nalpha+1:ne)
            dmatb(i-nalpha,j-nalpha) = sqrt( (r1%x(i)-r2%x(j))**2 + (r1%y(i)-r2%y(j))**2 + (r1%z(i)-r2%z(j))**2 )
         end forall
         call munkres(1, dmata, nalpha, nalpha, idxa, dista)
         call munkres(1, dmatb, nbeta, nbeta, idxb, distb)

         idx(1:nalpha) = idxa
         idx(nalpha+1:ne) = idxb + nalpha
         if (present(meanDist).or.present(maxDist)) call calcMaxAndMeanDist(excludeMode,distmean,distmax)
         ! permute r2
         forall (i=1:ne)
            xtmp(i) = r2%x(idx(i))
            ytmp(i) = r2%y(idx(i))
            ztmp(i) = r2%z(idx(i))
         end forall
         r2%x = xtmp
         r2%y = ytmp
         r2%z = ztmp
      case (ALLPERM)
         forall (i=1:ne,j=1:ne)
            dmat(i,j) = sqrt( (r1%x(i)-r2%x(j))**2 + (r1%y(i)-r2%y(j))**2 + (r1%z(i)-r2%z(j))**2 )
         end forall
         call munkres(1, dmat, ne, ne, idx, dista)
         if (present(meanDist).or.present(maxDist)) call calcMaxAndMeanDist(excludeMode,distmean,distmax)
         ! permute r2
         forall (i=1:ne)
            xtmp(i) = r2%x(idx(i))
            ytmp(i) = r2%y(idx(i))
            ztmp(i) = r2%z(idx(i))
         end forall
         r2%x = xtmp
         r2%y = ytmp
         r2%z = ztmp
      case default
         call abortp("calcRefDiffPerm: illegal mode")
      end select

      if (present(meanDist)) meanDist = distmean
      if (present(maxDist)) maxDist   = distmax

   contains

      subroutine calcMaxAndMeanDist(emode,mdist,dmax)
         ! duplicated from calcRefDifference because of optional args to main subroutine
         integer, intent(in)   :: emode          ! decides which elec positions to exclude for mean and max
         real*8, intent(inout) :: mdist,dmax     ! mean distance and max distance
         real*8 d,dsum,r(3)
         integer i,ii,nsum,rIdx
         logical isInExclList
         dsum = 0
         dmax = 0
         select case (emode)
            case (NONE)
               do i=1,ne
                  d = sqrt( (r1%x(i)-r2%x(idx(i)))**2 + (r1%y(i)-r2%y(idx(i)))**2 + (r1%z(i)-r2%z(idx(i)))**2 )
                  dsum = dsum + d
                  dmax = max(dmax,d)
               end do
               mdist = dsum / ne
            case (IGNOREREF)
               ii = 1     ! idx in irev
               do i=1,ne
                  if (ii <= size(irev)) then
                     if (i==irev(ii)) then
                        ii = ii+1
                        cycle
                     end if
                  end if
                  d = sqrt( (r1%x(i)-r2%x(idx(i)))**2 + (r1%y(i)-r2%y(idx(i)))**2 + (r1%z(i)-r2%z(idx(i)))**2 )
                  dsum = dsum + d
                  dmax = max(dmax,d)
               end do
               mdist = dsum / (ne-size(irev))
            case (EXCLUDEATOMS)
               nsum = 0
               do i=1,ne
                  r = (/ r2%x(i), r2%y(i), r2%z(i) /)
                  call atoms_whatPosition(atoms,r,resultTypeCode=rIdx)
                  isInExclList = int_isInSortedList(exclist,rIdx)
                  if (isInExclList) cycle
                  d = sqrt( (r1%x(i)-r2%x(idx(i)))**2 + (r1%y(i)-r2%y(idx(i)))**2 + (r1%z(i)-r2%z(idx(i)))**2 )
                  dsum = dsum + d
                  nsum = nsum + 1
                  dmax = max(dmax,d)
               end do
               mdist = dsum / nsum
            case (EXCLUDEINDICES)
               nsum = 0
               do i=1,ne
                  r = (/ r2%x(i), r2%y(i), r2%z(i) /)
                  call atoms_whatPosition(atoms,r,resultIndexCode=rIdx)
                  isInExclList = int_isInSortedList(exclist,rIdx)
                  if (isInExclList) cycle
                  d = sqrt( (r1%x(i)-r2%x(idx(i)))**2 + (r1%y(i)-r2%y(idx(i)))**2 + (r1%z(i)-r2%z(idx(i)))**2 )
                  dsum = dsum + d
                  nsum = nsum + 1
                  dmax = max(dmax,d)
               end do
               mdist = dsum / nsum
            case default
               call abortp("calcRefDiffPerm: illegal emode")
         end select
      end subroutine calcMaxAndMeanDist

   end subroutine calcRefDiffPerm


end module refUtilsModule
