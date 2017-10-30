#Requires -Modules TelligentCommunityRest,TelligentCommunitySample
## Start Configuration

$CommunityUrl = 'http://sampletest.local/'
$AdminUsername = 'admin'
$ApiKey = 'abc123'

## End Configuration


$creds = New-CommunityCredential $CommunityUrl $AdminUsername $ApiKey


$productGroup = New-CommunitySampleGroup -ParentGroupId 1 -GroupType Joinless -Name "Products" -Wiki 0 -Gallery 0 -Forum 0 -Blog 0 -Credential $creds
$productOneGroup = New-CommunitySampleGroup -ParentGroupId $productGroup.Id -GroupType PublicOpen -Name "Product One" -Wiki 1 -Gallery 1 -Credential $creds
$productTwoGroup = New-CommunitySampleGroup -ParentGroupId $productGroup.Id -GroupType PublicOpen -Name "Product Two" -Wiki 1 -Gallery 1 -Credential $creds
$productThreeGroup = New-CommunitySampleGroup -ParentGroupId $productGroup.Id -GroupType PublicOpen -Name "Product Three" -Wiki 1 -Gallery 1 -Credential $creds

Initialize-CommunitySampleGroup -GroupId $productOneGroup.Id -Credential $creds
Initialize-CommunitySampleGroup -GroupId $productTwoGroup.Id -Credential $creds
Initialize-CommunitySampleGroup -GroupId $productThreeGroup.Id -Credential $creds