
function scanCloudwatchAlarms($region)
{
    $cwAlarms = Get-CWAlarm -Region $region
    
    $baseTemplate = Get-Content .\CloudwatchAlarm.tf.template
    $cwAlarms |ForEach-Object {
        $dimensions= ""
        $template = $baseTemplate
        Write-Host "Working on" + $_.AlarmName
        $template = $template.Replace("^name^",$_.AlarmName)
        $template = $template.Replace("^comparisonOperator^",$_.ComparisonOperator)
        $template = $template.Replace("^evaluationPeriods^",$_.EvaluationPeriods)
        $template = $template.Replace("^metricName^",$_.MetricName)
        $template = $template.Replace("^nameSpace^",$_.Namespace)
        $template = $template.Replace("^period^",$_.Period)
        $template = $template.Replace("^statistic^",$_.Statistic)
        $template = $template.Replace("^threshold^",$_.Threshold)
        $template = $template.Replace("^alarmDescription^",$_.AlarmDescription)
        $template = $template.Replace("^dimensions^",$_.Dimensions[0].Name + " = """ + $_.Dimensions.Value + """")
        Add-Content .\output\CloudwatchAlarm.tf  $template
    }
    
}

function performInventory($region)
{
    scanCloudwatchAlarms($region)

}
function main (){
    Write-Host "Beginning scan."
    $regions = Get-AwsRegion | ForEach-Object {$_|Select-Object Region}
    $regions | ForEach-Object {$_| performInventory($_.Region)}
}

main