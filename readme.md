# Sample Data Generator for Telligent Commnity

The sample data generation scripts can be used to populate a community with sample data for testing purposes.  They can either be used to create a whole community from scratch (e.g. create 5 groups, each with 3 sub groups, each of which should be populated with content), or can be used with some level of explicit structure followed by random data (e.g. create a Departments group with sub groups Support and Engineering.  Create a News group etc.  Populate all these with sample content).

These scripts work with Telligent Community 7.6+, although they use REST and so should be mostly compatible with previous versions.

The current weightings of how we decide how much data to generate is based around generating sample data for test purposes (e.g. 50% of content that supports ratings will have 1 or more ratings).  Although some of the building blocks behind these scripts could be reused to generate more realistic data.  (e.g. if you wnt to create 1000 forum threads, you can just use the Initialize-CommunitySampleForum command with a ThreadCount of 1000.

## Installation

The sample data generation scripts are published to the PowerShell gallery and can be installed by running the following command at the PowerShell prompt.

```powershell
Set-ExecutionPolicy RemoteSigned
Install-Module -Name TelligentCommunitySample
```

## Credentials

The most important command is the New-CommunityCredential command.  This contains the details for accessing your community, that is required by all the sample data generation functions

```powershell
$cred = New-CommunityCredential -CommunityRoot http://community.com/ -Username username –ApiKey apiKey
```

If using windows auth, you can specify HTTP Credentials to be used on the request

```powershell
$httpCreds = Get-Credential
#Type credentials at prompt
$cred = ncc http://community.com/ admin abc123 –HttpCredentials $httpCred 
```

## Examples

Populate all applications in an existing group with sample content
```powershell
$cred = New-CommunityCredential http://mycommunity.local/ admin abc123
Initialize-CommunitySampleGroup -GroupId 3 -Credential $cred
```

Create 1000 threads within a specific forum
```powershell
$cred = ncc http://mycommunity.local/ admin abc123
Initialize-CommunitySampleForum -ForumId 265 -ThreadCount 1000 -Credential $cred
```

Create 5 empty wikis in a specific group
```powershell
$cred = ncc http://mycommunity.local/ admin abc123
1..5 |% { New-CommunitySampleWiki -GroupId 43 -Credential $cred }
```

Create 2 new blogs in a group, and populate them with dummy content
```powershell
$cred = ncc http://mycommunity.local/ admin abc123
1..2 |% {
    $blog = New-CommunitySampleBlog -GroupId 2 -Credential $cred
    Initialize-CommunitySampleBlog -BlogId $blog.Id -Credential $cred 
}
```

Populate content in all groups in the community
```powershell
Get-CommunityGroup -IncludeAllSubGroups $true -Credential $cred |% {
    Initialize-CommunitySampleGroup -GroupId $_.Id -Credential $cred | Out-Null
}
```

## Architecture

### CommunitytRest

The Community Rest module is an API to interact with the community REST API.  It is mostly code generated.

### CommunitySample

The CommunitySample module is where the real magic happens.  This uses some custom logic to determine quantities and generate random content (see below for more detail on the methodology), and then interacts with the CommunityRest module to populate content in the community.

## Sample Data Generation Methodology

Textual data is generated as follows.  The exact lists can be found in the .txt files in the CommunitySample module.

* Application / Group names are based on a list of sports
* Subjects are the union of several sets of data:
   * Fairy Tales
   * Place Names
   * Recent UK Number 1 Singles
   * Some Lorem Ipsum generated junk
* Post / Comment bodies are based on stitching together random paragraphs from Peter Pan (the book is now public domain)
* Usernames are based upon joining a random forename to a random surname
* Tags are based on a list of animals

Where content uses core services out of the box, these items will have content randomly generated in the core services.  e.g. wikis will have a 50% probability of having ratings, and a 50% probability of being liked, and a 50% probability of having tags.

## Command List

Below is a list of commands in the CommunitySample module - further information on these commands can be found using `Get-Help`.

* `Get-RandomApplicationName`
* `Get-RandomBiasedCommentCount`
* `Get-RandomExternalUrl`
* `Get-RandomFile`
* `Get-RandomHtml`
* `Get-RandomName`
* `Get-RandomTag`
* `Get-RandomTitle`
* `Initialize-CommunitySampleBlog`
* `Initialize-CommunitySampleBlogPost`
* `Initialize-CommunitySampleComment`
* `Initialize-CommunitySampleContentCoreService`
* `Initialize-CommunitySampleForum`
* `Initialize-CommunitySampleForumThread`
* `Initialize-CommunitySampleGallery`
* `Initialize-CommunitySampleGalleryFile`
* `Initialize-CommunitySampleGroup`
* `Initialize-CommunitySampleGroupMember`
* `Initialize-CommunitySampleLike`
* `Initialize-CommunitySampleRating`
* `Initialize-CommunitySampleTag`
* `Initialize-CommunitySampleUser`
* `Initialize-CommunitySampleWiki`
* `Initialize-CommunitySampleWikiPage`
* `New-CommunitySampleBlog`
* `New-CommunitySampleForum`
* `New-CommunitySampleGallery`
* `New-CommunitySampleGroup`
* `New-CommunitySampleWiki`
* `Test-Probability`
