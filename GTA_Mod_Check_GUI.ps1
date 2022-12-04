Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName "System.Windows.Forms"


$xamlFile = ".\MainWindow.xaml"

$inputXML = Get-Content $xamlFile -Raw
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[xml]$XAML = $inputXML


$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $window = [Windows.Markup.XamlReader]::Load( $reader )
}
catch {
    Write-Warning $_.Exception
    throw
}

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    try {
        Set-Variable -Name "var_$($_.Name)" -Value $window.FindName($_.Name) -ErrorAction Stop
    } catch {
        throw
   }
}

Get-Variable var_*

$var_txtSource.Text = gc $env:userprofile\documents\mod_check\dir.ini
$var_txtBackup.Text = gc $env:userprofile\documents\mod_check\backup.ini

$var_btnSource.Add_Click({
    $GameFolder = New-Object System.Windows.Forms.FolderBrowserDialog
    $GameFolder.ShowDialog()
    $var_txtSource.Text=$GameFolder.SelectedPath
})

$var_btnBackup.Add_Click({
    $BackupFolder = New-Object System.Windows.Forms.FolderBrowserDialog
    $BackupFolder.ShowDialog()
    $var_txtBackup.Text=$BackupFolder.SelectedPath
})

$var_btnClear.Add_Click({
    $var_txtOutput.text = ""
})

function modcheck {

cls
$erroractionpreference = 'silentlycontinue'

$intro = @'
  __ _____ __    __ __  __  __     ____  _ ___ ____  __ 
 / _]_   _/  \  |  V  |/__\| _\   / _/ || | __/ _/ |/ / 
| [/\ | || /\ | | \_/ | \/ | v | | \_| >< | _| \_|   <  
 \__/ |_||_||_| |_| |_|\__/|__/   \__/_||_|___\__/_|\_\ 
--------------------------------------------------------
            GTA 5 Mod Cleanup Tool / Ver 1.1                      
--------------------------------------------------------
'@

Add-txtOutput -message $intro

$test = test-path -Path $env:userprofile\documents\mod_check
    
$whitelist = '.egstore 
CommonRedist
EOSSDK-Win64-Shipping.dll
EntryPoints.ini
GFSDK_ShadowLib.win64.dll
GFSDK_TXAA.win64.dll
GFSDK_TXAA_AlphaResolve.win64.dll
GPUPerfAPIDX11-x64.dll
GTA5.exe
GTAVLanguageSelect.exe
GTAVLauncher.exe
Installers
NvPmApi.Core.win64.dll
PlayGTAV.exe
ReadMe
Readme
Redistributables
bink2w64.dll
commandline.ini
common.rpf
d3dcompiler_46.dll
d3dcsx_46.dll
index.bin
installscript.vdf
steam_api64.dll
steam_appid.ini
uninstall.exe
update
version.ini
x64
x64a.rpf
x64b.rpf
x64c.rpf
x64d.rpf
x64e.rpf
x64f.rpf
x64g.rpf
x64h.rpf
x64i.rpf
x64j.rpf
x64k.rpf
x64l.rpf
x64m.rpf
x64n.rpf
x64o.rpf
x64p.rpf
x64q.rpf
x64r.rpf
x64s.rpf
x64t.rpf
x64u.rpf
x64v.rpf
x64w.rpf'
    
if (!($test -eq $true)){
$dir = $($var_txtSource.Text)
$backup = $($var_txtBackup.Text)
new-item -ItemType directory -Path $env:userprofile\documents\mod_check\ >$null 2>&1
new-item -ItemType file -path $env:userprofile\documents\mod_check\ -name "dir.ini" -value $dir >$null 2>&1
new-item -ItemType file -path $env:userprofile\documents\mod_check\ -name "backup.ini" -value $backup >$null 2>&1
new-item -ItemType file -path $env:userprofile\documents\mod_check\ -name "whitelist.ini" -value $whitelist >$null 2>&1
}
    
$getdircont = gc $env:userprofile\documents\mod_check\dir.ini
$testdirpath = test-path -path $getdircont
$getbackpath = gc $env:userprofile\documents\mod_check\backup.ini
$testbackup = test-path -path $getbackpath
$testbackfiles = test-path -path $getbackpath\*

if ($null -eq $getdircont -or $null -eq $getbackpath){
    [System.Windows.MessageBox]::Show('Source fields cannot be left blank!','GTA Mod Check','OK','Error')
    remove-item -path $env:userprofile\documents\mod_check -recurse
    return
}

Add-txtOutput -message "Scanning for folder: $($getdircont)"
    
if ($testdirpath -eq $true){
    Add-txtOutput -message "Directory $($getdircont) was found!"
    Add-txtOutput
    get-childitem -path $getdircont | foreach {$_.name} | out-file $env:userprofile\documents\mod_check\scan.ini
}
else {
    [System.Windows.MessageBox]::Show("Game directory $($getdircont) does not exist! Please use a valid game directory.",'GTA Mod Check','OK','Error')
    remove-item -path $env:userprofile\documents\mod_check -recurse
    return
}

$stock = test-path $env:userprofile\documents\mod_check\stock.ini
    
if (!($stock -eq $true)){
    Compare-Object -ReferenceObject (gc $env:userprofile\documents\mod_check\whitelist.ini) -DifferenceObject (gc $env:userprofile\documents\mod_check\scan.ini) -IncludeEqual -ExcludeDifferent | % {$_.inputobject} | out-file $env:userprofile\documents\mod_check\stock.ini
}
    
$comp1 = gc $env:userprofile\documents\mod_check\stock.ini
$comp2 = gc $env:userprofile\documents\mod_check\scan.ini
    
$comparefile = Compare-Object -ReferenceObject $comp1 -DifferenceObject $comp2
$missingfiles = $comparefile | Where-Object {$_.sideindicator -eq "<="}
    
if ($comparefile.sideindicator -eq "<="){

    foreach ($missingfile in $missingfiles){ 
        [System.Windows.MessageBox]::Show("ERROR: File $($missingfile.inputobject) missing from game directory!",'GTA Mod Check','OK','Error')
}
    
[System.Windows.MessageBox]::Show('Game folder may be corrupted, please run intregrity check on folder for verification.','GTA Mod Check','OK','Warning')
return
}
    
$validdir = gc $env:userprofile\documents\mod_check\stock.ini
    
if ($null -eq $validdir){
    [System.Windows.MessageBox]::Show('No valid game files found! Please enter a valid game directory!','GTA Mod Check','OK','Warning')
    remove-item -path $env:userprofile\documents\mod_check -force -recurse
    return
}

if ($null -eq $comparefile -and $testbackup -eq $true -and $testbackfiles -eq $true){
    get-childitem -path $getbackpath | foreach {$_.name} | out-file $env:userprofile\documents\mod_check\bfolder.ini
    Add-txtOutput -message "Scanning for modded files:"
    Add-txtOutput -message "No modded files detected in game directory"
    Add-txtOutput
    Add-txtOutput -message "Checking for backup folder:"
    Add-txtOutput -message "Backup folder found!"
    Add-txtOutput
    $bfiles = Compare-Object -ReferenceObject (gc -path $env:userprofile\documents\mod_check\bfolder.ini) -DifferenceObject (gc -path $env:userprofile\documents\mod_check\modded_files.ini) -includeequal -excludedifferent | foreach {$_.inputobject}
    remove-item $env:userprofile\documents\mod_check\modded_files.ini
    remove-item $env:userprofile\documents\mod_check\bfolder.ini
    
    foreach ($b in $bfiles){
        Add-txtOutput -message "Moving $b back to game directory"
        move-item -Path $getbackpath\$b -destination $getdircont -force
}

[System.Windows.MessageBox]::Show("Successfully moved $($bfiles.count) file(s) to $($getdircont).",'GTA Mod Check','OK')
}
    
if ($null -eq $comparefile -and $testbackup -eq $true -and $testbackfiles -ne $true){
    Add-txtOutput -message "Scanning for modded files:"
    Add-txtOutput -message "No modded files detected in game directory"
    Add-txtOutput
    Add-txtOutput -message "Checking for backup folder:"
    Add-txtOutput -message "Backup folder found!"
    Add-txtOutput
    Add-txtOutput -message "No modded files detected in backup folder" 
    Add-txtOutput -message "If mod files reside here manually move back to game directory"
    remove-item -path $env:userprofile\documents\mod_check\modded_files.ini -force
    return
}
    
if ($null -eq $comparefile -and $testbackup -ne $true){
    Add-txtOutput -message "Scanning for modded files:"
    Add-txtOutput -message "No modded files detected in game directory"
    Add-txtOutput
    Add-txtOutput -message "Checking for backup folder:"
    Add-txtOutput -message "Backup folder not found!"
    Add-txtOutput    
    return
}
    
if ($null -ne $comparefile -and $testbackup -ne $true){
    Add-txtOutput -message "Scanning for modded files:"
    Add-txtOutput -message "Modded files detected in game directory"
    Add-txtOutput
    Add-txtOutput -message "Checking for backup folder:"
    Add-txtOutput -message "Backup folder not found!"
    Add-txtOutput
    Add-txtOutput -message "Creating folder: $getbackpath"
    Add-txtOutput
    new-item -itemtype directory -path $getbackpath >$null 2>&1
    Compare-Object -ReferenceObject $comp1 -DifferenceObject $comp2 | foreach {$_.InputObject} | out-file $env:userprofile\documents\mod_check\modded_files.ini
}

if ($null -ne $comparefile -and $testbackup -eq $true){
    Add-txtOutput -message "Scanning for modded files:"
    Add-txtOutput -message "Modded files detected in game directory"
    Add-txtOutput
    Add-txtOutput -message "Checking for backup folder:"
    Add-txtOutput -message "Backup folder found!"
    Add-txtOutput
    Compare-Object -ReferenceObject $comp1 -DifferenceObject $comp2 | foreach {$_.InputObject} | out-file $env:userprofile\documents\mod_check\modded_files.ini
}

if (test-path $env:userprofile\documents\mod_check\modded_files.ini){

$modfiles = gc $env:userprofile\documents\mod_check\modded_files.ini

    foreach ($m in $modfiles){
        Add-txtOutput -message "Modded file $m found! Moving to backup folder."
        move-item -path $getdircont\$m -destination $getbackpath
}

[System.Windows.MessageBox]::Show("Successfully moved $($modfiles.count) file(s) to $($getbackpath).",'GTA Mod Check','OK')
}
}

Function Add-txtOutput {
    Param ($Message)
    $var_txtOutput.AppendText("`n$Message")
}

$var_btnExecute.Add_Click({
    modcheck
})

$Null = $window.ShowDialog()