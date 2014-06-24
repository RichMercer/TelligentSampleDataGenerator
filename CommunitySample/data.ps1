Set-StrictMode -Version 2

function Get-RandomHtml{
    param([int]$MaxParagraphs = 3)

    $html = ""
    0..(Get-Random -Min 0 -Max $MaxParagraphs) |% {
        $para = $dummyData.Paragraphs | Get-Random
        $html+= "<p>$([System.Web.HttpUtility]::HtmlEncode($para))</p>"
    }
    $html += "<!-- $([guid]::NewGuid()) -->"

    $html
}

function Test-Probability {
    param(
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(0,1)]
        [double]$Probability
    )
    (Get-Random -Minimum 1 -max 1001) -lt ($Probability * 1000)
}

function Get-RandomBiasedCommentCount
{
    param(
        [int]$LowerMax = 5,
        [int]$Max = 20
        )

    if (Test-Probability 0.15) {
        Get-Random -min $LowerMax -max $max
    }
    else {
        Get-Random -max $LowerMax
    }
}


function Get-RandomApplicationName {
    $dummyData.AppNames | Get-Random
}
function Get-RandomTitle {
    $dummyData.Subjects | Get-Random
}
function Get-RandomTag {
    $dummyData.Tags | Get-Random
}
function Get-RandomName {
    "$($dummyData.Forenames | Get-Random) $($dummyData.Surnames | Get-Random)"
}
function Get-RandomExternalUrl {
    $dummyData.ExternalUrls | Get-Random
}
function Get-RandomFile {
    $dummyData.Files | Get-Random
}

push-location $PSScriptRoot
$dummyData = @{
    Subjects = Get-Content Subjects.txt -Encoding UTF8
    Paragraphs = Get-Content Paragraphs.txt -Encoding UTF8
    AppNames = Get-Content AppNames.txt -Encoding UTF8
    Tags = Get-Content tags.txt -Encoding UTF8
    Forenames = Get-Content Forenames.txt -Encoding UTF8
    Surnames = Get-Content Surnames.txt -Encoding UTF8
    ExternalUrls = Get-Content ExternalUrls.txt -Encoding UTF8
    Avatars = Get-ChildItem Avatars | Select -ExpandProperty FullName
    Files = Get-ChildItem Files | Select -ExpandProperty FullName
}
Pop-Location