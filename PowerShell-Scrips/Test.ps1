# Get JSON from the 
# URI for the PaperCut health Service
$uri = "http://152.30.32.191:9191/api/health?Authorization=J3bua56koNptqMg7PjNXf8D5IO8mLtcv"
#$response = Invoke-RestMethod -Uri $uri

# pick the values you want
#$gcTimeMilliseconds = $response.applicationserver.SystemMetrics.gcTimeMilliseconds
#$gcExecutions = $response.applicationserver.SystemMetrics.gcExecutions
#$gcTimePerExec = ($gcTimeMilliseconds / $gcExecutions)
#Write-Host ($gcTimeMilliseconds, $gcExecutions, [math]::Round($gcTimePerExec))

# Create a new ArayList object
#[System.Collections.ArrayList]$table = @()

# Insert the values into the ArayList
#$obj = [PSCustomObject]@{
#	gcTimeMilliseconds = $gcTimeMilliseconds
#	gcExecutions = $gcExecutions
#	gcTimePerExec = [math]::Round($gcTimePerExec)
#}
Invoke-RestMethod -Uri $uri | Select-Object -ExpandProperty applicationServer | Select-Object -ExpandProperty systemMetrics | ft
#$table.Add($obj)|Out-Null
While ($true) {
# Sleep for 60 seconds
Start-Sleep -s 30
Invoke-RestMethod -Uri $uri | Select-Object -ExpandProperty applicationServer | Select-Object -ExpandProperty systemMetrics | ft -HideTableHeaders
# Refresh data
#$response = Invoke-RestMethod -Uri $uri

# If gcExecutions has increased, store the new values

#if ($response.applicationserver.SystemMetrics.gcExecutions -gt $gcExecutions){

	#$dif_gcExecutions = ($response.applicationserver.SystemMetrics.gcExecutions - $gcExecutions)
	#$dif_gcTimeMilliseconds = ($response.applicationserver.SystemMetrics.gcTimeMilliseconds - $gcTimeMilliseconds)
	#$gcTimePerExec = [math]::Round($dif_gcTimeMilliseconds / $dif_gcExecutions)
	#$gcTimeMilliseconds = $response.applicationserver.SystemMetrics.gcTimeMilliseconds
	#$gcExecutions = $response.applicationserver.SystemMetrics.gcExecutions

	#Write-Host ($gcTimeMilliseconds, $gcExecutions, $gcTimePerExec)

	# Insert the new values into the ArayList
#	$obj = [PSCustomObject]@{
#		gcTimeMilliseconds = $gcTimeMilliseconds
#		gcExecutions = $gcExecutions
#		gcTimePerExec = $gcTimePerExec
#	}
#	$table.Add($obj)|Out-Null
#}
}
