# VBRestoreInfo
Veeam PowerShell Script to pull info on restore jobs from Veeam Backup & Replication (VBR) Server.

## Instructions:
~~~
cd /path/to/script/
. .\Get-VBRestoreInfo.ps1
Get-VBRestoreInfo -VBRServer localhost -ReportPath C:\Temp\
~~~

### Example Output:
| VM Name  | Creation Time | End Time | Runtime | Size (GB) | Full/Incremental | Job Type | Result | Job Name | Restore Reason |
| -------- | ------------- | -------- | ------- | --------- | ---------------- | -------- | ------ | -------- | -------------- |
| WinServer 2019-1  | 6/19/2021 13:44 | 6/19/2021 13:48 | 04:26.9 |	15.15	| Full | Full VM Restore | Success | Windows VMs | |
| WinServer 2019-2  | 6/18/2021 21:59 | 6/18/2021 21:59 | 00:49.8 |	15.15 | Increment | Full VM Restore | Success | Windows VMs | |
