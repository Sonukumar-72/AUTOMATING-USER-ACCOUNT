# Read the users.csv file
$users = Import-Csv -Path "D:\AUTOMATING USER ACCOUNT\users.csv"

# Define log file path
$logFile = "D:\AUTOMATING USER ACCOUNT\user_management.log"

# Function to log actions
function Log-Action {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFile -Value $logMessage
}

# Check if script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as an administrator!" -ForegroundColor Red
    Log-Action "Script was not run as Administrator. Terminating execution."
    exit
}

# Iterate through each user in the file
foreach ($user in $users) {
    $username = $user.Username
    $password = $user.Password
    $role = $user.Role

    try {
        # Check if the user already exists
        $existingUser = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

        if ($existingUser) {
            Log-Action "User '$username' exists. Updating the account."
            # Update the password for the existing user
            Set-LocalUser -Name $username -Password (ConvertTo-SecureString -AsPlainText $password -Force)

            # Manage group membership
            if ($role -eq "Administrator") {
                if (-not (Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.Name -eq $username })) {
                    Add-LocalGroupMember -Group "Administrators" -Member $username
                    Log-Action "Added '$username' to the 'Administrators' group."
                }
            } elseif ($role -eq "Standard User") {
                if (Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.Name -eq $username }) {
                    Remove-LocalGroupMember -Group "Administrators" -Member $username
                    Log-Action "Removed '$username' from the 'Administrators' group."
                }
            }
        } else {
            Log-Action "Creating new user '$username'."
            # Create a new user
            New-LocalUser -Name $username -Password (ConvertTo-SecureString -AsPlainText $password -Force) -FullName $username -Description "Created by script."
            Log-Action "User '$username' created successfully."

            # Assign roles
            if ($role -eq "Administrator") {
                Add-LocalGroupMember -Group "Administrators" -Member $username
                Log-Action "Added '$username' to the 'Administrators' group."
            } elseif ($role -eq "Standard User") {
                Add-LocalGroupMember -Group "Users" -Member $username
                Log-Action "Added '$username' to the 'Users' group."
            }
        }

        # Create home directory for the user and set permissions
        $homeDir = "C:\Users\$username"
        if (-not (Test-Path -Path $homeDir)) {
            New-Item -ItemType Directory -Path $homeDir -Force | Out-Null
            Log-Action "Created home directory for '$username' at '$homeDir'."
        }

        # Set permissions on the home directory
        if (Test-Path -Path $homeDir) {
            $acl = Get-Acl -Path $homeDir
            $permission = New-Object System.Security.AccessControl.FileSystemAccessRule("$username", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($permission)
            Set-Acl -Path $homeDir -AclObject $acl
            Log-Action "Set full control permissions for '$username' on their home directory."
        } else {
            Log-Action "Failed to set permissions. Home directory '$homeDir' does not exist."
        }

    } catch {
        Log-Action "Error encountered for user '$username': $_"
        Write-Host "Error encountered for user '$username': $_" -ForegroundColor Red
    }
}
