      MODULE aomo

      use wfdata
      use aos
      use aosdata
      use aomo_task
      use mos
      use cubicspline
      implicit none

      CONTAINS

c     ----------------------------------
      subroutine calc_aomo(ie,x,y,z,rai)
c     ----------------------------------
      ! automatically calls the correct routines to calculate the AOs and MOs
      ! depending on the user preferences
        integer, intent(in) :: ie
        real*8, dimension(:), intent(in) :: x, y, z
        real*8, dimension(:,:), intent(in) :: rai

        if (aomocomb) then
          if (spline) then
            if (cutmo) then
              call aomocut1spl_calc(ie,x,y,z,rai)
            else
              call aomo1spl_calc(ie,x,y,z,rai)
            endif
          else
            if (cutmo) then
              call aomocut1_calc(ie,x,y,z,rai)
            else
              call aomo1_calc(ie,x,y,z,rai)
            endif
          endif
        else
          if (spline) then
            call ao1splcalc(ie,x,y,z,rai)
          else
            call ao1calc(ie,x,y,z,rai)
          endif
          call mo1calc(ie)
        endif
      end subroutine

c     ----------------------------------
      subroutine aomo_calc(ie,x,y,z,rai)
c     ----------------------------------
        integer ie                 ! if >0 only AO's for electron ie recalculated

        real*8, dimension(:) :: x,y,z    ! x,y,z coordinates of position vector
        real*8, dimension(:,:) :: rai ! r_ai electron-nucleus distances

        if(aomotask) then
          if(aomopair) then
            call aomo_calc_task_pair(ie,x,y,z,rai)
          else
            call aomo_calc_task(ie,x,y,z,rai)
          endif
        else
          call aomo_calc_orig(ie,x,y,z,rai)
        endif
      end subroutine

c     ----------------------------------
      subroutine aomo_calc_orig(ie,x,y,z,rai)
c     ----------------------------------

c input parameters:
      integer ie                 ! if >0 only AO's for electron ie recalculated

      real*8, dimension(:) :: x,y,z    ! x,y,z coordinates of position vector
      real*8, dimension(:,:) :: rai ! r_ai electron-nucleus distances

c constants:
      real*8 :: sqr3,sqr5
      parameter (sqr3=1.73205080756887729d0,sqr5=2.236067977499789696d0)
c local variables
      integer :: bf,a,i,i1,i2,ii,ic
      integer :: j,d,moc
      real*8 :: xx,yy,zz,rr,r2,alp,nrm,u,ux,dx,dy,dz,tmp,
     .       dx2,dy2,dz2,dxyz,dxdy,dxdz,dydz
      real*8 :: dy2dx,dx2dy,dx2dz,dz2dx,dy2dz,dz2dy,dxdydz
ccc
      real*8, dimension(5)     :: tmps !second index means:
      real*8, dimension(0:2,5) :: tmpp !1:   AO itsself
      real*8, dimension(0:5,5) :: tmpd !2-4: derivative with respect to x,y,z
      real*8, dimension(0:9,5) :: tmpf !5:   laplacian
      logical gaussFOrder       ! .t.: Gaussian order for f function
                                ! .f.: Gamess==Turbomole order used



c bf refers to the degenerate set of cartesian
c basis function (S:1,P:3,D:6,F:10) as input, which may be of type STO
c or contracted GTO.
c al refers to the individual basis function, as used in LCAO-MO's.
c (composed in subroutine mdetwf)
c i refers to the current electron.

c-----Calculation of the AO's and their derivatives

      if (evfmt=='gau' .or. evfmt=='mol' ) then
         gaussFOrder = .true.
      else
         gaussFOrder = .false.
      endif

      if (ie .eq. 0) then                     ! AO's for all electrons
         i1 = 1
         i2 = ne
      else
         i1 = ie                              ! only AO for electron ie
         i2 = ie
      endif

      do i=i1,i2                              ! loop over electrons
         xx = x(i)
         yy = y(i)
         zz = z(i)

         moc = 0                              !Pointer for cmoa array

c initialisation

         mat(1:norb,i,1)   = 0d0
         mat1x(1:norb,i,1) = 0d0
         mat1y(1:norb,i,1) = 0d0
         mat1z(1:norb,i,1) = 0d0
         mat2(1:norb,i,1)  = 0d0

         do bf=1,nbasf                        ! loop over basis functions
           a = bc(bf)                         ! center of AO
           rr = rai(a,i)                      ! r_ai

           if (cutao) then                    !AO - Cutoff
             if (rr.gt.aocuts(bf)) then       ! --> do nothing but adjusting the counters
               if (bl(bf) .eq. 'S') then
                 moc = moc + norb
               elseif (bl(bf) .eq. 'P') then
                 moc = moc + 3*norb
               elseif (bl(bf) .eq. 'D') then
                 moc = moc + 6*norb
               elseif (bl(bf) .eq. 'F') then
                 moc = moc + 10*norb
               else
                 call abortp('(getaos): wrong GTO')
               endif
               cycle  !continue with next basis function
             endif
           endif

            r2 = rr*rr

            if (bl(bf) .eq. 'S') then                 ! 1s GTO

               dx = xx-atoms(a)%cx
               dy = yy-atoms(a)%cy
               dz = zz-atoms(a)%cz

               tmps = 0d0

               do ic=1,ngto(bf)                     ! loop over contraction
                  alp = cntrctn(1,ic,bf)
                  u = cntrctn(2,ic,bf) * exp(-alp*r2)
                  ux = -2d0*alp*u

                  tmps(1) = tmps(1) + u
                  tmps(2) = tmps(2) + ux*dx
                  tmps(3) = tmps(3) + ux*dy
                  tmps(4) = tmps(4) + ux*dz
                  tmps(5) = tmps(5) + ux*(3d0-2d0*alp*r2)
               enddo
ccc MO calculation
               do j=1, norb
                 moc=moc+1
                 tmp = cmoa(moc)
                 mat(j,i,1)   = mat(j,i,1)   + tmp*tmps(1)
                 mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmps(2)
                 mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmps(3)
                 mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmps(4)
                 mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmps(5)
               enddo

            else if (bl(bf) .eq. 'P') then             ! 2p GTO's
c              // do all 3 P simultaneously (same exponent is required)
c              // order p_x,p_y,p_z

               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz

               dxdy = dx*dy
               dxdz = dx*dz
               dydz = dy*dz

               tmpp = 0d0

               do ic=1,ngto(bf)                      ! loop over contraction
                  alp = cntrctn(1,ic,bf)
                  u = cntrctn(2,ic,bf) * exp(-alp*r2)
                  ux = -2d0*alp*u

                  tmpp(0,1) = tmpp(0,1) + dx*u
                  tmpp(1,1) = tmpp(1,1) + dy*u
                  tmpp(2,1) = tmpp(2,1) + dz*u

                  tmpp(0,2) = tmpp(0,2) + u + ux*dx2
                  tmpp(1,2) = tmpp(1,2) + ux*dxdy
                  tmpp(2,2) = tmpp(2,2) + ux*dxdz
                  tmpp(0,3) = tmpp(0,3) + ux*dxdy
                  tmpp(1,3) = tmpp(1,3) + u + ux*dy2
                  tmpp(2,3) = tmpp(2,3) + ux*dydz
                  tmpp(0,4) = tmpp(0,4) + ux*dxdz
                  tmpp(1,4) = tmpp(1,4) + ux*dydz
                  tmpp(2,4) = tmpp(2,4) + u + ux*dz2

                  tmp = (5d0-2d0*alp*r2)*ux
                  tmpp(0,5) = tmpp(0,5) + tmp*dx
                  tmpp(1,5) = tmpp(1,5) + tmp*dy
                  tmpp(2,5) = tmpp(2,5) + tmp*dz
               enddo

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,2
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpp(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpp(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpp(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpp(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpp(d,5)
                 enddo
               enddo

            else if (bl(bf) .eq. 'D') then         ! 3d GTO
c              // do all 6 D simultaneously (same exponent is required)
c              // order: d_xx, d_yy, d_zz, d_xy, d_xz, d_yz  (like GAMESS)

               dx    = xx-atoms(a)%cx
               dx2   = dx*dx
               dy    = yy-atoms(a)%cy
               dy2   = dy*dy
               dz    = zz-atoms(a)%cz
               dz2   = dz*dz

               dxdy  = dx*dy
               dxdydz =dxdy*dz
               dy2dx = dxdy*dy
               dx2dy = dxdy*dx
               dxdz  = dx*dz
               dx2dz = dxdz*dx
               dz2dx = dxdz*dz
               dydz  = dy*dz
               dy2dz = dydz*dy
               dz2dy = dydz*dz

               tmpd = 0d0

               do ic=1,ngto(bf)                      ! loop over contraction
                  alp = cntrctn(1,ic,bf)
                  u = cntrctn(2,ic,bf) * exp(-alp*r2)
                  ux = -2d0*alp*u

                  tmpd(0,1) = tmpd(0,1) + dx2*u
                  tmpd(1,1) = tmpd(1,1) + dy2*u
                  tmpd(2,1) = tmpd(2,1) + dz2*u

                  tmpd(0,2) = tmpd(0,2) + (2d0*u + ux*dx2)*dx
                  tmpd(1,2) = tmpd(1,2) + dy2dx*ux
                  tmpd(2,2) = tmpd(2,2) + dz2dx*ux
                  tmpd(0,3) = tmpd(0,3) + dx2dy*ux
                  tmpd(1,3) = tmpd(1,3) + (2d0*u + ux*dy2)*dy
                  tmpd(2,3) = tmpd(2,3) + dz2dy*ux
                  tmpd(0,4) = tmpd(0,4) + dx2dz*ux
                  tmpd(1,4) = tmpd(1,4) + dy2dz*ux
                  tmpd(2,4) = tmpd(2,4) + (2d0*u + ux*dz2)*dz
                  tmp       = (7d0 - 2d0*alp*r2)*ux
                  tmpd(0,5) = tmpd(0,5) + 2d0*u + dx2*tmp
                  tmpd(1,5) = tmpd(1,5) + 2d0*u + dy2*tmp
                  tmpd(2,5) = tmpd(2,5) + 2d0*u + dz2*tmp

                  u = sqr3*u                   ! correction of norm
                  ux = sqr3*ux                 ! N(dxx)*sqr3 = N(dxy)

                  tmpd(3,1) = tmpd(3,1) + dxdy*u
                  tmpd(4,1) = tmpd(4,1) + dxdz*u
                  tmpd(5,1) = tmpd(5,1) + dydz*u
                  tmp = ux*dxdydz
                  tmpd(3,2) = tmpd(3,2) + (u + ux*dx2)*dy
                  tmpd(4,2) = tmpd(4,2) + (u + ux*dx2)*dz
                  tmpd(5,2) = tmpd(5,2) + tmp
                  tmpd(3,3) = tmpd(3,3) + (u + ux*dy2)*dx
                  tmpd(4,3) = tmpd(4,3) + tmp
                  tmpd(5,3) = tmpd(5,3) + (u + ux*dy2)*dz
                  tmpd(3,4) = tmpd(3,4) + tmp
                  tmpd(4,4) = tmpd(4,4) + (u + ux*dz2)*dx
                  tmpd(5,4) = tmpd(5,4) + (u + ux*dz2)*dy
                  tmp = (7d0 - 2d0*alp*r2)*ux
                  tmpd(3,5) = tmpd(3,5) + tmp*dxdy
                  tmpd(4,5) = tmpd(4,5) + tmp*dxdz
                  tmpd(5,5) = tmpd(5,5) + tmp*dydz

               enddo

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,5
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpd(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpd(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpd(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpd(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpd(d,5)
                 enddo
               enddo

            else if (bl(bf)=='F'.and..not.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, fd_xxy, f_xxz, f_yyx,
c              //   f_yyz, f_zzx, f_zzy, f_xyz  (like GAMESS)

               tmpf = 0d0

               do ic=1,ngto(bf)                      ! loop over contraction
                  alp = cntrctn(1,ic,bf)
                  u = cntrctn(2,ic,bf) * exp(-alp*r2)
                  dx = xx-atoms(a)%cx
                  dx2 = dx*dx
                  dy = yy-atoms(a)%cy
                  dy2 = dy*dy
                  dz = zz-atoms(a)%cz
                  dz2 = dz*dz
                  dxyz = dx*dy*dz
                  ux = -2d0*alp*u

c                 // f_xxx, f_yyy, f_zzz
                  tmpf(0,1) = tmpf(0,1) + dx2*dx*u
                  tmpf(1,1) = tmpf(1,1) + dy2*dy*u
                  tmpf(2,1) = tmpf(2,1) + dz2*dz*u

                  tmpf(0,2) = tmpf(0,2) + (3d0*u + ux*dx2)*dx2
                  tmpf(1,2) = tmpf(1,2) + dy2*dy*ux*dx
                  tmpf(2,2) = tmpf(2,2) + dz2*dz*ux*dx
                  tmpf(0,3) = tmpf(0,3) + dx2*dx*ux*dy
                  tmpf(1,3) = tmpf(1,3) + (3d0*u + ux*dy2)*dy2
                  tmpf(2,3) = tmpf(2,3) + dz2*dz*ux*dy
                  tmpf(0,4) = tmpf(0,4) + dx2*dx*ux*dz
                  tmpf(1,4) = tmpf(1,4) + dy2*dy*ux*dz
                  tmpf(2,4) = tmpf(2,4) + (3d0*u + ux*dz2)*dz2
                  tmp          = (9d0 - 2d0*alp*r2)*ux
                  tmpf(0,5) = tmpf(0,5) + (6d0*u + dx2*tmp)*dx
                  tmpf(1,5) = tmpf(1,5) + (6d0*u + dy2*tmp)*dy
                  tmpf(2,5) = tmpf(2,5) + (6d0*u + dz2*tmp)*dz

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
                  u = sqr5*u                   ! correction of norm
                  ux = sqr5*ux                 ! N(fxxx)*sqrt(5) = N(fxxy)

                  tmpf(3,1) = tmpf(3,1) + dx2*dy*u
                  tmpf(4,1) = tmpf(4,1) + dx2*dz*u
                  tmpf(5,1) = tmpf(5,1) + dy2*dx*u
                  tmpf(6,1) = tmpf(6,1) + dy2*dz*u
                  tmpf(7,1) = tmpf(7,1) + dz2*dx*u
                  tmpf(8,1) = tmpf(8,1) + dz2*dy*u

c derivatives
                  tmp = ux*dxyz
                  tmpf(3,2) = tmpf(3,2) + (2d0*u + ux*dx2)*dx*dy
                  tmpf(4,2) = tmpf(4,2) + (2d0*u + ux*dx2)*dx*dz
                  tmpf(5,2) = tmpf(5,2) + (u + ux*dx2)*dy2
                  tmpf(6,2) = tmpf(6,2) + tmp*dy
                  tmpf(7,2) = tmpf(7,2) + (u + ux*dx2)*dz2
                  tmpf(8,2) = tmpf(8,2) + tmp*dz
                  tmpf(3,3) = tmpf(3,3) + (u + ux*dy2)*dx2
                  tmpf(4,3) = tmpf(4,3) + tmp*dx
                  tmpf(5,3) = tmpf(5,3) + (2d0*u + ux*dy2)*dx*dy
                  tmpf(6,3) = tmpf(6,3) + (2d0*u + ux*dy2)*dy*dz
                  tmpf(7,3) = tmpf(7,3) + tmp*dz
                  tmpf(8,3) = tmpf(8,3) + (u + ux*dy2)*dz2
                  tmpf(3,4) = tmpf(3,4) + tmp*dx
                  tmpf(4,4) = tmpf(4,4) + (u + ux*dz2)*dx2
                  tmpf(5,4) = tmpf(5,4) + tmp*dy
                  tmpf(6,4) = tmpf(6,4) + (u + ux*dz2)*dy2
                  tmpf(7,4) = tmpf(7,4) + (2d0*u + ux*dz2)*dx*dz
                  tmpf(8,4) = tmpf(8,4) + (2d0*u + ux*dz2)*dy*dz
c laplacians
                  tmp = (9d0 - 2d0*alp*r2)*ux
                  tmpf(3,5) = tmpf(3,5) + (2d0*u + dx2*tmp)*dy
                  tmpf(4,5) = tmpf(4,5) + (2d0*u + dx2*tmp)*dz
                  tmpf(5,5) = tmpf(5,5) + (2d0*u + dy2*tmp)*dx
                  tmpf(6,5) = tmpf(6,5) + (2d0*u + dy2*tmp)*dz
                  tmpf(7,5) = tmpf(7,5) + (2d0*u + dz2*tmp)*dx
                  tmpf(8,5) = tmpf(8,5) + (2d0*u + dz2*tmp)*dy

c                 // f_xyz
                  u = sqr3*u                  ! correction of norm
                  ux = sqr3*ux                ! N(fxxx)*sqrt(15)=
                                              ! N(fxxy)*sqrt(3)=N(fxyz)

                  tmpf(9,1) = tmpf(9,1) + dxyz*u

                  tmpf(9,2) = tmpf(9,2) + (u + ux*dx2)*dy*dz
                  tmpf(9,3) = tmpf(9,3) + (u + ux*dy2)*dx*dz
                  tmpf(9,4) = tmpf(9,4) + (u + ux*dz2)*dx*dy
                  tmp = (9d0 - 2d0*alp*r2)*ux
                  tmpf(9,5) = tmpf(9,5) + dxyz*tmp

               enddo

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpf(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpf(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpf(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpf(d,5)
                 enddo
               enddo

            else if (bl(bf)=='F'.and.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, f_xyy, f_xxy, f_xxz,
c              //   f_xzz, f_yzz, f_yyz, f_xyz  (like Gaussian)

               tmpf = 0d0

               do ic=1,ngto(bf)                      ! loop over contraction
                  alp = cntrctn(1,ic,bf)
                  u = cntrctn(2,ic,bf) * exp(-alp*r2)
                  dx = xx-atoms(a)%cx
                  dx2 = dx*dx
                  dy = yy-atoms(a)%cy
                  dy2 = dy*dy
                  dz = zz-atoms(a)%cz
                  dz2 = dz*dz
                  dxyz = dx*dy*dz
                  ux = -2d0*alp*u

c                 // f_xxx, f_yyy, f_zzz
                  tmpf(0,1) = tmpf(0,1) + dx2*dx*u
                  tmpf(1,1) = tmpf(1,1) + dy2*dy*u
                  tmpf(2,1) = tmpf(2,1) + dz2*dz*u

                  tmpf(0,2) = tmpf(0,2) + (3d0*u + ux*dx2)*dx2
                  tmpf(1,2) = tmpf(1,2) + dy2*dy*ux*dx
                  tmpf(2,2) = tmpf(2,2) + dz2*dz*ux*dx
                  tmpf(0,3) = tmpf(0,3) + dx2*dx*ux*dy
                  tmpf(1,3) = tmpf(1,3) + (3d0*u + ux*dy2)*dy2
                  tmpf(2,3) = tmpf(2,3) + dz2*dz*ux*dy
                  tmpf(0,4) = tmpf(0,4) + dx2*dx*ux*dz
                  tmpf(1,4) = tmpf(1,4) + dy2*dy*ux*dz
                  tmpf(2,4) = tmpf(2,4) + (3d0*u + ux*dz2)*dz2
                  tmp          = (9d0 - 2d0*alp*r2)*ux
                  tmpf(0,5) = tmpf(0,5) + (6d0*u + dx2*tmp)*dx
                  tmpf(1,5) = tmpf(1,5) + (6d0*u + dy2*tmp)*dy
                  tmpf(2,5) = tmpf(2,5) + (6d0*u + dz2*tmp)*dz

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
                  u = sqr5*u                   ! correction of norm
                  ux = sqr5*ux                 ! N(fxxx)*sqrt(5) = N(fxxy)

                  tmpf(4,1) = tmpf(4,1) + dx2*dy*u
                  tmpf(5,1) = tmpf(5,1) + dx2*dz*u
                  tmpf(3,1) = tmpf(3,1) + dy2*dx*u
                  tmpf(8,1) = tmpf(8,1) + dy2*dz*u
                  tmpf(6,1) = tmpf(6,1) + dz2*dx*u
                  tmpf(7,1) = tmpf(7,1) + dz2*dy*u

c derivatives
                  tmp = ux*dxyz
                  tmpf(4,2) = tmpf(4,2) + (2d0*u + ux*dx2)*dx*dy
                  tmpf(5,2) = tmpf(5,2) + (2d0*u + ux*dx2)*dx*dz
                  tmpf(3,2) = tmpf(3,2) + (u + ux*dx2)*dy2
                  tmpf(8,2) = tmpf(8,2) + tmp*dy
                  tmpf(6,2) = tmpf(6,2) + (u + ux*dx2)*dz2
                  tmpf(7,2) = tmpf(7,2) + tmp*dz
                  tmpf(4,3) = tmpf(4,3) + (u + ux*dy2)*dx2
                  tmpf(5,3) = tmpf(5,3) + tmp*dx
                  tmpf(3,3) = tmpf(3,3) + (2d0*u + ux*dy2)*dx*dy
                  tmpf(8,3) = tmpf(8,3) + (2d0*u + ux*dy2)*dy*dz
                  tmpf(6,3) = tmpf(6,3) + tmp*dz
                  tmpf(7,3) = tmpf(7,3) + (u + ux*dy2)*dz2
                  tmpf(4,4) = tmpf(4,4) + tmp*dx
                  tmpf(5,4) = tmpf(5,4) + (u + ux*dz2)*dx2
                  tmpf(3,4) = tmpf(3,4) + tmp*dy
                  tmpf(8,4) = tmpf(8,4) + (u + ux*dz2)*dy2
                  tmpf(6,4) = tmpf(6,4) + (2d0*u + ux*dz2)*dx*dz
                  tmpf(7,4) = tmpf(7,4) + (2d0*u + ux*dz2)*dy*dz
c laplacians
                  tmp = (9d0 - 2d0*alp*r2)*ux
                  tmpf(4,5) = tmpf(4,5) + (2d0*u + dx2*tmp)*dy
                  tmpf(5,5) = tmpf(5,5) + (2d0*u + dx2*tmp)*dz
                  tmpf(3,5) = tmpf(3,5) + (2d0*u + dy2*tmp)*dx
                  tmpf(8,5) = tmpf(8,5) + (2d0*u + dy2*tmp)*dz
                  tmpf(6,5) = tmpf(6,5) + (2d0*u + dz2*tmp)*dx
                  tmpf(7,5) = tmpf(7,5) + (2d0*u + dz2*tmp)*dy

c                 // f_xyz
                  u = sqr3*u                  ! correction of norm
                  ux = sqr3*ux                ! N(fxxx)*sqrt(15)=
                                              ! N(fxxy)*sqrt(3)=N(fxyz)

                  tmpf(9,1) = tmpf(9,1) + dxyz*u

                  tmpf(9,2) = tmpf(9,2) + (u + ux*dx2)*dy*dz
                  tmpf(9,3) = tmpf(9,3) + (u + ux*dy2)*dx*dz
                  tmpf(9,4) = tmpf(9,4) + (u + ux*dz2)*dx*dy
                  tmp = (9d0 - 2d0*alp*r2)*ux
                  tmpf(9,5) = tmpf(9,5) + dxyz*tmp

               enddo

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpf(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpf(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpf(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpf(d,5)
                 enddo
               enddo

            else
               call abortp('(getaos): wrong GTO')
            endif  ! bl
         enddo    ! bf-loop over basis functions
      enddo       ! i-loop over electrons

      end subroutine aomo_calc_orig



c     -----------------------------------
      subroutine aomo1_calc(ie,x,y,z,rai)
c     -----------------------------------

      integer ie                 ! if >0 only AO's for electron ie recalculated

      real*8, dimension(:)      :: x,y,z  ! x,y,z coordinates of position vector
      real*8, dimension(:,:) :: rai    ! r_ai electron-nucleus distances


c constants:
      real*8 :: sqr3,sqr5
      parameter (sqr3=1.73205080756887729d0,sqr5=2.236067977499789696d0)
c variables
      integer :: bf,a,i,ii,i1,i2,ic
      integer :: j,d,moc
      real*8 :: xx,yy,zz,rr,alp,nrm,u,dx,dy,dz,r2,dx2,dy2,dz2
      real*8 :: dxdy,dxdz,dydz
      real*8 :: tmp

ccc
      real*8                 :: tmps
      real*8, dimension(0:2) :: tmpp
      real*8, dimension(0:5) :: tmpd
      real*8, dimension(0:9) :: tmpf
      logical gaussFOrder       ! .t.: Gaussian order for f function
                                ! .f.: Gamess==Turbomole order used


      if (evfmt=='gau' .or. evfmt=='mol' ) then
         gaussFOrder = .true.
      else
         gaussFOrder = .false.
      endif


c-----Calculation of the AO's

      if (ie .eq. 0) then                     ! AO's for all electrons
         i1 = 1
         i2 = ne
      else
         i1 = ie                              ! only AO for electron ie
         i2 = ie
      endif

      do i=i1,i2                              ! loop over electrons
         xx = x(i)
         yy = y(i)
         zz = z(i)

         moc= 0                               !Pointer for cmoa array

c initialisation
         mat(1:norb,i,1)   = 0d0

         do bf=1,nbasf                        ! loop over basis functions
           a = bc(bf)                         ! center of AO
           rr = rai(a,i)                      ! r_ai

           if (cutao) then                    !AO - Cutoff
             if (rr.gt.aocuts(bf)) then       ! --> do nothing but adjusting the counter
               if (bl(bf) .eq. 'S') then
                 moc = moc + norb
               elseif (bl(bf) .eq. 'P') then
                 moc = moc + 3*norb
               elseif (bl(bf) .eq. 'D') then
                 moc = moc + 6*norb
               elseif (bl(bf) .eq. 'F') then
                 moc = moc + 10*norb
               else
                 call abortp('(getaos): wrong GTO')
               endif
               cycle
             endif
           endif

           r2 = rr*rr

           if (bl(bf) .eq. 'S') then                 ! 1s GTO

              tmps = 0d0

              do ic=1,ngto(bf) ! loop over contraction
                 alp = cntrctn(1,ic,bf)
                 u = cntrctn(2,ic,bf) * exp(-alp*r2)

                 tmps = tmps + u
              enddo

ccc MO calculation
              do j=1, norb
                moc=moc+1
                mat(j,i,1)   = mat(j,i,1)   + cmoa(moc)*tmps
              enddo

           else if (bl(bf) .eq. 'P') then             ! 2p GTO's
c              // do all 3 P simultaneously (same exponent is required)
c              // order p_x,p_y,p_z

              dx = xx-atoms(a)%cx
              dy = yy-atoms(a)%cy
              dz = zz-atoms(a)%cz

              tmpp = 0d0

              do ic=1,ngto(bf)                      ! loop over contraction
                 alp = cntrctn(1,ic,bf)
                 u = cntrctn(2,ic,bf) * exp(-alp*r2)

                 tmpp(0) = tmpp(0) + dx*u
                 tmpp(1) = tmpp(1) + dy*u
                 tmpp(2) = tmpp(2) + dz*u
              enddo

ccc MO calculation
              do j=1, norb
                do d=0,2
                  moc=moc+1
                  mat(j,i,1)   = mat(j,i,1)   + cmoa(moc)*tmpp(d)
                enddo
              enddo

           else if (bl(bf) .eq. 'D') then         ! 3d GTO
c              // do all 6 D simultaneously (same exponent is required)
c              // order: d_xx, d_yy, d_zz, d_xy, d_xz, d_yz  (like GAMESS)

              dx = xx-atoms(a)%cx
              dx2 = dx*dx
              dy = yy-atoms(a)%cy
              dy2 = dy*dy
              dz = zz-atoms(a)%cz
              dz2 = dz*dz

              dxdy = dx*dy
              dxdz = dx*dz
              dydz = dy*dz

              tmpd = 0d0

              do ic=1,ngto(bf)                      ! loop over contraction
                 alp = cntrctn(1,ic,bf)
                 u = cntrctn(2,ic,bf) * exp(-alp*r2)

                 tmpd(0) = tmpd(0) + dx2*u
                 tmpd(1) = tmpd(1) + dy2*u
                 tmpd(2) = tmpd(2) + dz2*u

                 u = sqr3*u                   ! correction of norm for last 3

                 tmpd(3) = tmpd(3)  + dxdy*u
                 tmpd(4) = tmpd(4)  + dxdz*u
                 tmpd(5) = tmpd(5)  + dydz*u

              enddo

ccc MO calculation
              do j=1, norb
                do d=0,5
                  moc=moc+1
                  mat(j,i,1)   = mat(j,i,1)   + cmoa(moc)*tmpd(d)
                enddo
              enddo

           else if (bl(bf)=='F'.and..not.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, fd_xxy, f_xxz, f_yyx,
c              //   f_yyz, f_zzx, f_zzy, f_xyz  (like GAMESS)

              tmpf = 0d0

              do ic=1,ngto(bf)                      ! loop over contraction
                 alp = cntrctn(1,ic,bf)
                 u = cntrctn(2,ic,bf) * exp(-alp*r2)
                 dx = xx-atoms(a)%cx
                 dx2 = dx*dx
                 dy = yy-atoms(a)%cy
                 dy2 = dy*dy
                 dz = zz-atoms(a)%cz
                 dz2 = dz*dz

c                 // f_xxx, f_yyy, f_zzz
                 tmpf(0) = tmpf(0) + dx2*dx*u
                 tmpf(1) = tmpf(1) + dy2*dy*u
                 tmpf(2) = tmpf(2) + dz2*dz*u

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
                 u = sqr5*u                   ! correction of norm

                 tmpf(3) = tmpf(3) + dx2*dy*u
                 tmpf(4) = tmpf(4) + dx2*dz*u
                 tmpf(5) = tmpf(5) + dy2*dx*u
                 tmpf(6) = tmpf(6) + dy2*dz*u
                 tmpf(7) = tmpf(7) + dz2*dx*u
                 tmpf(8) = tmpf(8) + dz2*dy*u

c                 // f_xyz
                 u = sqr3*u                  ! correction of norm

                 tmpf(9) = tmpf(9) + dx*dy*dz*u

               enddo
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   mat(j,i,1)   = mat(j,i,1)   + cmoa(moc)*tmpf(d)
                 enddo
               enddo

            else if (bl(bf)=='F'.and.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, f_xyy, f_xxy, f_xxz,
c              //   f_xzz, f_yzz, f_yyz, f_xyz  (like Gaussian)

              tmpf = 0d0

              do ic=1,ngto(bf)                      ! loop over contraction
                 alp = cntrctn(1,ic,bf)
                 u = cntrctn(2,ic,bf) * exp(-alp*r2)
                 dx = xx-atoms(a)%cx
                 dx2 = dx*dx
                 dy = yy-atoms(a)%cy
                 dy2 = dy*dy
                 dz = zz-atoms(a)%cz
                 dz2 = dz*dz

c                 // f_xxx, f_yyy, f_zzz
                 tmpf(0) = tmpf(0) + dx2*dx*u
                 tmpf(1) = tmpf(1) + dy2*dy*u
                 tmpf(2) = tmpf(2) + dz2*dz*u

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
                 u = sqr5*u                   ! correction of norm

                 tmpf(4) = tmpf(4) + dx2*dy*u
                 tmpf(5) = tmpf(5) + dx2*dz*u
                 tmpf(3) = tmpf(3) + dy2*dx*u
                 tmpf(8) = tmpf(8) + dy2*dz*u
                 tmpf(6) = tmpf(6) + dz2*dx*u
                 tmpf(7) = tmpf(7) + dz2*dy*u

c                 // f_xyz
                 u = sqr3*u                  ! correction of norm

                 tmpf(9) = tmpf(9) + dx*dy*dz*u

               enddo
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   mat(j,i,1)   = mat(j,i,1)   + cmoa(moc)*tmpf(d)
                 enddo
               enddo

            else
               call abortp('(getaos): wrong GTO')
            endif  ! bl
         enddo     ! bf-loop over basis functions
      enddo        ! i-loop over electrons

      end subroutine aomo1_calc


c     ----------------------------------
c     -------------------------------------
      subroutine aomospl_calc(ie,x,y,z,rai)
c     -------------------------------------

c input parameters:
      integer ie                 ! if >0 only AO's for electron ie recalculated

      real*8, dimension(:) :: x,y,z    ! x,y,z coordinates of position vector
      real*8, dimension(:,:) :: rai ! r_ai electron-nucleus distances

c constants:
      real*8 :: sqr3,sqr5
      parameter (sqr3=1.73205080756887729d0,sqr5=2.236067977499789696d0)
c local variables
      integer :: bf,a,i,i1,i2,ii,ic
      integer :: j,d,moc
      integer :: spl,ispl
      real*8 :: xx,yy,zz,rr,r2,alp,nrm,u,ux,uxx,u2,dx,dy,dz,tmp,
     .       dx2,dy2,dz2,dxyz,dxdy,dxdz,dydz
      real*8 :: df
ccc
      real*8, dimension(5)     :: tmps !second index means:
      real*8, dimension(0:2,5) :: tmpp !1:   AO itsself
      real*8, dimension(0:5,5) :: tmpd !2-4: derivative with respect to x,y,z
      real*8, dimension(0:9,5) :: tmpf !5:   laplacian
      logical gaussFOrder       ! .t.: Gaussian order for f function
                                ! .f.: Gamess==Turbomole order used


c bf refers to the degenerate set of cartesian
c basis function (S:1,P:3,D:6,F:10) as input, which may be of type STO
c or contracted GTO.
c al refers to the individual basis function, as used in LCAO-MO's.
c (composed in subroutine mdetwf)
c i refers to the current electron.

c-----Calculation of the AO's and their derivatives

      if (evfmt=='gau' .or. evfmt=='mol' ) then
         gaussFOrder = .true.
      else
         gaussFOrder = .false.
      endif

      if (ie .eq. 0) then                     ! AO's for all electrons
         i1 = 1
         i2 = ne
      else
         i1 = ie                              ! only AO for electron ie
         i2 = ie
      endif

      do i=i1,i2                              ! loop over electrons
         xx = x(i)
         yy = y(i)
         zz = z(i)

         moc = 0                              !Pointer for cmoa array

c initialisation

         mat(1:norb,i,1)   = 0d0
         mat1x(1:norb,i,1) = 0d0
         mat1y(1:norb,i,1) = 0d0
         mat1z(1:norb,i,1) = 0d0
         mat2(1:norb,i,1)  = 0d0

         do bf=1,nbasf                        ! loop over basis functions
           a = bc(bf)                         ! center of AO
           rr = rai(a,i)                      ! r_ai

           if (cutao) then                    !AO - Cutoff
             if (rr.gt.aocuts(bf)) then       ! --> do nothing but adjusting the counters
               if (bl(bf) .eq. 'S') then
                 moc = moc + norb
               elseif (bl(bf) .eq. 'P') then
                 moc = moc + 3*norb
               elseif (bl(bf) .eq. 'D') then
                 moc = moc + 6*norb
               elseif (bl(bf) .eq. 'F') then
                 moc = moc + 10*norb
               else
                 call abortp('(getaos): wrong GTO')
               endif
               cycle  !continue with next basis function
             endif
           endif

           r2 = rr*rr

           if (so(bf).eq.0) then !only 1 GTO in contraction, no splines used !

            if (bl(bf) .eq. 'S') then                 ! 1s GTO

               dx = xx-atoms(a)%cx
               dy = yy-atoms(a)%cy
               dz = zz-atoms(a)%cz

               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)
               ux = -2d0*alp*u

ccc tmps(1) not used here because u directly in MO loop
               tmps(2) = ux*dx
               tmps(3) = ux*dy
               tmps(4) = ux*dz
               tmps(5) = ux*(3d0-2d0*alp*r2)

ccc MO calculation
               do j=1, norb
                 moc=moc+1
                 tmp = cmoa(moc)
                 mat(j,i,1)   = mat(j,i,1)   + tmp*u
                 mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmps(2)
                 mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmps(3)
                 mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmps(4)
                 mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmps(5)
               enddo

            else if (bl(bf) .eq. 'P') then             ! 2p GTO's
c              // do all 3 P simultaneously (same exponent is required)
c              // order p_x,p_y,p_z

               dx = xx-atoms(a)%cx
               dy = yy-atoms(a)%cy
               dz = zz-atoms(a)%cz

               dxdy = dx*dy
               dxdz = dx*dz
               dydz = dy*dz

               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)
               ux = -2d0*alp*u

               tmpp(0,1) = dx*u
               tmpp(1,1) = dy*u
               tmpp(2,1) = dz*u

               tmpp(0,2) = u + ux*dx*dx
               tmpp(1,2) = ux*dxdy
               tmpp(2,2) = ux*dxdz
               tmpp(0,3) = ux*dxdy
               tmpp(1,3) = u + ux*dy*dy
               tmpp(2,3) = ux*dydz
               tmpp(0,4) = ux*dxdz
               tmpp(1,4) = ux*dydz
               tmpp(2,4) = u + ux*dz*dz

               tmp = (5d0-2d0*alp*r2)*ux
               tmpp(0,5) = tmp*dx
               tmpp(1,5) = tmp*dy
               tmpp(2,5) = tmp*dz

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,2
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpp(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpp(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpp(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpp(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpp(d,5)
                 enddo
               enddo

            else if (bl(bf) .eq. 'D') then         ! 3d GTO
c              // do all 6 D simultaneously (same exponent is required)
c              // order: d_xx, d_yy, d_zz, d_xy, d_xz, d_yz  (like GAMESS)

               dx    = xx-atoms(a)%cx
               dx2   = dx*dx
               dy    = yy-atoms(a)%cy
               dy2   = dy*dy
               dz    = zz-atoms(a)%cz
               dz2   = dz*dz

               dxdy  = dx*dy
               dxdz  = dx*dz
               dydz  = dy*dz
ccc
               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)
               ux = -2d0*alp*u

               tmpd(0,1) = dx2*u
               tmpd(1,1) = dy2*u
               tmpd(2,1) = dz2*u

               tmpd(0,2) = (2d0*u + ux*dx2)*dx
               tmpd(1,2) = dxdy*dy*ux
               tmpd(2,2) = dxdz*dz*ux
               tmpd(0,3) = dxdy*dx*ux
               tmpd(1,3) = (2d0*u + ux*dy2)*dy
               tmpd(2,3) = dydz*dz*ux
               tmpd(0,4) = dxdz*dx*ux
               tmpd(1,4) = dydz*dy*ux
               tmpd(2,4) = (2d0*u + ux*dz2)*dz
               tmp       = (7d0 - 2d0*alp*r2)*ux
               tmpd(0,5) = 2d0*u + dx2*tmp
               tmpd(1,5) = 2d0*u + dy2*tmp
               tmpd(2,5) = 2d0*u + dz2*tmp

               u = sqr3*u                   ! correction of norm
               ux = sqr3*ux                 ! N(dxx)*sqr3 = N(dxy)

               tmpd(3,1) = dxdy*u
               tmpd(4,1) = dxdz*u
               tmpd(5,1) = dydz*u
               tmp = ux*dx*dy*dz
               tmpd(3,2) = (u + ux*dx2)*dy
               tmpd(4,2) = (u + ux*dx2)*dz
               tmpd(5,2) = tmp
               tmpd(3,3) = (u + ux*dy2)*dx
               tmpd(4,3) = tmp
               tmpd(5,3) = (u + ux*dy2)*dz
               tmpd(3,4) = tmp
               tmpd(4,4) = (u + ux*dz2)*dx
               tmpd(5,4) = (u + ux*dz2)*dy
               tmp = (7d0 - 2d0*alp*r2)*ux
               tmpd(3,5) = tmp*dxdy
               tmpd(4,5) = tmp*dxdz
               tmpd(5,5) = tmp*dydz

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,5
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpd(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpd(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpd(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpd(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpd(d,5)
                 enddo
               enddo

            else if (bl(bf)=='F'.and..not.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, fd_xxy, f_xxz, f_yyx,
c              //   f_yyz, f_zzx, f_zzy, f_xyz  (like GAMESS)

               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)
               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz
               dxyz = dx*dy*dz
               ux = -2d0*alp*u

c                 // f_xxx, f_yyy, f_zzz
               tmpf(0,1) = dx2*dx*u
               tmpf(1,1) = dy2*dy*u
               tmpf(2,1) = dz2*dz*u

               tmpf(0,2) = (3d0*u + ux*dx2)*dx2
               tmpf(1,2) = dy2*dy*ux*dx
               tmpf(2,2) = dz2*dz*ux*dx
               tmpf(0,3) = dx2*dx*ux*dy
               tmpf(1,3) = (3d0*u + ux*dy2)*dy2
               tmpf(2,3) = dz2*dz*ux*dy
               tmpf(0,4) = dx2*dx*ux*dz
               tmpf(1,4) = dy2*dy*ux*dz
               tmpf(2,4) = (3d0*u + ux*dz2)*dz2
               tmp          = (9d0 - 2d0*alp*r2)*ux
               tmpf(0,5) = (6d0*u + dx2*tmp)*dx
               tmpf(1,5) = (6d0*u + dy2*tmp)*dy
               tmpf(2,5) = (6d0*u + dz2*tmp)*dz

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
               u = sqr5*u                   ! correction of norm
               ux = sqr5*ux                 ! N(fxxx)*sqrt(5) = N(fxxy)

               tmpf(3,1) = dx2*dy*u
               tmpf(4,1) = dx2*dz*u
               tmpf(5,1) = dy2*dx*u
               tmpf(6,1) = dy2*dz*u
               tmpf(7,1) = dz2*dx*u
               tmpf(8,1) = dz2*dy*u

c derivatives
               tmp = ux*dxyz
               tmpf(3,2) = (2d0*u + ux*dx2)*dx*dy
               tmpf(4,2) = (2d0*u + ux*dx2)*dx*dz
               tmpf(5,2) = (u + ux*dx2)*dy2
               tmpf(6,2) = tmp*dy
               tmpf(7,2) = (u + ux*dx2)*dz2
               tmpf(8,2) = tmp*dz
               tmpf(3,3) = (u + ux*dy2)*dx2
               tmpf(4,3) = tmp*dx
               tmpf(5,3) = (2d0*u + ux*dy2)*dx*dy
               tmpf(6,3) = (2d0*u + ux*dy2)*dy*dz
               tmpf(7,3) = tmp*dz
               tmpf(8,3) = (u + ux*dy2)*dz2
               tmpf(3,4) = tmp*dx
               tmpf(4,4) = (u + ux*dz2)*dx2
               tmpf(5,4) = tmp*dy
               tmpf(6,4) = (u + ux*dz2)*dy2
               tmpf(7,4) = (2d0*u + ux*dz2)*dx*dz
               tmpf(8,4) = (2d0*u + ux*dz2)*dy*dz
c laplacians
               tmp = (9d0 - 2d0*alp*r2)*ux
               tmpf(3,5) = (2d0*u + dx2*tmp)*dy
               tmpf(4,5) = (2d0*u + dx2*tmp)*dz
               tmpf(5,5) = (2d0*u + dy2*tmp)*dx
               tmpf(6,5) = (2d0*u + dy2*tmp)*dz
               tmpf(7,5) = (2d0*u + dz2*tmp)*dx
               tmpf(8,5) = (2d0*u + dz2*tmp)*dy

c                 // f_xyz
               u = sqr3*u                  ! correction of norm
               ux = sqr3*ux                ! N(fxxx)*sqrt(15)=
                                           ! N(fxxy)*sqrt(3)=N(fxyz)
               tmpf(9,1) = dxyz*u

               tmpf(9,2) = (u + ux*dx2)*dy*dz
               tmpf(9,3) = (u + ux*dy2)*dx*dz
               tmpf(9,4) = (u + ux*dz2)*dx*dy
               tmp = (9d0 - 2d0*alp*r2)*ux
               tmpf(9,5) = dxyz*tmp


ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpf(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpf(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpf(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpf(d,5)
                 enddo
               enddo

            else if (bl(bf)=='F'.and.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, f_xyy, f_xxy, f_xxz,
c              //   f_xzz, f_yzz, f_yyz, f_xyz  (like Gaussian)

               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)
               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz
               dxyz = dx*dy*dz
               ux = -2d0*alp*u

c                 // f_xxx, f_yyy, f_zzz
               tmpf(0,1) = dx2*dx*u
               tmpf(1,1) = dy2*dy*u
               tmpf(2,1) = dz2*dz*u

               tmpf(0,2) = (3d0*u + ux*dx2)*dx2
               tmpf(1,2) = dy2*dy*ux*dx
               tmpf(2,2) = dz2*dz*ux*dx
               tmpf(0,3) = dx2*dx*ux*dy
               tmpf(1,3) = (3d0*u + ux*dy2)*dy2
               tmpf(2,3) = dz2*dz*ux*dy
               tmpf(0,4) = dx2*dx*ux*dz
               tmpf(1,4) = dy2*dy*ux*dz
               tmpf(2,4) = (3d0*u + ux*dz2)*dz2
               tmp          = (9d0 - 2d0*alp*r2)*ux
               tmpf(0,5) = (6d0*u + dx2*tmp)*dx
               tmpf(1,5) = (6d0*u + dy2*tmp)*dy
               tmpf(2,5) = (6d0*u + dz2*tmp)*dz

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
               u = sqr5*u                   ! correction of norm
               ux = sqr5*ux                 ! N(fxxx)*sqrt(5) = N(fxxy)

               tmpf(4,1) = dx2*dy*u
               tmpf(5,1) = dx2*dz*u
               tmpf(3,1) = dy2*dx*u
               tmpf(8,1) = dy2*dz*u
               tmpf(6,1) = dz2*dx*u
               tmpf(7,1) = dz2*dy*u

c derivatives
               tmp = ux*dxyz
               tmpf(4,2) = (2d0*u + ux*dx2)*dx*dy
               tmpf(5,2) = (2d0*u + ux*dx2)*dx*dz
               tmpf(3,2) = (u + ux*dx2)*dy2
               tmpf(8,2) = tmp*dy
               tmpf(6,2) = (u + ux*dx2)*dz2
               tmpf(7,2) = tmp*dz
               tmpf(4,3) = (u + ux*dy2)*dx2
               tmpf(5,3) = tmp*dx
               tmpf(3,3) = (2d0*u + ux*dy2)*dx*dy
               tmpf(8,3) = (2d0*u + ux*dy2)*dy*dz
               tmpf(6,3) = tmp*dz
               tmpf(7,3) = (u + ux*dy2)*dz2
               tmpf(4,4) = tmp*dx
               tmpf(5,4) = (u + ux*dz2)*dx2
               tmpf(3,4) = tmp*dy
               tmpf(8,4) = (u + ux*dz2)*dy2
               tmpf(6,4) = (2d0*u + ux*dz2)*dx*dz
               tmpf(7,4) = (2d0*u + ux*dz2)*dy*dz
c laplacians
               tmp = (9d0 - 2d0*alp*r2)*ux
               tmpf(4,5) = (2d0*u + dx2*tmp)*dy
               tmpf(5,5) = (2d0*u + dx2*tmp)*dz
               tmpf(3,5) = (2d0*u + dy2*tmp)*dx
               tmpf(8,5) = (2d0*u + dy2*tmp)*dz
               tmpf(6,5) = (2d0*u + dz2*tmp)*dx
               tmpf(7,5) = (2d0*u + dz2*tmp)*dy

c                 // f_xyz
               u = sqr3*u                  ! correction of norm
               ux = sqr3*ux                ! N(fxxx)*sqrt(15)=
                                           ! N(fxxy)*sqrt(3)=N(fxyz)
               tmpf(9,1) = dxyz*u

               tmpf(9,2) = (u + ux*dx2)*dy*dz
               tmpf(9,3) = (u + ux*dy2)*dx*dz
               tmpf(9,4) = (u + ux*dz2)*dx*dy
               tmp = (9d0 - 2d0*alp*r2)*ux
               tmpf(9,5) = dxyz*tmp


ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpf(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpf(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpf(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpf(d,5)
                 enddo
               enddo

            else
               call abortp('(getaos): wrong GTO')
            endif  ! bl


           else ! CGTO (more than one primitive gaussian) --> use splines

ccc            r2 = rr*rr
            spl  = (csplnpnt-1)*rr/(csalpha+rr)  + 1
            df = rr - csplx(spl)


            if (bl(bf) .eq. 'S') then                 ! 1s GTO

               ispl       = 3*so(bf)-2
               tmps(1)    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .                    + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl       = ispl + 1
               ux         = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .                    + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl       = ispl + 1
               u2         = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .                    + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dy = yy-atoms(a)%cy
               dz = zz-atoms(a)%cz

               tmps(2)    = ux*dx/rr
               tmps(3)    = ux*dy/rr
               tmps(4)    = ux*dz/rr
               tmps(5)    = u2 + 2*ux/rr

ccc MO calculation
               do j=1, norb
                 moc=moc+1
                 tmp = cmoa(moc)
                 mat(j,i,1)   = mat(j,i,1)   + tmp*tmps(1)
                 mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmps(2)
                 mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmps(3)
                 mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmps(4)
                 mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmps(5)
               enddo

            else if (bl(bf) .eq. 'P') then             ! 2p GTO's
c              // do all 3 P simultaneously (same exponent is required)
c              // order p_x,p_y,p_z

               ispl = 3*so(bf)-2
               u    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl = ispl + 1
               ux   = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl = ispl + 1
               uxx  = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dy = yy-atoms(a)%cy
               dz = zz-atoms(a)%cz

               dxdy = dx*dy
               dxdz = dx*dz
               dydz = dy*dz

ccc
               tmpp(0,1) = dx*u
               tmpp(1,1) = dy*u
               tmpp(2,1) = dz*u

               tmpp(0,2) = u + ux*dx*dx
               tmpp(1,2) = ux*dxdy
               tmpp(2,2) = ux*dxdz
               tmpp(0,3) = ux*dxdy
               tmpp(1,3) = u + ux*dy*dy
               tmpp(2,3) = ux*dydz
               tmpp(0,4) = ux*dxdz
               tmpp(1,4) = ux*dydz
               tmpp(2,4) = u + ux*dz*dz

               tmpp(0,5) = uxx*dx
               tmpp(1,5) = uxx*dy
               tmpp(2,5) = uxx*dz

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,2
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpp(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpp(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpp(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpp(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpp(d,5)
                 enddo
               enddo

            else if (bl(bf) .eq. 'D') then         ! 3d GTO
c              // do all 6 D simultaneously (same exponent is required)
c              // order: d_xx, d_yy, d_zz, d_xy, d_xz, d_yz  (like GAMESS)

               ispl = 3*so(bf)-2
               u    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl = ispl + 1
               ux   = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl = ispl + 1
               uxx   = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz
               dxdy = dx*dy
               dxdz = dx*dz
               dydz = dy*dz

               tmpd(0,1) = dx2*u
               tmpd(1,1) = dy2*u
               tmpd(2,1) = dz2*u

               tmpd(0,2) = (2d0*u + ux*dx2)*dx
               tmpd(1,2) = dy2*ux*dx
               tmpd(2,2) = dz2*ux*dx
               tmpd(0,3) = dx2*ux*dy
               tmpd(1,3) = (2d0*u + ux*dy2)*dy
               tmpd(2,3) = dz2*ux*dy
               tmpd(0,4) = dx2*ux*dz
               tmpd(1,4) = dy2*ux*dz
               tmpd(2,4) = (2d0*u + ux*dz2)*dz

               tmpd(0,5) = 2d0*u + dx2*uxx
               tmpd(1,5) = 2d0*u + dy2*uxx
               tmpd(2,5) = 2d0*u + dz2*uxx

               u = sqr3*u                   ! correction of norm
               ux = sqr3*ux                 ! N(dxx)*sqr3 = N(dxy)
               uxx = sqr3*uxx

               tmpd(3,1) = dxdy*u
               tmpd(4,1) = dxdz*u
               tmpd(5,1) = dydz*u
               tmp = ux*dx*dy*dz
               tmpd(3,2) = (u + ux*dx2)*dy
               tmpd(4,2) = (u + ux*dx2)*dz
               tmpd(5,2) = tmp
               tmpd(3,3) = (u + ux*dy2)*dx
               tmpd(4,3) = tmp
               tmpd(5,3) = (u + ux*dy2)*dz
               tmpd(3,4) = tmp
               tmpd(4,4) = (u + ux*dz2)*dx
               tmpd(5,4) = (u + ux*dz2)*dy

               tmpd(3,5) = uxx*dxdy
               tmpd(4,5) = uxx*dxdz
               tmpd(5,5) = uxx*dydz

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,5
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpd(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpd(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpd(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpd(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpd(d,5)
                 enddo
               enddo

            else if (bl(bf)=='F'.and..not.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, fd_xxy, f_xxz, f_yyx,
c              //   f_yyz, f_zzx, f_zzy, f_xyz  (like GAMESS)

               ispl = 3*so(bf)-2
               u    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl = ispl + 1
               ux   = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl = ispl + 1
               uxx   = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz
               dxyz = dx*dy*dz

c                 // f_xxx, f_yyy, f_zzz
               tmpf(0,1) = dx2*dx*u
               tmpf(1,1) = dy2*dy*u
               tmpf(2,1) = dz2*dz*u

               tmpf(0,2) = (3d0*u + ux*dx2)*dx2
               tmpf(1,2) = dy2*dy*ux*dx
               tmpf(2,2) = dz2*dz*ux*dx
               tmpf(0,3) = dx2*dx*ux*dy
               tmpf(1,3) = (3d0*u + ux*dy2)*dy2
               tmpf(2,3) = dz2*dz*ux*dy
               tmpf(0,4) = dx2*dx*ux*dz
               tmpf(1,4) = dy2*dy*ux*dz
               tmpf(2,4) = (3d0*u + ux*dz2)*dz2

               tmpf(0,5) = (6d0*u + dx2*uxx)*dx
               tmpf(1,5) = (6d0*u + dy2*uxx)*dy
               tmpf(2,5) = (6d0*u + dz2*uxx)*dz

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
               u = sqr5*u                   ! correction of norm
               ux = sqr5*ux                 ! N(fxxx)*sqrt(5) = N(fxxy)
               uxx = sqr5*uxx

               tmpf(3,1) = dx2*dy*u
               tmpf(4,1) = dx2*dz*u
               tmpf(5,1) = dy2*dx*u
               tmpf(6,1) = dy2*dz*u
               tmpf(7,1) = dz2*dx*u
               tmpf(8,1) = dz2*dy*u

c derivatives
               tmp = ux*dxyz
               tmpf(3,2) = (2d0*u + ux*dx2)*dx*dy
               tmpf(4,2) = (2d0*u + ux*dx2)*dx*dz
               tmpf(5,2) = (u + ux*dx2)*dy2
               tmpf(6,2) = tmp*dy
               tmpf(7,2) = (u + ux*dx2)*dz2
               tmpf(8,2) = tmp*dz
               tmpf(3,3) = (u + ux*dy2)*dx2
               tmpf(4,3) = tmp*dx
               tmpf(5,3) = (2d0*u + ux*dy2)*dx*dy
               tmpf(6,3) = (2d0*u + ux*dy2)*dy*dz
               tmpf(7,3) = tmp*dz
               tmpf(8,3) = (u + ux*dy2)*dz2
               tmpf(3,4) = tmp*dx
               tmpf(4,4) = (u + ux*dz2)*dx2
               tmpf(5,4) = tmp*dy
               tmpf(6,4) = (u + ux*dz2)*dy2
               tmpf(7,4) = (2d0*u + ux*dz2)*dx*dz
               tmpf(8,4) = (2d0*u + ux*dz2)*dy*dz
c laplacians
               tmpf(3,5) = (2d0*u + dx2*uxx)*dy
               tmpf(4,5) = (2d0*u + dx2*uxx)*dz
               tmpf(5,5) = (2d0*u + dy2*uxx)*dx
               tmpf(6,5) = (2d0*u + dy2*uxx)*dz
               tmpf(7,5) = (2d0*u + dz2*uxx)*dx
               tmpf(8,5) = (2d0*u + dz2*uxx)*dy

c                 // f_xyz
               u = sqr3*u                  ! correction of norm
               ux = sqr3*ux                ! N(fxxx)*sqrt(15)=
               uxx = sqr3*uxx              ! N(fxxy)*sqrt(3)=N(fxyz)

               tmpf(9,1) = dxyz*u

               tmpf(9,2) = (u + ux*dx2)*dy*dz
               tmpf(9,3) = (u + ux*dy2)*dx*dz
               tmpf(9,4) = (u + ux*dz2)*dx*dy
               tmpf(9,5) = dxyz*uxx

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpf(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpf(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpf(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpf(d,5)
                 enddo
               enddo

            else if (bl(bf)=='F'.and.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, f_xyy, f_xxy, f_xxz,
c              //   f_xzz, f_yzz, f_yyz, f_xyz  (like Gaussian)

               ispl = 3*so(bf)-2
               u    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl = ispl + 1
               ux   = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))
               ispl = ispl + 1
               uxx   = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz
               dxyz = dx*dy*dz

c                 // f_xxx, f_yyy, f_zzz
               tmpf(0,1) = dx2*dx*u
               tmpf(1,1) = dy2*dy*u
               tmpf(2,1) = dz2*dz*u

               tmpf(0,2) = (3d0*u + ux*dx2)*dx2
               tmpf(1,2) = dy2*dy*ux*dx
               tmpf(2,2) = dz2*dz*ux*dx
               tmpf(0,3) = dx2*dx*ux*dy
               tmpf(1,3) = (3d0*u + ux*dy2)*dy2
               tmpf(2,3) = dz2*dz*ux*dy
               tmpf(0,4) = dx2*dx*ux*dz
               tmpf(1,4) = dy2*dy*ux*dz
               tmpf(2,4) = (3d0*u + ux*dz2)*dz2

               tmpf(0,5) = (6d0*u + dx2*uxx)*dx
               tmpf(1,5) = (6d0*u + dy2*uxx)*dy
               tmpf(2,5) = (6d0*u + dz2*uxx)*dz

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
               u = sqr5*u                   ! correction of norm
               ux = sqr5*ux                 ! N(fxxx)*sqrt(5) = N(fxxy)
               uxx = sqr5*uxx

               tmpf(4,1) = dx2*dy*u
               tmpf(5,1) = dx2*dz*u
               tmpf(3,1) = dy2*dx*u
               tmpf(8,1) = dy2*dz*u
               tmpf(6,1) = dz2*dx*u
               tmpf(7,1) = dz2*dy*u

c derivatives
               tmp = ux*dxyz
               tmpf(4,2) = (2d0*u + ux*dx2)*dx*dy
               tmpf(5,2) = (2d0*u + ux*dx2)*dx*dz
               tmpf(3,2) = (u + ux*dx2)*dy2
               tmpf(8,2) = tmp*dy
               tmpf(6,2) = (u + ux*dx2)*dz2
               tmpf(7,2) = tmp*dz
               tmpf(4,3) = (u + ux*dy2)*dx2
               tmpf(5,3) = tmp*dx
               tmpf(3,3) = (2d0*u + ux*dy2)*dx*dy
               tmpf(8,3) = (2d0*u + ux*dy2)*dy*dz
               tmpf(6,3) = tmp*dz
               tmpf(7,3) = (u + ux*dy2)*dz2
               tmpf(4,4) = tmp*dx
               tmpf(5,4) = (u + ux*dz2)*dx2
               tmpf(3,4) = tmp*dy
               tmpf(8,4) = (u + ux*dz2)*dy2
               tmpf(6,4) = (2d0*u + ux*dz2)*dx*dz
               tmpf(7,4) = (2d0*u + ux*dz2)*dy*dz
c laplacians
               tmpf(4,5) = (2d0*u + dx2*uxx)*dy
               tmpf(5,5) = (2d0*u + dx2*uxx)*dz
               tmpf(3,5) = (2d0*u + dy2*uxx)*dx
               tmpf(8,5) = (2d0*u + dy2*uxx)*dz
               tmpf(6,5) = (2d0*u + dz2*uxx)*dx
               tmpf(7,5) = (2d0*u + dz2*uxx)*dy

c                 // f_xyz
               u = sqr3*u                  ! correction of norm
               ux = sqr3*ux                ! N(fxxx)*sqrt(15)=
               uxx = sqr3*uxx              ! N(fxxy)*sqrt(3)=N(fxyz)

               tmpf(9,1) = dxyz*u

               tmpf(9,2) = (u + ux*dx2)*dy*dz
               tmpf(9,3) = (u + ux*dy2)*dx*dz
               tmpf(9,4) = (u + ux*dz2)*dx*dy
               tmpf(9,5) = dxyz*uxx

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d,1)
                   mat1x(j,i,1) = mat1x(j,i,1) + tmp*tmpf(d,2)
                   mat1y(j,i,1) = mat1y(j,i,1) + tmp*tmpf(d,3)
                   mat1z(j,i,1) = mat1z(j,i,1) + tmp*tmpf(d,4)
                   mat2(j,i,1)  = mat2(j,i,1)  + tmp*tmpf(d,5)
                 enddo
               enddo

            else
               call abortp('(getaos): wrong GTO')
            endif ! bl
           endif  ! CGTO or primitive gaussian function
         enddo    ! bf-loop over basis functions
      enddo       ! i-loop over electrons

      end subroutine aomospl_calc



c     --------------------------------------
      subroutine aomo1spl_calc(ie,x,y,z,rai)
c     --------------------------------------

c input parameters:
      integer ie                 ! if >0 only AO's for electron ie recalculated

      real*8, dimension(:) :: x,y,z    ! x,y,z coordinates of position vector
      real*8, dimension(:,:) :: rai ! r_ai electron-nucleus distances

c constants:
      real*8 :: sqr3,sqr5
      parameter (sqr3=1.73205080756887729d0,sqr5=2.236067977499789696d0)
c local variables
      integer :: bf,a,i,i1,i2,ii,ic
      integer :: j,d,moc
      integer :: spl,ispl
      real*8 :: xx,yy,zz,rr,r2,alp,nrm,u,ux,uxx,u2,dx,dy,dz,tmp,
     .       dx2,dy2,dz2,dxdy,dxdz,dydz
      real*8 :: df
ccc
      real*8                 :: tmps
      real*8, dimension(0:2) :: tmpp
      real*8, dimension(0:5) :: tmpd
      real*8, dimension(0:9) :: tmpf
      logical gaussFOrder       ! .t.: Gaussian order for f function
                                ! .f.: Gamess==Turbomole order used

c bf refers to the degenerate set of cartesian
c basis function (S:1,P:3,D:6,F:10) as input, which may be of type STO
c or contracted GTO.
c al refers to the individual basis function, as used in LCAO-MO's.
c (composed in subroutine mdetwf)
c i refers to the current electron.

c-----Calculation of the AO's and their derivatives

      if (evfmt=='gau' .or. evfmt=='mol' ) then
         gaussFOrder = .true.
      else
         gaussFOrder = .false.
      endif

      if (ie .eq. 0) then                     ! AO's for all electrons
         i1 = 1
         i2 = ne
      else
         i1 = ie                              ! only AO for electron ie
         i2 = ie
      endif

      do i=i1,i2                              ! loop over electrons
         xx = x(i)
         yy = y(i)
         zz = z(i)

         moc = 0                              !Pointer for cmoa array

c initialisation

         mat(1:norb,i,1)   = 0d0

         do bf=1,nbasf                        ! loop over basis functions
           a = bc(bf)                         ! center of AO
           rr = rai(a,i)                      ! r_ai

           if (cutao) then                    !AO - Cutoff
             if (rr.gt.aocuts(bf)) then       ! --> do nothing but adjusting the counters
               if (bl(bf) .eq. 'S') then
                 moc = moc + norb
               elseif (bl(bf) .eq. 'P') then
                 moc = moc + 3*norb
               elseif (bl(bf) .eq. 'D') then
                 moc = moc + 6*norb
               elseif (bl(bf) .eq. 'F') then
                 moc = moc + 10*norb
               else
                 call abortp('(getaos): wrong GTO')
               endif
               cycle  !continue with next basis function
             endif
           endif

           r2 = rr*rr

           if (so(bf).eq.0) then !only 1 GTO in contraction, no splines used !

            if (bl(bf) .eq. 'S') then                 ! 1s GTO

               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)

ccc MO calculation
               do j=1, norb
                 moc=moc+1
                 tmp = cmoa(moc)
                 mat(j,i,1)   = mat(j,i,1)   + tmp*u
               enddo

            else if (bl(bf) .eq. 'P') then             ! 2p GTO's
c              // do all 3 P simultaneously (same exponent is required)
c              // order p_x,p_y,p_z

               dx = xx-atoms(a)%cx
               dy = yy-atoms(a)%cy
               dz = zz-atoms(a)%cz

               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)

               tmpp(0) = dx*u
               tmpp(1) = dy*u
               tmpp(2) = dz*u

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,2
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpp(d)
                 enddo
               enddo

            else if (bl(bf) .eq. 'D') then         ! 3d GTO
c              // do all 6 D simultaneously (same exponent is required)
c              // order: d_xx, d_yy, d_zz, d_xy, d_xz, d_yz  (like GAMESS)

               dx    = xx-atoms(a)%cx
               dy    = yy-atoms(a)%cy
               dz    = zz-atoms(a)%cz
ccc
               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)

               tmpd(0) = dx*dx*u
               tmpd(1) = dy*dy*u
               tmpd(2) = dz*dz*u

               u = sqr3*u                   ! correction of norm
                                            ! N(dxx)*sqr3 = N(dxy)

               tmpd(3) = dx*dy*u
               tmpd(4) = dx*dz*u
               tmpd(5) = dy*dz*u

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,5
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpd(d)
                 enddo
               enddo

            else if (bl(bf)=='F'.and..not.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, fd_xxy, f_xxz, f_yyx,
c              //   f_yyz, f_zzx, f_zzy, f_xyz  (like GAMESS)

               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)

               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz

c                 // f_xxx, f_yyy, f_zzz
               tmpf(0) = dx2*dx*u
               tmpf(1) = dy2*dy*u
               tmpf(2) = dz2*dz*u

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
               u = sqr5*u                   ! correction of norm
                                            ! N(fxxx)*sqrt(5) = N(fxxy)

               tmpf(3) = dx2*dy*u
               tmpf(4) = dx2*dz*u
               tmpf(5) = dy2*dx*u
               tmpf(6) = dy2*dz*u
               tmpf(7) = dz2*dx*u
               tmpf(8) = dz2*dy*u

c                 // f_xyz
               u = sqr3*u                  ! correction of norm
                                           ! N(fxxx)*sqrt(15)=
                                           ! N(fxxy)*sqrt(3)=N(fxyz)
               tmpf(9) = dx*dy*dz*u

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d)
                 enddo
               enddo
            else if (bl(bf)=='F'.and.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, f_xyy, f_xxy, f_xxz,
c              //   f_xzz, f_yzz, f_yyz, f_xyz  (like Gaussian)

               alp = cntrctn(1,1,bf)
               u = cntrctn(2,1,bf) * exp(-alp*r2)

               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz

c                 // f_xxx, f_yyy, f_zzz
               tmpf(0) = dx2*dx*u
               tmpf(1) = dy2*dy*u
               tmpf(2) = dz2*dz*u

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
               u = sqr5*u                   ! correction of norm
                                            ! N(fxxx)*sqrt(5) = N(fxxy)

               tmpf(4) = dx2*dy*u
               tmpf(5) = dx2*dz*u
               tmpf(3) = dy2*dx*u
               tmpf(8) = dy2*dz*u
               tmpf(6) = dz2*dx*u
               tmpf(7) = dz2*dy*u

c                 // f_xyz
               u = sqr3*u                  ! correction of norm
                                           ! N(fxxx)*sqrt(15)=
                                           ! N(fxxy)*sqrt(3)=N(fxyz)
               tmpf(9) = dx*dy*dz*u

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d)
                 enddo
               enddo

            else
               call abortp('(getaos): wrong GTO')
            endif  ! bl


           else ! CGTO (more than one primitive gaussian) --> use splines

ccc            r2 = rr*rr
            spl  = (csplnpnt-1)*rr/(csalpha+rr)  + 1
            df = rr - csplx(spl)


            if (bl(bf) .eq. 'S') then                 ! 1s GTO

               ispl       = 3*so(bf)-2
               tmps       = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .                    + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

ccc MO calculation
               do j=1, norb
                 moc=moc+1
                 tmp = cmoa(moc)
                 mat(j,i,1)   = mat(j,i,1)   + tmp*tmps
               enddo

            else if (bl(bf) .eq. 'P') then             ! 2p GTO's
c              // do all 3 P simultaneously (same exponent is required)
c              // order p_x,p_y,p_z

               ispl = 3*so(bf)-2
               u    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dy = yy-atoms(a)%cy
               dz = zz-atoms(a)%cz

               tmpp(0) = dx*u
               tmpp(1) = dy*u
               tmpp(2) = dz*u

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,2
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpp(d)
                 enddo
               enddo

            else if (bl(bf) .eq. 'D') then         ! 3d GTO
c              // do all 6 D simultaneously (same exponent is required)
c              // order: d_xx, d_yy, d_zz, d_xy, d_xz, d_yz  (like GAMESS)

               ispl = 3*so(bf)-2
               u    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dy = yy-atoms(a)%cy
               dz = zz-atoms(a)%cz

               tmpd(0) = dx*dx*u
               tmpd(1) = dy*dy*u
               tmpd(2) = dz*dz*u

               u = sqr3*u                   ! correction of norm
                                            ! N(dxx)*sqr3 = N(dxy)

               tmpd(3) = dx*dy*u
               tmpd(4) = dx*dz*u
               tmpd(5) = dy*dz*u

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,5
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpd(d)
                 enddo
               enddo

            else if (bl(bf)=='F'.and..not.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, fd_xxy, f_xxz, f_yyx,
c              //   f_yyz, f_zzx, f_zzy, f_xyz  (like GAMESS)

               ispl = 3*so(bf)-2
               u    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz

c                 // f_xxx, f_yyy, f_zzz
               tmpf(0) = dx2*dx*u
               tmpf(1) = dy2*dy*u
               tmpf(2) = dz2*dz*u

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
               u = sqr5*u                   ! correction of norm
                                            ! N(fxxx)*sqrt(5) = N(fxxy)

               tmpf(3) = dx2*dy*u
               tmpf(4) = dx2*dz*u
               tmpf(5) = dy2*dx*u
               tmpf(6) = dy2*dz*u
               tmpf(7) = dz2*dx*u
               tmpf(8) = dz2*dy*u

c                 // f_xyz
               u = sqr3*u                  ! correction of norm
                                           ! N(fxxx)*sqrt(15)=
                                           ! N(fxxy)*sqrt(3)=N(fxyz)

               tmpf(9) = dx*dy*dz*u

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d)
                 enddo
               enddo
            else if (bl(bf)=='F'.and.gaussFOrder) then     ! 3f GTO
c              // do all 10 F simultaneously (same exponent is required)
c              // order: f_xxx, f_yyy, f_zzz, f_xyy, f_xxy, f_xxz,
c              //   f_xzz, f_yzz, f_yyz, f_xyz  (like Gaussian)

               ispl = 3*so(bf)-2
               u    = cspla(ispl,spl) + df*(csplb(ispl,spl)
     .              + df*(csplc(ispl,spl) + df*cspld(ispl,spl)))

               dx = xx-atoms(a)%cx
               dx2 = dx*dx
               dy = yy-atoms(a)%cy
               dy2 = dy*dy
               dz = zz-atoms(a)%cz
               dz2 = dz*dz

c                 // f_xxx, f_yyy, f_zzz
               tmpf(0) = dx2*dx*u
               tmpf(1) = dy2*dy*u
               tmpf(2) = dz2*dz*u

c                 // f_xxy, f_xxz, f_yyx, f_yyz, f_zzx, f_zzy
               u = sqr5*u                   ! correction of norm
                                            ! N(fxxx)*sqrt(5) = N(fxxy)

               tmpf(4) = dx2*dy*u
               tmpf(5) = dx2*dz*u
               tmpf(3) = dy2*dx*u
               tmpf(8) = dy2*dz*u
               tmpf(6) = dz2*dx*u
               tmpf(7) = dz2*dy*u

c                 // f_xyz
               u = sqr3*u                  ! correction of norm
                                           ! N(fxxx)*sqrt(15)=
                                           ! N(fxxy)*sqrt(3)=N(fxyz)

               tmpf(9) = dx*dy*dz*u

ccc MO calculation (It's up to the compiler to unroll this loop if that's faster)
               do j=1, norb
                 do d=0,9
                   moc=moc+1
                   tmp = cmoa(moc)
                   mat(j,i,1)   = mat(j,i,1)   + tmp*tmpf(d)
                 enddo
               enddo

            else
               call abortp('(getaos): wrong GTO')
            endif ! bl
           endif  ! CGTO or primitive gaussian function
         enddo    ! bf-loop over basis functions
      enddo       ! i-loop over electrons

      end subroutine aomo1spl_calc

      END MODULE aomo

