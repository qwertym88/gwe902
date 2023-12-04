#!/ps1
# gen_e902.ps1 {path to E902_RTL_FACTORY} {E902_asic_rtl.fl}

param (
    $CODE_BASE_PATH,
    $FL_NAME = "E902_asic_rtl.fl"
)
$OUT_NAME = "opene902.v"
Remove-Item $OUT_NAME

$files = (Get-Content $CODE_BASE_PATH/gen_rtl/filelists/$FL_NAME) -match '\.[vh]$' -replace "\$\{CODE_BASE_PATH\}", ${CODE_BASE_PATH} 
foreach ($file in $files) {
    Write-Host "Appending $file to $OUT_NAME..."
    Get-Content $file | Add-Content $OUT_NAME
}