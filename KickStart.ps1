function Write-OutputMessage { Param([parameter(Mandatory=$true)] $message)
    Write-Host $message -ForegroundColor Cyan 
}

function Write-InstructionMessage {	Param([parameter(Mandatory=$true)] $message)
    Write-Host $message -ForegroundColor Green 
}

function Install-ChocoPackage {
	Param(
		[parameter(Mandatory=$true)] $name,
		[parameter(Mandatory=$false)] $version
	)

	# get a list of packages, loop through them all to check if any is installed
	$chocList = powershell choco list -lo 
	foreach($chocoPackage in $chocList) {
		if ([string]::IsNullOrEmpty($version)) {
			$exists = $chocoPackage.ToLower().StartsWith($name.ToLower())
			
			if ($exists) {
				Write-Output "Package $name installed, skipping"
				return
			}
		}
		else {
			$exists = $chocoPackage.ToLower().StartsWith("$name $version".ToLower())
		
			if ($exists) {
				Write-Output "Package $name v$version installed, skipping"
				return
			}
		}		
	}

	if ([string]::IsNullOrEmpty($version)) {
		Write-Output "Package $name installing"
		choco install $name
	}
	else {
		Write-Output "Package $name installing specific version $version"
		choco install $name --version=$version
	}
}

Write-OutputMessage ""
Write-OutputMessage "=================================================================================================================================="
Write-OutputMessage "KICKSTART - Chocolatey package manager (this may take a while)"
Write-OutputMessage "=================================================================================================================================="

# CHOCOLATEY
$testChocoInstall = powershell choco -v
if(-not($testChocoInstall)){
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}
else{
    Write-Output "Chocolatey version $testChocoInstall is already installed"
}

Write-OutputMessage ""
Write-OutputMessage "=================================================================================================================================="
Write-OutputMessage "KICKSTART - Chocolatey packages (this may take a while)"
Write-OutputMessage "=================================================================================================================================="

# PACKAGES
Install-ChocoPackage "7zip"
Install-ChocoPackage "python2"
Install-ChocoPackage "nvm" "1.1.5"
Install-ChocoPackage "dotnet-sdk"
Install-ChocoPackage "nuget.commandline"

# NVM
Write-OutputMessage ""
Write-OutputMessage "=================================================================================================================================="
Write-OutputMessage "KICKSTART - NPM version switch"
Write-OutputMessage "=================================================================================================================================="

$nodeVersion = "14.15.4"
nvm install $nodeVersion
nvm use $nodeVersion

# ANGULAR
Write-OutputMessage ""
Write-OutputMessage "=================================================================================================================================="
Write-OutputMessage "KICKSTART - Angular installing (this will take a good amount of time)"
Write-OutputMessage "=================================================================================================================================="

Set-Location angular
$npm = "$env:NVM_HOME\v$nodeVersion\npm.cmd"
$npmArguments = "install yarn"
Start-Process $npm $npmArguments -NoNewWindow -Wait
yarn config set "strict-ssl" false
yarn install
Set-Location ..

Write-OutputMessage ""
Write-OutputMessage "=================================================================================================================================="
Write-OutputMessage "KICKSTART - Building API"
Write-OutputMessage "=================================================================================================================================="

Set-Location aspnet-core
dotnet build "NAME_OF_SOLUTION.Web.sln"

Write-OutputMessage ""
Write-OutputMessage "=================================================================================================================================="
Write-OutputMessage "KICKSTART - Running DB Migrator"
Write-OutputMessage "=================================================================================================================================="

Set-Location src
Set-Location NAME_OF_SOLUTION.Migrator
(Get-Content -path appsettings.json -Raw) -replace 'TestDb','NAME_OF_SOLUTION' | Set-Content -Path appsettings.json
dotnet run --project "NAME_OF_SOLUTION.Migrator.csproj"

Set-Location ..
Set-Location ..
Set-Location ..

Write-OutputMessage ""
Write-OutputMessage "=================================================================================================================================="
Write-OutputMessage "KICKSTART - Finished"
Write-OutputMessage "=================================================================================================================================="
Write-InstructionMessage "Usage:"
Write-InstructionMessage "In a new command terminal from the aspnet-core/src/NAME_OF_SOLUTION.Web.Host folder run 'dotnet run NAME_OF_SOLUTION.Web.Host.csproj'"
Write-InstructionMessage "Open the API https://localhost:44301/"
Write-InstructionMessage "In a new command terminal from the angular folder run 'npm run start'"
Write-InstructionMessage "Open the UI http://localhost:4200/"
Write-InstructionMessage "	default admin username: admin"
Write-InstructionMessage "	default admin password: 123qwe"
