$awServerUrl = "http://localhost:5600/api/0"
$clientName = "aw-watcher-window"
$timePeriod = "-24h"  # check for last 1 day

try {
  # find bucketId
    $bucketsEndpoint = "$awServerUrl/buckets/"
    $buckets         = Invoke-RestMethod -Uri $bucketsEndpoint -Method Get
    $bucketId        = $null
    foreach ($bucket in $buckets.PSObject.Properties) {
        if ($bucket.Value.client -eq $clientName) {
            $bucketId = $bucket.Name
            break
        }
    }

    if (-not $bucketId) {
        throw "No bucket found for client '$clientName'"
    }

    # find events
    $startTime      = (Get-Date).AddHours(-24).ToUniversalTime().ToString("o")
    $eventsEndpoint = "$awServerUrl/buckets/$bucketId/events?start=$startTime&limit=-1"
    $response       = Invoke-RestMethod -Uri $eventsEndpoint -Method Get

    # pre-processing events
    $filteredEvents = $response | Where-Object { $_.data.app -ne "unknown" } | ForEach-Object {
        $_.data.app = $_.data.app -replace "\.exe$", ""  # Remove .exe from app name
        $_
    }

    if ($filteredEvents) {
        foreach ($event in $filteredEvents) {
            $xml  = "<SOFTWAREACTIVITY>"
            $xml += "<ACCESSED_AT>$($event.timestamp)</ACCESSED_AT>"
            $xml += "<APP_NAME>$($event.data.app)</APP_NAME>"
            $xml += "<AVERAGE_USAGE>$($event.duration)</AVERAGE_USAGE>"   # duration in seconds.decimal
            $xml += "</SOFTWAREACTIVITY>"
            Write-Host $xml
        }
    }
    else {
        Write-Host "<SOFTWAREACTIVITY/>"
    }
}
catch {
    Write-Error "Error: $_"
}
