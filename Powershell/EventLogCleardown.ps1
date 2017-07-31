﻿
<#

 Script Title:     EventLogCleardown.ps1
       
 Author:           Gary Wells  
 
 Creation Date:    25th July 2017

 Version:          2

 Revision History:
 27th July 20017   Gary Wells
 Added the command to limit event log max size after the clear down command for each log file to prevent log expanding before the new MOF can be processed

 28th July 20017   Gary Wells
 Added gpupdate /Target:Computer /force to enforce the policy settings immediately - by default there could be a 90 minute refresh window where the values could
 be manually changed in the GUI


   
#>
    # 
    # This script will clear down selected Event Logs on a target host
    # Only APPLICATION, SYSTEM & SECURITY Event Logs can be targeted
    # Log Files will be tested against a Maximum size value of ~1000MB
    # Log files exceeding this size can be cleared down
    #
$MaxLogFileSizeInBytes = 1MB
    #
    # The operator will be asked to input the name of the remote host to clear down
    #
$Computername = read-host -prompt 'Please enter the Hostname of the server that you wish to clear down'
    #
    # The script will search the remote host for the 3 applicable Event Logs
    #
$LogDetails = invoke-command -ComputerName $Computername -ScriptBlock `
{
    Get-WmiObject -Class win32_nteventlogfile | Where-Object {$_.name -match "Security.evt?" -or $_.name -match "System.evt?" -or $_.name -match "Application.evt?"} 
}
    #
    # The Event Log details will be displayed to the operator
    #
Write-Host "The Event Log details for $Computername are" 
$LogDetails | select Filesize,logfilename,name,numberofrecords | ft | Out-String | %{Write-Host $_}
    #
$SecurityLogDetails = $LogDetails | where{$_.LogFileName -eq "Security"}
$SystemLogDetails = $LogDetails | where{$_.LogFileName -eq "System"}
$ApplicationLogDetails = $LogDetails | where{$_.LogFileName -eq "Application"}
    #
    # Logic will then determine if any of the logs need to to be cleared down (Those of 1GB or more)
    # Eligible files will be presented to the operator with an option to clear them down
    #
    # This process will be performed individually on each of the 3 target log files
    #
    ################
    # Security Log #
    ################
    #
if ($SecurityLogDetails.FileSize -ge $MaxLogFileSizeInBytes)
        {
        Write-Host "The $Computername Security Log File can be cleared down"
        $response = Read-Host -Prompt "Would you like to clear down this Log File? (Type YES to confirm)"
            if(($response.ToUpper()) -eq "YES"){
                Clear-EventLog -ComputerName $Computername -LogName Security -Verbose 
                Limit-EventLog -LogName Security -ComputerName $Computername -OverflowAction OverwriteAsNeeded -MaximumSize 1GB 
                Invoke-Command -ComputerName $Computername {gpupdate /Target:Computer /force}  
        }
    }
else
    {
         Write-Host "The Security Log file is currently below the Maximum Size allowed. No action is required at this time"
    }
    #
    ##############
    # System Log #
    ############## 
    #
if ($SystemLogDetails.FileSize -ge $MaxLogFileSizeInBytes)
        {
        Write-Host "The $Computername System Log File can be cleared down"
        $response = Read-Host -Prompt "Would you like to clear down this Log File? (Type YES to confirm)"
        if(($response.ToUpper()) -eq "YES"){
                Clear-EventLog -ComputerName $Computername -LogName System -Verbose
                Limit-EventLog -LogName System -ComputerName $Computername -OverflowAction OverwriteAsNeeded -MaximumSize 1GB
                Invoke-Command -ComputerName $Computername {gpupdate /Target:Computer /force}
        }
    }
else
    {
        Write-Host "The System Log file is currently below the Maximum Size allowed. No action is required at this time"
    }
    #
    ###################
    # Application Log #
    ###################
    #
if ($ApplicationLogDetails.FileSize -ge $MaxLogFileSizeInBytes)
        {
        Write-Host "The $Computername Application Log File can be cleared down"
        $response = Read-Host -Prompt "Would you like to clear down this Log File? (Type YES to confirm)"
        if(($response.ToUpper()) -eq "YES"){
               Clear-EventLog -ComputerName $Computername -LogName Application -Verbose
               Limit-EventLog -LogName Application -ComputerName $Computername -OverflowAction OverwriteAsNeeded -MaximumSize 1GB
               Invoke-Command -ComputerName $Computername {gpupdate /Target:Computer /force}
        }
    }
else
    {
        Write-Host "The Application Log file is currently below the Maximum Size allowed. No action is required at this time"
    }
