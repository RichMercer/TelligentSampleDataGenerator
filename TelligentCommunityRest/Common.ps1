Set-StrictMode -Version 2

function New-CommunityCredential 
{
    <#
    .Synopsis
        Creates a new Community Credential
    .Description
        The New-CommunityCredential cmdlet creates a new Credential to use when connecting to a Telligent Evolution community via REST.  This credential contains the core infomration needed for all REST requests and needs to be passed to all REST calls.

        When connecting to a site behind Windows or Basic authentication, the HttpCredentials Parameter should be provided to provide these credentials.

        Before creating the Credentials, a test connection will be made to the community to validate the credentials.  If this connection fails, then an error will occur.  This check can be bypassed by specifying the -Force flag.
    .Parameter CommunityRoot
        The root url for your Telligent Evolution community
    .Parameter UserName
        The username of the user to connect to the community as
    .Parameter ApiKey
        The Api Key of the user connecting to the community
    .Parameter HttpCredentials
        Specifies the HTTP Credentials to use when connecting to a community behind Windows or Basic authentication.
    .Parameter Force
        If specified, the credentials will be created without being validated
    .Example
        New-CommunityCredential http://mycommunity.com/ admin abc123

        Create a basic Community Credential
    .Example
        New-CommunityCredential http://mycommunity.com/ admin abc123 (Get-Credential)

        Create an Community Credential for a community secured by Windows authentication. You will be prompted for your password at the PowerShell prompt by the Get-Credential command
    #>   
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
		[alias("Url")]
		[alias("Root")]
        [Uri] $CommunityRoot,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $UserName,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
 		[string] $ApiKey,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [PSCredential] $HttpCredentials,
        [switch] $Force
    )

    $creds = New-Object CommunityCredential @($CommunityRoot, $UserName, $ApiKey, $HttpCredentials)

    if ($Force -or (Test-CommunityCredential $creds)) {
        Write-Output $creds
    }
}

function Test-CommunityCredential {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [CommunityCredential] $Credential
    )

    $initialErrorCount = $Error.Count

    Write-Progress 'Validating Credentials' 'Connecting to Info endpoint'
    $result = Invoke-CommunityRestRequest api.ashx/v2/info.json GET $Credential
    Write-Progress 'Validating Credentials' 'Connecting to Info endpoint' -Completed    

    return $result -and $Error.Count -eq $initialErrorCount
}


function Expand-ItemWithSingleProperty
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipeline=$true)]
        $Item
    )
    if ($Item){
        $properties = $Item | Get-Member -MemberType NoteProperty
        if (!($properties -is [array]))
        {
            $propertyName = $properties.Name
            if ($propertyName -eq '*') {
                #If Select-Object excludes all properties, it returns an object with an empty * Parameter
                # We want to treat this as no output so do nothing
            }
            else {
                Write-Verbose "Expanding Property: $propertyName"
                $Item = $Item | select -ExpandProperty $propertyName
                $Item.psobject.TypeNames.Insert(0, $propertyName)
            }
        }
        $Item
    }
}


function ConvertTo-MimeMultiPartBody
{
    param(
		[Parameter(Mandatory=$true)]
        [string]$Boundary,
		[Parameter(Mandatory=$true)]
        [hashtable]$Data,
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
    )

    $body = "";

    $Data.GetEnumerator() |% {
        $name = $_.Key
        $value = $_.Value

        $body += "--$Boundary`r`n"
        $body += "Content-Disposition: form-data; name=`"$name`""
        if ($value -is [byte[]]) {
            $fileName = $Data['FileName']
            if(!$fileName) {
                $fileName = $name
            }
            $body += "; filename=`"$fileName`"`r`n"
            $body += "Content-Type: application/octet-stream"
            #ISO-8859-1 is only encoding where byte value == code point value
            $value = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString($value)
        }
        $body += "`r`n`r`n"
        $body += $value
        $body += "`r`n"
    }
    $body += "--$boundary--"
    $body
}

function Write-RestErrors
{
    param(
        $response
    )
    if ($response) {
        $response.Errors |% { Write-Error -Message $_ }
        $response.Warnings |% { Write-Warning -Message $_ }
        try{
            $response.Info |% { Write-Host $_ -ErrorAction SilentlyContinue }
        }
        catch {}
    }
}


function Invoke-CommunityRestRequest 
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
 		[ValidateSet('GET','POST', 'PUT', 'DELETE')]
        [string]$Method,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential,
        [parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [AllowEmptyCollection()]
        [hashtable]$Parameter,
		[string]$Impersonate
    )
    process {



        $endpointUri = $Credential.Root.AbsoluteUri.TrimEnd('/') + '/' + $Endpoint.TrimStart('/')

        $headers = @{
            'Rest-User-Token' = [Convert]::ToBase64String([System.Text.Encoding]::Utf8.GetBytes("$($Credential.ApiKey):$($Credential.Username)"))
        }

        if ($method -eq 'PUT' -or $method -eq 'DELETE'){
            $headers['Rest-Method'] = $Method
        }

		if ($Impersonate) {
            $headers['Rest-Impersonate-User'] = $Impersonate
		}


		$splat = @{}
		if($Parameter) {
			$body = @{}
            $containsFileData = $false;
			$Parameter.GetEnumerator() |% {
                if($_.Value -is [byte[]]) {
                    $containsFileData = $true;
					$body[$_.Key] = $_.Value                    
                }
				elseif ($_.Value -is [Array]) {
					$body[$_.Key] = $_.Value -Join ','
				}
				elseif($_.Value -is [Hashtable]) {
                    $name = $_.Key
                    $_.Value.GetEnumerator() |% {
						$key = $_.key
    					$body["_${name}_${key}"] = $_.Value
                    }
				}
				else {
					$body[$_.Key] = $_.Value
				}
			}
            if ($containsFileData) {
                $boundary =  [Guid]::NewGuid().ToString('N')
                $splat.ContentType = "multipart/form-data; boundary=$boundary"                
                $body = ConvertTo-MimeMultiPartBody -Boundary $boundary -Data $body
            }
    		$paramJson = $Parameter | ConvertTo-Json -Compress
		}
		else {
			$body = $null
            $paramJson = "{}"
		}


		#Don't actually submit as json, but use for -WhatIf and -Verbose messages

        if ($method -ne 'GET' -and -not $PSCmdlet.ShouldProcess($endpointUri, "${method}: $paramJson")) {
            return 
        }	

        Write-Verbose "$method $Endpoint $paramJson (User: '$($Credential.Username)'$(if($Impersonate){ "Impersonate: '$Impersonate'"}))"
        $response = $null
        try {
			if ($Credential.HttpCredential) {
				$splat.Credential = $Credential.HttpCredential
			}

			# Hide progress from Invoke-Web Request
			$progressPreference = 'silentlyContinue'
            $response = Invoke-RestMethod -Uri $endpointUri `
                -Headers $headers `
                -Body $body `
                -MaximumRedirection 0 `
                -Method $(if ($Method -eq 'GET') { 'GET' } else { 'POST'}) `
                -UserAgent 'Zimbra Community Powershell REST Client' `
				@splat
        }
        catch [System.Net.WebException] {
            try {
                #Due to .net stupidity, any non 200 status codes throw an exception
                $httpResponse = [System.Net.HttpWebResponse]$_.Exception.Response
                if (!$httpResponse) {
                    Write-Error $_
                }
                else {
                    $responseStream = $httpResponse.GetResponseStream()
                    $responseStream.Seek(0, 'Begin') | Out-Null
                    $reader = new-object System.IO.StreamReader $responseStream
                    $content = $reader.ReadToEnd()

                    #If response is JSON, try to get errors from Errors element
                    try {
                        $response = $content | ConvertFrom-Json
                    }
                    catch  {}
                    if (!($response -and $response.Errors)) { Write-Error $_ } 
                }
            }
            finally {
                if($reader) { $reader.Dispose() }
                if ($responseStream) { $responseStream.Dispose() }
                if ($httpResponse) { $httpResponse.Dispose() }
            }

        }
        if ($response) {
            Write-RestErrors $response

			if (!$response.Errors)
			{
				# Make response objects easier to deal with by excluding Errors, Warnings and Info
				# 99% of the time, these won't be needed programatically.
				# If they are, the ErrorVariable & WarningVariable common parameters can be used
				$response |
					select * -ExcludeProperty Errors, Warnings, Info |
					Expand-ItemWithSingleProperty
			}
        }
    }
}

function Invoke-CommunityRestPagedRequest
{
    [CmdletBinding(SupportsPaging=$true, SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Endpoint,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
 		[ValidateSet('GET','POST', 'PUT', 'DELETE')]
        [string]$Method,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential,
        [parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [AllowEmptyCollection()]
        [hashtable]$Parameter,
		[string]$Impersonate
    )

    $firstItem = $PSCmdlet.PagingParameters.Skip
    $lastItem = $firstItem + $PSCmdlet.PagingParameters.First

    $pageSize = [Math]::Min($PSCmdlet.PagingParameters.First, 100)
    $firstPage = [Math]::Floor($firstItem / $pageSize)
    $lastPage = [Math]::Ceiling($lastItem / $pageSize) - 1
    $skipStart = $firstItem - ($firstPage * $pageSize)

    Write-Verbose "Retrieving Items $firstItem - $lastItem"

    if (!$Parameter) {
        $Parameter= @{}
    }
    $Parameter["PageSize"] = $pageSize

    $totalCount = 0
    for($i = $firstPage; $i -le $lastPage; $i++)
    {
        Write-Verbose "Retrieving Page $i (PageSize $pageSize)"
        $Parameter["PageIndex"] = $i
        $response = Invoke-CommunityRestRequest -Endpoint $Endpoint -Method $Method -Credential $Credential -Parameter $Parameter -Impersonate $Impersonate   

		if($response) {
			if ($response.PageSize -ne $PageSize) {
				Write-Warning "Wrong Page Size used (Actual: $($response.PageSize), Expected: $PageSize)"
			}
			if ($response.PageIndex -ne $i) {
				Write-Warning "Wrong Page Index used (Actual: $($response.PageIndex), Expected: $i)"
			}
		}

        #TODO: Need to trim out start & end of boundary
        #TODO: Ensure when doing this, the PSObject type does not rever to PSCustomObject

        $response |
            select * -ExcludeProperty PageSize, PageIndex, TotalCount |
            Expand-ItemWithSingleProperty


        #Break early if there are no more pages of data
        $totalCount = $response.TotalCount
        if ($totalCount -lt ($i + 1) * $pageSize) {
            break;
        }
    }

    if ($PSCmdlet.PagingParameters.IncludeTotalCount) {
        $PSCmdlet.PagingParameters.NewTotalCount($totalCount, 1)
    }
}


New-Alias -Name ncc -Value 'New-CommunityCredential'
Export-ModuleMember -Function New-CommunityCredential, Test-CommunityCredential, Invoke-CommunityRestRequest, Invoke-CommunityRestPagedRequest
