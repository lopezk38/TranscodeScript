$clipCounter = 0
$renameCounter = 0
$directory = ""
$failedClips = @() #spawns empty array
$transcodeDir = "F:\transcode"
$scratchFolder = "I:\Scratch Folder"
$ffmpegInstances = 4

function beepError {
    for ($i = 0; $i -lt 3; $i++) {
        [console]::beep(200,100)
    }
}

function beepSuccess {
        for ($i = 1; $i -lt 4; $i++) {
        [console]::beep(200 * $i,100)
    }
}

for($region = 0; $region -lt 5; $region++) {
    Switch ($region) {
        0 {$directory = "D:\Videos\Clip Submissions\Arizona"} #Arizona
        1 {$directory = "D:\Videos\Clip Submissions\Atlantic"} #Atlantic
        2 {$directory = "D:\Videos\Clip Submissions\Central"} #Central
        3 {$directory = "D:\Videos\Clip Submissions\Mountain"} #Mountain
        4 {$directory = "D:\Videos\Clip Submissions\Pacific"} #Pacific
    }
    Get-ChildItem $directory -Filter *.mp4 | ForEach-Object {
        $clipCounter++
        If ($_.BaseName -ne '0') {
            $year=$month=$day=$hour=$minute=$second = -1
            $dupecount = 0

            If ($_.BaseName -match '\d\d\d\d\.\d\d\.\d\d\.\d\d\.\d\d\.\d\d\.\d\d') {
                echo ($_.BaseName + " is already in the correct format.")
                if (Test-Path -Path ($transcodeDir + '\' + $_.BaseName + '.mp4')) {
                    echo "...has already been copied. Skipping copy..."
                } else {
                    echo "Copying..."
                    Copy-Item $_.FullName -Destination $transcodeDir 
                    $renameCounter++
                }
            } else {

                If ($_.BaseName -match '\d\d\d\d\.\d\d\.\d\d') {
                    $year = $Matches[0].substring(0,4)
                    $month = $Matches[0].substring(5,2)
                    $day = $Matches[0].substring(8,2)
                    If ($_.BaseName -match '((?<=-)|(?<=- ))(\d\d\.\d\d)') {
                        $foundFormat = 0 
                        $hour = ""
                        $minute = ""
                        $second = ""

                        If ($_.BaseName -match '(\d\d\.\d\d\.\d\d\.\d\d)(?!\.\d)') { #Check for Shadowplay File Name Format. Number after seconds is a client side counter. Not useful for me 
                            $hour = $Matches[0].substring(0,2)
                            $minute = $Matches[0].substring(3,2)
                            $second = $Matches[0].substring(6,2)
                            $foundFormat = 1
                        } Elseif ($_.BaseName -match '(?<=-)(\d\d\.\d\d)(?!\.\d)') { #Check for ReLive File Name Format. Has less data than Shadowplay, set extra data to 00
                            $hour = $Matches[0].substring(0,2)
                            $minute = $Matches[0].substring(3,2)
                            $second = "00"
                            $foundFormat = 1
                        } Else {echo ('Could not find fine date (Format Determination) for: ' + $_.BaseName); $failedClips += $_.BaseName; beepError; sleep -s 10;}

                        If ($foundFormat -eq 1) {
                            $DateObject = Get-Date -Year $year -Month $month -Day $day -Hour $hour -Minute $minute -Second $second
                            $DateObject = [System.DateTime]::SpecifyKind($DateObject, 0)

                            Switch ($region) { #Timezone offset. Normalize to pacific
                                0 { if (!((Get-Date).IsDaylightSavingTime())) { # TimeZoneInfo is not aware of Arizona's lack of DST, so we just leave the time alone when it's DST
                                        $DateObject = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($DateObject, 'Mountain Standard Time', 'Pacific Standard Time')
                                    $year = $DateObject.Year; $month = $DateObject.Month; $day = $DateObject.Day; $hour = $DateObject.Hour; $minute = $DateObject.Minute; $second = $DateObject.Second
                                  };}
                                1 {
                                    $DateObject = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($DateObject, 'Eastern Standard Time', 'Pacific Standard Time')
                                    $year = $DateObject.Year; $month = $DateObject.Month; $day = $DateObject.Day; $hour = $DateObject.Hour; $minute = $DateObject.Minute; $second = $DateObject.Second
                                  }
                                2 {
                                   $DateObject = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($DateObject, 'Central Standard Time', 'Pacific Standard Time')
                                    $year = $DateObject.Year; $month = $DateObject.Month; $day = $DateObject.Day; $hour = $DateObject.Hour; $minute = $DateObject.Minute; $second = $DateObject.Second
                                 }
                              3 {
                                  $DateObject = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($DateObject, 'Mountain Standard Time', 'Pacific Standard Time')
                                  $year = $DateObject.Year; $month = $DateObject.Month; $day = $DateObject.Day; $hour = $DateObject.Hour; $minute = $DateObject.Minute; $second = $DateObject.Second
                                 }
                              4 { } #Don't need to do anything for Pacific
                          }


                           #Find suitable name and rename
                           #https://social.technet.microsoft.com/wiki/contents/articles/4250.powershell-string-formatting.aspx#NET_formatting
                           #gist of it is that '{0:0000}' -f <string> means pad front of int with zeros until string length is >= 4
                           # '{<keep 0 for most cases>:<number of digits (based off number of zeros you write) you want in the final product. Will pad zeros until met>}'
                           $nameToTry = '{0:0000}' -f $year + '.' + '{0:00}' -f $month + '.' + '{0:00}' -f $day + '.' + '{0:00}' -f $hour + '.' + '{0:00}' -f $minute +'.' + '{0:00}' -f $second + '.' + '{0:00}' -f $dupecount + '.mp4'
                           While (Test-Path -Path ($transcodeDir + '\' + $nameToTry)) {
                               if ($dupecount -eq 10) {
                                   echo ("Warning: " + $_.BaseName + " has over 10 duplicates")
                               }
                               
                              if ($dupecount -gt 25) {
                                  echo ($_.BaseName + " has too many duplicates. Skipping...")
                                  $failedClips += $_.BaseName
                                  beepError
                                  pause
                                  break
                               }

                               $dupecount++
                               $nameToTry = '{0:0000}' -f $year + '.' + '{0:00}' -f $month + '.' + '{0:00}' -f $day + '.' + '{0:00}' -f $hour + '.' + '{0:00}' -f $minute +'.' + '{0:00}' -f $second + '.' + '{0:00}' -f $dupecount + '.mp4'
                          }
                          $_ | Rename-Item -NewName ($nameToTry)
                          Copy-Item ($directory + '\' + $nameToTry) -Destination $transcodeDir
                          $renameCounter++
                      }
                    } else {echo ('Could not find fine date (Pre Format Determination) for: ' + $_.BaseName); $failedClips += $_.BaseName; beepError; sleep -s 10}
                } else {echo ('Could not find coarse date for: ' + $_.BaseName); $failedClips += $_.BaseName; beepError; sleep -s 10}
            } 
        } else {Copy-Item $_.FullName -Destination $transcodeDir; $renameCounter++}
    }
}


echo ('Succeeded renaming ' + $renameCounter.ToString() + ' out of ' + $clipCounter.ToString() + ' clips')
If ($failedClips.Count -gt 0) {
    echo "Printing names of failed clips:"
    $failedClips
    sleep -s 10
}

sleep -s 5

echo "Beginning Transcodes..."
$timer = New-Object -TypeName System.Diagnostics.Stopwatch
$timer.Start()

for ($instances = 0; $instances -lt $ffmpegInstances; $instances++) {
	$aList = $instances, $ffmpegInstances, $transcodeDir, $scratchFolder
	Start-Job -ArgumentList $aList -ScriptBlock { 
		param($instances, $ffmpegInstances, $transcodeDir, $scratchFolder)
		$files = Get-ChildItem $transcodeDir -Filter *.mp4
		for ($i = $instances; $i -lt $files.Count; $i = $i + $ffmpegInstances) {
			ffmpeg -nostdin -hwaccel dxva2 -i $files[$i].FullName -c:v dnxhd -vf "scale=2560:1440,fps=60000/1001,format=yuv422p" -profile:v dnxhr_sq -c:a pcm_s16le ($scratchFolder + "\" + $files[$i].BaseName + '.mov')
		}
	} 
}

Get-Job | Wait-Job
$timer.Stop()
echo "Milliseconds to encode: "
echo $timer.ElapsedMilliseconds

$clipCounter = 1
Get-ChildItem $scratchFolder -Filter *.mov | Sort-Object |
ForEach-Object {
	If ($_.BaseName -eq '0') {
		Rename-Item -Path ($scratchFolder + "\" + $_.BaseName + '.mov') -NewName ('0' + '.mp4')
	} Else {
		Rename-Item -Path ($scratchFolder + "\" + $_.BaseName + '.mov') -NewName ($clipCounter.ToString() + '.mp4')
		$clipCounter++
	}
}



beepSuccess

echo ""
echo "Press Enter to Exit..."
Read-Host















































