[string]$logodata = "
      ____ ___ ___
 ___ / __/|_  <  /
/ -_) _ \/ __// /
\__/\___/____/_/        __             __
  / _ \___ _    _____  / /__  ___ ____/ /__ ____
 / // / _ \ |/|/ / _ \/ / _ \/ _ `/ _  / -_) __/
/____/\___/__,__/_//_/_/\___/\_,_/\_,_/\__/_/

"

# Logo credit: http://patorjk.com/software/taag/#p=display&f=Small%20Slant&t=e621%0ADownloader

## Making the Class and setting default attributes
class e621Attributes {
    [boolean]$VerbosePreference
    #Root of E621
    [string]$RootURI = "https://e621.net/post"
    #URI of e621's indexes
    hidden[array]$IndexURI
    #User Submitted Filters (should pull at run or from text file)
    [array]$Filters
    #folder to download to, should be relative path
    [string]$DownloadFolder = ".\Downloads"
    #how many pages to pull posts from
    [int]$PageLimit
    #maximum number of posts to download, regardless of pages selected
    [int]$PostLimit = 75
    #A generated list of all queued posts to download from e621.net
    hidden[array]$PostsQueued
    hidden[array]$PostsPreviouslyDownloaded
    #The rating to filter by
    [array]$Rating
    #the score threshold for the posts, filter any content below the score value
    [int]$Score
    #extra blacklist, this does not count against E621's search tag limit, this will filter any unfiltered posts that may have labels contained in the blacklist
    [Array]$Blacklist
}
$e621Attributes = New-Object -TypeName e621Attributes

#$logodata
$logodata
Write-Host "Version 1.0" -ForegroundColor Yellow
Write-Host "Consider Donating: http://ko-fi.com/hashooves" -ForegroundColor Green
if (!(test-path ".\Default.config.txt")) {
    "
VerbosePreference=false
Filters=
Blacklist=
Score=0
Rating=safe,questionable,explicit
PageLimit=1
PostLimit=15
" | Out-File -FilePath .\Default.config.txt -Encoding utf8
    Write-Host "please edit the Default.config.txt file or create your own config file, then run the script again" -ForegroundColor Yellow
    pause
    Break
}

#Set the user's config file, logfile, and downloads folder
$UserConfig = Get-ChildItem .\ | Where-Object { $_.name -like "*config*" } | Out-GridView -Title "select a config file" -OutputMode Multiple

if ([string]::IsNullOrWhiteSpace($UserConfig)) {
    break
}

function Downloadfromconfig {

    $config = $config.FullName
    $tempfilepath = (split-path $config) + "\downloads\" + (Split-Path $config -Leaf).Replace(".config.txt", "") + "\"

    if (!(Test-Path $tempfilepath.Trim("\"))) {
        $temp = New-Item -Path $tempfilepath.Trim("\") -ItemType directory
    }
    $UserLog = $tempfilepath + ($config.Split("\")[-1]) -replace ("config", "log")
    if (!(Test-Path -Path $UserLog)) {
        $temp = New-Item -ItemType file -Path $UserLog
    }
    $UserDownloads = $tempfilepath.Trim("\")
    if (!(Test-Path -Path $UserDownloads)) {
        $temp = New-Item -ItemType directory -Path $UserDownloads
    }

    #Update all needed attributes

    $ConfigSettings = Get-Content $config | ConvertFrom-StringData
    $e621Attributes.VerbosePreference = $ConfigSettings.verbosePreference

    if ($ConfigSettings.verbosePreference -like "false") {
        $e621Attributes.VerbosePreference = $false
    }
    else {
        $e621Attributes.VerbosePreference = $true
    }

    $e621Attributes.Filters = $ConfigSettings.filters.Split(",").replace(" ", "_") | ForEach-Object { ($_).trim("_") }
    $e621Attributes.Blacklist = $ConfigSettings.blacklist.Split(",").replace(" ", "_") | ForEach-Object { ($_).trim("_") } | Where-Object { $_ }
    $e621Attributes.Score = $ConfigSettings.score
    $e621Attributes.Rating = $ConfigSettings.rating.Split(",").replace(" ", "_") | ForEach-Object { ($_).trim("_") }
    $e621Attributes.PageLimit = $ConfigSettings.pagelimit
    $e621Attributes.PostLimit = $ConfigSettings.postlimit
    $e621Attributes.DownloadFolder = $UserDownloads
    $e621Attributes.PostsPreviouslyDownloaded = get-content $UserLog

    $e621Attributes

    ##setting powershell to verbose mode if marked true in the config

    if ($e621Attributes.VerbosePreference -eq $true) {
        $VerbosePreference = "Continue"
    }
    else {
        $VerbosePreference = "SilentlyContinue"
    }

    ##display logo, creation date, EULA

    #Test E621
    if (!(Invoke-WebRequest -Uri $e621Attributes.RootURI).statuscode -like "200") {
        Write-Warning -Message "E621.net is not accessible!"
        pause
        Break
    }

    #generate the index pages that will be used to download content
    function GENERATEPAGES {
        #setting the temporary filters to generate the URLs
        $tempfilters = $e621Attributes.Filters | ForEach-Object { $_ + "," }
        $tempfilters = (-join $tempfilters).Trim(",")
        #setting the page counter to 1 (e621's pages effectivly start at one as page 0 and page one are equivilant)
        [int]$pagecounter = 1
        $tempoutput = @()
        do {
            #generating the pages that need to be searched
            $tempoutput += ($e621Attributes.RootURI + "/index/" + $pagecounter + "/" + $tempfilters)

            #incrementing the page counter one step
            $pagecounter = $pagecounter + 1
        }
        until ($pagecounter -gt $e621Attributes.PageLimit)

        $tempoutput
    }; $e621Attributes.IndexURI = GENERATEPAGES

    #get all the posts!
    $weblinks = foreach ($item in $e621Attributes.IndexURI) { (Invoke-WebRequest -Uri $item).links | Where-Object { $_.href -like "/post/show/*" } }

    #get the previously downloaded posts (to filter out...)
    $DLLog = Get-Content -path $UserLog

    #Starting filtering for previous posts blacklist filtering

    $Global:WeblinksOmitted = @()
    $Global:WeblinksFiltered = @()

    function POSTQUALITYTEST ($PostsToParse) {

        ##FUNCTIONS

        function BLACKLIST_TEST ($Post, $BlacklistedTags) {

            $TempPostTags = (((($post.outerHTML) -split 'alt="')[1] -split '&#13')[0]).Split(" ")
            $BlacklistTestResults = foreach ($BlacklistedTag in $BlacklistedTags) { $TempPostTags -contains $BlacklistedTag }
            if ($BlacklistTestResults -contains $true) {
                "FAIL"
            }
            else {
                "PASS"
            }

        }
        function PREVIOUSLYDOWNLOADEDPOST_TEST ($Post, $PreviouslyDownloadedPosts) {
            $TestingPostNumber = ((($Post.outerHTML) -split "&#13").trim(";") -split "`n")[0].split("/")[3]
            #$ItemResults += [string]::IsNullOrWhiteSpace(($PreviouslyDownloadedPosts -like $TestingPostNumber))

            if ($PreviouslyDownloadedPosts -contains $TestingPostNumber) {
                "FAIL"
            }
            else {
                "PASS"
            }

        }
        function RATING_TEST ($Post, $Rating) {
            $PostRating = ((($Post.outerHTML) -split "&#13").trim(";") -split "`n")[2] -replace "Rating: "  #rating
            $results = foreach ($RatingTag in $Rating) { $PostRating -contains $RatingTag }

            if ($results -contains $true) {
                "PASS"
            }
            else {
                "FAIL"
            }

        }
        function SCORE_TEST ($Post, $Score) {
            [int]$TestingScore = ((($Post.outerHTML) -split "&#13").trim(";") -split "`n")[3] -replace "Score: ", ""
            if ($TestingScore -ge $Score) {
                "PASS"
            }
            else {
                "FAIL"
            }
        }
        function POSTQUALITY_TEST {
            SCORE_TEST -Post $Post -Score $e621Attributes.Score
            RATING_TEST -Post $Post -Rating $e621Attributes.Rating
            PREVIOUSLYDOWNLOADEDPOST_TEST -Post $Post -PreviouslyDownloadedPosts (Get-Content -path $UserLog)
            BLACKLIST_TEST -Post $Post -BlacklistedTags $e621Attributes.Blacklist
        }
        ##ENDOFFUNCTIONS
        ##START PROCESS

        foreach ($Post in $PostsToParse) {

            if ((POSTQUALITY_TEST) -contains "FAIL") {
                $Global:WeblinksOmitted += $Post.href
                Write-Verbose -Message ($Post.href + " failed user selected criteria")
            }
            else {
                $Global:WeblinksFiltered += $Post.href
                Write-Verbose -Message ($Post.href + " passed user selected criteria")
            }

        }

        ##END PROCESS
    };
    POSTQUALITYTEST -PostsToParse $weblinks -BlacklistTags $e621Attributes.Blacklist

    Write-Verbose -Message ($WeblinksOmitted.count.ToString() + " posts have been omitted due to your filters!")
    $e621Attributes.PostsQueued = foreach ($item in $WeblinksFiltered) { $item.Split("/")[3] }

    if ($e621Attributes.PostsQueued.count -gt $e621Attributes.PostLimit) {
        Write-Verbose -Message (($e621Attributes.PostsQueued.count).ToString() + " posts had been found, due to your post download limit only " + ($e621Attributes.PostLimit).ToString() + " will be downloaded.")
    }

    if ($e621Attributes.PostsQueued.count -lt $e621Attributes.PostLimit) {
        Write-Host (($e621Attributes.PostsQueued.count).ToString() + " posts had been found based on your search criteria, because of this only " + ($e621Attributes.PostsQueued.count).ToString() + " posts will be downloaded.") -ForegroundColor Yellow
    }

    $e621Attributes.PostsQueued = $e621Attributes.PostsQueued | Select-Object -First ($e621Attributes.PostLimit)

    Write-Verbose -Message ("Planning to download the following posts:" + "`n" + $WeblinksFiltered)

    Write-Verbose -Message ("starting download of " + $e621Attributes.PostsQueued.Count + " posts!")
    [int]$ProgressCounter = 0
    foreach ($item in $e621Attributes.PostsQueued) {

        $ProgressCounter += 1
        Write-Progress -Activity "e621 Downloader" -Status ("downloading image number " + $ProgressCounter)  -PercentComplete ($ProgressCounter / $e621Attributes.PostsQueued.count * 100)

        $imagepost = Invoke-WebRequest -Uri ("https://e621.net/post" + "/show/" + ($item))
        $image = ($imagepost.Links | Where-Object { $_.outertext -like "download" }).href

        if ([string]::IsNullOrWhiteSpace($image)) {
            Write-Warning -Message ("Something has failed with item " + (($imagepost.Links | Where-Object { $_.outertext -like "Download" }).href).tostring())

        }

        if (Test-Path ($e621Attributes.DownloadFolder + $image.Split("/")[-1])) {
            Write-verbose -Message ($image.Split("/")[-1] + " already exists!")
        }
        else {

            Start-BitsTransfer -Source $Image -Destination $e621Attributes.DownloadFolder -Description ("https://e621.net/post" + "/show/" + ($item)) -DisplayName "Downloading Image"

        }

    }

    #log the downloaded posts
    function LOGDOWNLOADEDPOSTS ($Posts) {

        #load up the log of already downloaded posts
        $DLLog = Get-Content -path $UserLog
        #add the just downloaded posts
        $Output = $Posts + $DLLog
        #Update the downloaded posts logfile, (filtering dulicates too)
        $Output | Sort-Object -Unique | Out-File -FilePath $UserLog -Force -Encoding utf8

    } ; LOGDOWNLOADEDPOSTS -Posts $e621Attributes.PostsQueued

    Write-Host ("Downloads Completed, " + $e621Attributes.PostsQueued.count + " have been downloaded")
}

foreach ($Config in $UserConfig) {
    Downloadfromconfig $Config
    "-" * 50
    "`n"
}

pause