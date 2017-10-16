Set-StrictMode -Version 2

workflow Initialize-CommunitySampleGroup {
	[CmdletBinding()]
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [int]$GroupId,
        [string[]]$Creator,
        [string[]]$Contributor,
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [CommunityCredential]$Credential
    )
    #TODO: Add support for joinless groups
    # Joinless groups don't support membership, so the following fails
    # For $Contributors, just create new site users
    # For $Creators, create them as Group Owners
    # Need to fix Get-CommunityGroup -GroupId so it returns the correct group rather than the root group
    # This is an issue with the code generated API to be resolved.

    $group = Get-CommunityGroup -Id $GroupId -Credential $Credential
    
    if($group.GroupType -ne 'Joinless') {
        if(!$Creator) {
            $Creator = (Initialize-CommunitySampleGroupMember `
                            -GroupId $GroupId `
                            -MemberType Manager `
                            -Min 3 `
                            -Maximum 6 `
                            -Credential $Credential
                       ).Username
        }

        if(!$Contributor) {
            $Contributor = (Initialize-CommunitySampleGroupMember `
                                -GroupId $GroupId `
                                -Credential $Credential
                            ).Username + $Creator
        }
    }

    #Would like to use foreach -parallel() here, but that seems to have problem loading the assembly containing [CommunityCredential]
    parallel {
        foreach ($forum in (Get-CommunityForum -GroupId $GroupId -Credential $Credential))
        {
            Initialize-CommunitySampleForum `
                -ForumId $forum.Id `
                -Username $Contributor `
                -Credential $Credential
        }

        foreach ($wiki in (Get-CommunityWiki -GroupId $GroupId -Credential $Credential))
        {
            Initialize-CommunitySampleWiki `
                -WikiId $wiki.Id `
                -Username $Contributor `
                -Credential $Credential 
        }

        foreach ($blog in (Get-CommunityBlog -GroupId $GroupId -Credential $Credential))
        {
            #TODO: Come up with a better implementation
            #Make all new members authors of the blog to ensure they can create content:
            #$authors = @($blog.Authors.Username) + $Username
            #Set-CommunityBlog -Id $blog.Id -Authors $authors -Credential $Credential
            Initialize-CommunitySampleBlog `
                -BlogId $blog.Id `
                -Creator $Creator `
                -Contributor $Contributor `
                -Credential $Credential 
        } 

        foreach ($gallery in (Get-CommunityGallery -GroupId $GroupId -Credential $Credential))
        {
            Initialize-CommunitySampleGallery `
                -GalleryId $gallery.Id `
                -Creator $Creator `
                -Contributor $Contributor `
                -Credential $Credential 
        }

    }
}