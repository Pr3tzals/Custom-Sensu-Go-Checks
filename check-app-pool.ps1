# TITLE:
#   check-app-pool.ps1
#
# DESCRIPTION:
#   This plugin collects the name, state/status of the Apppool in IIS, with functionality for missing/or mispelled apppools
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
#   Powershell.exe -NonInteractive -NoProfile -ExecutionPolicy Bypass -NoLogo -File check-app-pool.ps1 -AppPool 'DefaultAppPool'
#
# NOTES:
#
# LICENSE:
#   Copyright 2020 sensu-plugins
#   Released under the same terms as Sensu (the MIT license); see LICENSE for details.
#

#Requires -Version 3.0

# AppPool Check PS1 optimized by Fabio
# Parsing of Sensu Variable to powershell
[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
  [string]$AppPool
)
# Sets Sensu Status Results
[int]$intResult = 0 
# Get list of Application Pools that are stopped.
# This one only grabs name and State/Status
$ApplicationPool= Get-IISAppPool | Select-Object Name,State | Where {$_.Name -like "$AppPool"} 
#Check for NULL first
$NullCheck= $ApplicationPool -eq "" -or $ApplicationPool -eq $null
#Get CheckResult
IF ($NullCheck -eq "True"){
			$CheckResult = 1	
			}
# If no Null Value was returned Continue with script
ELSEIF ($ApplicationPool.state -eq 'Stopped') {
# Set the error level to 2 (critical) 
            		$CheckResult = 2 
			}
ELSEIF ($ApplicationPool.state -eq 'Started') {
			$CheckResult = 0
            		} 
ELSE { 
			write-host "Something has exploded"
			exit 2
            		} 
# Handling of errors base of value of check result
Switch ($CheckResult) { 
    # Default/no errors 
    default { 
	write-host "Application Pool Status:"
        write-host $ApplicationPool.name is $ApplicationPool.state
        exit 0 
    } 
    # Warning error(s) only 
    1 { 
	write-host "Application Pool Status:"
        write-host "Application Pool Not Found: $AppPool"
        exit 1 
    } 
    # Critical error(s) only 
    2 {  
	write-host "Application Pool Status:"
        write-host $ApplicationPool.name is $ApplicationPool.state
        exit 2 
    }  
    # Critical and Warning errors 
    3 { 
        write-host $strResultError 
        write-host $strResultWarning 
        exit 2 
    }  
}
