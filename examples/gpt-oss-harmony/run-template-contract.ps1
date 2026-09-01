[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $TestBinary,
    [string] $Template = (Join-Path $PSScriptRoot 'gpt-oss-native-tools.jinja'),
    [string] $Fixture = (Join-Path $PSScriptRoot 'harmony-native-template.json')
)

$ErrorActionPreference = 'Stop'
foreach ($path in @($TestBinary, $Template, $Fixture)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Required path not found: $path" }
}

$output = & $TestBinary --no-common --json $Fixture $Template 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) { throw "Jinja contract failed: $output" }
foreach ($required in @(
    'namespace browser',
    'namespace container',
    'namespace repo_browser',
    'to=browser.search',
    'to=container.exec',
    'to=repo_browser.print_tree',
    'to=repo_browser.search',
    'to=repo_browser.open_file',
    'to=repo_browser.list_dir',
    'to=repo_browser.apply_patch',
    'to=functions.normal_tool',
    '<|start|>browser.search to=assistant',
    '<|start|>container.exec to=assistant',
    '<|start|>repo_browser.print_tree to=assistant',
    '<|start|>repo_browser.search to=assistant',
    '<|start|>repo_browser.open_file to=assistant',
    '<|start|>repo_browser.list_dir to=assistant',
    '<|start|>repo_browser.apply_patch to=assistant',
    '<|start|>functions.normal_tool to=assistant',
    'namespace functions'
)) {
    if ($output -notmatch [regex]::Escape($required)) { throw "Missing expected rendered fragment: $required" }
}
[ordered]@{ status = 'PASS'; fixture = $Fixture; template = $Template } | ConvertTo-Json
