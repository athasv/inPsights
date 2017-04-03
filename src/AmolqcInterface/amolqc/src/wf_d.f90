! Data module containing public data related to general wave function definition

MODULE wfdata

  use global
  use atomModule
  implicit none

! $Id: wf_m.f90,v 1.2 2008/02/05 22:21:35 luechow Exp $

! $Log: wf_m.f90,v $
! Revision 1.2  2008/02/05 22:21:35  luechow
! minor bugs removed after compilation with sun compiler.
! parselib.f adapted to fortran standard
!
! Revision 1.1.1.1  2007/04/25 13:42:20  luechow
! QMC program amolqc. rewritten in 2006. AL
!

!-------Constants-----------------------------------------

  integer, parameter :: amax=80     ! max # of atoms
  integer, parameter :: basmax=1000 ! max # basis functions (!)
  integer, parameter :: kmax=100    ! max # of Jastrow terms
  integer, parameter :: cnmax=30    ! max GTO contraction length


!-------Definitions for the wave function------------------

  integer :: mult = 1                      ! spin multiplicity
  integer :: charge = 0                    ! charge of molecule
  integer :: bn(basmax) = 0                ! n quantum numbers of orbitals
  integer :: bc(basmax) = 0                ! # of center for orbital
  integer :: ncenter = 0                   ! # of nuclei
  integer :: nscenter = 0                  ! # of nuclei (not sym.-equiv.)
  integer :: nalpha = 0                    ! # of alpha, beta electrons
  integer :: nbeta = 0
  integer :: ndet = 0                      ! # of determinants
  integer :: ncsf = 0                      ! # of CSFs
  integer :: nbas = 0                      ! # of basis functions (counting p,d as one)
  integer :: nbasf = 0                     ! # of individual (cartesian) basis functions (counting p,d as 3,6!)
  integer :: norb = 0                      ! # of MO's

  logical :: partial = .false.             ! "partial" charges for initial sampling
  type(atom), allocatable :: atoms(:)      ! contains the molecular geometry with properties

  character(len=79) :: title = 'no title'  ! title of wavefunction
  character(len=3)  :: evfmt = 'gau'       ! eigenvector format
  character(len=9)  :: jastype = 'none'    ! jastrow type
  character(len=20) :: basis = ''          ! basis set from basis set library
  logical :: normalize = .true.            ! whether the contraction coefficients should be normalized
  character(len=20) :: envvar = 'AMOLQC_BASLIB' ! default environment variable

  real*8 :: vpot0 = 0                      ! nuclear repulsion

!--------- spline parameters --------------------------------

  integer :: splinpnts = 4000              ! # of spline points
  logical :: spline = .true.               ! spline radial parts of AO's?
  logical :: aosopt = .false.              ! optimize Cusp-corrrection-function ?
  logical :: cuspcor = .true.              ! correct cusp of 1S + 2S GTO ?

!--------- aomo parameters ----------------------------------

  logical :: cutao=.false.               ! use AO cutoff
  logical :: cutmo=.false.               ! use MO cutoff
  logical :: aomotask=.false.
  logical :: aomopair=.false.
  logical :: aomocomb=.false.            ! .true. means combined AO/MO evaluation using aomo_calc
                                         ! .false. means AO/MO evaluation using aocalc and mocalc
  real*8  :: aocutoff = 0.d0             ! CHECK WHAT PRECISELY THAT VALUE IS
  real*8  :: mocutoff = 0.d0             !
  real*8  :: prodcutoff = 0.d0

!--------- sample generation ----------------------------------

  real*8  :: mFac = 0.05d0               ! radial scaling factor for density sampling

!--------- optimization parameters ----------------------------

  logical :: optyn=.false.                  ! Levenberg-Marquardt optimization with fixed sample


!-------- general parameters ------------------
  integer :: printAOs = 0                 ! print level for aos
  integer :: printMOs = 0                 ! print level for mos
  integer :: printJ   = 0                 ! print level for jastrow
  integer :: printDet = 0                 ! print level for dets
  logical :: useLAlib_mos = .true.        ! use LA library (BLAS/LAPACK) in mos
  logical :: useLAlib_mdet = .true.       ! use LA library (BLAS/LAPACK) in mdet
  logical :: fastmdet = .false.           ! use fast excited determinant calculation
  logical :: repeatedDetsOpt = .true.     ! optimize calculation of repeated determinants 

!------------- Properties----------------------

  character(len=6) :: mProptype = ''

!--------------Epart---------------------------
  logical:: do_epart = .false.
  real*8 :: Vnni(amax,amax) = 0d0


CONTAINS

  integer pure function getNNuc()
     getNNuc = ncenter
  end function getNNuc

  integer pure function getNAlpha()
     getNAlpha = nalpha
  end function getNAlpha

  integer pure function getNBeta()
     getNBeta = nbeta
  end function getNBeta


  !------------------------------------!
  subroutine calcNucElecDists(x,y,z,rai)
  !------------------------------------!

  ! calculates nucleus electron distances
  real*8, intent(in)    :: x(:),y(:),z(:)
  real*8, intent(inout) :: rai(:,:)
  integer a,i
  do i=1,ne
     do a=1,ncenter
        rai(a,i) = sqrt( (x(i)-atoms(a)%cx)**2 + (y(i)-atoms(a)%cy)**2 + (z(i)-atoms(a)%cz)**2 )
     enddo
  enddo
  end subroutine calcNucElecDists

  !-------------------------------------!
  subroutine calcElecElecDists(x,y,z,rij)
  !-------------------------------------!

  ! calculates electron electron distances
  ! ONLY FOR i<j !!!
  real*8, intent(in)    :: x(:),y(:),z(:)
  real*8, intent(inout) :: rij(:,:)
  integer i,j
  do i=1,ne
     do j=i+1,ne
        rij(i,j) = sqrt( (x(i)-x(j))**2 + (y(i)-y(j))**2 + (z(i)-z(j))**2 )
     enddo
  enddo
  end subroutine calcElecElecDists

  !----------------------------------!
  real*8 function wf_getRadiusSpread()
     wf_getRadiusSpread = mFac
  end function wf_getRadiusSpread
  !----------------------------------!

  !----------------------------------!
  subroutine wf_setRadiusSpread(fac)
     real*8, intent(in) :: fac
     mFac = fac
  end subroutine wf_setRadiusSpread
  !----------------------------------!

END MODULE wfdata
