      subroutine ao_cut(aocut)

c This routine calculates the range of |\nabla(phi)| for each AO along the
c respective main axis of the orbital.
c the functions lapl_sx,lapl_sp,lapl_dxx,lapl_dxy,lapl_fxxx,lapl_fxxy and
c lapl_fxyz have three modes:
c 1: calculation of \nabla(phi(r)) (points into the direction of the main axis)
c 2: 1st derivative of \nabla(phi(r)) which is used for the linear inverse interpolation
c 3: appropriate initial guess for inverse interpolation. In most cases largest root of 
c    the 1st derivative of \nabla(phi(r)) + the trust radius. Interpolation procedure starts
c    from this point (because function decays or increases monotonically from that 
c    position on (which is nice for linear interpolation).
c These functions are not addressed directly but through the Routine evallapl (which handles
c the different types of d and f functions (including the different norms).
c
c For the current implementation this is a bit too much effort since for each angular momentum 'l' the
c x^l*exp(-a*r^2) compound has the largest range....
c
c the functions sx,sp,dxx,dxy,fxxx,fxxy and fxyz do the same things for the orbitals
c (for future applications)

      use aosdata

      implicit none

ccc input
      real*8 :: aocut

ccc local parameters
      real*8 :: trustr,conv
      integer :: itermax
      parameter(trustr=0.1,conv=0.1d-10)
      parameter(itermax=10000)

ccc local variables
      real*8 :: alpha,coef
      real*8 :: maxr,maxrp,tmp
      real*8 :: r,r_new,y,m     !variables for laplacian
      real*8 :: rp,rp_new,yp,mp !variables for orbital itsself

      integer :: niter
      integer :: bf,ic,mod,tp,ntypes
      integer :: alstat

      character(len=1) :: l

      allocate(aocuts(nbasf),stat=alstat)
      if (alstat.ne.0) call abortp('(ao_cut): allocation error')

      do bf=1, nbasf

        l = bl(bf)

        if ((l.eq.'S').or.(l.eq.'P')) ntypes=1
        if (l.eq.'D') ntypes=2
        if (l.eq.'F') ntypes=3

        maxr  = 0d0
c        maxrp = 0d0

        do tp=1, ntypes

c search smallest alpha in contraction (most diffuse CTO)
          alpha=cntrctn(1,1,bf)
          do ic=2, ngto(bf)
            tmp = cntrctn(1,ic,bf)
            if (abs(tmp).lt.abs(alpha)) then 
              alpha=tmp
              coef=cntrctn(2,ic,bf)
            endif
          enddo

c start guess on the basis of most diffuse CTO
          r = evallapl(3,l,tp,alpha,0d0)
          y = coef * evallapl(1,l,tp,alpha,r)

          niter=0

c inverse interpolation
          do while (abs(abs(y) - aocut).gt.conv)
            niter=niter+1
            if (niter.gt.itermax) then
              call abortp('ao_cut: niter.gt.maxiter')
            endif

            m=0d0
            y=0d0

c loop over contraction 
            do ic=1, ngto(bf)
              alpha=cntrctn(1,ic,bf)
              coef=abs(cntrctn(2,ic,bf))
              m = m + coef * evallapl(2,l,tp,alpha,r)
              y = y + coef * evallapl(1,l,tp,alpha,r)
            enddo

            r_new = (aocut - y)/m + r

            if (abs(r-r_new).le.trustr) then
              r = r_new
            else
              r = sign(trustr,r_new-r) + r
            endif

          enddo  !iterations

          if (r.gt.maxr) maxr=r

ccc end of laplacian
ccc inverse interpolation for orbitals

c            rp = evalphi(3,l,tp,alpha,aocut)
c            yp = coef * evalphi(1,l,tp,alpha,rp)
c            write(*,*) rp,yp
c
c            niter=0
c
c            do while (abs(abs(yp) - aocut).gt.conv)
c              niter=niter+1
c              if (niter.gt.itermax) then
c                call abortp('something wrong in ao_cut')
c              endif
c
c              mp = coef * evalphi(2,l,tp,alpha,rp)
c              yp = coef * evalphi(1,l,tp,alpha,rp)
c              rp_new = (aocut - yp)/mp + rp
c
c              if (abs(rp-rp_new).le.trustr) then
c                rp = rp_new
c              else
c                rp = sign(trustr,rp_new-rp) + rp
c              endif
c
c            enddo  !iterations
c
c            if (rp.gt.maxrp) maxrp=rp

        enddo ! types

        aocuts(bf)  = maxr   ! cutoff radius for laplacian
c        aocutsp(bf) = maxrp  ! cutoff radius for orbital

      enddo     ! basis functions


ccc some debug output

c      do bf=1, nbasf
c        do ic=1, ngto(bf)
c        write(*,'(2f20.14,2x,a,2f14.8)')
c     .    cntrctn(1,ic,bf),cntrctn(2,ic,bf),bl(bf),aocuts(bf),
c     .    aocuts(bf)*0.52918
c          if (bl(bf).eq.'S') then
c            write(*,*) s(1,cntrctn(1,ic,bf),aocuts(bf))*cntrctn(2,ic,bf)
c          elseif (bl(bf).eq.'P') then
c           write(*,*) px(1,cntrctn(1,ic,bf),aocuts(bf))*cntrctn(2,ic,bf)
c          elseif (bl(bf).eq.'D') then
c          write(*,*) dxx(1,cntrctn(1,ic,bf),aocuts(bf))*cntrctn(2,ic,bf)
c          write(*,*) dxy(1,cntrctn(1,ic,bf),aocuts(bf))*cntrctn(2,ic,bf)
c          elseif (bl(bf).eq.'F') then
c         write(*,*) fxxx(1,cntrctn(1,ic,bf),aocuts(bf))*cntrctn(2,ic,bf)
c         write(*,*) fxxy(1,cntrctn(1,ic,bf),aocuts(bf))*cntrctn(2,ic,bf)
c         write(*,*) fxyz(1,cntrctn(1,ic,bf),aocuts(bf))*cntrctn(2,ic,bf)
c          endif
c        enddo
c        write(*,*)
c      enddo


      contains


        real*8 function evalphi(mode,l,type,a,x)

          real*8 :: sqr3,sqr5
          parameter(sqr3=1.73205080756887729d0)
          parameter(sqr5=2.236067977499789696d0)

          real*8 :: a,x,normc
          integer :: mode,type
          character(len=1) :: l

          if (l.eq.'S') then

            if (type.ne.1) call abortp('error in evallapl in ao_cut')
            evalphi = s(mode,a,x)

          elseif (l.eq.'P') then

            if (type.ne.1) call abortp('error in evallapl in ao_cut')
            evalphi = px(mode,a,x)

          elseif (l.eq.'D') then

            if (type.eq.1) evalphi = dxx(mode,a,x)
            if (type.eq.2) then
              if (mode.eq.3) then
                normc = 1.0d0
              else
                normc = sqr3
              endif
              evalphi = normc * dxy(mode,a,x)
            endif

          elseif (l.eq.'F') then

            if (type.eq.1) evalphi = fxxx(mode,a,x)
            if (type.eq.2) then

              if (mode.eq.3) then
                normc = 1.0d0
              else
                normc = sqr5
              endif
              evalphi = normc * fxxy(mode,a,x)

            elseif (type.eq.3) then

              if (mode.eq.3) then
                normc = 0.0d0
              else
                normc = sqr3 * sqr5
              endif
              evalphi = normc * fxyz(mode,a,x)

            endif

          else
            call abortp('error in evallapl in ao_cut')
          endif

        end function evalphi



        real*8 function evallapl(mode,l,type,a,x)

          real*8 :: sqr3,sqr5
          parameter(sqr3=1.73205080756887729d0)
          parameter(sqr5=2.236067977499789696d0)

          real*8 :: a,x,normc
          integer :: mode,type
          character(len=1) :: l

c mode:1 laplacian
c mode:2 1st derivative of laplacian
c mode:3 start value for inverse interpolation 
c        (in most cases largest root of 1st  derivative)
c type:1 s,px,dxx,fxxx
c type:2 dxy,fxxy
c type:3 fxyz

          if (l.eq.'S') then

            if (type.ne.1) call abortp('error in evallapl in ao_cut')
            evallapl = lapl_sx(mode,a,x)

          elseif (l.eq.'P') then

            if (type.ne.1) call abortp('error in evallapl in ao_cut')
            evallapl = lapl_px(mode,a,x)

          elseif (l.eq.'D') then

            if (type.eq.1) evallapl = lapl_dxx(mode,a,x)
            if (type.eq.2) then
              if (mode.eq.3) then 
                normc=1.0d0
              else
                normc=sqr3
              endif
              evallapl = normc * lapl_dxy(mode,a,x)      !correction of norm with respect
            endif                                        !to dxx

          elseif (l.eq.'F') then

            if (type.eq.1) then

              if (mode.eq.3) then
                evallapl = startguess(type,a,x)
              else
                evallapl = lapl_fxxx(mode,a,x)
              endif              

            elseif (type.eq.2) then

              if (mode.eq.3) then
                evallapl = startguess(type,a,x)
              else
                evallapl = sqr5 * lapl_fxxy(mode,a,x)     !correction of norm with respect
              endif                                       !to fxxx

            elseif (type.eq.3) then

              if (mode.eq.3) then
                normc=1.0d0
              else
                normc=sqr3*sqr5
              endif
              evallapl = normc * lapl_fxyz(mode,a,x)

            endif

          else
            call abortp('error in evallapl in ao_cut')
          endif

        end function evallapl



        real*8 function startguess(type,a,x)

c provides initial guesses for fxxx and fxxy were analytical roots of 1st derivative
c of laplacian are not accessible. Guesses are based on the exponential part

          real*8 :: a,x
          integer :: type

          real*8 :: tmp

          if (type.eq.1) then
            tmp = log(0.5*aocut/a)
            tmp = abs(tmp)
            startguess = sqrt(tmp)            
          elseif (type.eq.2) then
            tmp = log(9.0d0/(2.0d0*sqrt(3.0d0))*aocut/a)
            tmp = abs(tmp)
            startguess = sqrt(tmp)
          else
            call abortp('invalid type in startguess')
          endif

        end function startguess



        real*8 function s(mode,a,r)

          real*8 :: r,a
          integer :: mode


          if (mode.eq.1) then
            s = exp(-a*r**2)
          elseif (mode.eq.2) then
           call abortp('function s in ao_cut:This should never happen!')
           ! Because we are feeding in the analytical value for the cutoff radius
           ! Therefore no iteration should be necessary
          elseif (mode.eq.3) then
            s = sqrt(-log(r/coef)/a)  !Analytical inverse function
          endif

        end function s


        real*8 function px(mode,a,r)

          real*8 :: r,a
          integer :: mode


          if (mode.eq.1) then
            px = r * exp(-a*r**2)
          elseif (mode.eq.2) then
            px = (-1.0d0 + 2.0d0 * a * r**2) * (-exp(-a * r**2))
          elseif (mode.eq.3) then
            px = 0.5 * sqrt(2.0d0)/sqrt(a) + trustr
            !Start guess: largest root of 1st derivative + trust radius
          endif

        end function px


        real*8 function dxx(mode,a,r)

          real*8 :: r,a
          integer :: mode


          if (mode.eq.1) then
            dxx = r**2 * exp(-a*r**2)
          elseif (mode.eq.2) then
            dxx = (-1.0d0 + a * r**2) * (-2.d0) * r * exp(-a * r**2)
          elseif (mode.eq.3) then
            dxx = 1/sqrt(a) + trustr
          endif

        end function dxx


        real*8 function dxy(mode,a,r)

          real*8 :: r,a
          integer :: mode

          if (mode.eq.1) then
            dxy = 0.5 * r**2 * exp(-a*r**2) * sqrt(3.0d0)
          elseif (mode.eq.2) then
            dxy = (-1.0d0 + a * r**2) * (-r) * exp(-a * r**2) * 
     .                                                    sqrt(3.0d0)
          elseif (mode.eq.3) then
            dxy = 1/sqrt(a) + trustr
          endif

        end function dxy


        real*8 function fxxx(mode,a,r)

          real*8 :: r,a
          integer :: mode

          if (mode.eq.1) then
            fxxx = r**3 * exp(-a*r**2)
          elseif (mode.eq.2) then
            fxxx = ((-3.0d0) + 2.0d0 * a * r**2) * (-r)**2 *exp(-a*r**2)
          elseif (mode.eq.3) then
            fxxx = 0.5 * sqrt(6.0d0/a) + trustr
          endif

        end function fxxx

        
        real*8 function fxxy(mode,a,r)

          real*8 :: r,a
          integer :: mode

          if (mode.eq.1) then
            fxxy = 2.0d0*sqrt(3.0d0)/9.0d0 * r**3 * exp(-a*r**2) *
     .                                                     sqrt(5.0d0)
          elseif (mode.eq.2) then
            fxxy = (-3.0d0 + 2.0d0 * a * r**2) *
     .             (-2.0d0) * sqrt(3.0d0)/9.0d0 * r**2 * exp(-a*r**2) * 
     .                                                      sqrt(5.0d0)
          elseif (mode.eq.3) then
            fxxy = 0.5 * sqrt(6.0d0/a) + trustr
          endif

        end function fxxy


        real*8 function fxyz(mode,a,r)

          real*8 :: r,a
          integer :: mode

          if (mode.eq.1) then
            fxyz = sqrt(3.0d0)/9.0d0 * r**3 * exp(-a*r**2) *
     .                                                 sqrt(15.0d0)
          elseif (mode.eq.2) then
            fxyz = (-3.0D0 + 2.0D0 * a * r**2) *
     .             (-sqrt(3.0d0))/9 * r**2 * exp(-a * r**2) *
     .                                                 sqrt(15.0d0)
          elseif (mode.eq.3) then
            fxyz = 0.5 * sqrt(6.0d0/a) + trustr
          endif

        end function fxyz



        real*8 function lapl_sx(mode,a,x)

          real*8 :: a,x
          integer :: mode !mode=1: laplacian in x-direction
                          !mode=2: derivative of laplacian in x-direction
                          !mode=3: position of largest extreme value (root of derivative)

          if (mode.eq.1) then
            lapl_sx = (2.0d0 * a * x**2 - 3.0d0)* 2.0d0 * a * 
     .                exp(-a * x**2)
          elseif (mode.eq.2) then
            lapl_sx = (-0.5D1 + 0.2D1 * x**2 * a) *
     .               (-0.4D1 * a**2 * x * exp(-x**2 * a))
          elseif (mode.eq.3) then
            lapl_sx = sqrt(0.10D2) * a**(-0.1D1 / 0.2D1) / 0.2D1 +trustr
          endif

        end function lapl_sx



        real*8 function lapl_px(mode,a,x)

          real*8 :: a,x
          integer :: mode !mode=1: laplacian in x-direction
                          !mode=2: derivative of laplacian in x-direction
                          !mode=3: position of largest extreme value (root of derivative)

          if (mode.eq.1) then
            lapl_px = (-5.0d0 + 2.0d0 * x**2 * a) * 
     .                               2.0d0 * a * x * exp(-a * x**2)
          elseif (mode.eq.2) then
            lapl_px = (-16.0d0 * x**2 * a + 5.0d0 + 4 * x**4 * a**2) *
     .                (-2.0d0 * a * exp(-x**2*a))
          elseif (mode.eq.3) then
            lapl_px = (16.0d0 + 4.0d0 * sqrt(11.0d0)) * sqrt(2.0d0) * 
     .      (a * (4.0d0 + sqrt(11.0d0))) ** (-1.0d0 / 2.0d0) / 8.0d0 +
     .                                                    trustr
          endif

        end function lapl_px


        real*8 function lapl_dxx(mode,a,x)

          real*8 :: a,x
          integer :: mode !mode=1: laplacian in x-direction
                          !mode=2: derivative of laplacian in x-direction
                          !mode=3: position of largest extreme value (root of derivative)

          if (mode.eq.1) then
           lapl_dxx = (1.0d0 - 7.0d0 * x**2 * a + 2.0d0 * x**4 * a**2)*
     .                  2 * exp(-a * x**2)
          elseif (mode.eq.2) then
           lapl_dxx = (8.0d0 - 11.0d0 * a * x**2 + 2.0d0 * x**4 * a**2)*
     .                 (-4.0d0) * a * x * exp(-a * x**2)
          elseif (mode.eq.3) then
           lapl_dxx = (0.44D2 + 0.4D1 * sqrt(0.57D2)) * 
     .     (a * (0.11D2 + sqrt(0.57D2))) ** (-0.1D1 / 0.2D1) / 0.8D1 +
     .                                                     trustr
          endif

        end function lapl_dxx


        real*8 function lapl_dxy(mode,a,r)

          real*8 :: a,r  !r = sqrt(x**2+y**2) = sqrt(2.0d0)*x
          integer :: mode !mode=1: laplacian in xy-direction (x = y)
                          !mode=2: derivative of laplacian in xy-direction
                          !mode=3: position of largest extreme value (root of derivative)

          if (mode.eq.1) then
           lapl_dxy = (-7.0d0 + 2.0d0 * a * r**2) * 
     .                 r**2 * a * exp(-a * r**2)
          elseif (mode.eq.2) then
           lapl_dxy = (7.0d0 - 11.0d0 * a * r**2 + 2 * r**4 * a**2) *
     .                (-2.0d0) * a * r * exp(-a * r**2)
          elseif (mode.eq.3) then
           lapl_dxy = (0.44D2 + 0.4D1 * sqrt(0.65D2)) * 
     .     (a * (0.11D2 + sqrt(0.65D2))) ** (-0.1D1 / 0.2D1) / 0.8D1 +
     .                                                    trustr
          endif

        end function lapl_dxy


        real*8 function lapl_fxxx(mode,a,x)

          real*8 :: a,x  
          integer :: mode !mode=1: laplacian in x-direction
                          !mode=2: derivative of laplacian in x-direction
                          !mode=3: position of largest extreme value (root of derivative)

          if (mode.eq.1) then
           lapl_fxxx = (3.0d0 - 9.0d0 * a * x**2 + 2 * x**4 * a**2)*
     .                 2.0d0 * x * exp(-a * x**2)
          elseif (mode.eq.2) then
           lapl_fxxx = (-3.0d0 + 33.0d0 * a * x**2 - 28.0d0 * x**4 * 
     .                 a**2 +  4.0d0 * x**6 * a**3) *
     .                 (-2.0d0) * exp(-a * x**2)
          elseif (mode.eq.3) then
           ! this one is too hard for maple...
            call abortp('error in function fxxx')
          endif

        end function lapl_fxxx


        real*8 function lapl_fxxy(mode,a,r)

          real*8 :: a,r 
          integer :: mode !mode=1: laplacian in x^2y-direction
                          !--> y=1/3*sqrt(3)*r; x=1/3*sqrt(6)*r
                          !mode=2: derivative of laplacian in x-direction
                          !mode=3: position of largest extreme value (root of derivative)

          if (mode.eq.1) then
           lapl_fxxy = (0.3D1 - 0.18D2 * a * r**2 + 
     .                            0.4D1 * r**4 * a**2) *
     .           0.2D1 / 0.9D1 * sqrt(0.3D1) * r * exp(-a * r**2)
          elseif (mode.eq.2) then
           lapl_fxxy =(-0.3D1 + 0.60D2 * a * r**2 - 0.56D2 * r**4 * 
     .                 a**2 + 0.8D1 * a**3 * r**6) *
     .                 (-0.2D1) / 0.9D1 * sqrt(0.3D1) * exp(-a * r ** 2)
          elseif (mode.eq.3) then
           ! this one is too hard for maple...
            call abortp('error in function fxxy')
          endif

        end function lapl_fxxy


        real*8 function lapl_fxyz(mode,a,r)

          real*8 :: a,r 
          integer :: mode !mode=1: laplacian in xyz-direction (x=y=z)
                          !--> 
                          !mode=2: derivative of laplacian in x-direction
                          !mode=3: position of largest extreme value (root of derivative)

          if (mode.eq.1) then
           lapl_fxyz =  (-0.9D1 + 0.2D1 * a * r**2) *
     .       0.2D1 / 0.9D1 * r**3 * sqrt(0.3D1) * a * exp(-a * r**2)
          elseif (mode.eq.2) then
           lapl_fxyz =  (0.27D2 - 0.28D2 * a * r**2 + 
     .                   0.4D1 * r**4 * a**2) *
     . (-0.2D1) / 0.9D1 * r**2 * sqrt(0.3D1) * a * exp(-a * r**2) 
          elseif (mode.eq.3) then
           lapl_fxyz = (0.28D2 + 0.4D1 * sqrt(0.22D2)) * sqrt(0.2D1) * 
     .      (a * (0.7D1 + sqrt(0.22D2))) ** (-0.1D1 / 0.2D1) / 0.8D1 +
     .                                                    trustr
          endif

        end function lapl_fxyz


      end subroutine ao_cut
