
! the wfmodule contains routines related to the wavefunction data (wfdata)
! please note that all default values are defined in the "constructors" in
! wfdata (for readability). Here should be only *changes* of the data.


MODULE wfmodule
  use atomModule
  use wfdata
  use elocaldata, only: eloc_initialize, WFType
  use ecpio
  use ecpModule, only: EcpType
  use aosdata, only: aoinputg, aoinputex, aoinputabs, aoinput, &
                     aooutput, aooutputg, inquireBasisFile
  use jastrow, only: jasinput, jasoutput, jas_shortoutput, jasSetInitMode
  use mos, only: moinput, mooutput
  use mdet, only: mdetinput, mdetcsfinput, mdetoutput
  use utilsmodule
  use Utils, only: readFileParallel, intToStr, replace
  implicit none

CONTAINS


  subroutine readwriteWF(lines,nl,wf)
  !----------------------------------!

    integer, intent(in)           :: nl
    character(len=*), intent(in)  :: lines(nl)
    type(WFType), intent(inout)   :: wf

    integer                       :: iflag,i,LAmode,r
    character(len=40)             :: wfFile
    character(len=3)              :: s
    character(len=120)            :: line
    character(len=26)             :: s26
    logical                       :: found,ltmp,finda,readMode,writeMode,writeBasis

    call getinta(lines,nl,"jas_init=",i,iflag)
    if (iflag == 0) then
      call jasSetInitMode(i)
    endif

    writeMode = finda(lines,nl,'write')
    readMode = finda(lines,nl,'read')
    call assert(.not.(readMode .and. writeMode),"readwriteWF:read and write given")
    if (.not.(readMode .or. writeMode)) readMode = .true.
    if (finda(lines,nl,'epart')) then
       do_epart = .true.
    else
       do_epart = .false.
    end if
    call getstra(lines,nl,'file=',wfFile,iflag)
    call assert(iflag==0,'readwriteWF: no wavefunction given')

    ! allow wf file names like wf_$idx.wf, where $idx is the current loop index
    call replace(wfFile,"$idx",intToStr(getCurrentLoopIdx()),.true.)
    ! Replace $in with the name of the input file
    call replace(wfFile,"$in",baseName,.true.)

    ! select linear algebra code
    call getinta(lines,nl,'la_mode=',LAmode,iflag)
    if (iflag==0) then
       useLAlib = .false.; useLAlib_mos = .false.; useLAlib_mdet = .false.
       r = mod(LAmode,2)
       if (r == 1) useLAlib = .true.
       LAmode = LAmode / 2
       r = mod(LAmode,2)
       if (r == 1) useLAlib_mos = .true.
       LAmode = LAmode / 2
       r = mod(LAmode,2)
       if (r == 1) useLAlib_mdet = .true.
    endif

    if (readMode) then

    call getinta(lines,nl,'spline_points=',splinpnts,iflag)

    found = finda(lines,nl,'no_cuspcor')
    if (found) then
       cuspcor = .false.
    else
       found = finda(lines,nl,'cuspcor')
       if (found) cuspcor = .true.
    endif

    found = finda(lines,nl,'no_splineaos')
    if (found) then
       spline = .false.
       cuspcor = .false.
    else
       found = finda(lines,nl,'splineaos')
       if (found) spline = .true.
    endif

    aosopt    = finda(lines,nl,'aosopt')

    if (MASTER .and. logmode>=1) then
       write(iul,'(a)') ' wave function settings:'
       if (useLAlib)  then; s26='   with BLAS/LAPACK'; else; s26='   without BLAS/LAPACK'; endif
       write(iul,'(1X,A25,1X)') s26
       if (aosopt)  then
          write(iul,'(1X,A)') ' ONLY CONSTRUCTING CUSP PARAMETERS'
       endif
       if (spline)  then
          if (cuspcor) then
             write(iul,'(1X,A/)') '   cusp-corrected splines for contracted GTOs'
          else
             write(iul,'(1X,A/)') '   splines for contracted GTOs (no cusp correction!)'
          endif
       else
          write(iul,'(1X,A/)') '   no splines for contracted GTOs'
       endif
    endif

    fastmdet = finda(lines,nl,'fastdet')

    found = finda(lines,nl,'no_repeat_det_opt')
    if (found) then
       repeatedDetsOpt = .false.
    endif

    found = finda(lines,nl,'task')
    if(found) then
      aomotask = .true.
    endif

    found = finda(lines,nl,'pair')
    if(found) then
      aomopair = .true.
    endif

    call getdbla(lines,nl,'prod_cutoff=',prodcutoff,iflag)
    ! parameters for new AOMO cutoffs (CD)
    found = finda(lines,nl,'no_aomo')
    if (found) then
       aomocomb = .false.
    else
       found = finda(lines,nl,'aomo')
       if (found) aomocomb = .true.
    endif
    call getdbla(lines,nl,'ao_cutoff=',aocutoff,iflag); if (iflag==0) cutao=.true.
    call getdbla(lines,nl,'mo_cutoff=',mocutoff,iflag); if (iflag==0) cutmo=.true.

    if (logmode>=1) then
       if (aomocomb) then
          write(iul,'(1X,A)',advance='no') 'using direct AO/MO mode '
          if (cutao) then
             write(iul,'(A,G15.6,1X)',advance='no') 'with AO cutoff=',aocutoff
          else
             write(iul,'(A)',advance='no') 'without AO cutoff '
          endif
          if (cutmo) then
             write(iul,'(A,G15.6,1X)',advance='no') 'with MO cutoff=',mocutoff
          else
             write(iul,'(A)',advance='no') 'without MO cutoff '
          endif
          write(iul,*)
       else
          write(iul,'(1X,A)') 'using sequential AO and MO mode '
       endif
       write(iul,*)
    endif

    ! print options
    if (finda(lines,nl,'print_all')) then
       printAOs=1; printMOs=1; printJ=1; printDet=1
    endif
    if (finda(lines,nl,'print_aos')) printAOs=1
    if (finda(lines,nl,'print_jas')) printJ=1
    if (finda(lines,nl,'print_mos')) printMOs=1
    if (finda(lines,nl,'print_dets')) printDet=1
    if (.not. MASTER) then
       printAOs=0; printMOs=0; printJ=0; printDet=0
    endif

    ! some consistency checks
    if ((.not.(aomocomb)).and.(cutao)) then
       write(iul,*)
       write(iul,*) ' ao_cutoff only available with aomo in this implementation'
       write(iul,*)
       call abortp('initWF: aomocomb=.false. and cutao=.true.')
    endif
    if ((.not.(aomocomb)).and.(cutmo)) then
       write(iul,*)
       write(iul,*) ' mo_cutoff only available with aomo in this implementation'
       write(iul,*)
       call abortp('initWF: aomocomb=.false. and cutmo=.true.')
    endif

    call readWF(wfFile,wf)

    endif ! readMode

    if (writeMode) then
       writeBasis = .false.
       if (finda(lines,nl,'write_basis')) writeBasis = .true.
       call writeWF(wfFile,writeBasis,wf)
    endif

  end subroutine readwriteWF



!=================================================================================


  subroutine readWF(wfFile,wf)
  !---------------------------!

    character(len=*), intent(in) :: wfFile
    type(WFType), intent(inout)  :: wf

    integer, parameter :: MAXLINES=50000
    integer, parameter :: MAXBLOCK=50000
    integer, parameter :: MAXLEN=120
    character(len=MAXLEN)  :: lines(MAXBLOCK)
    character(len=MAXLEN)  :: allLines(MAXLINES)
    integer a,idx,i,ii,ii1,ii2,io,j,iflag,nl,nAllLines,idxsave
    real*8 rr
    character text*3,s*10
    logical form
    logical ltmp,findf,finda,ang,found,withSA,ignoreHAtoms,withBasis
    logical absExists,simpleBasisExists

    !! ---- Read Wavefunction file

    call readFileParallel(mytid,wfFile,allLines,nAllLines)

    idx = 1 ! start searching from the beginning
    call getNextBlock(allLines,nAllLines,idx,'$general','$end','!', &
                      MAXBLOCK,lines,nl)
    if (nl==0) call abortp('wf file: $general block is required as first block')

    !! ---- $general block ----

    call getstra(lines,nl,'evfmt=',evfmt,iflag)
    call getstra(lines,nl,'basis=',basis,iflag)
    call getstra(lines,nl,'jastrow=',jastype,iflag)
    call getstra(lines,nl,'title=',title,iflag)
    call getinta(lines,nl,'charge=',charge,iflag)
    call getinta(lines,nl,'spin=',mult,iflag)
    call getloga(lines,nl,'norm=',normalize,iflag)
    call getstra(lines,nl,'geom=',s,iflag)
    if (iflag==0) then
       if (s=='bohr') then
          ang = .false.
       else
          ang = .true.
       endif
    else
       ang = .true.    ! default
    endif

    ltmp = finda(lines,nl,'atomic_charges')
    if (ltmp) partial = .true.
    if (.not.partial .and. charge/=0) call abortp('$general: charge<>0 requires atomic_charges')
    withSA = finda(lines,nl,'same_atoms_input')
    ignoreHAtoms = finda(lines,nl,'no_hydrogen_jastrow')

    if (MASTER .and. logmode >= 2) then
       write(iul,'(3A)') ' wave function ',trim(wfFile), ' with: '
       write(iul,'(1X,A17,A)') 'title =',trim(title)
       write(iul,'(1X,3(A17,A12,1X))') 'basis =',trim(basis),'MO format =',evfmt,  &
              'jastrow =',jastype
       s = 'bohr'; if (ang) s = 'angstrom'
       write(iul,'(1X,2(A17,I6,7X),A17,A12)') 'charge =',charge,'spin =',mult,' coord =',s
       write(iul,'(1X,3(A17,L7,1X))') 'atomic_charges =',partial,'same_atoms =',withSA,' no_H_jastrow =',ignoreHAtoms
       write(iul,*)
    end if

    !! ------ $geom block ---------

    call getNextBlock(allLines,nAllLines,idx,'$geom','$end','!', &
                      MAXBLOCK,lines,nl)
    if (nl<2) call abortp('wf file: $geom block not found or empty')
    call assert(.not.allocated(atoms),'geometry cannot be read twice')
    read(lines(2),*) ncenter                     ! # atoms, # of distinct atoms
    if (nl < ncenter+2) call abortp('wf file: $geom block not correctly formatted')

    allocate(atoms(ncenter))
    withBasis = (basis=='diff')
    call atoms_configure(ang,withSA,partial,withBasis)
    if (ignoreHAtoms) call atoms_ignoreHAtoms()
    call atoms_read(atoms,lines,nl,withSymbol=.true.)

    ne = atoms_countElectrons(atoms)
    ! correct (all) electron count with overall charge of molecule
    ! ECP core electrons are removed in ecp part below
    ne = ne - charge

    nscenter = atoms_getNSCenter(atoms)

    if (logmode >= 2) then
       write(iul,*) ' geometry (in angstrom):'
       call atoms_write(atoms,iul)
       write(iul,*)
       call flush(iul)
    end if

    ! the actual eloc initialization has to happen after the $ecp block
    ! because of the removal of ECP core electrons

    !! JASTROW MOVED AFTER ECP (ANISOJAS REQUIRES INITIALIZED BASIS)
    idxsave=idx    ! We need this because of the change in order!
    !! ---- $basis block

    call getNextBlock(allLines,nAllLines,idx,'$basis','$end','!', &
                      MAXBLOCK,lines,nl)

    absExists = .false.
    simpleBasisExists = .false.
    if (basis == 'gaussian') then
       ! read basis in gaussian format from $basis block
       if (nl == 0) call abortp("$basis block required for basis=gaussian")
       call aoinputg(lines,nl)
    else if (basis == 'general') then
       ! read basis in general (STO and GTO) format from $basis block
       if (nl == 0) call abortp("$basis block required for basis=general")
       call aoinput(lines,nl)
    else
      if (basis=='diff') then
        absExists = .true.
        simpleBasisExists=.true.
        do a=1,ncenter
          absExists = (absExists .and. inquireBasisFile(trim(atoms(a)%ba)//'.abs'))
          simpleBasisExists = (simpleBasisExists .and. inquireBasisFile(trim(atoms(a)%ba)))
        enddo
      else
       absExists = inquireBasisFile(trim(basis)//'.abs')
       simpleBasisExists = inquireBasisFile(trim(basis))
      endif
       if (absExists) then
          call aoinputabs()
       else if (simpleBasisExists) then
          call aoinputex()
       else
          call abortp("basis file not found")
       endif
    endif
    if (logmode>=2) then
       write(iul,'(/A)') ' basis set:'
       if (absExists) then
          write(iul,'(A,A)') ' basis name: ',trim(basis)//'.abs'
       else
          write(iul,'(A,A)') ' basis name: ',trim(basis)
       endif
       write(iul,'(A,I5/A,I5/)') ' different basis functions  =',nbasf, &
          ' individual basis functions =',nbas
       if (spline) write(iul,'(A16,I6)') ' spline_points =',splinpnts
    endif
    if (logmode>=3 .or. (MASTER.and.printAOs>0)) call aooutput(iul)
    if (logmode>= 2) write(iul,'(A/)') ' basis read ...'
    call flush(iul)


    !! ---- $ecp block
    call getNextBlock(allLines,nAllLines,idx,'$ecp','$end','!', &
                      MAXBLOCK,lines,nl)
    if (nl > 0) then ! $ecp block exists
       idx=idxsave                         ! We need this because the change in order!
       call ecpinput(lines,nl,wf%ecp)
       if (wf%ecp%isInitialised() .and. logmode >= 2) write(iul,*) ' ECPs read from $ecp block ...'
       if (logmode >= 2 .and. .not.(basis=='gaussian' .or. basis=='general')) &
          write(iul,'(/a/)') ' !!! $ecp block has overwritten any ECPs from the library !!!'
    else ! no $ecp block: check if ecp/basis set combination used
       call ecpinputex(wf%ecp)
       if (wf%ecp%isInitialised() .and. logmode >= 2) write(iul,*) ' ECPs read from ECP library ...'
    endif
    if (wf%ecp%isInitialised() .and. logmode >= 2) call ecpoutput(iul,wf%ecp)
    call flush(iul)

    ! now that the core electrons have potentially been removed, initialize
    ! the eloc part
    call eloc_initialize()

    ! calculate number of (valence) alpha and beta electrons (nalpha, nbeta)
    nalpha = (ne + mult - 1)/2
    if (2*nalpha /= ne+mult-1) call abortp('readWF: given multiplicity is impossible')
    nbeta = ne - nalpha
    if (logmode >= 2) then
       write(iul,'(/A,I4,A)') ' calculation with ',ne,' electrons'
       write(iul,'(2(I4,A))') nalpha,' alpha and ',nbeta,' beta'
    endif

    !! ---- $jastrow block

    call getNextBlock(allLines,nAllLines,idx,'$jastrow','$end','!', &
                      MAXBLOCK,lines,nl)
    if ((nl>0 .and. jastype(1:2)/='no') .or. jastype=='sm0') then
       call jasinput(lines,nl)
    else if (.not.(jastype(1:2)=='no')) then
       call abortp('$jastrow block required in .wf')
    end if

    if (logmode>=3 .or. printJ>0) then
       write(iul,'(/2a)') ' Jastrow type = ',jastype
       call jasoutput(iul)
    else if (logmode>=2) then
       write(iul,'(/3a)') ' Jastrow factor of type ',trim(jastype),' read with:'
       call jas_shortoutput(iul)
       write(iul,*), ' Jastrow factor read ...'
       call flush(iul)
    end if

    !! ---- $mos block

    call getNextBlock(allLines,nAllLines,idx,'$mos','$end','!', &
                      MAXBLOCK,lines,nl)
    if (nl==0) call abortp('$mos block required in .wf')
    call moinput(lines,nl)
    if (logmode>=3 .or. printMOs>0) call mooutput(iul)
    if (logmode >= 2) write(iul,*) ' MOs read ...'
    call flush(iul)

    ! CSF part

    call getNextBlock(allLines,nAllLines,idx,'$dets','$end','!', &
                      MAXBLOCK,lines,nl)
    if (nl>0) then
       call mdetinput(lines,nl)
    else
       call getNextBlock(allLines,nAllLines,idx,'$csfs','$end','!', &
                         MAXBLOCK,lines,nl)
       if (nl>0) then
          call mdetcsfinput(lines,nl)
       else
          call abortp("wf file: $dets or $csfs block is required")
       endif
    endif
    if (logmode >= 3 .or. printDet>0) call mdetoutput(iul)
    if (logmode >= 2) write(iul,*) ' CSFs read ...'
    call flush(iul)

    ! PROPERTIES
    !call getstra(lines,nl,'proptype=',mProptype,iflag)

    !found = findf(iu,'$props')
    !if(found.and.mProptype == 'dma') then
    ! call propInput(mProptype,ncenter,iu)
    !endif

    ! Calculate Potential Energy for Internuclear Repulsion
    vpot0 = 0d0
    do i=1,ncenter
       do j=i+1,ncenter
          rr = sqrt((atoms(i)%cx-atoms(j)%cx)**2 + (atoms(i)%cy-atoms(j)%cy)**2 + (atoms(i)%cz-atoms(j)%cz)**2)
          vpot0 = vpot0 + atoms(i)%za*atoms(j)%za/rr
          if(do_epart) Vnni(i,j) = atoms(i)%za*atoms(j)%za/rr
       enddo
    enddo
    if (do_epart) then
       do i=1,ncenter
          do j=i+1,ncenter
             Vnni(j,i) = Vnni(i,j)
          end do
       end do
    end if

  end subroutine readWF

!=================================================================================


  subroutine writeWF(wfFile,writeBasis,wf)
  !---------------------------------------

  ! writeWF writes the current wave function to the file wfFile

    integer, parameter :: ldim=500
    character(len=*), intent(inout) :: wfFile
    logical, intent(in)             :: writeBasis
    !!!!type(WFType), intent(in)     :: wf       ! in prevented by ecpwriteWF
    type(WFType), intent(inout)     :: wf
    integer a,i,ii,ii1,ii2,io,iu,j,iflag,nl,k
    real*8 rr
    character text*3,s*10
    character(len=120) lines(ldim),line
    logical form
    logical ltmp,findf,finda,ang,found

    if(.not. MASTER) return
    iu = 20

    ! Open Wavefunction file
    open(iu,file=wfFile,iostat=io)
    if (io /= 0) call abortp('writeWF: could not open '//trim(wfFile))

    write(iu,'(A)') '$general'
    line = ''
    if (title /= 'no title') then
       line=' title='//trim(title)
       write(iu,'(a)') trim(line)
       line = ''
    endif
    if (evfmt /= 'gau' .or. evfmt=='mol' ) line=trim(line)//' evfmt='//trim(evfmt)//','
    if (basis /= 'gaussian')  then
       if (writeBasis) then
          line=trim(line)//' basis=general,'
       else
          line=trim(line)//' basis='//trim(basis)//','
       endif
    endif

    ! If we're writing normalized AOs (general or gaussian basis which was *not*
    ! read from a bib file), make sure they're not "normalized" again when the
    ! WF is read the next time.
    if (.not. normalize .and. (basis == 'gaussian' .or. basis == 'general')) then
      line=trim(line)//' norm=.f.,'
    endif
    if (jastype /= 'none') line=trim(line)//' jastrow='//trim(jastype)//','
    if (len(trim(line))>0) then
       write(iu,'(a)') line(1:len(trim(line))-1)
       line = ''
    endif
    write(line,'(a,i2,a,i2)') ' charge=',charge,', spin=',mult
    if (partial) line=trim(line)//', atomic_charges'
    if (atoms_withSA()) line=trim(line)//', same_atoms_input'
    write(iu,'(a)') trim(line)

    ! jasLinscal ignored
    write(iu,'(a)') '$end'

    write(iu,'(a)') '$geom'
    write(iu,'(i3)') ncenter
    call atoms_write(atoms,iu)
    write(iu,'(a)') '$end'

    ! AO part
    if (basis == 'gaussian') then
       write(iu,'(a)') '$basis'
       call aooutputg(iu)
       write(iu,'(a)') '$end'
    else if (basis == 'general' .or. writeBasis) then
       write(iu,'(a)') '$basis'
       call aooutput(iu)
       write(iu,'(a)') '$end'
    endif

    ! Write ECP data
    if (wf%ecp%isInitialised()) then
      write(iu,'(a)') '$ecp'
      call ecpwriteWF(iu,wf%ecp)
      write(iu,'(a)') '$end'
    endif

    ! Jastrow part
    if (jastype(1:2) /= 'no') then
       write(iu,'(a)') '$jastrow'
       call jasoutput(iu)
       write(iu,'(a)') '$end'
    endif

    ! MO part
    write(iu,'(a)') '$mos'
    call mooutput(iu)
    write(iu,'(a)') '$end'

    ! CSF part
    write(iu,'(a)') '$csfs'
    call mdetoutput(iu)
    write(iu,'(a)') '$end'

    close(iu)

  end subroutine writeWF



  !------------------------------
  subroutine trajectory_head(iu)
  !------------------------------

    ! writes atom coordinates in xyz format

    integer iu,i

    write(iu,*) ncenter
    write(iu,*) 'amolqc trajectory data: atoms in xyz'
    do i=1,ncenter
       write(iu,'(A2,2X,3G13.6)')    &
            atoms(i)%elem,atoms(i)%cx*bohr2angs,atoms(i)%cy*bohr2angs,atoms(i)%cz*bohr2angs
    enddo
    write(iu,*) 'walker 1 trajectory for electron='
    write(iu,*) ne

  end subroutine trajectory_head


END MODULE wfmodule
