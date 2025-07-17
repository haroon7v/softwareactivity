$awServerUrl  = "http://localhost:5600/api/0"
$clientName   = "aw-watcher-window"
$lookbackHrs  = 24

try {
    # ---------- bucket lookup (unchanged) ----------
    $bucketsEndpoint = "$awServerUrl/buckets/"
    $bucketId = (Invoke-RestMethod -Uri $bucketsEndpoint -Method Get).psobject.Properties |
                Where-Object { $_.Value.client -eq $clientName } |
                Select-Object -First 1 -ExpandProperty Name
    if (-not $bucketId) { throw "No bucket for '$clientName'" }

    # ---------- fetch raw events for the last 24h ----------
    $startTime      = (Get-Date).AddHours(-$lookbackHrs).ToUniversalTime().ToString("o")
    $eventsEndpoint = "$awServerUrl/buckets/$bucketId/events?start=$startTime&limit=-1"
    $events         = Invoke-RestMethod -Uri $eventsEndpoint -Method Get

    # ---------- drop “unknown”, strip .exe ----------
    $cleanEvents = $events |
        Where-Object { $_.data.app -ne "unknown" } |
        ForEach-Object {
            $_.data.app = $_.data.app -replace '\.exe$',''
            $_
        }

    # ---------- emit ONE XML block per *raw* event (no grouping) ----------
    if ($cleanEvents) {
        foreach ($event in $cleanEvents) {
            $xml  = "<SOFTWAREACTIVITY>"
            $xml += "<ACCESSED_AT>$($event.timestamp)</ACCESSED_AT>"
            $xml += "<APP_NAME>$($event.data.app)</APP_NAME>"
            $xml += "<AVERAGE_USAGE>$($event.duration)</AVERAGE_USAGE>"
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
