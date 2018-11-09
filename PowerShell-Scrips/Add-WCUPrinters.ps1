<#
.SYNOPSIS
  Name:Add-WCUPrinters.ps1
  Graphical Application. Shows a list of printers available on a given server and a list of installed printers
  User can pick from the list and install one or multiple printers

.NOTES
  Updated: 2018-10-22
  Author: Richie
  ToDo:
    1. Decide if we should query remote server or get the list from a CSV
    2. Sign script
    
#>
# Load required assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.forms")
[System.Windows.forms.Application]::EnableVisualStyles()

# Start Creating Functions
Function Getprinters{

    # Reset the columns and content of listView_Printers before adding data to it.
    $listView_Printers.Items.Clear()
    $listView_Printers.Columns.Clear()
    
    # Get a list and create an array of all shared printers
    $printers = net view \\$server | Where-Object { $_ -match "print"} | ForEach-Object { $_ -replace "\s{2,}","`t"} | ConvertFrom-Csv -Delimiter "`t" -Header Name, Type, Description

    # Create a column in the listView for each property
    $listView_Printers.Columns.Add("Name") | Out-Null
    $listView_Printers.Columns.Add("Description") | Out-Null

    # Looping through each object in the array, and add a row for each
    ForEach ($Printer in $printers){

        # Create a listViewItem, and add the printer description
        $printerListViewItem = New-Object System.Windows.forms.ListViewItem($printer.Name)
        $printerListViewItem.SubItems.Add("$($printer.Description)") | Out-Null

        # Add the created listViewItem to the ListView control
        # (not adding 'Out-Null' at the end of the line will result in numbers outputred to the console)
        $listView_Printers.Items.Add($printerListViewItem) | Out-Null
    }

    # Resize all columns of the listView to fit their contents
    $listView_Printers.AutoResizeColumns("HeaderSize")
}

Function GetInstalledPrinters{

    # Reset the columns and content of listView_Printers before adding data to it.
    $listView_InstalledPrinters.Items.Clear()
    $listView_InstalledPrinters.Columns.Clear()
    
    # Get a list and create an array of all shared printers
    $InstalledPrinters = Get-Printer | Where-Object { $_.type -eq "Connection" }
    
    # Create a column in the listView for each property
    $listView_InstalledPrinters.Columns.Add("Name") | Out-Null
    $listView_InstalledPrinters.Columns.Add("Description") | Out-Null
    $listView_InstalledPrinters.Columns.Add("Server") | Out-Null

    # Looping through each object in the array, and add a row for each
    ForEach ($InstalledPrinter in $InstalledPrinters){

        # Create a listViewItem, and add the printer description
        $installedPrintersListViewItem = New-Object System.Windows.forms.ListViewItem($InstalledPrinter.ShareName)
        $installedPrintersListViewItem.SubItems.Add("$($InstalledPrinter.comment)") | Out-Null
        $installedPrintersListViewItem.SubItems.Add("$($InstalledPrinter.ComputerName)") | Out-Null

        # Add the created listViewItem to the ListView control
        # (not adding 'Out-Null' at the end of the line will result in numbers outputred to the console)
        $listView_InstalledPrinters.Items.Add($installedPrintersListViewItem) | Out-Null
    }

    # Resize all columns of the listView to fit their contents
    $listView_InstalledPrinters.AutoResizeColumns("HeaderSize")
}

Function InstallPrinters{

    # Since we allowed 'MultiSelect = $true' on the listView control,
    # Compile a list in an array of selected items
    $Selectedprinters = @($listView_Printers.SelectedIndices)

    # Setup Progress Bar values
    $Counter = 0
    $progressBarFull = $Selectedprinters.Count
    [Int]$Percentage = 25
    $progressBar_InstallPrinters.Value = $Percentage
    $form_AddPrinters.Refresh()

    # Find which column index has an the named printer on it, for the listView control
    $NameColumnIndex = ($listView_Printers.Columns | Where-Object {$_.Text -eq "Name"}).Index

    # For each object/item in the array of selected item, find which SubItem/cell of the row...
    $Selectedprinters | ForEach-Object {
    
        # ...contains the name of the Printer that is currently being "foreach'd",
        $PrinterName = ($listView_Printers.Items[$_].SubItems[$NameColumnIndex]).Text

        # Execute The PowerShell Code and Update the Status of the Progress-Bar
        # Install Printer
        Add-Printer -ConnectionName \\$server\$PrinterName
        
		## -- Calculate The Percentage Completed
		$Counter++
		[Int]$Percentage = ($Counter/$progressBarFull)*100
		$progressBar_InstallPrinters.Value = $Percentage
		$form_AddPrinters.Refresh()
	}

    # Refresh your Printer lists
    Getprinters
    GetInstalledPrinters
    $form_AddPrinters.Refresh()
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

$server = 'serif.wcu.edu'
$lastColumnClicked = 0 # tracks the last column number that was clicked
$lastColumnAscending = $false # tracks the direction of the last sort of this column

# Drawing form and controls
$form_AddPrinters = New-Object System.Windows.forms.form
    $form_AddPrinters.Text = "Printer Manager"
    $form_AddPrinters.Size = New-Object System.Drawing.Size(832,690)
    $form_AddPrinters.MaximizeBox  = $true
    $form_AddPrinters.MinimizeBox  = $true
    $form_AddPrinters.ControlBox = $true
    $form_AddPrinters.StartPosition = "CenterScreen"
    $form_AddPrinters.Font = "Segoe UI"

# Adding a label control to form
$label_AddPrinters = New-Object System.Windows.forms.Label
    $label_AddPrinters.Location = New-Object System.Drawing.Size(8,8)
    $label_AddPrinters.Size = New-Object System.Drawing.Size(500,32)
    $label_AddPrinters.TextAlign = "MiddleLeft"
    $label_AddPrinters.Text = "Please choose the printers you would like to add"
	    ## Add the label to the Form
        $form_AddPrinters.Controls.Add($label_AddPrinters)

# Create Progress-Bar
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

# Adding a listView control to form, which will hold available Printer information
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

# Adding a label control to form
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

# Adding a second listView control to form, which will hold installed Printer information
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

# Adding a button control to form
$button_RefreshPrinters = New-Object System.Windows.forms.Button
    $button_RefreshPrinters.Location = New-Object System.Drawing.Size(8,610)
    $button_RefreshPrinters.Size = New-Object System.Drawing.Size(240,32)
    $button_RefreshPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Left
    $button_RefreshPrinters.TextAlign = "MiddleCenter"
    $button_RefreshPrinters.Text = "Refresh Printer List"
    $button_RefreshPrinters.Add_Click({Getprinters})
    $button_RefreshPrinters.Add_Click({GetInstalledPrinters})
        # Add the button to the Form
        $form_AddPrinters.Controls.Add($button_RefreshPrinters)

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