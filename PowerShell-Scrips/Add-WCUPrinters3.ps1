<#
.SYNOPSIS
  Name:Add-WCUPrinters3.ps1
  Graphical Application. Shows a list of printers from a CSV file and a list of installed printers
  User can pick from the list and install one or multiple printers

.NOTES
  Updated: 2018-11-21
    Added runspace and fake progress so the application does not appear to freeze
  Author: Richie
  ToDo:
    1. Sign script?
    
#>
# Load required assemblies
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.forms")
[System.Windows.forms.Application]::EnableVisualStyles()

# Declarations
$server = "printserver.wcu.edu"
$PrinterListFile = "\\printserver.wcu.edu\Share\Lists\PrinterList.tsv"
$printers = Import-Csv $PrinterListFile -Delimiter "`t"
$lastColumnClicked = 0 # tracks the last column number that was clicked
$lastColumnAscending = $false # tracks the direction of the last sort of this column

# Start Creating Functions
Function GetPrinters{
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
    foreach ($Printer in $printers){

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

Function GetFilteredPrinters{

    param ([parameter(Position=0)]$filterPrintersText)

    # Check if filterPrinterText is null and call GetPrinters function if it is
    if (!$filterPrintersText){
        GetPrinters
    }
    else {
        # Reset the columns and content of listView_Printers before adding data to it.
        $listView_Printers.Items.Clear()
        $listView_Printers.Columns.Clear()

        # Get a list and create an array of all shared printers on server
        $filteredPrinters = $printers | Where-Object {$_ -match $filterPrintersText}

        # Create a column in the listView for each property
        # ('Out-Null' is added at the end of the line to prevent output to the console)
        $listView_Printers.Columns.Add("ShareName") | Out-Null
        $listView_Printers.Columns.Add("Location") | Out-Null
        $listView_Printers.Columns.Add("Comment") | Out-Null

        # Loop through each object in the array, and add a row for each
        ForEach ($Printer in $filteredPrinters){

            # Create a listViewItem, and add the printer location and comment
            $printerListViewItem = New-Object System.Windows.forms.ListViewItem($Printer.ShareName)
            $printerListViewItem.SubItems.Add("$($Printer.Location)") | Out-Null
            $printerListViewItem.SubItems.Add("$($Printer.Comment)") | Out-Null

            # Add the created listViewItem to the ListView control
            $listView_Printers.Items.Add($printerListViewItem) | Out-Null
        }
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
    # ('Out-Null' is added at the end of the line to prevent output to the console)
    $listView_InstalledPrinters.Columns.Add("ShareName") | Out-Null
    $listView_InstalledPrinters.Columns.Add("Location") | Out-Null
    $listView_InstalledPrinters.Columns.Add("SystemName") | Out-Null

    # Loop through each object in the array, and add a row for each
    foreach ($InstalledPrinter in $InstalledPrinters){

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

    # Since we allowed "MultiSelect = $true" on the listView control, compile a list in an array of selected items
    $Selectedprinters = @($listView_Printers.SelectedIndices)

    # Update progress bar (it is fake, but needed since the interface freezes while we ware waiting on the runspace to finish)
    $Percentage = 1
    $progressBar_InstallPrinters.Value = $Percentage
    $form_AddPrinters.Refresh()

    # Warn if no printers have been selected 
    if ($Selectedprinters.count -lt "1"){
        [System.Windows.Forms.MessageBox]::Show("No printer(s) have been selected. Please select one or more printers in the list." , "Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    }
    else {
        # Setup Runspace
        $SyncHash = [hashtable]::Synchronized(@{ listView = $listView_Printers; Server = $server; Selectedprinters = $Selectedprinters })
        $Runspace = [runspacefactory]::CreateRunspace()
        $Runspace.ThreadOptions = "ReuseThread"
        $Runspace.Open()
        $Runspace.SessionStateProxy.SetVariable("SyncHash", $SyncHash)
        $powerShell = [PowerShell]::Create()
        $powerShell.Runspace = $Runspace
        [void]$powerShell.AddScript({
        
            # For each object/item in the array of selected item, find which SubItem/cell of the row...
            foreach ($Selectedprinter in $SyncHash.Selectedprinters) {
    
                # ...contains the name of the Printer that is currently being "foreach'd",
                $PrinterName = ($SyncHash.listView.Items[$Selectedprinter].SubItems[0]).Text

                # Install printer and update the status of the progress-bar
                (New-Object -ComObject WScript.Network).AddWindowsPrinterConnection("\\$($SyncHash.Server)\$PrinterName")
        
            }
        })

        # Invoke runspace
        $handle = $powerShell.BeginInvoke()
    
        # While runspace is not complete, animate the fake progress bar
        While (-Not $handle.IsCompleted) {
            if ($Percentage -gt 99) {$Percentage = 1}
            $Percentage++
            $progressBar_InstallPrinters.Value = $Percentage
            $form_AddPrinters.Refresh()
            Start-Sleep -Milliseconds 200
        }

        # Cleanup finished runspace
        $powerShell.EndInvoke($handle)
        $runspace.Close()
        $powerShell.Dispose()

        # Set fake progress bar to 100%
        $progressBar_InstallPrinters.Value = 100
        $form_AddPrinters.Refresh()

        # Show "completed" dialog box
        [System.Windows.Forms.MessageBox]::Show("$($Selectedprinters.count) printer(s) have been installed." , "Done",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information)

        # Refresh your Printer lists and reset progress bar
        GetPrinters
        GetInstalledPrinters
        $progressBar_InstallPrinters.Value = 0
        $form_AddPrinters.Refresh()
    }
}

function SortListView{
    # Eric Siron
    # RR - added $activeList parameter to handle multiple lists, removed numeric sorting
    param([parameter(Position=0)][UInt32]$column,
    [parameter(Position=1)][Windows.Forms.ListView]$activeList)

    # if the user clicked the same column that was clicked last time, reverse its sort order. otherwise, reset for normal ascending sort
    if ($Script:LastColumnClicked -eq $column){
        $Script:LastColumnAscending = -not $Script:LastColumnAscending
    }
    else {
        $Script:LastColumnAscending = $true
    }

    $Script:LastColumnClicked = $column
    # three-dimensional array; column 1 indexes the other columns, column 2 is the value to be sorted on, and column 3 is the System.Windows.Forms.ListViewItem object
    $listItems = @(@(@()))
 
    foreach ($listItem in $activeList.Items){
        $listItems += ,@($listItem.SubItems[[int]$Column].Text,$listItem)
    }
 
    # create the expression that will be evaluated for sorting
    $EvalExpression = {return [String]$_[0] }
 
    # all information is gathered; perform the sort
    $listItems = $listItems | Sort-Object -Property @{Expression=$EvalExpression; Ascending=$Script:LastColumnAscending}
 
    ## the list is sorted; display it in the listview
    $activeList.BeginUpdate()
    $activeList.Items.Clear()
    foreach ($listItem in $listItems)
        {
        $activeList.Items.Add($listItem[1])
        }
    $activeList.EndUpdate()
}

# Draw form and controls
$form_AddPrinters = New-Object System.Windows.forms.form
    $form_AddPrinters.Text = "Printer Manager"
    $form_AddPrinters.Size = New-Object System.Drawing.Size(832,688)
    $form_AddPrinters.MaximizeBox  = $true
    $form_AddPrinters.MinimizeBox  = $true
    $form_AddPrinters.ControlBox = $true
    $form_AddPrinters.StartPosition = "CenterScreen"
    $form_AddPrinters.Font = "Segoe UI"

# Add a label control to form for available printers
$label_AddPrinters = New-Object System.Windows.forms.Label
    $label_AddPrinters.Location = New-Object System.Drawing.Point(8,8)
    $label_AddPrinters.Size = New-Object System.Drawing.Size(500,28)
    $label_AddPrinters.TextAlign = "MiddleLeft"
    $label_AddPrinters.Text = "Please choose the printer(s) you would like to add."
	    ## Add the label to the form
        $form_AddPrinters.Controls.Add($label_AddPrinters)

# Add a label control to form to warn about form becoming non-responsive durring driver install
$label_Note = New-Object System.Windows.forms.Label
    $label_Note.Location = New-Object System.Drawing.Point(8,30)
    $label_Note.Size = New-Object System.Drawing.Size(500,28)
    $label_Note.TextAlign = "MiddleLeft"
    $label_Note.Text = "Note: It may take some time to install the first printer because the driver must also be installed."
	    ## Add the label to the form
        $form_AddPrinters.Controls.Add($label_Note)

# Add a progress-bar to form
$progressBar_InstallPrinters = New-Object System.Windows.Forms.ProgressBar
    $progressBar_InstallPrinters.Location = New-Object System.Drawing.Point(608,8)
    $progressBar_InstallPrinters.Size = New-Object System.Drawing.Size(200,20)
    $progressBar_InstallPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Right -bor 
    [System.Windows.forms.AnchorStyles]::Top
    $progressBar_InstallPrinters.Name = "Adding Printer(s)"
    $progressBar_InstallPrinters.Value = 0
    $progressBar_InstallPrinters.Style = "Continuous"
        ## Add the label to the form
        $form_AddPrinters.Controls.Add($progressBar_InstallPrinters)

# Add a text box to filter listView_Printers
$textBox_FilterPrinters = New-Object System.Windows.Forms.TextBox
    $textBox_FilterPrinters.Location = New-Object System.Drawing.Point(608,32)
    $textBox_FilterPrinters.Size = New-Object System.Drawing.Size(100,24)
    $textBox_FilterPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Right -bor 
    [System.Windows.forms.AnchorStyles]::Top
    $textBox_FilterPrinters.Add_KeyUp({GetFilteredPrinters $textBox_FilterPrinters.Text})
        ## Add textBox to form
        $form_AddPrinters.Controls.Add($textBox_FilterPrinters)

# Add a button to filter on textBox
$button_FilterPrinters = New-Object System.Windows.forms.Button
    $button_FilterPrinters.Location = New-Object System.Drawing.Point(710,31)
    $button_FilterPrinters.Size = New-Object System.Drawing.Size(98,24) 
    $button_FilterPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Right -bor 
    [System.Windows.forms.AnchorStyles]::Top
    $button_FilterPrinters.TextAlign = "MiddleCenter"
    $button_FilterPrinters.Text = "Filter"
    $button_FilterPrinters.Add_Click({GetFilteredPrinters $textBox_FilterPrinters.Text})
        # Add the button to the Form
        $form_AddPrinters.Controls.Add($button_FilterPrinters)

# Add a listView control to form, which will hold available Printer information
$Global:listView_Printers = New-Object System.Windows.forms.ListView
    $listView_Printers.Location = New-Object System.Drawing.Point(8,58)
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
    $listView_Printers.Add_ItemActivate({InstallPrinters})
    $listView_Printers.Add_ColumnClick({SortListView $_.Column $listView_Printers})
    	## Add the listview to the Form
        $form_AddPrinters.Controls.Add($listView_Printers)

# Add a label control to form for installed printers
$label_InstalledPrinters = New-Object System.Windows.forms.Label
    $label_InstalledPrinters.Location = New-Object System.Drawing.Point(8,362)
    $label_InstalledPrinters.Size = New-Object System.Drawing.Size(800,28)
    $label_InstalledPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Right -bor 
    [System.Windows.forms.AnchorStyles]::Left
    $label_InstalledPrinters.TextAlign = "MiddleLeft"
    $label_InstalledPrinters.Text = "Currently installed printers"
        ## Add the label to the Form
        $form_AddPrinters.Controls.Add($label_InstalledPrinters)

# Add a second listView control to form, which will hold installed Printer information
$Global:listView_InstalledPrinters = New-Object System.Windows.forms.ListView
    $listView_InstalledPrinters.Location = New-Object System.Drawing.Point(8,390)
    $listView_InstalledPrinters.Size = New-Object System.Drawing.Size(800,214)
    $listView_InstalledPrinters.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Right -bor 
    [System.Windows.forms.AnchorStyles]::Left
    $listView_InstalledPrinters.View = "Details"
    $listView_InstalledPrinters.FullRowSelect = $true
    $listView_InstalledPrinters.MultiSelect = $false
    $listView_InstalledPrinters.Sorting = "None"
    $listView_InstalledPrinters.AllowColumnReorder = $true
    $listView_InstalledPrinters.GridLines = $true
    $listView_InstalledPrinters.Add_ColumnClick({SortListView $_.Column $listView_InstalledPrinters})
        ## Add the listview to the Form
        $form_AddPrinters.Controls.Add($listView_InstalledPrinters)

# Add a button control to form for Exit
$button_Exit = New-Object System.Windows.forms.Button
    $button_Exit.Location = New-Object System.Drawing.Point(8,610)
    $button_Exit.Size = New-Object System.Drawing.Size(240,32)
    $button_Exit.Anchor = [System.Windows.forms.AnchorStyles]::Bottom -bor
    [System.Windows.forms.AnchorStyles]::Left
    $button_Exit.TextAlign = "MiddleCenter"
    $button_Exit.Text = "Exit"
    $button_Exit.Add_Click({$form_AddPrinters.Close()})
        # Add the button to the Form
        $form_AddPrinters.Controls.Add($button_Exit)

# Add a button to install selected printers
$button_InstallPrinters = New-Object System.Windows.forms.Button
    $button_InstallPrinters.Location = New-Object System.Drawing.Point(568,610)
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