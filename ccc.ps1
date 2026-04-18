param(
	[string]$Path = (Join-Path $PSScriptRoot 'build/compile_commands.json'),
	[switch]$SpawnWatcher,
	[switch]$Worker,
	[long]$BaselineTicks = 0,
	[int]$TimeoutSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FileLastWriteTicks {
	param(
		[Parameter(Mandatory = $true)]
		[string]$TargetPath
	)

	if (-not (Test-Path -LiteralPath $TargetPath)) {
		return 0L
	}

	return (Get-Item -LiteralPath $TargetPath).LastWriteTimeUtc.Ticks
}

function Invoke-NormalizeCompileCommands {
	param(
		[Parameter(Mandatory = $true)]
		[string]$TargetPath
	)

	if (-not (Test-Path -LiteralPath $TargetPath)) {
		return $false
	}

	$content = [System.IO.File]::ReadAllText($TargetPath)
	$normalizedContent = [System.Text.RegularExpressions.Regex]::Replace(
		$content,
		'(?<![A-Za-z])([A-Z]):',
		{
			param($match)
			return $match.Groups[1].Value.ToLowerInvariant() + ':'
		}
	)

	if ($normalizedContent -ceq $content) {
		return $false
	}

	$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
	[System.IO.File]::WriteAllText($TargetPath, $normalizedContent, $utf8NoBom)
	return $true
}

function Start-NormalizeWatcher {
	param(
		[Parameter(Mandatory = $true)]
		[string]$TargetPath,
		[Parameter(Mandatory = $true)]
		[long]$InitialTicks,
		[Parameter(Mandatory = $true)]
		[int]$WaitSeconds
	)

	$currentShell = (Get-Process -Id $PID).Path
	$arguments = @(
		'-NoProfile'
		'-ExecutionPolicy'
		'Bypass'
		'-File'
		$PSCommandPath
		'-Path'
		$TargetPath
		'-Worker'
		'-BaselineTicks'
		$InitialTicks.ToString()
		'-TimeoutSeconds'
		$WaitSeconds.ToString()
	)

	Start-Process -FilePath $currentShell -ArgumentList $arguments -WindowStyle Hidden | Out-Null
}

if ($SpawnWatcher) {
	$ticks = Get-FileLastWriteTicks -TargetPath $Path
	Start-NormalizeWatcher -TargetPath $Path -InitialTicks $ticks -WaitSeconds $TimeoutSeconds
	exit 0
}

if ($Worker) {
	$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)

	while ([DateTime]::UtcNow -lt $deadline) {
		$currentTicks = Get-FileLastWriteTicks -TargetPath $Path

		if ($currentTicks -gt 0 -and ($BaselineTicks -eq 0 -or $currentTicks -ne $BaselineTicks)) {
			Start-Sleep -Milliseconds 250

			try {
				Invoke-NormalizeCompileCommands -TargetPath $Path | Out-Null
				exit 0
			}
			catch {
				Start-Sleep -Milliseconds 250
			}
		}

		Start-Sleep -Milliseconds 250
	}

	Invoke-NormalizeCompileCommands -TargetPath $Path | Out-Null
	exit 0
}

Invoke-NormalizeCompileCommands -TargetPath $Path | Out-Null
