#Requires -Version 4
#Requires -RunAsAdministrator

<#
.Overview
  This script will pull data from a Veeam Backup & Replication (VBR) Server and output
  a CSV file with filtered results.

.Notes
    Version: 0.1
    Author: Wes MacKay
    Modified Date: 6-21-2021

.EXAMPLE
    Get-VBRestoreInfo -VBRServer localhost -ReportPath C:\Temp\

.Future Changes
  - find a report that contains the filesize that was transferred during a restore job
  - add a check if a jobs running, if yes, don't output runtime variable
  - optimize the cross-reference check (could take forever with many backup files)
  - remove decimal number from runtime result

.Issues to Resolve
  - the Size variable shows the restore point filesize, not how much data was transferred for the restore process
  - if a backup retention point is deleted after a restore is performed, the next report will show 0GB size for that restore session
#>

function Get-VBRestoreInfo {
  param(
    # VBRServer
    [Parameter(Mandatory)]
    [string]$VBRServer,
    [Parameter(Mandatory)]
    [string]$ReportPath
  )

  begin {

    #Load the Veeam PSSnapin
    if (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
      Add-PSSnapin -Name VeeamPSSnapIn
      Connect-VBRServer -Server $VBRServer
    }

    else {
      Disconnect-VBRServer
      Connect-VBRServer -Server $VBRServer
    }

    if (!(Test-Path $ReportPath)) {
      New-Item -Path $ReportPath -ItemType Directory | Out-Null
    }

    Push-Location -Path $ReportPath
    Write-Verbose ("Changing directory to '$ReportPath'")

  }

  process {
    $RestorePoints = Get-VBRRestorePoint          # this report contains the backup job file sizes
    $RestoreSessions = Get-VBRRestoreSession      # this report contains majority of restore job info
    
    [System.Collections.ArrayList]$AllRestoreIds = @()

    # we will store the backup job file sizes and type temporarily so we can output them in the report later
    foreach ($Restore in $RestorePoints) {
      $RestoreOutput = @{
        id = $Restore.Uid
        size = $Restore.ApproxSize
        type = $Restore.Type
      }
      $null = $AllRestoreIds.Add($RestoreOutput)
      Remove-Variable RestoreOutput
    }

    [System.Collections.ArrayList]$AllRestoreSessions = @()

    # we will go through each restore session in Veeams DB and output the details in a report
    foreach ($Restore in $RestoreSessions) {
      $size, $type = ""
      # we have to match the job ID with another report to cross reference the backup job size
      $AllRestoreIds.GetEnumerator() | ForEach-Object {
        if ($($_.id) -eq $($Restore.OibUid)) {        # check if the current id matches the job ID we want
          $size = $($_.size / 1GB)                    # store the job size and convert KB to GB
          $type = $($_.type)                          # store the type of backup (full/incremental)
        }
      }
      # format our report
      $RestoreOutput = [pscustomobject][ordered] @{
        'VM Name'   = $Restore.Name
        'Creation Time' = $Restore.CreationTimeUTC
        'End Time' = $Restore.EndTimeUTC
        'Runtime' = $Restore.EndTimeUTC - $Restore.CreationTimeUTC
        'Size (GB)' = [math]::round($size,2)
        'Full/Incremental' = $type
        'Job Type' = $Restore.JobTypeString
        'Result' = $Restore.Result
        'Job Name' = $Restore.Options | Select-Xml -XPath '//BackupName'
        'Restore Reason' = $Restore.Description
        'ID' = $Restore.OibUid
      }
      $null = $AllRestoreSessions.Add($RestoreOutput)
      Remove-Variable RestoreOutput
    }
  }

  end {
    $AllRestoreSessions | Export-Csv -Path $("$ReportPath\$VBRServer" + '_ShowRestores.csv') -NoTypeInformation
    Disconnect-VBRServer
    Pop-Location
  }
}
