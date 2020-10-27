# TITLE:
#   check-windows-updates.ps1
#
# DESCRIPTION:
#   This plugin collects currently missing updates and catalougues wether they are security, rollup updates or general updates.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Windows
#
# DEPENDENCIES:
#   Powershell 3.0 or above
#
# USAGE:
#   Powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -NoLogo -File check-windows-updates.ps1
#
# NOTES:
#
# LICENSE:
#   Copyright 2020 sensu-plugins
#   Released under the same terms as Sensu (the MIT license); see LICENSE for details.
#
# Windows Updates Checks optimized by Fabio

[int]$intResult = 0 
#Grabs all updates waiting
$data = {@()}.Invoke(); $upS = New-Object -ComObject Microsoft.Update.Session; $srch = $upS.CreateupdateSearcher();
               $up = @($srch.Search('IsHidden=0 and IsInstalled=0').Updates); $up  | Select Title, Categories, KBArticleIDs, RebootRequired |
                ForEach-Object { $obj = [PSCustomObject]@{}; $obj | Add-Member -MemberType NoteProperty -Name Title -Value $_.Title;
               $obj | Add-Member -MemberType NoteProperty -Name RebootRequired -Value $_.RebootRequired;  $obj_cats = {@()}.Invoke(); $_.Categories |
                ForEach-Object { $obj_cats.Add($_.Name) }; $obj | Add-Member -MemberType NoteProperty -Name Categories -Value $obj_cats;
               $obj | Add-Member -MemberType NoteProperty -Name KBArticleID -Value $_.KBArticleIDs; $data.Add($obj)}; 

#TotalUpdates
$Total = $data.count
#CalculatesSecurityUpdates			   
$SecurityUpdates = $data | where{ $_.Categories -like "*security*"}
#CalculatesRollups			   
$RollupsUpdates = $data | where{ $_.Categories -like "*rollup*"}
#CalculatesUpdates			   
$Updates = $data | where{ $_.Categories -notlike "*security*" -and $_.Categories -notlike "*rollup*"}
#TotalUpdates Minus the other updates
$TotalTrimmed = $Total - $SecurityUpdates.count - $RollupsUpdates.count

#Security Updates are all either 1 or less
IF (($SecurityUpdates.count -le '1') -and ($RollupsUpdates.count -le '1') -and ($TotalTrimmed -le '1')) {
			$CheckResult = 0	
			}
#If any updates hit the critical threshold
ELSEIF (($SecurityUpdates.count -ge '2') -or ($RollupsUpdates.count -ge '2') -or ($TotalTrimmed -ge '4')) {
# Set the error level to 2 (critical) 
			$CheckResult = 2
            		} 
#If any updates hit the warning threshold
ELSEIF (($SecurityUpdates.count -ge '1') -or ($RollupsUpdates.count -ge '1') -or ($TotalTrimmed -ge '1')) {
# Set the error level to 1 (warning) 
            $CheckResult = 1 
			}
ELSE { 
			write-host "Something has exploded"
			exit 3
            		} 

<# write-host $CheckResult
pause #>

Switch ($CheckResult) { 
    # Default/no errors 
    default { 
		write-host CheckWindowsUpdate OK: There are: $SecurityUpdates.count Critical Updates $RollupsUpdates.count Update Rollups $TotalTrimmed Updates
        exit 0 
    } 
    # Warning error(s) only 
    1 { 
		write-host CheckWindowsUpdate WARNING: There are: $SecurityUpdates.count Critical Updates $RollupsUpdates.count Update Rollups $TotalTrimmed Updates
        exit 1 
    } 
    # Critical error(s) only 
    2 { 
        #write-host $strResultError 
		write-host CheckWindowsUpdate CRITICAL: There are: $SecurityUpdates.count Critical Updates $RollupsUpdates.count Update Rollups $TotalTrimmed Updates
        exit 2 
    }  
    # Error Handling Unknown 
    3 { 
		write-host CheckWindowsUpdate UNKNOWN: Unable to retrieve results
        exit 3 
    }  
}
