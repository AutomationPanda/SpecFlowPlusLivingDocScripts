# SpecFlow+ LivingDoc Scripts

This repository contains PowerShell scripts for modifying
[SpecFlow+ LivingDoc](https://docs.specflow.org/projects/specflow-livingdoc/en/latest/index.html) reports.


## Why Modify LivingDoc?

SpecFlow+ LivingDoc is a great way to turn Gherkin feature files into living documentation.
They can also include high-level test results.
However, you might need to modify some of the data you put into your reports.
For example, you may need to remove certain scenarios or scrub certain tags for data protection.

By default, LivingDoc generates an HTML report.
However, you can make LivingDoc generate a JSON file containing
[feature data JSON files](https://docs.specflow.org/projects/specflow-livingdoc/en/latest/LivingDocGenerator/CLI/livingdoc-feature-data.html).
You can then modify this feature data and use it to generate a modified HTML report.
The scripts in this repository modify feature data JSON files.
Here are the steps for using them:

### PreRequisites
1. clone / download the repo / copy the .ps1 scripts
2. make them executable, e.g. [Set-ExecutionPolicy](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.2#example-1-set-an-execution-policy) or [unblock](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.2#example-7-unblock-a-script-to-run-it-without-changing-the-execution-policy)
3. add the location of the scripts to your OS path so you can run them from anywhere

1. Generate a feature data JSON file from a SpecFlow test assembly (.dll) using `livingdoc test-assembly --output-type JSON <testAssembly>`.
     -  from your project's output dir
```
PS> livingdoc.exe test-assembly --output-type JSON .\<YourAssembly>.dll  

Framework: .NET 5.0.15
<OutputDir>\FeatureData.json was successfully generated.

```
  
2. Run the feature data JSON modification script(s).
      - example with [RemoveSkippedScenarios.ps1](RemoveSkippedScenarios.ps1):
```
PS> RemoveSkippedScenarios.ps1 <OutputDir>\TestExecution.json  <OutputDir>\FeatureData.json result.json

Reading '<OutputDir>\FeatureData.json'
Reading '<OutputDir>\TestExecution.json'
Hashing each Test Execution scenario from '<OutputDir>\TestExecution.json'
1 Test Execution scenario(s) found
Pruning unexecuted scenarios from Feature Data
Saving the pruned Feature Data to 'result.json' 
```
   
3. Generate a LivingDoc HTML report with the modified feature data JSON file using `livingdoc feature-data <featureDataJson>`.
```
PS> livingdoc.exe feature-data .\result.json --output-type HTML -t <OutputDir>\TestExecution.json
Framework: .NET 5.0.15
<OutputDir>\LivingDoc.html was successfully generated.

```
4. Open in your default browser `PS> <OutputDir> Invoke-Item .\LivingDoc.html`


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


## Links

* [SpecFlow](https://specflow.org/)
* [SpecFlow+ LivingDoc](https://specflow.org/plus/livingdoc/)
* [SpecFlow+ LivingDoc documentation](https://docs.specflow.org/projects/specflow-livingdoc/en/latest/)
