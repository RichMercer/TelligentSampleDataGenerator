Set-StrictMode -Version 2

function Initialize-CommunitySampleGroupMember {
    <#
        .SYNOPSIS
            Adds sample members to a set of group
        .PARAMETER ForumId
            The groups to create members in
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            TODO
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int[]]$GroupId,
        [string]$MemberType,
        [int]$Minimum =7,
        [int]$Maximum = 20,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )

    foreach($i in 1..(Get-Random -Minimum $Minimum -Maximum $Maximum)) {
        $user = Initialize-CommunitySampleUser -Credential $Credential
        if($user) {
            $user
            $GroupId |% {
                $member = New-CommunityGroupuser `
                    -GroupId $_ `
                    -User $user.Id `
                    -GroupMembershipType $MemberType `
                    -Credential $Credential
                }
            }
    }    
}

function Initialize-CommunitySampleUser {
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $name = Get-RandomName
        $username = $name.Replace(' ', '').Replace("'", '')

        $result = New-CommunityUser `
            -Username $username `
            -Password password `
            -PrivateEmail "$username@tempuri.org" `
            -DisplayName $name `
            -ReceiveEmails $false `
            -Credential $Credential

        if($result -and $result.User) {
            if ((Get-Random -Maximum 6) -ge 1) {
                $avatarPath = $dummyData.Avatars | Get-Random
                Set-CommunityUserAvatar `
                    -UserId $result.User.Id `
                    -FileData (Get-Content $avatarPath -Encoding Byte -ReadCount 0) `
                    -Credential $Credential | Out-Null
            }

            $result.User
        }

    }
}

function Initialize-CommunitySampleForum {
    <#
        .SYNOPSIS
            Populates a forum with sample content
        .PARAMETER ForumId
            The forum to generate content in.
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityForum -Group 1 -Credential $cred | Initialize-CommunitySampleBlog -Credential $cred
            
            Populates all forums in Group 1 with sample content.
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$ForumId,
        [int]$ThreadCount = (Get-Random -Min 5 -Max 30),
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        1..$ThreadCount |% {
            Write-Progress 'Sample Data' 'Populating Forum' -PercentComplete (($_-1)/$ThreadCount * 100) -CurrentOperation "$_ of $ThreadCount" -id 801
            Initialize-CommunitySampleForumThread `
                -ForumId $ForumId `
                -Username $Username `
                -Credential $Credential
        }
        Write-Progress 'Sample Data' 'Populating Forum' -Completed -Id 801
        $forum

    }
}

function Initialize-CommunitySampleBlog {
    <#
        .SYNOPSIS
            Populates a blog with sample content
        .PARAMETER BlogId
            The blog to generate content in.
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityBlog -Group 1 -Credential $cred | Initialize-CommunitySampleBlog -Credential $cred
            
            Populates all blogs in Group 1 with sample content.
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$BlogId,
        [int]$PostCount = (Get-Random -Min 5 -Max 30),
        [string[]]$Creator,
        [string[]]$Contributor,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        1..$PostCount |% {
            Write-Progress 'Sample Data' 'Populating Blog' -PercentComplete (($_-1)/$PostCount * 100) -CurrentOperation "$_ of $PostCount" -id 802
            Initialize-CommunitySampleBlogPost `
                -BlogId $BlogId `
                -Creator $Creator `
                -Contributor $Contributor `
                -Credential $Credential
        }
        Write-Progress 'Sample Data' 'Populating Blog' -Completed -Id 802
    }
}

function Initialize-CommunitySampleGallery {
    <#
        .SYNOPSIS
            Populates a gallery with sample content
        .PARAMETER GalleryId
            The gallery to generate content in.
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            TODO
            
            Populates all galleries in Group 1 with sample content.
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GalleryId,
        [int]$PostCount = (Get-Random -Min 5 -Max 30),
        [string[]]$Creator,
        [string[]]$Contributor = $Creator,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        1..$PostCount |% {
            Write-Progress 'Sample Data' 'Populating Gallery' -PercentComplete (($_-1)/$PostCount * 100) -CurrentOperation "$_ of $PostCount" -id 802
            Initialize-CommunitySampleGalleryFile `
                -GalleryId $GalleryId `
                -Creator $Creator `
                -Contributor $Contributor `
                -Credential $Credential
        }
        Write-Progress 'Sample Data' 'Populating Gallery' -Completed -Id 802
    }
}

function Initialize-CommunitySampleWiki {
    <#
        .SYNOPSIS
            Populates a wiki with sample content
        .PARAMETER WikiId
            The wiki to generate content in.
        .PARAMETER TopLevelPages
            The number of top level pages to add to the wiki.  These pages will randomly have child pages generated.
        .PARAMETER Username
            A pool of users to use when creating the blog post.
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityWiki -Group 1 -Credential $cred | Initialize-CommunitySampleWiki -Credential $cred
            
            Populates all wikis in Group 1 with sample content.
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$WikiId,
        [int]$TopLevelPages = (Get-Random -Min 5 -Max 10),
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        1..$TopLevelPages |% {
            Write-Progress 'Sample Data' 'Populating Wiki' -PercentComplete (($_-1)/$TopLevelPages * 100) -CurrentOperation "$_ of $TopLevelPages" -id 803
            Initialize-CommunitySampleWikiPage `
                -WikiId $WikiId `
                -Username $Username  `
                -ChildPages (Get-Random -max 6) `
                -Credential $Credential
        }
        Write-Progress 'Sample Data' 'Populating Wiki' -Completed -Id 803
    }
}

function Initialize-CommunitySampleForumThread {
    <#
        .SYNOPSIS
            Generates a forum thread post inside the specified forum
        .PARAMETER ForumId
            The forum to generate the thread in.
        .PARAMETER Username
            A pool of users to use when creating the blog post.
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityForum -Group 1 -Credential $cred | Initialize-CommunitySampleForumThread -Credential $cred
            
            Creates a sample forum thread in all forums in the Group with Id 1.
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$ForumId,
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {

        $thread = New-CommunityForumthread `
            -Forumid $ForumId `
            -Subject (Get-RandomTitle) `
            -Body (Get-RandomHtml -MaxParagraphs 6) `
            -Credential $Credential `
            -Impersonate ($Username | Get-Random -ErrorAction SilentlyContinue)

        if($thread) {
            $thread

            $thread | Initialize-CommunitySampleContentCoreService  `
                -Like -Tag  -Rate `
                -Username $username `
                -Credential $Credential

            $replyCount = Get-RandomBiasedCommentCount -Max 40
            $parentReplyId = -1

            for ($i = 1; $i -le $replyCount; $i++) {
                Write-Progress 'Sample Data' 'Creating Forum Reply' -PercentComplete (($i - 1)/$replyCount * 100) -CurrentOperation "$i of $replyCount" -Id 804
                
                $reply = New-CommunityForumreply `
                    -ThreadId $thread.Id `
                    -Body (Get-RandomHtml 3) `
                    -Credential $Credential `
					-ParentReplyId $parentReplyId `
                    -Impersonate ($Username | Get-Random -ea SilentlyContinue)

                if($reply) {
                    $reply | Initialize-CommunitySampleContentCoreService  `
                        -Like -Tag -Rate `
                        -Username $username `
                        -Credential $Credential

                    $switch = Get-Random -Minimum 0 -Maximum 3
                    switch($switch){
                        0 { $parentReplyId = -1 }                    
                        1 { $parentReplyId = $reply.Id }                    
                        2 { $parentReplyId = $parentReplyId }                    
                    }   
                 
                }

            }
            Write-Progress 'Sample Data' 'Creating Forum Reply' -Complete -Id 804
        }
    }
}

function Initialize-CommunitySampleBlogPost {
    <#
        .SYNOPSIS
            Generates a blog post inside the specified blog
        .PARAMETER BlogId
            The blog to generate the page in.
        .PARAMETER Username
            A pool of users to use when creating the blog post.
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityBlog -Group 1 -Credential $cred | Initialize-CommunitySampleBlogPost -Credential $cred
            
            Creates a sample blog post in all blogs in the Group with Id 1.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$BlogId,
        [string[]]$Creator,
        [string[]]$Contributor = $Creator,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $post = New-CommunityBlogPost `
            -BlogId $BlogId `
            -Title (Get-RandomTitle) `
            -Body (Get-RandomHtml -MaxParagraphs 20) `
            -Credential $Credential `
            -Impersonate ($Creator | Get-Random -ErrorAction SilentlyContinue)
       

        if($post) {
            $post
            $post | Initialize-CommunitySampleContentCoreService `
                -Comment `
                -Like `
                -Tag `
                -Rate `
                -Username $Contributor `
                -Credential $Credential
        }
    }
}

function Initialize-CommunitySampleWikiPage {
    <#
        .SYNOPSIS
            Generates a wiki page inside the specified wiki
        .PARAMETER WikiId
            The wiki to generate the page in.
        .PARAMETER ParentPageId
            If specified, will create the wiki page as a child of the given page.
        .PARAMETER ChildPages
            If specified, will generate the specified number of additional wiki pages as children of the newly generated page
        .PARAMETER Username
            A pool of users to use when creating the wiki page
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityWiki -Group 1 -Credential $cred | Initialize-CommunitySampleWikiPage -Credential $cred
            
            Creates a sample wiki page in all wikis in the Group with Id 1.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$WikiId,
        [int]$ParentPageId,
        [int]$ChildPages = 0,
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process
    {
        $page = New-CommunityWikiPage `
            -WikiId $WikiId `
            -Title (Get-RandomTitle) `
            -Body (Get-RandomHtml -MaxParagraphs 20) `
            -ParentPageId $ParentPageId `
            -Credential $Credential `
            -Impersonate ($Username | Get-Random -ea SilentlyContinue)
       
        if($page) {

            $page
            $page | Initialize-CommunitySampleContentCoreService  `
                -Like `
                -Tag `
                -Rate `
                -Username $username `
                -Credential $Credential

            if($ChildPages -gt 0)
            {
                1..$ChildPages |% {
                    #TODO: Look at this biasing of child page count
                    Initialize-CommunitySampleWikiPage `
                        -WikiId $WikiId `
                        -ParentPageId $page.Id `
                        -ChildPages (-3..($ChildPages - 1) | Get-Random) `
                        -Username $Username `
                        -Credential $Credential
                }
            }
        }
    }
}

function Initialize-CommunitySampleGalleryFile {
    <#
        .SYNOPSIS
            Generates a file inside the specified gallery
        .PARAMETER GalleryId
            The gallery to generate the file in.
        .PARAMETER Username
            A pool of users to use when creating the blog post.
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            TODO:
            
            Creates a sample file in all galleries in the Group with Id 1.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GalleryId,
        [string[]]$Creator,
        [string[]]$Contributor = $Creator,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $splat = @{}
        if (Test-Probability 0.25) {
            $splat['FileUrl'] = Get-RandomExternalUrl
        }
        else {
            $file = Get-RandomFile
            $splat['FileName'] = Split-path $file -Leaf
            $splat['FileData'] = Get-Content $file -Encoding Byte
			
			Split-path $file -Leaf
        }

        $file = New-CommunityMedium @splat `
            -MediaGalleryId $GalleryId `
            -Name (Get-RandomTitle) `
            -Description (Get-RandomHtml -MaxParagraphs 20) `
            -Credential $Credential `
            -Impersonate ($Creator | Get-Random -ErrorAction SilentlyContinue)
       

        if($file) {
            $file
            $file | Initialize-CommunitySampleContentCoreService  `
                -Username $Contributor `
                -Credential $Credential `
                -Comment `
                -Like `
                -Tag `
                -Rate
        }
    }
}



function Initialize-CommunitySampleContentCoreService {
    <#
        .SYNOPSIS
            Populates a piece of content with sample data using core services.
        .PARAMETER ContentId
            The ContentId of the content to populate
        .PARAMETER ContentTypeId
            The ContentTypeId of the content to populate
        .PARAMETER Username
            A pool of users to use when liking the content
        .PARAMETER Comment
            Add comments using with the Comment Core Service. Content is commented on with a 50% probability.
        .PARAMETER Like
            Add likes using with the Like Core Service. Content is liked with a 50% probability.
        .PARAMETER Tag
            Add tags using with the Tag Core Service. Content is tagged with a 50% probability.
        .PARAMETER Rate
            Add ratings using with the Tag Core Service. Content is rated with a 50% probability.
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityBlogpost -Credential $cred -First 1 | Initialize-CommunityContent -Tag -Comment
            
            Gets the most recent blog post, and then comments it & adds tags.
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentTypeId,
        [string[]]$Username,
        [double]$Probability = 0.5,
        [switch]$Comment,
        [switch]$Like,
        [switch]$Tag,
        [switch]$Rate,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $commonParams = @{
            ContentId = $ContentId
            ContentTypeId = $ContentTypeId
            Credential = $Credential
        }

        if ($Tag -and (Test-Probability $Probability)) {
            Initialize-CommunitySampleTag @commonParams
        }
        
        if ($Comment -and (Test-Probability $Probability)) {
            Initialize-CommunitySampleComment @commonParams -Username $Username
        }

        if ($Like -and (Test-Probability $Probability)) {
            Initialize-CommunitySampleLike @commonParams -Username $Username
        }

        if($Rate -and (Test-Probability $Probability)) {
            Initialize-CommunitySampleRating @commonParams -Username $Username
        }
    }
}

function Initialize-CommunitySampleTag {
    <#
        .SYNOPSIS
            Populates a piece of content with sample tags.
        .PARAMETER ContentId
            The ContentId of the content to populate
        .PARAMETER ContentTypeId
            The ContentTypeId of the content to populate
        .PARAMETER MaxCount
            The maximum number of tags to add to the content
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityBlogpost -Credential $cred -First 1 | Initialize-CommunitySampleTag -Credential $cred -MaxCount 3
            
            Gets the most recent blog post, and adds up to 3 tags to it.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentTypeId,
        [uint16]$MaxCount = 5,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $tagCount = Get-Random -Min 1 -Max ($MaxCount + 1)

        $tags = 1..$tagCount |% { Get-RandomTag }

        New-CommunityContentTag `
            -ContentId $ContentId `
            -ContentTypeId $ContentTypeId `
            -Credential $Credential `
            -Tags $tags | Out-Null
    }
}

function Initialize-CommunitySampleLike {
    <#
        .SYNOPSIS
            Populates a piece of content with sample likes.
        .PARAMETER ContentId
            The ContentId of the content to populate
        .PARAMETER ContentTypeId
            The ContentTypeId of the content to populate
        .PARAMETER MaxCount
            The maximum number of likes to add to the content
        .PARAMETER Username
            A pool of users to use when liking the content
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityBlogpost -Credential $cred -First 1 | Initialize-CommunitySampleTag -Credential $cred
            
            Gets the most recent blog post, and likes it
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentTypeId,
        [uint16]$MaxCount = 6,
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $likeCount = Get-Random -Min 1 -Max $MaxCount
        
        1..$likeCount |% {
            New-CommunityLike `
                -ContentId $ContentId `
                -ContentTypeId $ContentTypeId `
                -Credential $Credential `
                -Impersonate ($Username | Get-Random -ea SilentlyContinue)
        }
    }
}

function Initialize-CommunitySampleRating {
    <#
        .SYNOPSIS
            Populates a piece of content with sample likes.
        .PARAMETER ContentId
            The ContentId of the content to populate
        .PARAMETER ContentTypeId
            The ContentTypeId of the content to populate
        .PARAMETER MaxCount
            The maximum number of ratings to add to the content
        .PARAMETER Username
            A pool of users to use when liking the content
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityWikiPage -WikiId 1 -First 1 -Credential $cred | Initialize-CommunitySampleRating -Credential $cred -Max 3
            
            Gets a wiki page from Wiki 1, and rates it up to 3 times
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentTypeId,
        [uint16]$MaxCount = 4,
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $ratingCount = Get-Random -Min 1 -Max ($MaxCount + 1)
        1..$ratingCount |% {
            New-CommunityRating `
                -Value ((Get-Random -max 6)/5) `
                -ContentId $ContentId `
                -ContentTypeId $ContentTypeId `
                -Credential $Credential `
                -Impersonate ($Username | Get-Random -ea SilentlyContinue)
        }
    }
}

function Initialize-CommunitySampleComment {
    <#
        .SYNOPSIS
            Populates a piece of content with sample comments.
        .PARAMETER ContentId
            The ContentId of the content to comment on
        .PARAMETER ContentTypeId
            The ContentTypeId of the content to comment on
        .PARAMETER Username
            A pool of users to use when commenting on the content
        .PARAMETER Credential
            The credentials to connect to the Community REST API with.
        .EXAMPLE
            Get-CommunityBlogpost -Credential $cred -First 1 | Initialize-CommunitySampleComment -Credential $cred 
            
            Gets the most recent blog post, and rates it up to 3 times
    #>
	[CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentId,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [Guid]$ContentTypeId,
        [string[]]$Username,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    process {
        $commentCount = Get-RandomBiasedCommentCount
        $parentCommentId = ''

        for ($i = 1; $i -le $commentCount; $i ++) {
            Write-Progress 'Sample Data' "Creating Comments" -PercentComplete (($i - 1)/$commentCount * 100) -CurrentOperation "$i of $commentCount" -Id 805
            $body = ""
            0..(Get-Random -Min 0 -Max 3) |% {
                $body += "$($dummyData.Paragraphs | Get-Random)`r`n"
            }
            
            $params = @{
                ContentId = $ContentId
                ContentTypeId = $ContentTypeId
                Body = $body
                Credential = $Credential
                Impersonate = ($Username | Get-Random -ea SilentlyContinue)
            }

            if($parentCommentId){
                $params.Add("ParentCommentId", $parentCommentId)
            }
            
            $comment = New-CommunityComment @params

            if($comment) {
                $switch = Get-Random -Minimum 0 -Maximum 3
                    switch($switch){
                        0 { $parentCommentId = '' }                    
                        1 { $parentCommentId = $comment.CommentId }                    
                        2 { $parentCommentId = $parentCommentId }                    
                    }   


            
                Initialize-CommunitySampleContentCoreService `
                    -ContentId $comment.CommentId `
                    -ContentTypeId $comment.CommentContentTypeId `
                    -Like `
                    -Username $Username `
                    -Credential $Credential
            }
        }
        Write-Progress 'Sample Data' "Creating Comments" -Completed -Id 805
    }
}