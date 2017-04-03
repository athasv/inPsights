module OptimizeParamsModule

   use global
   use RWSampleModule
   use ElocAndPsiTermsLMModule
   use OptimizeParamsVarmin1Module
   use OptimizeParamsVarmin2Module
   use ElocAndPsiTermsLinModule
   use OptimizeParamsELinModule
   use ElocAndPsiTermsENRModule
   use OptimizeParamsENRModule
   use OptimizeParamsETRNRModule
   use ElocAndPsiTermsEBFGSModule
   use OptimizeParamsBFGSModule
   use OptimizeParamsLBFGSModule
   use ElocAndPsiTermsWEBFGSModule
   use OptimizeParamsWBFGSModule
   use OptimizeParamsPOptModule
   use WFParamsModule
   implicit none

   private
   public :: optimizeParameters

contains


   subroutine optimizeParameters(lines,nl,sample,converged)
   !------------------------------------------------------!

   integer, intent(in)            :: nl
   character(len=120), intent(in) :: lines(nl)
   type(RWSample), intent(inout)  :: sample
   logical, intent(out)           :: converged

   type(WFParamDef), target  :: WFP
   type(WFParamDef), pointer :: wfp_p => null()
   character(len=9)      :: optType      ! 'jastrow'|'ci'
   character(len=20)     :: optMethod    ! 'varmin1' ...
   integer               :: optMode      ! code for different parameter sets for same optType
   integer iter,oldlogmode,newlogmode,thislogmode,iflag
   logical energyMin, varMin

   converged = .true.

   ! general optimization initialization
   optType = 'jastrow'
   call getstra(lines,nl,'params=',optType,iflag)
   energyMin = finda(lines,nl,'energy_min')
   varMin = finda(lines,nl,'variance_min')
   if (energyMin .eqv. varMin) call abortp("$optimize_parameters: energy_min or variance_min required")
   if (varMin) then
      optMethod = 'varmin'
   else
      optMethod = 'lm_newton'
   end if
   call getstra(lines,nl,'method=',optMethod,iflag)
   optMode = 1
   call getinta(lines,nl,'optmode=',optMode,iflag)
   thislogmode = 0
   call getinta(lines,nl,'verbose=',thislogmode,iflag)

   oldlogmode = logmode
   if (MASTER .and. thislogmode>0) logmode = thislogmode

   if (optType=='mo' .or. optType=='jas+mo' .or. optType=='mo+ci' .or. optType=='jas+mo+ci' ) then
      call wfparams_init(WFP,optType,optMode,lines,nl)
   else
      call wfparams_init(WFP,optType,optMode)
   endif
   wfp_p => WFP

   if (logmode >= 2) then
      write(iul,'(5A,I3)') ' params = ',trim(optType),'    method = ',trim(optMethod),'    param mode=',optMode
   end if

   if (varMin) then
      if (optMethod=='lm') then
         call varmin1_optimizeSample(lines,nl,wfp_p,sample,converged)
      else if (optMethod=='varmin') then
         call varmin2_optimizeSample(lines,nl,wfp_p,sample,converged)
      else
         call abortp('$optimize_parameters: method not available')
      end if
   else if (energyMin) then
      if (optMethod=='eminlin') then
         call eminlin_optimizeSample(lines,nl,wfp_p,sample,converged)
      else if (optMethod=='newton' .or. optMethod=='scaled_newton' .or. optMethod=='lm_newton') then
         call eminNR_optimizeSample(lines,nl,wfp_p,sample,converged)
      else if (optMethod=='tr_newton') then
         call eminTRNR_optimizeSample(lines,nl,wfp_p,sample,converged)
      else if (optMethod=='popt') then
         call eminpopt_optimizeSample(lines,nl,wfp_p,sample,converged)
   !    else if (optMethod=='bfgs') then
   !       call eminBFGS_optimizeSample(lines,nl,wfp_p,sample)
   !    else if (optMethod=='lbfgs') then
   !       call eminLBFGS_optimizeSample(lines,nl,wfp_p,sample)
      else if (optMethod=='wbfgs') then
         call eminWBFGS_optimizeSample(lines,nl,wfp_p,sample,converged)
      else
         call abortp('optimizeParameters: method not available')
      endif
   end if

   call wfparams_destroy(WFP)
   logmode = oldlogmode

   end subroutine optimizeParameters

end module OptimizeParamsModule
