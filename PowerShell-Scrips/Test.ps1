Add-Type -AssemblyName System.Windows.Forms
$form1=New-Object System.Windows.Forms.Form
$form1.StartPosition='CenterScreen'
$WPFProgressBar = New-Object System.Windows.Forms.ProgressBar
$form1.Controls.Add($WPFProgressBar)
$WPFProgressBar.Style = 'Continuous'
$button1 = New-Object System.Windows.Forms.Button
$button1.Text='Run'
$button1.Location = '30,40'
$form1.Controls.Add($button1)
$button1.add_Click( {
	$SyncHash = [hashtable]::Synchronized(@{ Form = $Form1; WPFlistView = $WPFlistView; WPFProgressBar = $WPFProgressBar })
	$Runspace = [runspacefactory]::CreateRunspace()
	$Runspace.ThreadOptions = "ReuseThread"
	$Runspace.Open()
	$Runspace.SessionStateProxy.SetVariable("SyncHash", $SyncHash)
	$Worker = [PowerShell]::Create().AddScript({
			foreach ($i in (1..100)) {
				$i.Status = "Working"
				start-sleep -Milliseconds 100
				$SyncHash.WPFProgressBar.Value++
			}
		})
	$Worker.Runspace = $Runspace
	$Worker.BeginInvoke()
	
})

$form1.ShowDialog()