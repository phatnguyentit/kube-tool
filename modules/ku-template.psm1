Function Get-Template([string]$TemplateType) {
  $TemplateLocation = [System.IO.Path]::Combine($PWD, "ku-template", $TemplateType)
  
  $SortedTemplates = Get-ChildItem -Path $TemplateLocation -Recurse -Filter "*.yaml" -File | Sort-Object Name | ToArray
  $Option = Get-Option-From-List -Options $SortedTemplates -Prompt 'Which template do you want?'

  if ($null -ne $Option) {
     
    $Path = [System.IO.Path]::Combine($TemplateLocation, $Option.Value);
    # Write-Warning "Loading template $($Option.Value)"
    return ConvertFrom-Yaml (Get-Content -Path $Path -Raw)
  }
   
  return $null;
}