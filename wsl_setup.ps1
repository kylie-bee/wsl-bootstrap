# PowerShell script to set up a new WSL distribution and execute the Linux bootstrap script
param (
    [string]$ConfigFile = ".\config.yaml"
)

# Function to parse YAML file
function Parse-Yaml {
    param (
        [string]$FilePath
    )
    if (-not (Test-Path $FilePath)) {
        Write-Output "Configuration file $FilePath not found."
        exit 1
    }
    $yamlContent = Get-Content $FilePath | Out-String
    $parsedYaml = $yamlContent | ConvertFrom-Yaml
    return $parsedYaml
}

# Parse the configuration file
$config = Parse-Yaml -FilePath $ConfigFile

# Extract configuration values
$distroName = $config.wsl_distro
$credentials = $config.credentials
$rootPassword = $credentials.root_password
$githubUsername = $credentials.github_username
$githubEmail = $credentials.github_email
$githubToken = $credentials.github_token

# Create an environment file from env_vars in the configuration file
$envFilePath = ".\.env"
$envVars = $config.env_vars | ForEach-Object { "$($_.Name)=$($_.Value)" }
$envContent = @"
ROOT_PASSWORD=$rootPassword
GITHUB_USERNAME=$githubUsername
GITHUB_EMAIL=$githubEmail
GITHUB_TOKEN=$githubToken
$envVars
"@
Set-Content -Path $envFilePath -Value $envContent

# Install and configure WSL
Write-Output "Setting up WSL distribution: $distroName"
wsl --install -d $distroName
if ($LASTEXITCODE -ne 0) {
    Write-Output "Error installing WSL distribution."
    exit 1
}

# Get the current script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Path to the bootstrap script
$bootstrapScriptPath = Join-Path $scriptDir "bootstrap.sh"

# Ensure the bootstrap script is executable
wsl -d $distroName chmod +x /mnt/c/$($bootstrapScriptPath -replace ":", "").replace("\", "/")

# Copy the environment file to WSL
wsl -d $distroName cp /mnt/c/$($envFilePath -replace ":", "").replace("\", "/") /mnt/c/$($scriptDir -replace ":", "").replace("\", "/")

# Run the bootstrap script inside WSL
wsl -d $distroName /mnt/c/$($bootstrapScriptPath -replace ":", "").replace("\", "/")

Write-Output "WSL setup complete!"
