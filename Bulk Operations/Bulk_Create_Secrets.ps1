# Delinea Secret Server Bulk Creation Script using REST API
# This script creates a folder structure and populates it with secrets according to specified requirements
# Requirements:
# - Root folder: "Oznog Heavy Industries"
# - 500 folders with random names (10 with spaces at beginning/end)
# - ~3000 secrets with 2-word names (20% duplicated, 1% of non-duplicates with spaces at beginning/end)

# Configuration parameters
$SecretServerUrl = "YOURSSURL"  # Replace with your Secret Server URL
$RootFolderName = "The Biggest Secret"

# Prompt for credentials securely instead of hardcoding them
Write-Host "Please enter your Secret Server credentials..." -ForegroundColor Green
$Credential = Get-Credential -Message "Enter credentials for Secret Server" -Title "Secret Server Authentication"
$TotalFolders = 500
$FoldersWithSpaces = 10
$TotalSecrets = 3000
$DuplicateSecretPercentage = 0.20  # 20% of secrets will have duplicate names
$SpacedSecretPercentage = 0.01     # 1% of non-duplicated secrets will have spaces at beginning/end
$PasswordTemplate = "Password"     # Use either "Password" or "Web Password"

# Word lists for generating random names
$AdjectiveList = @(
    "Red", "Blue", "Green", "Yellow", "Purple", "Orange", "Black", "White", "Gray",
    "Shiny", "Dull", "Bright", "Dark", "Loud", "Quiet", "Fast", "Slow", "Hot", "Cold",
    "Big", "Small", "Tall", "Short", "Heavy", "Light", "Hard", "Soft", "Rough", "Smooth",
    "Sharp", "Blunt", "Clean", "Dirty", "New", "Old", "Fresh", "Stale", "Wet", "Dry",
    "Rich", "Poor", "Full", "Empty", "Deep", "Shallow", "High", "Low", "Wide", "Narrow",
    "Long", "Short", "Thick", "Thin", "Strong", "Weak", "Bold", "Shy", "Brave", "Cowardly",
    "Happy", "Sad", "Angry", "Calm", "Loud", "Quiet", "Bitter", "Sweet", "Sour", "Salty",
    "Early", "Late", "Young", "Old", "Pretty", "Ugly", "Kind", "Mean", "Wise", "Foolish",
    "Wild", "Tame", "Odd", "Even", "Open", "Closed", "Public", "Private", "Rare", "Common",
    "Simple", "Complex", "Easy", "Hard", "Safe", "Dangerous", "Right", "Wrong", "Real", "Fake"
)

$NounList = @(
    "Apple", "Ball", "Cat", "Dog", "Eagle", "Fish", "Goat", "Horse", "Igloo", "Jacket",
    "Key", "Lion", "Mouse", "Notebook", "Orange", "Pencil", "Queen", "Rabbit", "Snake", "Tiger",
    "Umbrella", "Violin", "Whale", "Xylophone", "Yacht", "Zebra", "Airplane", "Book", "Car", "Door",
    "Elephant", "Flower", "Guitar", "Hat", "Island", "Jungle", "Kite", "Lamp", "Mountain", "Nest",
    "Ocean", "Piano", "Quilt", "River", "Sun", "Tree", "Universe", "Volcano", "Window", "Box",
    "Cloud", "Diamond", "Earth", "Fire", "Gold", "Heart", "Ice", "Jewel", "King", "Leaf",
    "Moon", "Night", "Oasis", "Planet", "Queen", "Rainbow", "Star", "Time", "Unicorn", "Village",
    "Water", "Year", "Zone", "Ant", "Bridge", "Cake", "Desk", "Engine", "Flag", "Globe",
    "House", "Ink", "Jar", "Knife", "Lock", "Map", "Needle", "Owl", "Paper", "Quilt", "Road", "Ship"
)

$TechnologyWords = @(
    "Server", "Network", "Database", "Cloud", "Router", "Switch", "Firewall", "Computer",
    "System", "Application", "Software", "Hardware", "Platform", "Interface", "Protocol",
    "Backup", "Storage", "Memory", "Processor", "Security", "Encryption", "Authentication",
    "Certificate", "Container", "Virtual", "Machine", "Cluster", "Pipeline", "Framework",
    "Library", "Module", "Function", "Service", "Endpoint", "Gateway", "Proxy", "Cache",
    "Queue", "Load", "Balancer", "Monitor", "Logger", "Debugger", "Compiler", "Algorithm",
    "Code", "Script", "Program", "API", "SDK", "CLI", "GUI", "Dashboard", "Report", "Metric"
)

# Helper functions for generating random names
function Get-RandomWord($wordList) {
    return $wordList | Get-Random
}

function Get-RandomSecretName {
    $adjective = Get-RandomWord -wordList $AdjectiveList
    $noun = Get-RandomWord -wordList ($NounList + $TechnologyWords)
    return "$adjective $noun"
}

function Get-RandomFolderName {
    $nameType = Get-Random -Minimum 1 -Maximum 4
    
    switch ($nameType) {
        1 { # Department-style name
            $depts = @("IT", "HR", "Finance", "Marketing", "Sales", "Operations", "Engineering", "Support", "Legal", "Executive")
            $subDepts = @("Team", "Group", "Department", "Division", "Unit", "Office", "Staff", "Management")
            return "$(Get-RandomWord -wordList $depts) $(Get-RandomWord -wordList $subDepts)"
        }
        2 { # Project-style name
            $prefixes = @("Project", "Initiative", "Program", "Task Force", "Workgroup")
            return "$(Get-RandomWord -wordList $prefixes) $(Get-RandomWord -wordList $TechnologyWords)"
        }
        3 { # Environment-style name
            $envs = @("Dev", "Test", "QA", "Staging", "Production", "DR", "Backup")
            return "$(Get-RandomWord -wordList $envs) $(Get-RandomWord -wordList $TechnologyWords)"
        }
        4 { # Random two words
            return "$(Get-RandomWord -wordList $AdjectiveList) $(Get-RandomWord -wordList $NounList)"
        }
    }
}

function Add-SpaceToName($name, $position) {
    if ($position -eq "start") {
        return " $name"
    } else {
        return "$name "
    }
}

# REST API Functions
function Get-AuthToken {
    param (
        [System.Management.Automation.PSCredential]$Credential
    )
    
    # Extract username and password from credential object
    $Username = $Credential.UserName
    $Password = $Credential.GetNetworkCredential().Password
    
    # Authenticate to Secret Server via REST API
    $AuthBody = @{
        username = $Username
        password = $Password
        grant_type = "password"
    }

    try {
        Write-Host "Authenticating as $Username..."
        $response = Invoke-RestMethod -Uri "$SecretServerUrl/oauth2/token" -Method Post -Body $AuthBody -ContentType "application/x-www-form-urlencoded"
        return $response.access_token
    }
    catch {
        Write-Error "Authentication failed: $_"
        
        # Provide more detailed error information if available
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            Write-Error "HTTP Status Code: $statusCode"
            
            if ($statusCode -eq 401) {
                Write-Error "Invalid username or password. Please check your credentials."
            }
        }
        
        exit
    }
}

function Invoke-SecretServerApi {
    param (
        [string]$EndPoint,
        [string]$Method = "GET",
        [object]$Body = $null,
        [string]$ContentType = "application/json",
        [string]$AuthToken
    )

    $Headers = @{
        "Authorization" = "Bearer $AuthToken"
        "Accept" = "application/json"
    }

    $Uri = "$SecretServerUrl/api/v1/$EndPoint"
    $BodyJson = if ($Body) { $Body | ConvertTo-Json -Depth 10 } else { $null }

    try {
        if ($Method -eq "GET") {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers
        }
        else {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -Body $BodyJson -ContentType $ContentType
        }
    }
    catch {
        Write-Error "API call to $Uri failed: $_"
        Write-Error "Response: $($_.Exception.Response.GetResponseStream())"
        return $null
    }
}

function Get-SecretTemplateId {
    param (
        [string]$TemplateName,
        [string]$AuthToken
    )

    $Templates = Invoke-SecretServerApi -EndPoint "secret-templates" -AuthToken $AuthToken
    $Template = $Templates.records | Where-Object { $_.name -eq $TemplateName }
    
    if ($Template) {
        return $Template.id
    }
    else {
        Write-Error "Template '$TemplateName' not found."
        exit
    }
}

function New-SSFolder {
    param (
        [string]$FolderName,
        [int]$ParentFolderId,
        [string]$AuthToken
    )

    $Body = @{
        folderName = $FolderName
        parentFolderId = $ParentFolderId
        inheritPermissions = $true
    }

    $Response = Invoke-SecretServerApi -EndPoint "folders" -Method "POST" -Body $Body -AuthToken $AuthToken
    
    if ($Response) {
        Write-Host "  Created folder: $FolderName (ID: $($Response.id))"
        return $Response.id
    }
    else {
        Write-Error "Failed to create folder: $FolderName"
        return $null
    }
}

function New-SSSecret {
    param (
        [string]$SecretName,
        [int]$FolderId,
        [int]$TemplateId,
        [hashtable]$FieldValues,
        [string]$AuthToken
    )

    # Get a fresh stub for this folder and template
    $SecretStub = Get-SecretStub -TemplateId $TemplateId -FolderId $FolderId -AuthToken $AuthToken
    
    # Update basic properties
    $SecretStub.name = $SecretName
    
    # Update field values based on field names
    foreach ($fieldName in $FieldValues.Keys) {
        $itemToUpdate = $SecretStub.items | Where-Object { $_.fieldName -eq $fieldName }
        if ($itemToUpdate) {
            $itemToUpdate.itemValue = $FieldValues[$fieldName]
        }
        else {
            Write-Warning "Field '$fieldName' not found in template. Available fields: $($SecretStub.items.fieldName -join ', ')"
        }
    }

    $Response = Invoke-SecretServerApi -EndPoint "secrets" -Method "POST" -Body $SecretStub -AuthToken $AuthToken
    
    if ($Response) {
        Write-Host "    Created secret: $SecretName (ID: $($Response.id))"
        return $Response.id
    }
    else {
        Write-Error "Failed to create secret: $SecretName"
        return $null
    }
}

function Get-SecretStub {
    param (
        [int]$TemplateId,
        [int]$FolderId,
        [string]$AuthToken
    )

    # Get a secret stub for the specified template and folder
    $EndPoint = "secrets/stub?secretTemplateId=$TemplateId&folderId=$FolderId"
    $Stub = Invoke-SecretServerApi -EndPoint $EndPoint -AuthToken $AuthToken
    
    if ($Stub) {
        return $Stub
    }
    else {
        Write-Error "Failed to get stub for template ID: $TemplateId and folder ID: $FolderId"
        exit
    }
}

# Main script
Write-Host "Connecting to Secret Server at $SecretServerUrl..."
if ($Credential) {
    $AuthToken = Get-AuthToken -Credential $Credential
    Write-Host "Authentication successful." -ForegroundColor Green
}
else {
    Write-Error "No credentials provided. Exiting script."
    exit
}

# Get template ID
$TemplateId = Get-SecretTemplateId -TemplateName $PasswordTemplate -AuthToken $AuthToken
Write-Host "Using template: $PasswordTemplate (ID: $TemplateId)"

# Create the root folder
Write-Host "Creating root folder: $RootFolderName"
$RootFolderId = New-SSFolder -FolderName $RootFolderName -ParentFolderId -1 -AuthToken $AuthToken

if (-not $RootFolderId) {
    Write-Error "Failed to create root folder. Exiting."
    exit
}

# Generate folder names
Write-Host "Generating $TotalFolders folder names..."
$folderNames = @()
for ($i = 1; $i -le $TotalFolders; $i++) {
    $folderName = Get-RandomFolderName
    $folderNames += $folderName
}

# Add spaces to some folder names
$spacedFolderIndices = 1..$TotalFolders | Get-Random -Count $FoldersWithSpaces
foreach ($index in $spacedFolderIndices) {
    $position = if ((Get-Random -Minimum 0 -Maximum 2) -eq 0) { "start" } else { "end" }
    $folderNames[$index - 1] = Add-SpaceToName -name $folderNames[$index - 1] -position $position
}

# Create the folders
$folderIdMap = @{}
Write-Host "Creating $TotalFolders folders under the root folder..."
for ($i = 0; $i -lt $TotalFolders; $i++) {
    $folderName = $folderNames[$i]
    Write-Host "  Creating folder ($($i+1)/$TotalFolders): $folderName"
    $folderId = New-SSFolder -FolderName $folderName -ParentFolderId $RootFolderId -AuthToken $AuthToken
    
    if ($folderId) {
        $folderIdMap[$folderName] = $folderId
    }
    else {
        Write-Warning "Failed to create folder: $folderName. Continuing..."
    }
}

# Generate secret names
Write-Host "Generating secret names..."
$secretNames = @()
$uniqueSecretCount = [math]::Floor($TotalSecrets * (1 - $DuplicateSecretPercentage))
$duplicateSecretCount = $TotalSecrets - $uniqueSecretCount

# Generate unique secret names
for ($i = 1; $i -le $uniqueSecretCount; $i++) {
    $secretName = Get-RandomSecretName
    $secretNames += $secretName
}

# Handle spaces for some unique secret names
$spacedSecretCount = [math]::Floor($uniqueSecretCount * $SpacedSecretPercentage)
$spacedSecretIndices = 1..$uniqueSecretCount | Get-Random -Count $spacedSecretCount
foreach ($index in $spacedSecretIndices) {
    $position = if ((Get-Random -Minimum 0 -Maximum 2) -eq 0) { "start" } else { "end" }
    $secretNames[$index - 1] = Add-SpaceToName -name $secretNames[$index - 1] -position $position
}

# Generate duplicate secret names
$secretsToDuplicate = $secretNames | Get-Random -Count $duplicateSecretCount
$secretNames += $secretsToDuplicate

# Shuffle the secret names
$secretNames = $secretNames | Sort-Object { Get-Random }

# Create the secrets
Write-Host "Creating $TotalSecrets secrets across all folders..."
$secretsPerFolder = [math]::Ceiling($TotalSecrets / $TotalFolders)
$secretIndex = 0
$successCount = 0
$errorCount = 0

foreach ($folderName in $folderNames) {
    if (-not $folderIdMap.ContainsKey($folderName)) {
        Write-Warning "Folder not found: $folderName. Skipping..."
        continue
    }

    $folderId = $folderIdMap[$folderName]
    $folderSecretCount = [math]::Min($secretsPerFolder, ($TotalSecrets - $secretIndex))
    
    Write-Host "  Creating $folderSecretCount secrets in folder: $folderName"
    
    for ($i = 0; $i -lt $folderSecretCount; $i++) {
        if ($secretIndex -ge $TotalSecrets) {
            break
        }
        
        $secretName = $secretNames[$secretIndex]
        $password = [System.Guid]::NewGuid().ToString()
        
        # Prepare secret fields based on template
        $FieldValues = @{}
        
        if ($PasswordTemplate -eq "Password") {
            $FieldValues["password"] = $password
            $FieldValues["notes"] = "Auto-generated secret"
        }
        elseif ($PasswordTemplate -eq "Web Password") {
            $FieldValues["password"] = $password
            $FieldValues["url"] = "https://example.com"
            $FieldValues["username"] = "user$($secretIndex)"
            $FieldValues["notes"] = "Auto-generated secret"
        }
        
        # Create a new secret
        $secretId = New-SSSecret -SecretName $secretName -FolderId $folderId -TemplateId $TemplateId -FieldValues $FieldValues -AuthToken $AuthToken
        
        if ($secretId) {
            $successCount++
        }
        else {
            $errorCount++
        }
        
        $secretIndex++
    }
}

Write-Host "Completed creating folder structure and secrets."
Write-Host "Summary:"
Write-Host "  Root folder: $RootFolderName (ID: $RootFolderId)"
Write-Host "  Folders created: $($folderIdMap.Count) of $TotalFolders"
Write-Host "  Secrets created: $successCount of $TotalSecrets"
Write-Host "  Errors: $errorCount"

if ($errorCount -gt 0) {
    Write-Warning "Some operations failed. Check the log for details."
}