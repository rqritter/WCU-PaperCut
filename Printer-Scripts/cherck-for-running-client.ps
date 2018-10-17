/*
* Test to redirect job to release queue if user is in the "Worker" group and not running the client
*/

function printJobHook(inputs, actions) {
  
  var groupName = "Worker"
      var releaseQueue = "serif.wcu.edu\\Paw_Print"
      var fullName = inputs.user.fullName
      var documentName = inputs.job.documentName
      var printerName = inputs.job.printerName
      var emailRecipient = inputs.user.email
      var emailSubject = "Printing error: There is an issue with your PaperCut client"
      var emailBody = fullName
      + ",\n\n"
      + "Unfortunately, we were unable to complete the print job \""
      + documentName
      + "\" that was sent to \""
      + printerName
      + "\" because there is an issue with your PaperCut client. The print job will be held in the queue and can be released with your CatCard at any multifunction PawPrint printer. Please call the IT Help Desk at 227-7487 for assistance with fixing the PaperCut client."
      
      // Charge to personal account while analysing to prevent client popup
      if (!inputs.job.isAnalysisComplete) {
      actions.job.chargeToPersonalAccount();
  return;
}
// Perform action if the user is not running the client software.
if (!inputs.client.isRunning) {
  
  // Check if user is in the Worker group
  if (inputs.user.isInGroup(groupName)) {
    
    // Client is not running. Redirect to release queue and email user
    actions.job.chargeToPersonalAccount();
    actions.job.redirect(releaseQueue , {allowHoldAtTarget: true});
    actions.utils.sendEmail(emailRecipient, emailSubject, emailBody);
  }
} 
}
  ​
