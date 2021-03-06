//
// This script is used to allow Department Copy Cards to release documents. 
// The script will ask the user for the number on the card and reasign
// the print job to a user associated with the card.
//
function printJobHook(inputs, actions) {
  
  // Suppress the client pop-up until job analysis is complete
  if (!inputs.job.isAnalysisComplete) {
    actions.job.chargeToPersonalAccount();
    return;
  }
 
  // Set the pop-up message options
  var message = "";
  var deptCopyCard;
  var options =  {
    'fastResponse': true,
    'hideJobDetails' : true,
    'dialogTitle': "Enter Code",
    'dialogDesc': "Enter the code from your Departmental Copy Card.",
    'fieldLabel' : "Department Copy Card",
    'timeoutSecs' : 60
  };
  
  // Prompt for Copy Card
  var exampleCard = '81122334455';
  deptCopyCard = actions.client.promptForText(
    "<html>"
    + "<div style='text-align: center; font: 12px'>"
    + "Please enter the code from your Department Copy Card"
    + "<br><br>"
    + "<img height='208' width='320' src='http://%PC_SERVER%/custom/card.gif' />"
    + "<br>Example"
    + "</div></html>", options);
  
    if (deptCopyCard == "CANCEL" || deptCopyCard == "TIMEOUT") {
    // user canceled the dialog, took too long to answer or entered nothing
    actions.client.sendMessage("No valid Departmental Copy Card entered or job was cancelled. A valid card is required to print to this queue.");
    actions.job.addComment("No valid departmental copy card entered");
    actions.job.cancel();
    return;
  } else if (deptCopyCard == exampleCard) {
    // user entered the example card number
    actions.client.sendMessage("Please do not use the example card number. Job has been cancelled");
    actions.job.cancel();
    return;
  }
  
  //Change the user associated with the job and redirect to the normal release queue
  actions.client.sendMessage("Job can be released with Department Copy Card " + deptCopyCard);
  actions.job.changeUser(deptCopyCard);
  actions.job.redirect("printserver.wcu.edu\\Color-Print", {allowHoldAtTarget: true, recalculateCost: true});
  return;
}
