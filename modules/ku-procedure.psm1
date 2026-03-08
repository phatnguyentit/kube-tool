Function Execute-Procedure() {
    $ProcedureTemplate = Get-Template -TemplateType "procedure"

    $ProcedureSteps = $ProcedureTemplate.procedure

    foreach ($StepName in $ProcedureSteps) {
        Write-Host $StepName
        Write-Host $ProcedureSteps[$StepName]
        
        if ($StepName -eq 'wait') {
            Write-Host $ProcedureSteps.'wait'
        }
        elseif ($StepName -eq 'template') {
            $TemplateObject = $ProcedureSteps.'template'

            foreach ($Template in $TemplateObject.Keys) {
                Write-Host $Template
                Write-Host $StepObject[$Template]
            }
        }
    }
}