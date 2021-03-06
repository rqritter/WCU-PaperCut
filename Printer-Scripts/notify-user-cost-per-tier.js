/*
* Notify the user of the job cost on different tiers.
* If the user is a student, 
*/
function printJobHook(inputs, actions) {

  // Charge to personal account while analysing document. (prevents client popup)
  if (!inputs.job.isAnalysisComplete) { 
    actions.job.chargeToPersonalAccount();
    return;
  }

  // If user is in the "Student_Currently_Enrolled" AD group... 
  var groupName = "Student_Currently_Enrolled";
  // var groupName = "Worker";
  if (inputs.user.isInGroup(groupName)) {

    // Bypass prompt for release queues by charging the job to personal account (not sure we need to do this. students should already be using personal accounts)
    actions.job.chargeToPersonalAccount();
  }
  
  // The list of printer tiers with a printer using each.
  var tierOne_Printer = "printserver.wcu.edu\\Tier001";
  var tierTwo_Printer = "printserver.wcu.edu\\Tier002";
  var tierThree_Printer = "printserver.wcu.edu\\Tier003";
  var tierFour_Printer = "printserver.wcu.edu\\Tier004";
  
  // Calculate the cost for each printer tier.
  var tierOne_Cost = inputs.job.calculateCostForPrinter(tierOne_Printer);
  var tierTwo_Cost = inputs.job.calculateCostForPrinter(tierTwo_Printer);
  var tierThree_Cost = inputs.job.calculateCostForPrinter(tierThree_Printer);
  var tierFour_Cost = inputs.job.calculateCostForPrinter(tierFour_Printer);
  
  actions.log.debug("Cost for: " + tierOne_Printer + " is: " + inputs.utils.formatCost(tierOne_Printer));
  actions.log.debug("Cost for: " + tierTwo_Printer + " is: " + inputs.utils.formatCost(tierTwo_Printer));
  actions.log.debug("Cost for: " + tierThree_Printer + " is: " + inputs.utils.formatCost(tierThree_Printer));
  actions.log.debug("Cost for: " + tierFour_Printer + " is: " + inputs.utils.formatCost(tierFour_Printer));
  
  // Get the user's personal balance
  var balance = inputs.user.balance;

  // Notify user of the cost for each tier.
  // Generate warning if user is a student and balance is lower than some calculated costs
  if (inputs.user.isInGroup(groupName) && tierTwo_Cost > balance) {
    var warningMessage = "<br><br><b>Warning!</b> Your print job will fail if released on tier 1 or tier 2 printers because your available balance is less than " + inputs.utils.formatCost(tierTwo_Cost);
  } else if (inputs.user.isInGroup(groupName) && tierOne_Cost > balance) {
    var warningMessage = "<br><br><b>Warning!</b> Your print job will fail if released on tier 1 printers because your available balance is less than " + inputs.utils.formatCost(tierOne_Cost);
  } else { var warningMessage = "<br>";
  }

  // Set the pop-up message options
  
  var options =  {
    'fastResponse': true,
    'hideJobDetails' : true,
    'dialogTitle': "Printer Tiers",
    'dialogDesc': "Please pay attention to your printer tier",
    'timeoutSecs' : 60,
    'questionID' : "Prompt1"
  };
  
  // Pop-up for student printing
  var response = actions.client.promptPrintCancel(
    "<html>"
    + "<div style='text-align: center; font: 12px'>"
    + "CatCash balance: " + inputs.utils.formatCost(balance)
    + "<br><br>"
    + "<b>Attention!</b> Your print job will have different costs depending on the tier of the printer where it is released."
    + "<br><br>"
    + "Page Count<br>"
    + "BW(" + inputs.job.totalGrayscalePages + ") + Color(" + inputs.job.totalColorPages + ")"
    + "<br><br>"
    + "Tier 1 Printers -------- " + inputs.utils.formatCost(tierOne_Cost) + "<br>"
    + "Tier 2 Printers -------- " + inputs.utils.formatCost(tierTwo_Cost) + "<br>"
    + "Tier 3 Printers -------- " + inputs.utils.formatCost(tierThree_Cost) + "<br>"
    + "Tier 4 Printers -------- " + inputs.utils.formatCost(tierFour_Cost)
    + "<br><br>"
    + "You can view a list of printers and tiers "
    + "<a href=\"https://www.wcu.edu/learn/academic-services/it/paw-print-services/pawprint-2019upgrade.aspx#UpdatedPricing\">here</a>"
    + "<span style='color:red'>" + warningMessage + "</span>"
    + "</div></html>", options);
  
  // If user selects "Print" or the job times out...
  if (response == "PRINT" || response == "TIMEOUT") {
    // Continue with job
  }
  
  // If user selects "Cancel"...
  if (response == "CANCEL") {
    // Cancel the job.
    actions.job.cancel();
    return;
  }
}

