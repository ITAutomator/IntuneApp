# This script installs the Microsoft Visual C++ Redistributable for Visual Studio 2015, 2017, and 2019.
#
# https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170
#
# Ensure TLS 1.2 for web downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define minimum required version
$minVersion = [Version]"14.0.0.0"

# Determine architecture (supports x64 and ARM64)
$arch = (Get-CimInstance -ClassName Win32_OperatingSystem).OSArchitecture.ToLower()

if ($arch -like "*arm*") {
    $platform = "ARM64"
} elseif ($arch -like "*64*") {
    $platform = "x64"
} else {
    $platform = "x86"
}

# Set download URL and installer path
switch ($platform) {
    "ARM64" {
        $vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.arm64.exe"
        $installerName = "vc_redist.arm64.exe"
    }
    "x64" {
        $vcRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        $installerName = "vc_redist.x64.exe"
    }
    default {
        Write-Warning "Unsupported architecture: $platform. Skipping install."
        return
    }
}
$tempInstaller = "$env:TEMP\$installerName"

# Function to get current VC++ Redistributable version from registry
function Get-VCRedistVersion {
    $regKeys = @(
        "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$platform",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\$platform"
    )
    foreach ($key in $regKeys) {
        if (Test-Path $key) {
            try {
                $ver = Get-ItemProperty -Path $key | Select-Object -ExpandProperty Version -ErrorAction SilentlyContinue
                if ($ver) {
                    # Match and remove all non-digit characters at the beginning of the string
                    $cleanVer = $ver -replace '^[^0-9]+', ''
                    return [Version]$cleanVer
                }
            } catch {}
        }
    }
    return $null
}

# Check current version
$currentVersion = Get-VCRedistVersion

if ($currentVersion -and $currentVersion -ge $minVersion) {
    Write-Host "Microsoft Visual C++ Redistributable ($platform) already installed (version $currentVersion)."
} else {
    Write-Host "Installing Microsoft Visual C++ Redistributable ($platform)..."

    # Download the installer
    Invoke-WebRequest -Uri $vcRedistUrl -OutFile $tempInstaller -UseBasicParsing

    # Silently install
    Start-Process -FilePath $tempInstaller -ArgumentList "/install", "/quiet", "/norestart" -Wait

    # Cleanup
    Remove-Item $tempInstaller -Force -ErrorAction SilentlyContinue

    # Verify installation
    $newVersion = Get-VCRedistVersion
    if ($newVersion -and $newVersion -ge $minVersion) {
        Write-Host "Successfully installed VC++ Redistributable ($platform) version $newVersion."
    } else {
        Write-Warning "Installation may have failed. Please check manually."
    }
}
