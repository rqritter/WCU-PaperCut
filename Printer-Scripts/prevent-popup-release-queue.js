//
// This script is run when a new job arrives for this printer.  It prevents the client popup and
// re-assigns the job to charge to personal account. Using this instead of the built in
// "Override user-level settings" function allows the user to change where the job is charged
// when releasing the job at the printer.
//
function printJobHook(inputs, actions) {
  // Hold the job until analysis is complete 
  if (!inputs.job.isAnalysisComplete) { 
    actions.job.chargeToPersonalAccount();
    return;
  }
  // Automatically charge all Mobility Print jobs to a users personal account  
  actions.job.chargeToPersonalAccount();
}
