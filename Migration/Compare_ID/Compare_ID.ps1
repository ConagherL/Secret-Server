# Define the paths to the CSV files
$sourceCsv = "C:\temp\Source.csv"
$destinationCsv = "C:\temp\Destination.csv"
$outputCsv = "C:\temp\SecretIdComparison.csv"

# Import the CSV files into PowerShell objects
$sourceData = Import-Csv -Path $sourceCsv
$destinationData = Import-Csv -Path $destinationCsv

# Perform the comparison based on 'Secret Name'
$comparison = foreach ($srcRow in $sourceData) {
    $destRow = $destinationData | Where-Object { $_.'Secret Name' -eq $srcRow.'Secret Name' }
    
    if ($destRow) {
        # Handle multiple IDs by joining them into a comma-separated string if necessary
        $newSecretId = $destRow.'SecretId'
        
        # If there are multiple IDs (array), join them with commas
        if ($newSecretId -is [System.Array]) {
            $newSecretId = $newSecretId -join ','
        }
        
        # Output the Old SecretId, New SecretId, and Folder Path
        [PSCustomObject]@{
            'Secret Name' = $srcRow.'Secret Name'
            'Old SecretId' = $srcRow.'SecretId'
            'New SecretId' = $newSecretId
            'Folder Path' = $srcRow.'Folder Path'
        }
    }
}

# Export the comparison to a CSV file
$comparison | Export-Csv -Path $outputCsv -NoTypeInformation
Write-Host "Comparison completed. Output saved to $outputCsv"