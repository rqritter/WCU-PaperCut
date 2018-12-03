//
// This script is used to allow Library patrons to set a private release code. 
// The document name will be replaced by this code
//
function printJobHook(inputs, actions) {
  
  // Suppress the client pop-up until job analysis is complete
  if (!inputs.job.isAnalysisComplete) {
    actions.job.chargeToPersonalAccount();
    return;
  }

  // Set the pop-up message options
  var message = "<HTML>"
  + "<div style='text-align: center; font: 12px'>"
  + "Please create a release code to identify your document. Documents can be released at the Library Reference Desk."
  + "</HTML>";
  var releaseCode;
  var options =  {
    'fastResponse': true,
    'hideJobDetails' : false,
    'dialogTitle': "Enter Release Code",
    'dialogDesc': "Confirm your print job and enter a release code",
    'fieldLabel' : "Release Code",
    'timeoutSecs' : 60
  };
  
  // Prompt for Release Code
  releaseCode = actions.client.promptForText(message, options);
  if (releaseCode == "CANCEL" || releaseCode == "TIMEOUT") {
    // user canceled the dialog, took too long to answer or entered nothing
    actions.client.sendMessage("Job was cancelled or timed out without a response.");
    actions.job.addComment("Job was cancelled or timed out without a response");
    actions.job.cancel();
    return;
  }
  
  // Change the document name to the Release Code
  actions.job.changeDocumentName(releaseCode);
  return;
}
