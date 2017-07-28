﻿<#
 Script Title:     DSCLogFileCleardown.ps1
       
 Author:           Gary Wells  
 
 Creation Date:    25th July 2017

 Revision History:
   
   
#>   
    # 
    # This script will locate all .MOF and .JSON files relating to DSC and remove all but the last 7 days
    # This value can be changed by modifying the $RetentionTimeInDays parameter below
    #
$RetentionTimeInDays = 449
    #
    # The operator will be asked to input the name of the remote host to clear down
    #
$Computername = read-host -prompt 'Please enter the Hostname of the server that you wish to clear down'
    #
    # The script will search the path C:\Windows\System32\Configuration\ConfigurationStatus\ on the selected host for all files
    # Logic will then determine how many files are older than the specified Retention Time above
    #
[array]$files = invoke-command -ComputerName $Computername -ScriptBlock `
{
    $RetentionTimeInDays = $args[0]
    Get-ChildItem 'C:\windows\System32\Configuration\ConfigurationStatus' | Where {$_.Creationtime -lt (get-date).AddDays(-$RetentionTimeInDays)} 
} -ArgumentList $RetentionTimeInDays
    #
    # The number of files that can de deleted will be returned
    #
$filecount = $files.Count
    # 
    # If there are files to delete, a message is displayed with the number of eligible files that can be deleted
    #
if ($filecount -ge 1) {
        #
        # The operator must then confirm he or she wishes to proceed and cleanse the folder
        # Only YES will result in the deletions being processed. Any other key / phrase will exit the script. 
        # This value is NOT case-sensitive as all input values will be forced to Upper Case
        #   
    $response = read-host -Prompt "$ComputerName contains $filecount file(s) older than $RetentionTimeInDays days. Would you like to delete them? (Type YES to confirm)"
    if(($response.ToUpper()) -ne "YES"){EXIT}
        #
        # The script will then clear all of the eligible files and return a confirmation
        #     
    $filedelete = invoke-command -ComputerName $Computername -ScriptBlock `
    {
        $RetentionTimeInDays = $args[0]
        Get-ChildItem 'C:\windows\System32\Configuration\ConfigurationStatus' | Where {$_.Creationtime -lt (get-date).AddDays(-$RetentionTimeInDays)} | Remove-Item -Force
    } -ArgumentList $RetentionTimeInDays

    Write-Host "Deleted $filecount files from $Computername"
}
else {
    #
    # If there are NO eligible files to delete, a message is displayed stating there are zero files to delete and the script will exit
    #
    Write-Host "There are zero files to delete from $Computername"
}
# (get-date).AddDays(-450)