$base = "c:\development\Salah-App"
$dirs = @(
    "lib\core\widgets",
    "lib\features\auth\controller",
    "lib\features\auth\data\models",
    "lib\features\auth\data\repositories",
    "lib\features\auth\data\services",
    "lib\features\auth\presentation\bindings",
    "lib\features\auth\presentation\screens",
    "lib\features\prayer\controller",
    "lib\features\prayer\data\models",
    "lib\features\prayer\data\repositories",
    "lib\features\prayer\data\services",
    "lib\features\prayer\presentation\bindings",
    "lib\features\prayer\presentation\screens",
    "lib\features\prayer\presentation\widgets",
    "lib\features\family\controller",
    "lib\features\family\data\models",
    "lib\features\family\data\repositories",
    "lib\features\family\data\services",
    "lib\features\family\presentation\bindings",
    "lib\features\family\presentation\screens",
    "lib\features\family\presentation\widgets",
    "lib\features\settings\controller",
    "lib\features\settings\data\services",
    "lib\features\settings\presentation\bindings",
    "lib\features\settings\presentation\screens",
    "lib\features\notifications\controller",
    "lib\features\notifications\data\models",
    "lib\features\notifications\data\services",
    "lib\features\notifications\presentation\screens",
    "lib\features\onboarding\controller",
    "lib\features\onboarding\presentation\screens",
    "lib\features\profile\controller",
    "lib\features\profile\presentation\screens",
    "lib\features\splash\presentation\screens",
    "lib\shared\data\models",
    "lib\shared\data\repositories"
)
foreach ($d in $dirs) {
    $path = Join-Path $base $d
    New-Item -ItemType Directory -Path $path -Force | Out-Null
}
Write-Host "All directories created successfully!"
