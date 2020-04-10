$renderDir = "C:\Users\Kenneth Lopez\render"
$intermediateDir = "I:\Merge"
$intermediateDirForwardSlash = "I:/Merge/" #ffmpeg doesn't like backslashes, and I don't feel its worth doing a bunch of string operations just for one command
$outputDir = "D:\Video Projects"
$outputName = (Get-Date -Format "MM.dd.yy") + ".mp4"
$ffmpegInstances = 2 #Number of files in $renderDir MUST be equal to this

function beepSuccess {
        for ($i = 1; $i -lt 4; $i++) {
        [console]::beep(200 * $i,100)
    }
}

if ((Get-ChildItem $intermediateDir -Filter *.mp4).Count -le 0) {
	echo "Beginning Transcodes..."
	$timer = New-Object -TypeName System.Diagnostics.Stopwatch
	$timer.Start()

	for ($instances = 0; $instances -lt $ffmpegInstances; $instances++) {
		$aList = $instances, $ffmpegInstances, $renderDir, $intermediateDir
		Start-Job -ArgumentList $aList -ScriptBlock { 
			param($instances, $ffmpegInstances, $renderDir, $intermediateDir)
			$files = Get-ChildItem $renderDir -Filter *.mov
			ffmpeg -i $files[$instances].FullName -preset medium -c:v libx265 -crf 25 -c:a copy ($intermediateDir + '\' + $instances.ToString() + '.mp4')
		} 
	}

	Get-Job | Wait-Job
	$timer.Stop()
	echo "Milliseconds to encode: "
	echo $timer.ElapsedMilliseconds
} else {echo "Found files in intermediate directory. Skipping transcode..."}

echo "" > ($intermediateDir + "\list.txt")
Clear-Content ($intermediateDir + "\list.txt")
$inputs = Get-ChildItem $intermediateDir -Filter *.mp4
for ($i = 1; $i -le $inputs.Count; $i++) {
	if ($i -lt $inputs.Count) {
		Add-Content -Path ($intermediateDir + "\list.txt") -Value ("file " + $intermediateDirForwardSlash + $inputs[$i - 1].BaseName + ".mp4")
	} else {Add-Content -NoNewline -Path ($intermediateDir + "\list.txt") -Value ("file " + $intermediateDirForwardSlash + $inputs[$i - 1].BaseName + ".mp4")}
}

ffmpeg -safe 0 -f concat -i ($intermediateDir + "\list.txt") -c copy ($outputDir + "\" + $outputName)

beepSuccess

echo ""
echo "Press Enter to Exit..."
Read-Host