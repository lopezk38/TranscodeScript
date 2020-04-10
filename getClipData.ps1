$clipCount = 0
$clipLength = 0
$directory = ''
$wmpObject = New-Object -ComObject wmplayer.ocx

for($region=0; $region -lt 5; $region++) {
    Switch ($region) {
        0 {$directory = "D:\Videos\Clip Submissions\Arizona"} #Arizona
        1 {$directory = "D:\Videos\Clip Submissions\Atlantic"} #Atlantic
        2 {$directory = "D:\Videos\Clip Submissions\Central"} #Central
        3 {$directory = "D:\Videos\Clip Submissions\Mountain"} #Mountain
        4 {$directory = "D:\Videos\Clip Submissions\Pacific"} #Pacific
    }

    Get-ChildItem $directory -Filter *.mp4 | ForEach-Object {
        $clipCount++
        $clip = $wmpObject.newMedia($_.FullName)
        $clipLength = $clipLength + $clip.duration
    }
}

$timeSpan = [timespan]::fromSeconds($clipLength)
$formattedLength = ("{0:hh\:mm\:ss}" -f $timeSpan)

echo ""
echo ($clipCount.ToString() + " clips for a total raw time of " + $formattedLength)
echo ""
pause