$delay = 5
$directoriesToWipe = "D:\Videos\Clip Submissions\Arizona", "D:\Videos\Clip Submissions\Atlantic", "D:\Videos\Clip Submissions\Central", "D:\Videos\Clip Submissions\Mountain", "D:\Videos\Clip Submissions\Pacific", "F:\transcode", "I:\Scratch Folder", "C:\Users\Kenneth Lopez\render", "I:\Merge"

function beepWarning {
    for ($i = 0; $i -lt 3; $i++) {
        [console]::beep(3000,100)
    }
}


echo "Are you sure you want to delete all video directories?"
echo "Press Y to continue"

if ((Read-Host) -ne "Y") { echo "Aborted"; return }

echo ""
echo ("All clips, renders, and related files will be deleted in " + $delay.ToString() + " seconds.")
beepWarning
for ($i = $delay - 1; $i -ge 0; $i--) {
	sleep -S 1
	echo ($i.ToString() + " second(s)")
}

echo ""
echo "Beginning wipe"
echo ""

$directoriesToWipe | ForEach-Object {
    Get-ChildItem $_ | ForEach-Object {
	    rm -Path $_.FullName
    }
}