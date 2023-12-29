param(
    [string] $Name = 'libdatachannel',
    [string] $Version = 'v0.19.1',
    [string] $Uri = 'https://github.com/sean-der/libdatachannel.git',
    [string] $Hash = '0e02e5a65de4216da6d9fbc9f79cfac2258e61bc',
    [switch] $ForceShared = $true
)

function Setup {
    Invoke-GitCheckout -Uri $Uri -Commit $Hash
}

function Clean {
    Set-Location $Path

    if ( Test-Path "build_${Target}" ) {
        Log-Information "Clean build directory (${Target})"
        Remove-Item -Path "build_${Target}" -Recurse -Force
    }
}

function Configure {
    Log-Information "Configure (${Target})"
    Set-Location $Path

   if ( $ForceShared -and ( $script:Shared -eq $false ) ) {
        $Shared = $true
    } else {
        $Shared = $script:Shared.isPresent
    }

    $OnOff = @('OFF', 'ON')
    $Options = @(
        $CmakeOptions
        "-DENABLE_SHARED:BOOL=$($OnOff[$Shared])"
        '-DUSE_MBEDTLS=BOOL=ON'
        '-DNO_WEBSOCKET=BOOL=ON'
        '-DNO_TESTS=BOOL=ON'
        '-DNO_EXAMPLES=BOOL=ON'
    )

    Invoke-External cmake -S . -B "build_${Target}" @Options
}

function Build {
    Log-Information "Build (${Target})"
    Set-Location $Path

    $Options = @(
        '--build', "build_${Target}"
        '--config', $Configuration
    )

    if ( $VerbosePreference -eq 'Continue' ) {
        $Options += '--verbose'
    }

    $Options += @(
        '--'
        '/consoleLoggerParameters:Summary'
        '/noLogo'
        '/p:UseMultiToolTask=true'
        '/p:EnforceProcessCountAcrossBuilds=true'
    )

    Invoke-External cmake @Options
}

function Install {
    Log-Information "Install (${Target})"
    Set-Location $Path

    $Options = @(
        '--install', "build_${Target}"
        '--config', $Configuration
    )

    if ( $Configuration -match "(Release|MinSizeRel)" ) {
        $Options += '--strip'
    }

    Invoke-External cmake @Options
}
