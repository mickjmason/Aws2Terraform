
function scanCloudwatchAlarms($region)
{
    $cwAlarms = Get-CWAlarm -Region $region
    
    $template = Get-Content .\CloudwatchAlarm.template.tf
    $cwAlarms |ForEach-Object {
        $template = $template.Replace("^name^",$_.AlarmName)
        $template = $template.Replace("^comparisonOperator^",$_.ComparisonOperator)
        $template = $template.Replace("^evaluationPeriods^",$_.EvaluationPeriods)
        $template = $template.Replace("^metricName^",$_.MetricName)
        $template = $template.Replace("^nameSpace^",$_.Namespace)
        $template = $template.Replace("^period^",$_.Period)
        $template = $template.Replace("^statistic^",$_.Statistic)
        $template = $template.Replace("^threshold^",$_.Threshold)
        $template = $template.Replace("^alarmDescription^",$_.AlarmDescription)
        Add-Content .\CloudwatchAlarm.tf  $template
    }
    
}

function performInventory($region)
{
    scanCloudwatchAlarms($region)

}
function main (){
    $regions = Get-AwsRegion | ForEach-Object {$_|Select-Object Region}
    $regions | ForEach-Object {$_| performInventory($_.Region)}
}

main