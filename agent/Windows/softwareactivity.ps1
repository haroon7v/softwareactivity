$awServerUrl = "http://localhost:5600/api/0"
$clientName = "aw-watcher-window"
$lookbackHrs = 8

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
    $endHour   = (Get-Date).ToUniversalTime().
                   AddMinutes(- (Get-Date).Minute).
                   AddSeconds(- (Get-Date).Second)
    $startHour = $endHour.AddHours(-$lookbackHrs)
    $eventsEndpoint = "$awServerUrl/buckets/$bucketId/events?start=$($startHour.ToString('o'))&end=$($endHour.ToString('o'))&limit=-1"
    $response       = Invoke-RestMethod -Uri $eventsEndpoint -Method Get

    # pre-processing events
    $filteredEvents = $response | Where-Object { $_.data.app -ne "unknown" } | ForEach-Object {
        $_.data.app = $_.data.app -replace "\.exe$", ""  # Remove .exe from app name
        $_
    }

    # ── aggregate per app × date × hour ───────────────────────────────
    $hourSlots = $cleanEvents | Group-Object {
        $ts  = Get-Date $_.timestamp
        "$( $_.data.app )|$($ts.ToString('yyyy-MM-dd'))|$($ts.Hour)"
    } | ForEach-Object {
        $keyParts = $_.Name -split '\|'
        [pscustomobject]@{
            AppName = $keyParts[0]
            Day     = $keyParts[1]
            Hour    = [int]$keyParts[2]
            Seconds = ($_.Group | Measure-Object duration -Sum).Sum
        }
    }

    # latest event of unique apps
    $groupedEvents = $filteredEvents | Group-Object -Property { $_.data.app } | ForEach-Object {
        $_.Group | Sort-Object -Property timestamp -Descending | Select-Object -First 1
    }

    # ── emit XML ──────────────────────────────────────────────────────
    if ($hourSlots) {
        foreach ($slot in $hourSlots) {
            $xml  = "<SOFTWAREACTIVITY>"
            $xml += "<ACCESSED_AT>$($slot.Day)T$($slot.Hour.ToString('D2')):00:00Z</ACCESSED_AT>"
            $xml += "<APP_NAME>$($slot.AppName)</APP_NAME>"
            $xml += "<AVERAGE_USAGE>$($slot.Seconds)</AVERAGE_USAGE>"
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
