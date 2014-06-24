Set-StrictMode -Version 2

function New-CommunitySampleGroup {
	[CmdletBinding()]
    param(
        [int]$ParentGroupId = 0,
        [int]$Forum = (Get-Random -Maximum 3),
        [int]$Blog = (Get-Random -Maximum 3),
        [int]$Gallery = (Get-Random -Maximum 3),
        [int]$Wiki = (Get-Random -Maximum 3),
        [int]$SubGroup = 0,
        [ValidateSet('Joinless', 'PublicOpen', 'PublicClosed', 'PrivateUnlisted', 'PrivateListed')]

        #Don't create joinless unless specified as Initialize-CommunitySampleGroup don't work with  this yet
        [string]$GroupType = (@('PublicOpen', 'PublicClosed', 'PrivateUnlisted', 'PrivateListed') | Get-Random),
        [switch]$Data,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $groupSplat = @{}
        if ($ParentGroupId -gt 0) {
            $groupSplat['ParentGroupId'] = $ParentGroupId
        }

        $group = New-CommunityGroup @groupSplat `
            -GroupType $GroupType `
            -Description (Get-RandomTitle) `
            -Name (Get-RandomApplicationName) `
            -EnableGroupMessages $true `
            -AutoCreateApplications $false `
            -Credential $Credential

        if ($group) {
            $group
            $splatArgs = @{
                GroupId = $group.Id
                Credential = $Credential
            }

            for($i = 0; $i -lt $Blog; $i++) {
                New-CommunitySampleBlog @splatArgs | Out-Null
            }

            for($i = 0; $i -lt $Forum; $i++) {
                New-CommunitySampleForum @splatArgs | Out-Null
            }

            for($i = 0; $i -lt $Wiki; $i++) {
                New-CommunitySampleWiki @splatArgs | Out-Null
            }

            for($i = 0; $i -lt $Gallery; $i++) {
                New-CommunitySampleGallery @splatArgs | Out-Null
            }

            if ($Data) {
                Initialize-CommunitySampleGroup @splatArgs | Out-Null
            }

            for($i = 0; $i -lt $SubGroup; $i++) {
                New-CommunitySampleGroup -ParentGroupId $group.Id -Credential $Credential
            }

        }
    }

}

function New-CommunitySampleBlog {
	[CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GroupId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        New-CommunityBlog `
            -GroupId $GroupId `
            -Name "$(Get-RandomApplicationName) Blog" `
            -Description (Get-RandomTitle) `
            -Credential $Credential
    }
}

function New-CommunitySampleForum {
	[CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GroupId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        New-CommunityForum `
            -GroupId $GroupId `
            -Name "$(Get-RandomApplicationName) Forum" `
            -Description (Get-RandomTitle) `
            -Credential $Credential
    }
}

function New-CommunitySampleWiki {
	[CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GroupId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        New-CommunityWiki `
            -GroupId $GroupId `
            -Name "$(Get-RandomApplicationName) Wiki" `
            -Description (Get-RandomTitle) `
            -Credential $Credential
    }
}

function New-CommunitySampleGallery {
	[CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GroupId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        New-CommunityGallery `
            -GroupId $GroupId `
            -Name "$(Get-RandomApplicationName) Gallery" `
            -Description (Get-RandomTitle) `
            -Credential $Credential
    }
}
