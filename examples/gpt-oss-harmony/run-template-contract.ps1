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
    '## python',
    '## apply_patch',
    'to=python',
    'to=apply_patch',
    'to=python<|channel|>commentary<|message|>from math import pi',
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
    '<|start|>python to=assistant',
    '<|start|>apply_patch to=assistant',
    'FIRST_SYSTEM_INSTRUCTION',
    '<|start|>developer<|message|>LATER_DEVELOPER_INSTRUCTION<|end|>',
    '<|start|>developer<|message|>LATER_SYSTEM_INSTRUCTION<|end|>',
    'to=assistant<|channel|>commentary<|message|>[0] results<|end|>',
    'namespace functions'
)) {
    if ($output -notmatch [regex]::Escape($required)) { throw "Missing expected rendered fragment: $required" }
}
$firstInstruction = $output.IndexOf('FIRST_SYSTEM_INSTRUCTION')
$laterDeveloper = $output.IndexOf('LATER_DEVELOPER_INSTRUCTION')
$laterSystem = $output.IndexOf('LATER_SYSTEM_INSTRUCTION')
if ($firstInstruction -ge $laterDeveloper -or $laterDeveloper -ge $laterSystem) {
    throw 'Instruction message order changed'
}
$casePath = Join-Path ([System.IO.Path]::GetTempPath()) ('harmony-template-' + [guid]::NewGuid() + '.json')
try {
    $case = Get-Content -Raw -LiteralPath $Fixture | ConvertFrom-Json
    $case.builtin_tools = @()
    $case.tools = @($case.tools | Where-Object { $_.function.name -in @('python', 'apply_patch', 'normal_tool') })
    $case.messages = @(
        @{ role = 'system'; content = 'ORDINARY_FUNCTION_INSTRUCTION' },
        @{ role = 'user'; content = 'Calculate.' },
        @{ role = 'assistant'; tool_calls = @(@{ type = 'function'; function = @{ name = 'python'; arguments = @{ code = 'print(1)' } } }) },
        @{ role = 'tool'; content = '1' }
    )
    $case | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $casePath -Encoding utf8
    $ordinaryOutput = & $TestBinary --no-common --json $casePath $Template 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Ordinary-function template failed: $ordinaryOutput" }
    foreach ($required in @('type python', 'type apply_patch', 'to=functions.python', '<|start|>functions.python to=assistant')) {
        if (-not $ordinaryOutput.Contains($required)) { throw "Missing ordinary-function fragment: $required" }
    }
    if ($ordinaryOutput.Contains('to=python')) { throw 'Ordinary Python was rendered as a native recipient' }

    $case = Get-Content -Raw -LiteralPath $Fixture | ConvertFrom-Json
    foreach ($message in $case.messages) {
        if ($message.tool_calls) {
            foreach ($call in $message.tool_calls) {
                $call.function.arguments = $call.function.arguments | ConvertTo-Json -Depth 20 -Compress
            }
        }
    }
    $case | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $casePath -Encoding utf8
    $commonOutput = & $TestBinary --json $casePath $Template 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw "Serialized-argument common rendering failed: $commonOutput" }
    foreach ($recipient in @('browser.search', 'functions.python', 'functions.normal_tool')) {
        if ($commonOutput -notmatch ('to=' + [regex]::Escape($recipient) + '[^\r\n]*<\|message\|>\{')) {
            throw "Serialized arguments were not decoded for $recipient"
        }
    }
} finally {
    Remove-Item -LiteralPath $casePath -ErrorAction SilentlyContinue
}
[ordered]@{ status = 'PASS'; fixture = $Fixture; template = $Template } | ConvertTo-Json
