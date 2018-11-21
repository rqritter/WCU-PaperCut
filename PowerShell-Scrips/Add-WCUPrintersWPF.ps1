<#

    
#>

# Declarations
$server = "printserver.wcu.edu"
$PrinterListFile = "\\printserver.wcu.edu\Share\Lists\PrinterList.tsv"
$printers = Import-Csv $PrinterListFile -Delimiter "`t"
$lastColumnClicked = 0 # tracks the last column number that was clicked
$lastColumnAscending = $false # tracks the direction of the last sort of this column


# Load required assemblies

# Load XAML for the GUI
$xaml = @"

<Window x:Name="WCU_Print_Manager"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WCU Print Manager" Height="456" Width="808">
    <Grid>
        <Label x:Name="label_AddPrinters" Content="Please choose the printer(s) you would like to add." HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top"/>
        <Label x:Name="label_Note" Content="Note: It may take some time to install the first printer because the driver must also be installed." HorizontalAlignment="Left" Margin="10,29,0,0" VerticalAlignment="Top"/>
        <Label x:Name="label_InstalledPrinters" Content="Currently installed printers" HorizontalAlignment="Left" Margin="10,222,0,0" VerticalAlignment="Top"/>
        <ProgressBar x:Name="progressBar_InstallPrinters" HorizontalAlignment="Left" Height="20" Margin="685,10,0,0" VerticalAlignment="Top" Width="97"/>
        <TextBox x:Name="textBox_FilterPrinters" HorizontalAlignment="Left" Height="20" Margin="582,35,0,0" TextWrapping="Wrap" Text="" VerticalAlignment="Top" Width="120" RenderTransformOrigin="0.136,0.472"/>
        <Button x:Name="button_FilterPrinters" Content="Filter" HorizontalAlignment="Left" Margin="707,35,0,0" VerticalAlignment="Top" Width="75"/>
        <ListView x:Name="listView_Printers" HorizontalAlignment="Left" Height="161" Margin="10,60,0,0" VerticalAlignment="Top" Width="772">
            <ListView.View>
                <GridView>
                <GridViewColumn Width="150" Header="ShareName" DisplayMemberBinding="{Binding ShareName}"/> 
                <GridViewColumn Width="150" Header="Location" DisplayMemberBinding="{Binding Location}"/> 
                <GridViewColumn Width="400" Header="Comment" DisplayMemberBinding="{Binding Comment}"/> 
                </GridView>
            </ListView.View>
        </ListView>
        <ListView x:Name="listView_InstalledPrinters" HorizontalAlignment="Left" Height="139" Margin="10,245,0,0" VerticalAlignment="Top" Width="772">
            <ListView.View>
                <GridView>
                <GridViewColumn Width="150" Header="ShareName" DisplayMemberBinding="{Binding ShareName}"/> 
                <GridViewColumn Width="150" Header="Location" DisplayMemberBinding="{Binding Location}"/> 
                <GridViewColumn Width="400" Header="SystemName" DisplayMemberBinding="{Binding SystemName}"/> 
                </GridView>
            </ListView.View>
        </ListView>
        <Button x:Name="button_Exit" Content="Exit" HorizontalAlignment="Left" Margin="10,389,0,0" VerticalAlignment="Top" Width="100"/>
        <Button x:Name="button_InstallPrinters" Content="Install Printer(s)" HorizontalAlignment="Left" Margin="683,389,0,0" VerticalAlignment="Top" Width="100"/>

    </Grid>
</Window>

"@ 


function Convert-XAMLtoWindow
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $XAML
    )
    
    Add-Type -AssemblyName PresentationFramework
    
    $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
    $result = [Windows.Markup.XAMLReader]::Load($reader)
    $reader.Close()
    $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
    while ($reader.Read())
    {
        $name=$reader.GetAttribute('Name')
        if (!$name) { $name=$reader.GetAttribute('x:Name') }
        if($name)
        {$result | Add-Member NoteProperty -Name $name -Value $result.FindName($name) -Force}
    }
    $reader.Close()
    $result
}

function Show-WPFWindow
{
    param
    (
        [Parameter(Mandatory)]
        [Windows.Window]
        $Window
    )
    
    $result = $null
    $null = $window.Dispatcher.InvokeAsync{
        $result = $window.ShowDialog()
        Set-Variable -Name result -Value $result -Scope 1
    }.Wait()
    $result
}

$window = Convert-XAMLtoWindow -XAML $xaml

$window.button_Exit.add_Click{
    $window.DialogResult = $false
}

$window.button_InstallPrinters.add_Click{
    (New-Object -ComObject WScript.Network).AddWindowsPrinterConnection("\\$server\Printer001")
}

$window.listView_Printers.ItemsSource = @(Import-Csv $PrinterListFile -Delimiter "`t")

$window.listView_InstalledPrinters.ItemsSource = @(Get-WmiObject -Class Win32_Printer | Where-Object { $_.SystemName -match "\\\\" })

$null = Show-WPFWindow -Window $window

