# WSL Bootstrap Scripts

This repo holds my preferred WSL setup scripts. The PowerShell script is the primary entry point and creates the WSL instance using the a config.yaml file.

May fail if you already have a WSL instance with the same name, so be sure to delete it first if you want to run this script.

## **Usage Instructions**

1. **Install the `YamlDotNet` Module** (if not already installed):
    
    ```powershell
    Install-Module -Name YamlDotNet -Scope CurrentUser -Force -AllowClobber
    ```
    
2. **Install the `Yaml` Cmdlets Module** (which uses **`YamlDotNet`**):
    
    ```powershell
    Install-Module -Name Yaml -Scope CurrentUser -Force -AllowClobber
    ```
    
3. **Save the Scripts and Configuration File** in a directory:
    - **`config.yaml`**
    - **`bootstrap.sh`**
    - **`wsl_setup.ps1`**

4. **Run the PowerShell Script**:
    
    ```powershell
    .\wsl_setup.ps1 -ConfigFile ".\config.yaml"
    ```
    