<#

 Script Title:     BulkEventLogCleardown.ps1
       
 Author:           Gary Wells  
 
 Creation Date:    28th July 2017

 Version:          1.1

 Revision History:
 31st July 20017   Gary Wells
 Added the START and STOP transcript with write out to log file on target host(s)


    
#>   
    # 
    # This script will clear down selected Event Logs on a selection of target hosts loaded from a CSV file
    # It will also apply the new log file size limit of 1GB and enforce the setting with a gpupdate
    #
$list = Import-Csv c:\scripts\computers.csv
    #
    # Only APPLICATION, SYSTEM & SECURITY Event Logs will be targeted
    # Log Files will be tested against a Maximum size value of ~1000MB
    #
$maxLogFileSize = 50KB
    #
    # Log files exceeding this size will be included for clear down
    # The commands will be executed on the target host and not on the Operator's device
    #
foreach ($entry in $list) {
        $server = $entry.computername
        Invoke-command -ComputerName $server -ScriptBlock {
            $maxLogFileSize = $args[0]
            $server = $args[1]
    #
    # A Log file will be created and stored on the target server(s) with a verbose output of commands performed
    #
            $DateCompact = get-date -Format "yyyMMdd_HHmmss"
            $LogTranscriptPath = "C:\Windows\CWS_Build\Logs\ClearDownLogs_$DateCompact.txt"
            Start-Transcript -Path $LogTranscriptPath -NoClobber
    #
    # Only APPLICATION, SYSTEM & SECURITY Event Logs will be targeted
    # 
            $seclogs = Get-WmiObject -Class win32_nteventlogfile | Where-Object {$_.name -match "Security.evt?" -or $_.name -match "System.evt?" -or $_.name -match "Application.evt?" -and $_.filesize -ge $maxLogFileSize}  
            $seclogs | Out-Host
    #
    # Eligible Event Log files will be cleared down automatically and 
    # the new ICP Log File limit of 1GB will then be applied
    # A gpupdate will then be run to enforce the new Computer policy settings
    # 
            $seclogs | foreach {
                                    Clear-EventLog -log $_.LogFileName -Verbose | Out-Host
                                    Limit-EventLog -OverflowAction OverwriteAsNeeded -MaximumSize 1GB -log $_.LogFileName -Verbose | Out-Host
                                } 
    #
    # A gpupdate will then be run to enforce the new Computer policy settings
    #     
                                    gpupdate /Target:Computer /force | Out-Host
    #
    # A message will then advise the operator that the target server is completed and logging will stop
    #           
            Write-Host -backgroundcolor green -ForegroundColor black $server " is Finished !"
            Stop-Transcript
        } -ArgumentList $maxLogFileSize, $server
       }
   #
   # The above will loop trhrough each server in the CSV until complete
   #