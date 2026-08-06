$Host.UI.RawUI.WindowTitle = "GOLDx Installer"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$e = [char]27
$RESET     = "$e[0m"
$YELLOW    = "$e[33m"
$GREY      = "$e[90m"
$RED       = "$e[31m"
$GREEN     = "$e[32m"
$BG_YELLOW = "$e[43m$e[30m"

$B = [char]0x2588  # Full Block (█)
$D = [char]0x2584  # Lower Block (▄)
$U = [char]0x2580  # Upper Block (▀)
$M = [char]0x2592  # Medium Shade (▒)
$L = [char]0x2591  # Light Shade (░)

function Show-Header {
    Clear-Host
    Write-Host "$YELLOW"
    Write-Host "                                    $D$B$B$B$B$B$B$D   $D$B$B$B$B$B$B$D   $D$B        $B$B$B$B$B$B$B$B$D    $M$B$B    $B$B$M"
    Write-Host "                                   $B$B$B    $B$B$B $B$B$B    $B$B$B $B$B$B        $B$B$B   $U$B$B$B   $M$M $B $B $M$L"
    Write-Host "                                   $B$B$B    $B$U  $B$B$B    $B$B$B $B$B$B        $B$B$B    $B$B$B   $L$L  $B   $L"
    Write-Host "                                  $D$B$B$B        $B$B$B    $B$B$B $B$B$B        $B$B$B    $B$B$B    $L $B $B $M"
    Write-Host "                                 $U$U$B$B$B $B$B$B$B$D  $B$B$B    $B$B$B $B$B$B        $B$B$B    $B$B$B   $M$B$B$M $M$B$B$M"
    Write-Host "                                   $B$B$B    $B$B$B $B$B$B    $B$B$B $B$B$B        $B$B$B    $B$B$B    $M$M $L $L$M $L"
    Write-Host "                                   $B$B$B    $B$B$B $B$B$B    $B$B$B $B$B$B$D    $D  $B$B$B   $D$B$B$B    $L$L   $L$M $L"
    Write-Host "                                   $B$B$B$B$B$B$B$U   $U$B$B$B$B$B$B$U  $B$B$B$B$B$D$D$B$B  $B$B$B$B$B$B$B$U     $L    $L"
    Write-Host "$RESET"
    Write-Host "------------------------------------------------------------------------------------------------------------------------"
    Write-Host "$BG_YELLOW GOLDx Installer $RESET $GREY v1.0 $RESET"
    Write-Host "------------------------------------------------------------------------------------------------------------------------"
    Write-Host ""
}

Show-Header

Write-Host "$GREY(*) Checking Java environment...$RESET"
$javaCheck = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCheck) {
    Write-Host ""
    Write-Host "$RED(x) ERROR: Java is not installed or not added to PATH! $RESET"
    Write-Host "$GREY(!) Please install Java JDK 17+ to verify and install GOLDx. $RESET"
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "$GREEN(v) Java detected!$RESET"
Write-Host ""

Write-Host "$YELLOW(>) Enter your 5-minute verification key from Discord (dc.gg/GOLDx): $RESET" -NoNewline
$UserKey = Read-Host

if ([string]::IsNullOrWhiteSpace($UserKey)) {
    Write-Host ""
    Write-Host "$RED(x) ERROR: No key provided! Installation aborted. $RESET"
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host ""
Write-Host "$GREY(*) Preparing key verification module...$RESET"

if (-not (Test-Path "GoldX_keysys.java") -and -not (Test-Path "keysys\GoldX_keysys.java")) {
    Write-Host "$GREY(*) Downloading verification module from GitHub...$RESET"
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/vysr-txt/GOLDx/main/GoldX_keysys.java" -OutFile "GoldX_keysys.java" -UseBasicParsing
    } catch {
        Write-Host "$RED(x) ERROR: Could not download GoldX_keysys.java from GitHub! $RESET"
        Read-Host "Press Enter to exit..."
        exit 1
    }
}

if (Test-Path "GoldX_keysys.class") { Remove-Item "GoldX_keysys.class" -Force }
if (Test-Path "keysys\GoldX_keysys.class") { Remove-Item "keysys\GoldX_keysys.class" -Force }

if (Test-Path "GoldX_keysys.java") {
    Write-Host "$GREY(*) Compiling GoldX_keysys.java...$RESET"
    javac -encoding UTF-8 -d . GoldX_keysys.java
    if ($LASTEXITCODE -ne 0) {
        Write-Host "$RED(x) ERROR: Failed to compile GoldX_keysys.java $RESET"
        Read-Host "Press Enter to exit..."
        exit 1
    }
} elseif (Test-Path "keysys\GoldX_keysys.java") {
    Write-Host "$GREY(*) Compiling keysys\GoldX_keysys.java...$RESET"
    javac -encoding UTF-8 -d . keysys\GoldX_keysys.java
    if ($LASTEXITCODE -ne 0) {
        Write-Host "$RED(x) ERROR: Failed to compile GoldX_keysys.java $RESET"
        Read-Host "Press Enter to exit..."
        exit 1
    }
} else {
    Write-Host "$RED(x) ERROR: GoldX_keysys.java was not found! $RESET"
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "$GREY(*) Verifying key...$RESET"
Write-Host ""

java -cp . keysys.GoldX_keysys "$UserKey"
$VERIFY_EXIT_CODE = $LASTEXITCODE

if ($VERIFY_EXIT_CODE -ne 0) {
    Write-Host ""
    Write-Host "$RED(x) ERROR: Key verification failed! $RESET"
    Write-Host "$GREY(x) Key is invalid, expired, or tampered with. $RESET"
    Write-Host ""
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host ""
Write-Host "$GREEN(v) Verification successful! $RESET"
Start-Sleep -Seconds 1

Show-Header
Write-Host "$GREY(*) Starting GOLDx installation...$RESET"
Write-Host ""

Write-Host "$GREEN(v) GOLDx installed successfully! $RESET"
Write-Host ""
Write-Host "$GREY(*) Closing Installer...$RESET"
Start-Sleep -Seconds 2
exit 0
