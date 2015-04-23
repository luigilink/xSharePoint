function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$InstallAccount
	)

	Write-Verbose "Getting usage application '$Name'"

	$session = Get-xSharePointAuthenticatedPSSession $InstallAccount

	$result = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
		$serviceApp = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue |
						Where-Object { $_.TypeName -eq "Usage and Health Data Collection Service Application" }
		If ($serviceApp -eq $null)
        {
            return @{}
        }
		else
		{
			return @{
				Name = $serviceApp.DisplayName
			}
		}
    }
    $result
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$InstallAccount,

		[System.String]
		$DatabaseName,

		[System.String]
		$DatabasePassword,

		[System.String]
		$DatabaseServer,

		[System.String]
		$DatabaseUsername,

		[System.String]
		$FailoverDatabaseServer,

        [System.UInt32]
        $UsageLogCutTime,

        [System.String]
        $UsageLogLocation,

        [System.UInt32]
        $UsageLogMaxFileSizeKB,

        [System.UInt32]
        $UsageLogMaxSpaceGB
	)

	Write-Verbose "Setting usage application $Name"
	Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
		$app = Get-SPServiceApplication -Name $params.Name -ErrorAction SilentlyContinue

        if ($app -eq $null) { 
            $newParams = @{}
            $newParams.Add("Name", $params.Name)
            if ($params.ContainsKey("DatabaseName")) { $newParams.Add("DatabaseName", $params.DatabaseName) }
            if ($params.ContainsKey("DatabasePassword")) { $newParams.Add("DatabasePassword", $params.DatabasePassword) }
            if ($params.ContainsKey("DatabaseServer")) { $newParams.Add("DatabaseServer", $params.DatabaseServer) }
            if ($params.ContainsKey("DatabaseUsername")) { $newParams.Add("DatabaseUsername", $params.DatabaseUsername) }
            if ($params.ContainsKey("FailoverDatabaseServer")) { $newParams.Add("FailoverDatabaseServer", $params.FailoverDatabaseServer) }

            New-SPUsageApplication @newParams
        }
	}

	Write-Verbose "Configuring usage application $Name"
	Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
        $params = $args[0]
		$setParams = @{}
        $setParams.Add("LoggingEnabled", $true)
        if ($params.ContainsKey("UsageLogCutTime")) { $setParams.Add("UsageLogCutTime", $params.UsageLogCutTime) }
        if ($params.ContainsKey("UsageLogLocation")) { $setParams.Add("UsageLogLocation", $params.UsageLogLocation) }
        if ($params.ContainsKey("UsageLogMaxFileSizeKB")) { $setParams.Add("UsageLogMaxFileSizeKB", $params.UsageLogMaxFileSizeKB) }
        if ($params.ContainsKey("UsageLogMaxSpaceGB")) { $setParams.Add("UsageLogMaxSpaceGB", $params.UsageLogMaxSpaceGB) }
        Set-SPUsageService @setParams
	}
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$InstallAccount,

		[System.String]
		$DatabaseName,

		[System.String]
		$DatabasePassword,

		[System.String]
		$DatabaseServer,

		[System.String]
		$DatabaseUsername,

		[System.String]
		$FailoverDatabaseServer,

        [System.UInt32]
        $UsageLogCutTime,

        [System.String]
        $UsageLogLocation,

        [System.UInt32]
        $UsageLogMaxFileSizeKB,

        [System.UInt32]
        $UsageLogMaxSpaceGB
	)

	$result = Get-TargetResource -Name $Name -InstallAccount $InstallAccount
	Write-Verbose "Testing for usage application '$Name'"
	if ($result.Count -eq 0) { return $false }
	else {
		$returnVal = Invoke-Command -Session $session -ArgumentList $PSBoundParameters -ScriptBlock {
			$params = $args[0]

			$service = Get-SPUsageService
            if ($params.ContainsKey("UsageLogCutTime") -and $service.UsageLogCutTime -ne $params.UsageLogCutTime) { return $false }
            if ($params.ContainsKey("UsageLogLocation") -and $service.UsageLogDir -ne $params.UsageLogLocation) { return $false }
            if ($params.ContainsKey("UsageLogMaxFileSizeKB") -and $service.UsageLogMaxFileSize -ne $params.UsageLogMaxFileSizeKB) { return $false }
            if ($params.ContainsKey("UsageLogMaxSpaceGB") -and $service.UsageLogMaxSpaceGB -ne $params.UsageLogMaxSpaceGB) { return $false }
			return $true
		}
		return $returnVal
	}
}


Export-ModuleMember -Function *-TargetResource

