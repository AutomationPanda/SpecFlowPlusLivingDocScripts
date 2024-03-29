# SpecFlow+ LivingDoc Scripts

This repository contains PowerShell scripts for modifying
[SpecFlow+ LivingDoc](https://docs.specflow.org/projects/specflow-livingdoc/en/latest/index.html) reports.
Please read my article,
[Improving Teamwork with SpecFlow+ LivingDoc](https://automationpanda.com/2021/02/09/improving-teamwork-with-specflow-livingdoc/),
to learn more about the value LivingDoc provides.


## Why Modify LivingDoc?

SpecFlow+ LivingDoc is a great way to turn Gherkin feature files into living documentation.
They can also include high-level test results.
However, you might need to modify some of the data you put into your reports.
For example, you may need to remove certain scenarios or scrub certain tags for data protection.

By default, LivingDoc generates an HTML report.
However, you can make LivingDoc generate a JSON file containing
[feature data JSON files](https://docs.specflow.org/projects/specflow-livingdoc/en/latest/LivingDocGenerator/CLI/livingdoc-feature-data.html).
You can then modify this feature data and use it to generate a modified HTML report.


## Scripts

These scripts are written in PowerShell.

1. [RemoveSkippedScenarios.ps1](RemoveSkippedScenarios.ps1):
   * Takes in a feature data JSON file and a test execution JSON file
   * Identifies all executed test scenarios in the test exection JSON file
   * Removes all unexecuted scenarios from the feature data
   * Generates a new feature data JSON file for the pruned data
2. [RemoveTags.ps1](RemoveTags.ps1)
   * Takes in a list of tags and a feature data JSON file
   * Removes the tags from all features, scenarios, and examples tables in the feature data
   * Generates a new feature data JSON file without the tags


## Steps

The scripts in this repository modify feature data JSON files.
Here are the steps for using them from PowerShell:

1. Generate a feature data JSON file from a SpecFlow test assembly (.dll).
   * `livingdoc test-assembly --output-type JSON <testAssembly>`
2. Remove skipped scenarios from the feature data JSON file.
   * `RemoveSkippedScenarios.ps1 <testExecutionJson> <featureDataJson> <prunedFeatureDataJson>`
3. Remove a set of tags from the feature data JSON file.
   * `RemoveTags.ps1 <tagsToRemove> <featureDataJson> <prunedFeatureDataJson>`
4. Generate a LivingDoc HTML report with the modified feature data JSON file.
   * `livingdoc feature-data <featureDataJson>`


## Example Execution

In PowerShell:

```powershell
PS> livingdoc test-assembly --output-type JSON .\<YourAssembly>.dll  
Framework: .NET 5.0.15
<OutputDir>\FeatureData.json was successfully generated.

PS> RemoveSkippedScenarios.ps1 <OutputDir>\TestExecution.json <OutputDir>\FeatureData.json NoSkippedFeatureData.json
Reading '<OutputDir>\FeatureData.json'
Reading '<OutputDir>\TestExecution.json'
Hashing each Test Execution scenario from '<OutputDir>\TestExecution.json'
1 Test Execution scenario(s) found
Pruning unexecuted scenarios from Feature Data
Saving the pruned Feature Data to 'NoSkippedFeatureData.json'

PS> RemoveTags.ps1 -TagsToRemove web, mobile, ignore -FeatureDataPath NoSkippedFeatureData.json -PrunedFeatureDataPath FinalizedFeatureData.json
Reading 'NoSkippedFeatureData.json'
Removing tags from Feature Data
Tags to remove: web, mobile, ignore
Saving the new Feature Data to 'FinalizedFeatureData.json'

PS> livingdoc feature-data FinalizedFeatureData.json --output-type HTML -t <OutputDir>\TestExecution.json
Framework: .NET 5.0.15
<OutputDir>\LivingDoc.html was successfully generated.
```


## Links

* [SpecFlow](https://specflow.org/)
* [SpecFlow+ LivingDoc](https://specflow.org/plus/livingdoc/)
* [SpecFlow+ LivingDoc documentation](https://docs.specflow.org/projects/specflow-livingdoc/en/latest/)
