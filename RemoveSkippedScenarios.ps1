# ----------------------------------------------------------------------------------------------------
# Notes
# ----------------------------------------------------------------------------------------------------

# This script removes skipped tests from SpecFlow+ LivingDoc's FeatureData.json file.
# It requires both a FeatureData.json file and a TestExecution.json file.
# It removes any features and scenarios from FeatureData.json that do not have execution records.
# That way, we can generate HTML LivingDoc reports without the noise of skipped tests.

# WARNING: Feature Data must be generated from a test assembly, not from a feature folder!



# ----------------------------------------------------------------------------------------------------
# Parameters
# ----------------------------------------------------------------------------------------------------

Param(
	[Parameter(Mandatory=$true)][string] $TestExecutionPath,
	[Parameter(Mandatory=$true)][string] $FeatureDataPath,
	[Parameter(Mandatory=$true)][string] $PrunedFeatureDataPath
)



# ----------------------------------------------------------------------------------------------------
# Function: Get the hash value for a Test Execution scenario
# ----------------------------------------------------------------------------------------------------

function GenerateTestExecutionScenarioHash {

	Param(
		[Parameter(Mandatory=$true)] $Scenario
	)

	$ScenarioArgs = $Scenario.ScenarioArguments -join "|"
	$Scenario.FeatureFolderPath + "|||" + $Scenario.FeatureTitle + "|||" + $Scenario.ScenarioTitle + "|||" + $ScenarioArgs
}



# ----------------------------------------------------------------------------------------------------
# Function: Create a hash set for Test Execution scenarios
# ----------------------------------------------------------------------------------------------------

function CreateTestExecutionHashes {

	Param(
		[Parameter(Mandatory=$true)] $TestExecutionData
	)
	
	$HashedResults = New-Object System.Collections.Generic.HashSet[string]

	foreach ($Result in $TestExecutionData.ExecutionResults) {
		$Hash = GenerateTestExecutionScenarioHash $Result
		[void] $HashedResults.Add($Hash)
	}

	$HashedResults
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data object.
#	Prunes empty nodes.
# ----------------------------------------------------------------------------------------------------

function PruneFeatureData {
	
	Param(
		[Parameter(Mandatory=$true)] $FeatureData,
		[Parameter(Mandatory=$true)] $HashedResults
	)

	$FeatureData.Nodes = @($FeatureData.Nodes | Where-Object {-not (PruneNode $_ $HashedResults)})
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data node.
#	Prunes empty folders.
#	Returns true if the node should be pruned or false if it should be kept.
# ----------------------------------------------------------------------------------------------------

function PruneNode {
	
	Param(
		[Parameter(Mandatory=$true)] $Node,
		[Parameter(Mandatory=$true)] $HashedResults
	)

	$Node.Folders = @($Node.Folders | Where-Object {-not (PruneFolder $_ "" $HashedResults)})
	$Node.Features = @($Node.Features | Where-Object {-not (PruneFeature $_ "" $HashedResults)})

	($Node.Folders.Length + $Node.Features.Length) -eq 0
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data folder.
#	Prunes empty sub-folders and features.
#   Returns true if the folder should be pruned or false if it should be kept.
# ----------------------------------------------------------------------------------------------------

function PruneFolder {
	
	Param(
		[Parameter(Mandatory=$true)] $Folder,
		[Parameter(Mandatory=$true)] $Hash,
		[Parameter(Mandatory=$true)] $HashedResults
	)
	
	if ($Hash -eq "") {
		$NewHash = $Folder.Title
	}
	else {
		$NewHash = $Hash + "/" + $Folder.Title
	}

	$Folder.Folders = @($Folder.Folders | Where-Object {-not (PruneFolder $_ $NewHash $HashedResults)})
	$Folder.Features = @($Folder.Features | Where-Object {-not (PruneFeature $_ $NewHash $HashedResults)})

	($Folder.Folders.Length + $Folder.Features.Length) -eq 0
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data feature.
#	Prunes scenarios that do not have hashed results.
#   Returns true if the feature should be pruned or false if it should be kept.
# ----------------------------------------------------------------------------------------------------

function PruneFeature {

	Param(
		[Parameter(Mandatory=$true)] $Feature,
		[Parameter(Mandatory=$true)] $Hash,
		[Parameter(Mandatory=$true)] $HashedResults
	)
	
	$NewHash = $Hash + "|||" + $Feature.Title
	$Feature.ScenarioDefinitions = @($Feature.ScenarioDefinitions | Where-Object {-not (PruneScenario $_ $NewHash $HashedResults)})
	$Feature.ScenarioDefinitions.Length -eq 0
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data scenario or scenario outline.
#   Returns true if the scenario should be pruned or false if it should be kept.
# ----------------------------------------------------------------------------------------------------

function PruneScenario {

	Param(
		[Parameter(Mandatory=$true)] $Scenario,
		[Parameter(Mandatory=$true)] $Hash,
		[Parameter(Mandatory=$true)] $HashedResults
	)
	
	$Prune = $false
	$NewHash = $Hash + "|||" + $Scenario.Title + "|||"

	if ($Scenario.Keyword -eq "Scenario") {
		$Prune = -not $HashedResults.Contains($NewHash)
	}
	elseif ($Scenario.Keyword -eq "Scenario Outline") {
		$Scenario.Examples = @($Scenario.Examples | Where-Object {-not (PruneExampleTable $_ $NewHash $HashedResults)})
		$Prune = $Scenario.Examples.Length -eq 0
	}
	
	$Prune
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data scenario outline example table.
#	Prunes example rows that do not have hashed results.
#   Returns true if the example table should be pruned or false if it should be kept.
# ----------------------------------------------------------------------------------------------------

function PruneExampleTable {

	Param(
		[Parameter(Mandatory=$true)] $ExampleTable,
		[Parameter(Mandatory=$true)] $Hash,
		[Parameter(Mandatory=$true)] $HashedResults
	)
	
	$ExampleTable.Table.TableRows = @($ExampleTable.Table.TableRows | Where-Object {-not (PruneExampleRow $_ $Hash $HashedResults)})
	$ExampleTable.Table.TableRows.Length -eq 0
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data scenario outline example row.
#   Returns true if the example row should be pruned or false if it should be kept.
# ----------------------------------------------------------------------------------------------------

function PruneExampleRow {

	Param(
		[Parameter(Mandatory=$true)] $ExampleRow,
		[Parameter(Mandatory=$true)] $Hash,
		[Parameter(Mandatory=$true)] $HashedResults
	)
	
	$ScenarioArgs = $ExampleRow.Cells -join "|"
	$NewHash = $Hash + $ScenarioArgs
	-not $HashedResults.Contains($NewHash)
}



# ----------------------------------------------------------------------------------------------------
# Read JSON LivingDoc files
# ----------------------------------------------------------------------------------------------------

Write-Host "Reading '$FeatureDataPath'"
$FeatureData = Get-Content -Raw -Path "$FeatureDataPath" | ConvertFrom-Json

Write-Host "Reading '$TestExecutionPath'"
$TestExecution = Get-Content -Raw -Path "$TestExecutionPath" | ConvertFrom-Json



# ----------------------------------------------------------------------------------------------------
# Create a hash set for Test Execution scenarios
# ----------------------------------------------------------------------------------------------------

Write-Host "Hashing each Test Execution scenario from '$TestExecutionPath'"
$TestExecutionHashes = CreateTestExecutionHashes $TestExecution
Write-Host "$($TestExecutionHashes.Count) Test Execution scenario(s) found"



# ----------------------------------------------------------------------------------------------------
# Prune unexecuted scenarios from Feature Data
# ----------------------------------------------------------------------------------------------------

Write-Host "Pruning unexecuted scenarios from Feature Data"
PruneFeatureData $FeatureData $TestExecutionHashes



# ----------------------------------------------------------------------------------------------------
# Save the pruned Feature Data to a JSON file
# ----------------------------------------------------------------------------------------------------

Write-Host "Saving the pruned Feature Data to '$PrunedFeatureDataPath'"
$FeatureData | ConvertTo-Json -Depth 20 | Out-File "$PrunedFeatureDataPath"
