$logFilePath = "D:\AUTOMATING USER ACCOUNT\user_management.log"
$reportPath = "D:\AUTOMATING USER ACCOUNT\log_report.csv"

# Function to analyze logs
function AnalyzeLogs {
    param (
        [string]$logFilePath,
        [string]$dateFilter = "",
        [string]$timeFilter = ""
    )

    # Reading and filtering log entries
    $logEntries = Get-Content $logFilePath | Where-Object {
        if ($dateFilter -ne "") {
            $_ -match "$dateFilter"
        }
        elseif ($timeFilter -ne "") {
            $_ -match "$timeFilter"
        }
        else {
            $true
        }
    }

    # Creating a summary of logs
    $logSummary = @()
    foreach ($log in $logEntries) {
        $date = ($log -split " ")[0] # Extracting the date
        $time = ($log -split " ")[1] # Extracting the time
        $description = ($log -split " - ")[1] # Extracting the description of the log entry

        $logSummary += [PSCustomObject]@{
            Date        = $date
            Time        = $time
            Description = $description
        }
    }

    return $logSummary
}

# Generate CSV report
$dateFilter = "" # Provide your date filter here
$timeFilter = "" # Provide your time filter here

$analysisResult = AnalyzeLogs -logFilePath $logFilePath -dateFilter $dateFilter -timeFilter $timeFilter

$analysisResult | Export-Csv -Path $reportPath -NoTypeInformation

Write-Host "Log analysis is completed. Report is generated at: $reportPath"
