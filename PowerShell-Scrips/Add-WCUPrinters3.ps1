<#
.SYNOPSIS
  Name:Add-WCUPrinters3.ps1
  Graphical Application. Shows a list of printers from a CSV file and a list of installed printers
  User can pick from the list and install one or multiple printers

.NOTES
  Updated: 2018-10-22
  Author: Richie
  ToDo:
    1. Sign script?
    2. Add label or dialog that displays after install
    3. add double click feature
    
#>
# Load required assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.forms")
[System.Windows.forms.Application]::EnableVisualStyles()

# Declarations
$server = 'printserver.wcu.edu'
$PrinterListFile = "\\printserver.wcu.edu\Share\Lists\PrinterList.tsv"
$lastColumnClicked = 0 # tracks the last column number that was clicked
$lastColumnAscending = $false # tracks the direction of the last sort of this column

# Start Creating Functions
Function Getprinters{

    # Reset the columns and content of listView_Printers before adding data to it.
    $listView_Printers.Items.Clear()
    $listView_Printers.Columns.Clear()
    
    # Get a list and create an array of all shared printers on server
    $printers = Import-Csv $PrinterListFile -Delimiter "`t"

    # Create a column in the listView for each property
    # (not adding 'Out-Null' at the end of the line can result in output to the console)
    $listView_Printers.Columns.Add("ShareName") | Out-Null
    $listView_Printers.Columns.Add("Location") | Out-Null
    $listView_Printers.Columns.Add("Comment") | Out-Null

    # Loop through each object in the array, and add a row for each
    ForEach ($Printer in $printers){

        # Create a listViewItem, and add the printer location and comment
        $printerListViewItem = New-Object System.Windows.forms.ListViewItem($printer.ShareName)
        $printerListViewItem.SubItems.Add("$($printer.Location)") | Out-Null
        $printerListViewItem.SubItems.Add("$($printer.Comment)") | Out-Null

        # Add the created listViewItem to the ListView control
        $listView_Printers.Items.Add($printerListViewItem) | Out-Null
    }

    # Resize all columns of the listView to fit their contents
    $listView_Printers.AutoResizeColumns("HeaderSize")
}

Function GetInstalledPrinters{

    # Reset the columns and content of listView_Printers before adding data to it.
    $listView_InstalledPrinters.Items.Clear()
    $listView_InstalledPrinters.Columns.Clear()
    
    # Get a list and create an array of all mapped printers
    $InstalledPrinters = Get-WmiObject -Class Win32_Printer | Where-Object { $_.SystemName -match "\\\\" }
    
    # Create a column in the listView for each property
    # (not adding 'Out-Null' at the end of the line can result in output to the console)
    $listView_InstalledPrinters.Columns.Add("ShareName") | Out-Null
    $listView_InstalledPrinters.Columns.Add("Location") | Out-Null
    $listView_InstalledPrinters.Columns.Add("SystemName") | Out-Null

    # Loop through each object in the array, and add a row for each
    ForEach ($InstalledPrinter in $InstalledPrinters){

        # Create a listViewItem, and add the printer description
        $installedPrintersListViewItem = New-Object System.Windows.forms.ListViewItem($InstalledPrinter.ShareName)
        $installedPrintersListViewItem.SubItems.Add("$($InstalledPrinter.Location)") | Out-Null
        $installedPrintersListViewItem.SubItems.Add("$($InstalledPrinter.SystemName)") | Out-Null

        # Add the created listViewItem to the ListView control
        $listView_InstalledPrinters.Items.Add($installedPrintersListViewItem) | Out-Null
    }

    # Resize all columns of the listView to fit their contents
    $listView_InstalledPrinters.AutoResizeColumns("HeaderSize")
}

Function InstallPrinters{

    # Since we allowed 'MultiSelect = $true' on the listView control,
    # Compile a list in an array of selected items
    $Selectedprinters = @($listView_Printers.SelectedIndices)

    # Warn if no printers have been selected 
    if ($Selectedprinters.count -lt "1"){
        [System.Windows.Forms.MessageBox]::Show("No printer(s) have been selected. Please select one or more printers in the list." , "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
    else {

        # Setup Progress Bar values
        $Counter = 0
        $progressBarFull = $Selectedprinters.Count
        [Int]$Percentage = 25
        $progressBar_InstallPrinters.Value = $Percentage
        $form_AddPrinters.Refresh()

        # Find which column index has an the named printer on it, for the listView control
        $NameColumnIndex = ($listView_Printers.Columns | Where-Object {$_.Text -eq "ShareName"}).Index

        # For each object/item in the array of selected item, find which SubItem/cell of the row...
        $Selectedprinters | ForEach {
    
            # ...contains the name of the Printer that is currently being "foreach'd",
            $PrinterName = ($listView_Printers.Items[$_].SubItems[$NameColumnIndex]).Text

            # Install printer and update the status of the progress-bar
            (New-Object -ComObject WScript.Network).AddWindowsPrinterConnection("\\$server\$PrinterName")
        
		    ## -- Calculate The Percentage Completed
		    $Counter++
		    [Int]$Percentage = ($Counter/$progressBarFull)*100
		    $progressBar_InstallPrinters.Value = $Percentage
		    $form_AddPrinters.Refresh()
        }
        # Show "completed" dialog box
        [System.Windows.Forms.MessageBox]::Show("$($Selectedprinters.count) printer(s) have been installed." , "Done",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information)

        # Refresh your Printer lists
        Getprinters
        GetInstalledPrinters
        $form_AddPrinters.Refresh()
    }
}

function SortListView # Eric Siron
# RR - added $activeList parameter to handle multiple lists, removed numeric sorting
{
param([parameter(Position=0)][UInt32]$column,
[parameter(Position=1)][Windows.Forms.ListView]$activeList)

# if the user clicked the same column that was clicked last time, reverse its sort order. otherwise, reset for normal ascending sort
if($Script:LastColumnClicked -eq $column)
{
    $Script:LastColumnAscending = -not $Script:LastColumnAscending
}
else
{
    $Script:LastColumnAscending = $true
}
$Script:LastColumnClicked = $column
$listItems = @(@(@())) # three-dimensional array; column 1 indexes the other columns, column 2 is the value to be sorted on, and column 3 is the System.Windows.Forms.ListViewItem object
 
foreach($listItem in $activeList.Items)
{
    $listItems += ,@($listItem.SubItems[[int]$Column].Text,$listItem)
}
 
# create the expression that will be evaluated for sorting
$EvalExpression = {return [String]$_[0] }
 
# all information is gathered; perform the sort
$listItems = $listItems | Sort-Object -Property @{Expression=$EvalExpression; Ascending=$Script:LastColumnAscending}
 
## the list is sorted; display it in the listview
$activeList.BeginUpdate()
$activeList.Items.Clear()
foreach($listItem in $listItems)
{
    $activeList.Items.Add($listItem[1])
}
$activeList.EndUpdate()
}

# Begin to draw form
# Draw form and controls
$form_AddPrinters = New-Object System.Windows.forms.form
    $form_AddPrinters.Text = "Printer Manager"
    $form_AddPrinters.Size = New-Object System.Drawing.Size(832,690)
    $form_AddPrinters.MaximizeBox  = $true
    $form_AddPrinters.MinimizeBox  = $true
    $form_AddPrinters.ControlBox = $true
    $form_AddPrinters.StartPosition = "CenterScreen"
    $form_AddPrinters.Font = "Segoe UI"

# Add a label control to form for available printers
$label_AddPrinters = New-Object System.Windows.forms.Label
    $label_AddPrinters.Location = New-Object System.Drawing.Size(8,8)
    $label_AddPrinters.Size = New-Object System.Drawing.Size(500,32)
    $label_AddPrinters.TextAlign = "MiddleLeft"
    $label_AddPrinters.Text = "Please choose the printers you would like to add"
	    ## Add the label to the Form
        $form_AddPrinters.Controls.Add($label_AddPrinters)

# Add a progress-bar to form
$progressBar_InstallPrinters = New-Object System.Windows.Forms.ProgressBar
    $progressBar_InstallPrinters.Location = New-Object System.Drawing.Size(608,8)
    $progressBar_InstallPrinters.Size = New-Object System.Drawing.Size(200,24)
    $progressBar_InstallPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Right -bor 
    [System.Windows.forms.AnchorStyles]::Top
    $progressBar_InstallPrinters.Name = "Adding Printer(s)"
    $progressBar_InstallPrinters.Value = 0
    $progressBar_InstallPrinters.Style="Continuous"
        ## Add the label to the Form
        $form_AddPrinters.Controls.Add($progressBar_InstallPrinters)

# Add a listView control to form, which will hold available Printer information
$Global:listView_Printers = New-Object System.Windows.forms.ListView
    $listView_Printers.Location = New-Object System.Drawing.Size(8,40)
    $listView_Printers.Size = New-Object System.Drawing.Size(800,300)
    $listView_Printers.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Right -bor 
    [System.Windows.forms.AnchorStyles]::Top -bor
    [System.Windows.forms.AnchorStyles]::Left
    $listView_Printers.View = "Details"
    $listView_Printers.FullRowSelect = $true
    $listView_Printers.MultiSelect = $true
    $listView_Printers.Sorting = "None"
    $listView_Printers.AllowColumnReorder = $true
    $listView_Printers.GridLines = $true
    $listView_Printers.Add_ColumnClick({SortListView $_.Column $listView_Printers})
    	## Add the listview to the Form
        $form_AddPrinters.Controls.Add($listView_Printers)

# Add a label control to form for installed printers
$label_InstalledPrinters = New-Object System.Windows.forms.Label
    $label_InstalledPrinters.Location = New-Object System.Drawing.Size(8,350)
    $label_InstalledPrinters.Size = New-Object System.Drawing.Size(800,32)
    $label_InstalledPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Right -bor 
    #[System.Windows.forms.AnchorStyles]::Top -bor
    [System.Windows.forms.AnchorStyles]::Left
    $label_InstalledPrinters.TextAlign = "MiddleLeft"
    $label_InstalledPrinters.Text = "Currently installed printers"
        ## Add the label to the Form
        $form_AddPrinters.Controls.Add($label_InstalledPrinters)

# Add a second listView control to form, which will hold installed Printer information
$Global:listView_InstalledPrinters = New-Object System.Windows.forms.ListView
    $listView_InstalledPrinters.Location = New-Object System.Drawing.Size(8,382)
    $listView_InstalledPrinters.Size = New-Object System.Drawing.Size(800,220)
    $listView_InstalledPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Right -bor 
    #[System.Windows.forms.AnchorStyles]::Top -bor
    [System.Windows.forms.AnchorStyles]::Left
    $listView_InstalledPrinters.View = "Details"
    $listView_InstalledPrinters.FullRowSelect = $true
    $listView_InstalledPrinters.MultiSelect = $true
    $listView_InstalledPrinters.Sorting = "None"
    $listView_InstalledPrinters.AllowColumnReorder = $true
    $listView_InstalledPrinters.GridLines = $true
    $listView_InstalledPrinters.Add_ColumnClick({SortListView $_.Column $listView_InstalledPrinters})
        ## Add the listview to the Form
        $form_AddPrinters.Controls.Add($listView_InstalledPrinters)

# Add a button control to form for Exit
$button_Exit = New-Object System.Windows.forms.Button
    $button_Exit.Location = New-Object System.Drawing.Size(8,610)
    $button_Exit.Size = New-Object System.Drawing.Size(240,32)
    $button_Exit.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Left
    $button_Exit.TextAlign = "MiddleCenter"
    $button_Exit.Text = "Exit"
    $button_Exit.Add_Click({$form_AddPrinters.Close()})
        # Add the button to the Form
        $form_AddPrinters.Controls.Add($button_Exit)

# Adding another button control to form
$button_InstallPrinters = New-Object System.Windows.forms.Button
    $button_InstallPrinters.Location = New-Object System.Drawing.Size(568,610)
    $button_InstallPrinters.Size = New-Object System.Drawing.Size(240,32)
    $button_InstallPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Right
    $button_InstallPrinters.TextAlign = "MiddleCenter"
    $button_InstallPrinters.Text = "Install Selected Printer(s)"
    $button_InstallPrinters.Add_Click({InstallPrinters})
        ## Add the button to the Form
        $form_AddPrinters.Controls.Add($button_InstallPrinters)

# Show form with all of its controls
$form_AddPrinters.Add_Shown({$form_AddPrinters.Activate();GetPrinters})
$form_AddPrinters.Add_Shown({$form_AddPrinters.Activate();GetInstalledPrinters})
[Void] $form_AddPrinters.ShowDialog()
$form_AddPrinters.Refresh()