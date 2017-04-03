
!-----------------------------------
subroutine assert(logicalExp,string)
!-----------------------------------

  implicit none
#ifdef PARALLEL   
   include 'mpif.h'
#endif
  logical, intent(in)                    :: logicalExp
  character(len=*), optional, intent(in) :: string
  integer iexit,ierr,mytid
  
  if (.not.logicalExp) then
     if (present(string)) then
        print*,"Assertion violated:"
        print*,string
     else
        print*,"Assertion violated!"
     endif
     print*,"Aborting program ..."
#ifdef PARALLEL
     iexit = 1
     call MPI_ABORT(MPI_COMM_WORLD,iexit,ierr)
#endif
     stop
!!  else
!!     mytid = 0
!!#ifdef PARALLEL
!!     call MPI_COMM_RANK(MPI_COMM_WORLD, mytid, ierr)
!!#endif
!!     print*,"DBG:",mytid,string
  end if

end subroutine assert


program test

   use newstatistics
   implicit none
#ifdef PARALLEL   
   include 'mpif.h'
#endif
   
#ifdef PARALLEL
   integer             :: ierr, status(MPI_STATUS_SIZE)
#endif
   logical             :: MASTER
   integer             :: mytid,nproc,i,n,bl
   type(stat) :: s
   type(blockstat) :: bs
   type(vectorstat) :: vs
   type(blockvectorstat) :: bvs
   type(matrixstat) :: ms
   type(blockmatrixstat) :: bms
   real*8 d,mean,var,stddev,bmean,blmean
   real*8 v(3),vmean(3),vvar(3),vstddev(3), v2(2)
   real*8 mmean(2,2),mvar(2,2),mstddev(2,2)
   real*8 a(2,2)
   real*8, parameter :: TOL = 1.d-12
   
   mytid = 0; nproc = 1
#ifdef PARALLEL
   call MPI_INIT(ierr)
   call MPI_COMM_RANK(MPI_COMM_WORLD, mytid, ierr)
   call MPI_COMM_SIZE(MPI_COMM_WORLD, nproc, ierr)
#endif
   if (mytid==0) then
      MASTER = .true.
   else
      MASTER = .false.
   end if

   call assert(nproc==2,"ERR1: run test with 2 cores")

   call s%create()
   do i=1,5
      call s%add(i*1.d0+mytid)
   end do

   mean = s%mean()
   n = s%count()
   var = s%var()
   stddev = s%stddev()

   if (MASTER) then
      call assert(abs(mean-3.5d0)<TOL,"ERR2: mean")
      call assert(abs(var-2.25d0)<TOL,"ERR3: var")
      call assert(abs(stddev-0.5d0)<TOL,"ERR4: stddev")
   end if   
   call assert(n==10,"ERR5, count")        ! count() bcasts result!!

   mean = s%localmean()
   n = s%localcount()
   var = s%localvar()
   stddev = s%localstddev()
   call assert(abs(mean-3.d0-mytid)<TOL,"ERR6: localmean")
   call assert(abs(var-2.d0)<TOL,"ERR67: localvar")
   call assert(abs(stddev-1.d0/sqrt(2.d0))<TOL,"ERR8: localstddev")
   call assert(n==5,"ERR9: localcount")
  
#ifdef PARALLEL
   call MPI_BARRIER(MPI_COMM_WORLD,ierr)
#endif

   if (MASTER) print*, "all stat tests passed"

   ! testing block stat

   call bs%create(5)
   do bl=1,5
   do i=1,5
      call bs%add(i*1.d0+mytid)
   end do
   bmean = bs%lastblockmean()
   blmean = bs%locallastblockmean()
   !print*,bl,mytid,blmean
   if (MASTER) then
      call assert(abs(bmean-3.5d0)<TOL,"ERR1: bmean")
      !print*,"MASTER:",bl,bmean
   end if
   call assert(abs(blmean-3.d0-mytid)<TOL,"ERR2: blmean")
   end do

   mean = bs%mean()
   n = bs%count()
   var = bs%var()
   stddev = bs%stddev()

   if (MASTER) then
      call assert(abs(mean-3.5d0)<TOL,"ERR3: bmean")
      call assert(abs(var-2.25d0)<TOL,"ERR4: bvar")
      call assert(abs(stddev-0.5d0/3.d0)<TOL,"ERR5: bstddev")
      call assert(n==50,"ERR6, count")
   end if   

   if (MASTER) print*, "all bstat tests passed"

   ! testing vstat

   call vs%create(3)
   do i=1,5 
      d = i*1.d0 + mytid
      v = (/ d, 10+d, 100+d /)
      call vs%add(v)
   enddo

   vmean = vs%mean()
   vvar = vs%var()
   vstddev = vs%stddev()
   n = vs%count()
   if (MASTER) then
      call assert(all(abs(vmean- (/3.5d0, 13.5d0, 103.5d0 /) ) < TOL),"ERR10: vmean")
      call assert(all(abs(vvar-2.25d0) < TOL),"ERR11: vvar")
      call assert(all(abs(vstddev-0.5d0) < TOL),"ERR12: vstddev")
      call assert(n==10,"ERR13, vcount")
   end if   

   vmean = vs%localmean()
   vvar = vs%localvar()
   vstddev = vs%localstddev()
   n = vs%localcount()
   call assert(all(abs(vmean- (/3.d0+mytid, 13.d0+mytid, 103.d0+mytid /) ) < TOL),"ERR10: vlocalmean")
   call assert(all(abs(vvar-2.d0) < TOL),"ERR11: vlocalvar")
   call assert(all(abs(vstddev-sqrt(0.5d0)) < TOL),"ERR12: vlocalstddev")
   call assert(n==5,"ERR13, vlocalcount")

   call vs%destroy()


   if (MASTER) print*, "all vstat tests passed"
   
! testing mstat

   call ms%create(2,2)
   do i=1,5 
      d = i*1.d0 + mytid
      a = reshape( (/ d, 10+d, 100+d, 1000+d /), (/ 2,2 /) )
      call ms%add(a)
   enddo
   mmean = ms%mean()
   mvar = ms%var()
   mstddev = ms%stddev()
   n = ms%count()
   if (MASTER) then
      call assert(all(abs(mmean- reshape( (/3.5d0, 13.5d0, 103.5d0, 1003.5d0 /),(/ 2,2/) ) ) < TOL),"ERR14: mmean")
      call assert(all(abs(mvar-2.25d0) < TOL),"ERR15: mvar")
      call assert(all(abs(mstddev-0.5d0) < TOL),"ERR16: mstddev")
      call assert(n==10,"ERR16, count")
   end if   

   mmean = ms%localmean()
   mvar = ms%localvar()
   mstddev = ms%localstddev()
   n = ms%localcount()
   call assert(all(abs(mmean- reshape( (/3.d0+mytid, 13.d0+mytid, 103.d0+mytid, 1003.d0+mytid /), (/ 2,2 /) ) ) < TOL),"ERR10: mlocalmean")
   call assert(all(abs(mvar-2.d0) < TOL),"ERR11: mlocalvar")
   call assert(all(abs(mstddev-sqrt(0.5d0)) < TOL),"ERR12: mlocalstddev")
   call assert(n==5,"ERR13, mlocalcount")

   call ms%destroy()

   if (MASTER) print*, "all mstat tests passed"

! testing bvstat

   call bvs%create(3,5)
   do bl=1,5
   do i=1,5 
      d = i*1.d0 + mytid
      v = (/ d, 10+d, 100+d /)
      call bvs%add(v)
   end do
   vmean = bvs%lastblockmean()
   if (MASTER) then
      call assert(all(abs(vmean- (/3.5d0, 13.5d0, 103.5d0 /) ) < TOL),"ERR1: lbmean")
   end if
   vmean = bvs%locallastblockmean()
   call assert(all(abs(vmean- (/3.d0+mytid, 13.d0+mytid, 103.d0+mytid /) ) < TOL),"ERR2: llbmean")
   end do
   vmean = bvs%mean()
   vvar = bvs%var()
   vstddev = bvs%stddev()
   n = bvs%count()
   if (MASTER) then
      call assert(all(abs(vmean- (/3.5d0, 13.5d0, 103.5d0 /) ) < TOL),"ERR3: bvmean")
      call assert(all(abs(vvar-2.25d0) < TOL),"ERR4: bvvar")
      call assert(all(abs(vstddev-0.5d0/3.d0) < TOL),"ERR5: bvstddev")
      call assert(n==50,"ERR6, bvcount")
   end if   

   call bvs%destroy()

   if (MASTER) print*, "all bvstat tests passed"
   
! testing bmstat

   call bms%create(2,2,5)
   do bl=1,5
   do i=1,5 
      d = i*1.d0 + mytid
      a = reshape( (/ d, 10+d, 100+d, 1000+d /), (/ 2,2 /) )
      call bms%add(a)
   end do
   mmean = bms%lastblockmean()
   if (MASTER) then
      call assert(all(abs(mmean- reshape( (/3.5d0, 13.5d0, 103.5d0, 1003.5d0 /),(/ 2,2/) ) ) < TOL),"ERR1: mlbmean")
   end if
   mmean = bms%locallastblockmean()
   call assert(all(abs(mmean- reshape( (/3d0+mytid, 13d0+mytid, 103d0+mytid, 1003d0+mytid /),(/ 2,2/) ) ) < TOL),"ERR2: mllbmean")
   end do
   mmean = bms%mean()
   mvar = bms%var()
   mstddev = bms%stddev()
   n = bms%count()
   if (MASTER) then
      call assert(all(abs(mmean- reshape( (/3.5d0, 13.5d0, 103.5d0, 1003.5d0 /),(/ 2,2/) ) ) < TOL),"ERR3: mbmean")
      call assert(all(abs(mvar-2.25d0) < TOL),"ERR4: mbvar")
      call assert(all(abs(mstddev-0.5d0/3.d0) < TOL),"ERR5: mbstddev")
      call assert(n==50,"ERR6, mbcount")
   end if   

   call bms%destroy()

   

   if (MASTER) print*, "all bmstat tests passed"

#ifdef PARALLEL
   call MPI_FINALIZE(ierr)
#endif

end program


