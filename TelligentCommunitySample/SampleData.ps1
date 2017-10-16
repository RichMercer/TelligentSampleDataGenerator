Set-StrictMode -Version 2

function Initialize-CommunitySampleForum {
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GroupId,
        [int]$ThreadCount = (Get-Random -Min 5 -Max 30),
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $forum = New-CommunityForum `
            -GroupId $GroupId `
            -Name "$(Get-RandomAppName) Forum" `
            -Description ($dummyData.Subjects | Get-Random) `
            -Credential $Credential
           
        if($forum) {
            1..$ThreadCount |% {
                Write-Progress 'Sample Data' "Creating Forum Threads" -PercentComplete (($_-1)/$ThreadCount * 100) -CurrentOperation "$_ of $ThreadCount" -id 801
                Initialize-CommunitySampleForumThread `
                    -ForumId $forum.Id `
                    -Username $Username `
                    -Credential $Credential
            }
            Write-Progress 'Sample Data' "Creating Forum Threads" -Completed -Id 801
            $forum
        }
    }
}

function Initialize-CommunitySampleBlog {
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GroupId,
        [int]$PostCount = (Get-Random -Min 5 -Max 30),
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {

        $blog = New-CommunityBlog `
            -GroupId $GroupId `
            -Name "$(Get-RandomAppName) Blog" `
            -Author $Username `
            -Description ($dummyData.Subjects | Get-Random) `
            -Credential $Credential
           

        if($blog) {
            1..$PostCount |% {
                Write-Progress 'Sample Data' "Creating Blog Posts" -PercentComplete (($_-1)/$PostCount * 100) -CurrentOperation "$_ of $PostCount" -id 802
                Initialize-CommunitySampleBlogPost `
                    -BlogId $blog.Id `
                    -Username $username `
                    -Credential $Credential
            }
            Write-Progress 'Sample Data' "Creating Blog Posts" -Completed -Id 802
            $blog
        }
    }
}

function Initialize-CommunitySampleWiki {
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GroupId,
        [int]$Pages = (Get-Random -Min 5 -Max 10),
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $wiki = New-CommunityWiki `
            -GroupId $GroupId `
            -Name "$(Get-RandomAppName) Wiki" `
            -Description ($dummyData.Subjects | Get-Random) `
            -Credential $Credential

        if($wiki) {
            1..$Pages |% {
                Write-Progress 'Sample Data' "Creating Wiki Pages" -PercentComplete (($_-1)/$Pages * 100) -CurrentOperation "$_ of $Pages" -id 803
                Initialize-CommunitySampleWikiPage `
                    -WikiId $wiki.Id `
                    -Username $Username `
                    -ChildPages (Get-Random -max 6) `
                    -Credential $Credential
            }
            Write-Progress 'Sample Data' "Creating Wiki Pages" -Completed -Id 803
            $wiki
        }
    }
}



