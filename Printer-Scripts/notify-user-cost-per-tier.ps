/*
* Notify the user of the job cost on different tiers
*/
function printJobHook(inputs, actions) {
  // Hold the job until analysis is complete 
  if (!inputs.job.isAnalysisComplete) { 
    actions.job.chargeToPersonalAccount();
    return;
  }
  // Bypass prompt for release queues by setting to personal printing  
  actions.job.chargeToPersonalAccount();
  
  // The list of printer tiers with a printer using each.
  var tierOne_Printer = "serif.wcu.edu\\Printer001";
  var tierTwo_Printer = "serif.wcu.edu\\Printer002";
  var tierThree_Printer = "serif.wcu.edu\\Printer003";
  var tierFour_Printer = "serif.wcu.edu\\Printer004";
  
  // Calculate the cost for each printer tier.
  var tierOne_Cost = inputs.job.calculateCostForPrinter(tierOne_Printer);
  var tierTwo_Cost = inputs.job.calculateCostForPrinter(tierTwo_Printer);
  var tierThree_Cost = inputs.job.calculateCostForPrinter(tierThree_Printer);
  var tierFour_Cost = inputs.job.calculateCostForPrinter(tierFour_Printer);
  
  actions.log.debug("Cost for: " + tierOne_Printer + " is: " + inputs.utils.formatCost(tierOne_Printer));
  actions.log.debug("Cost for: " + tierTwo_Printer + " is: " + inputs.utils.formatCost(tierTwo_Printer));
  actions.log.debug("Cost for: " + tierThree_Printer + " is: " + inputs.utils.formatCost(tierThree_Printer));
  actions.log.debug("Cost for: " + tierFour_Printer + " is: " + inputs.utils.formatCost(tierFour_Printer));
  
  // Notify user of the cost for each tier.
  // Set the pop-up message options
  
  var options =  {
    'hideJobDetails' : true,
    'dialogTitle': 'Printer Tiers',
    'dialogDesc': 'Please pay attention to your printer tier',
    'timeoutSecs' : 60
  };
  
  var response = actions.client.promptPrintCancel(
    "<html>"
    + "<div style='text-align: center; font: 12px'><b>Attention!</b> Your print job will have different costs depending on the tier of the printer where it is released"
    + "<br><br>"
    + "Tier 1 Printers -------- " + inputs.utils.formatCost(tierOne_Cost) + "<br>"
    + "Tier 2 Printers -------- " + inputs.utils.formatCost(tierTwo_Cost) + "<br>"
    + "Tier 3 Printers -------- " + inputs.utils.formatCost(tierThree_Cost) + "<br>"
    + "Tier 4 Printers -------- " + inputs.utils.formatCost(tierFour_Cost)
    + "<br><br>"
    + "You can view a list of printers and tiers "
    + "<a href=\"https://www.wcu.edu/learn/academic-services/it/paw-print-services/paw-print-faqs/pricing-and-printer-tiers.aspx\">here</a></div>"
    + "</html>", options);
  
  if (response == "PRINT" || response == "TIMEOUT") {
    // Continue with the job.
  }
  
  if (response == "CANCEL") {
    // Cancel the job
    actions.job.cancel();
  }
}
