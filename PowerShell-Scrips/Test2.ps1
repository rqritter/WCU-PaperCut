# Get JSON from the 
# URI for the PaperCut health Service
$uri = "http://152.30.32.191:9191/api/health?Authorization=J3bua56koNptqMg7PjNXf8D5IO8mLtcv"
$CSV = "D:\Temp\PaperCutJVMStats.csv"

While ($true) {

    # Refresh data
    $request = Invoke-RestMethod -Uri $uri
    $systeMetrics = $request | Select-Object -ExpandProperty applicationServer | Select-Object -ExpandProperty systemMetrics
    $database = $request | Select-Object -ExpandProperty database
    $timestamp = Get-Date -Format s

    # Add data to psobject
    $out = new-object psobject
    $out | add-member noteproperty dateTime $timestamp
    $out | add-member noteproperty jvmMemoryTotalMB $systeMetrics.jvmMemoryTotalMB
    $out | add-member noteproperty jvmMemoryUsedMB $systeMetrics.jvmMemoryUsedMB
    $out | add-member noteproperty jvmMemoryUsedPercentage $systeMetrics.jvmMemoryUsedPercentage
    $out | add-member noteproperty totalConnections $database.totalConnections
    $out | add-member noteproperty activeConnections $database.activeConnections
    
    $formatedOut = $out | Select-Object -Property dateTime, jvmMemoryTotalMB, jvmMemoryUsedMB

    Write-Output $formatedOut

    Export-CSV -Path $CSV -InputObject $out -Append

    # Sleep for 30 seconds
    Start-Sleep -s 30

}
