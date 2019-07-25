/*
* Notify the user of the job cost on different tiers.
*/
function printJobHook(inputs, actions) {

  // Charge to personal account while analysing document. (prevents client popup)
  if (!inputs.job.isAnalysisComplete) { 
    actions.job.chargeToPersonalAccount();
    return;
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
    + "<br><br>Faculty and Staff will see additional options after clicking <b>Print</b>"
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

