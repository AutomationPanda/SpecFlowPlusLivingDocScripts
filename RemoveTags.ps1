# ----------------------------------------------------------------------------------------------------
# Notes
# ----------------------------------------------------------------------------------------------------

# This script removes tags from SpecFlow+ LivingDoc's FeatureData.json file.
# Removing tags scrubs LivingDoc reports of context-sensitive information, like banks.
# For example, BAML test reports should have tags for all other banks removed.
# Typically, this script should be run after the script to remove skipped tests from Feature Data.

# WARNING: Feature Data must be generated from a test assembly, not from a feature folder!



# ----------------------------------------------------------------------------------------------------
# Parameters
# ----------------------------------------------------------------------------------------------------

Param(
	[Parameter(Mandatory=$true)][string[]] $TagsToRemove,
	[Parameter(Mandatory=$true)][string] $FeatureDataPath,
	[Parameter(Mandatory=$true)][string] $PrunedFeatureDataPath
)



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data object.
# ----------------------------------------------------------------------------------------------------

function RemoveTagsFromFeatureData {
	
	Param(
		[Parameter(Mandatory=$true)][string[]] $Tags,
		[Parameter(Mandatory=$true)] $FeatureData
	)

	foreach ($Node in $FeatureData.Nodes) {
		RemoveTagsFromFolder $Tags $Node
	}
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data folder (or node).
# ----------------------------------------------------------------------------------------------------

function RemoveTagsFromFolder {
	
	Param(
		[Parameter(Mandatory=$true)][string[]] $Tags,
		[Parameter(Mandatory=$true)] $Folder
	)

	foreach ($SubFolder in $Folder.Folders) {
		RemoveTagsFromFolder $Tags $SubFolder
	}
	
	foreach ($Feature in $Folder.Features) {
		RemoveTagsFromFeature $Tags $Feature
	}
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data feature.
#	Removes tags from the feature.
# ----------------------------------------------------------------------------------------------------

function RemoveTagsFromFeature {

	Param(
		[Parameter(Mandatory=$true)][string[]] $Tags,
		[Parameter(Mandatory=$true)] $Feature
	)
	
	$Feature.Tags = @($Feature.Tags | Where-Object {-not ($Tags -contains $_)})

	foreach ($Scenario in $Feature.ScenarioDefinitions) {
		RemoveTagsFromScenario $Tags $Scenario
	}
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data scenario or scenario outline.
#	Removes tags from the scenario.
# ----------------------------------------------------------------------------------------------------

function RemoveTagsFromScenario {

	Param(
		[Parameter(Mandatory=$true)][string[]] $Tags,
		[Parameter(Mandatory=$true)] $Scenario
	)
	
	$Scenario.Tags = @($Scenario.Tags | Where-Object {-not ($Tags -contains $_)})

	if ($Scenario.Keyword -eq "Scenario Outline") {
		foreach ($Example in $Scenario.Examples) {
			RemoveTagsFromExample $Tags $Example
		}
	}
}



# ----------------------------------------------------------------------------------------------------
# Traversal Function:
#	Visits a Feature Data scenario outline example table.
#	Removes tags from the example table.
# ----------------------------------------------------------------------------------------------------

function RemoveTagsFromExample {

	Param(
		[Parameter(Mandatory=$true)][string[]] $Tags,
		[Parameter(Mandatory=$true)] $Example
	)
	
	$Example.Tags = @($Example.Tags | Where-Object {-not ($Tags -contains $_)})
}



# ----------------------------------------------------------------------------------------------------
# Read JSON LivingDoc files
# ----------------------------------------------------------------------------------------------------

Write-Host "Reading '$FeatureDataPath'"
$FeatureData = Get-Content -Raw -Path "$FeatureDataPath" | ConvertFrom-Json



# ----------------------------------------------------------------------------------------------------
# Remove tags from Feature Data
# ----------------------------------------------------------------------------------------------------

Write-Host "Removing tags from Feature Data"
Write-Host "Tags to remove:" $TagsToRemove
RemoveTagsFromFeatureData $TagsToRemove $FeatureData



# ----------------------------------------------------------------------------------------------------
# Save the new Feature Data to a JSON file
# ----------------------------------------------------------------------------------------------------

Write-Host "Saving the new Feature Data to '$PrunedFeatureDataPath'"
$FeatureData | ConvertTo-Json -Depth 20 | Out-File "$PrunedFeatureDataPath"
