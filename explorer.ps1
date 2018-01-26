#Let's start with a fresh screen
Clear-Host

#Create constants for output files
$Global:terraform = "C:\development\terraform\terraform.exe"
$Global:baseFolder = "C:\development\Aws2Terraform"
$Global:outputFolder = "$Global:baseFolder\output"
$Global:aws_cloudwatch_metric_alarm_template = ".\templates\aws_cloudwatch_metric_alarm.tf.template"
$Global:aws_route53_health_check_template = ".\templates\aws_route53_health_check.tf.template"


function renameOldFiles(){
    $filedate = Get-Date -format "yyyy-M-dd-HH-mm-ss"
    $files = Get-ChildItem -Path $Global:outputFolder -Filter "aws_*" |Rename-Item -NewName {$_.name -replace '.tf',$filedate }
    
}

function wrapInQuotes($list)
{
    $returnValue =""
    $list|ForEach-Object {
        $returnValue += """" + $_ + ""","
    }
    if($returnValue -ne ""){
        $returnValue = $returnValue -replace ".$"
    }
    return $returnValue
}
function scanCloudwatchAlarms($region)
{
    $regions = Get-AwsRegion | ForEach-Object {$_|Select-Object Region}
    $regions | ForEach-Object {
    $cwAlarms = Get-CWAlarm -Region $_.Region
    
    $baseTemplate = Get-Content $Global:aws_cloudwatch_metric_alarm_template
    $cwAlarms |ForEach-Object {
        $actions= ""
        $template = $baseTemplate
        Write-Host "Working on " $_.AlarmName
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
        $_.AlarmActions|ForEach-Object{
            $actions += """" + $_ + ""","
        }
        if($actions.Substring($actions.Length-1) -eq ",")
        {
            $actions = $actions -Replace ".$" 
        }
        $template = $template.Replace("^alarmActions^",$actions)
        Add-Content $Global:outputFolder\aws_cloudwatch_metric_alarms.tf  $template
    }

}
    
}
function scanR53HealthChecks()
{
    $healthChecks = Get-R53HealthCheckList
    $baseTemplate = Get-Content $Global:aws_route53_health_check_template
    $healthChecks | ForEach-Object {
        Write-Host "Working on " $_.Id
        $template = $baseTemplate
        $tags = ""
        $regions = ""
        if($_.HealthCheckConfig.FullyQualifiedDomainName -ne "") {
        $endpoint = "fqdn               = """ + $_.HealthCheckConfig.FullyQualifiedDomainName + """"
        } else {
            $endpoint = "ip_address             = """ + $_.HealthCheckConfig.IPAddress + """"
        }
        $template = $template.Replace("^id^",$_.Id)
        $template = $template.Replace("^endpoint^",$endpoint)
        $template = $template.Replace("^reference_name^",$_.CallerReference)
        $template = $template.Replace("^port^",$_.HealthCheckConfig.Port)
        $template = $template.Replace("^type^",$_.HealthCheckConfig.type)
        $template = $template.Replace("^failure_threshold^",$_.HealthCheckConfig.FailureThreshold)
        $template = $template.Replace("^request_interval^",$_.HealthCheckConfig.RequestInterval)
        $template = $template.Replace("^resource_path^",$_.HealthCheckConfig.ResourcePath)
        $template = $template.Replace("^search_string^",$_.HealthCheckConfig.SearchString)
        $template = $template.Replace("^measure_latency^",$_.HealthCheckConfig.MeasureLatency)
        $template = $template.Replace("^invert_healthcheck^",$_.HealthCheckConfig.Inverted)
        $template = $template.Replace("^enable_sni^",$_.HealthCheckConfig.EnableSNI)
        $childHealthChecks = wrapInQuotes $_.HealthCheckConfig.ChildHealthChecks
        $template = $template.Replace("^child_healthchecks^",$childHealthChecks)
        $template = $template.Replace("^child_health_threshold^",$_.HealthCheckConfig.HealthThreshold)
        $template = $template.Replace("^insufficient_data_health_status^",$_.HealthCheckConfig.InsufficientDataHealthStatus)
        $regions = wrapInQuotes $_.HealthCheckConfig.Regions
        $template = $template.Replace("^regions^", $regions)
        $resource = Get-R53TagsForResource -ResourceId $_.Id -ResourceType healthcheck
        $resource.Tags | ForEach-Object {
                $tags += $_.Key +  "= """ + $_.Value + ""","
        }
        if($tags.Substring($tags.Length-1) -eq ",")
        {
            $tags = $tags -Replace ".$" 
        }
        $template = $template.Replace("^tags^",$tags)
        Add-Content $Global:outputFolder\aws_route53_health_checks.tf  $template
    }

}

function performInventory()
{
    scanCloudwatchAlarms
    scanR53HealthChecks

}

function performImport()
{
    Set-Location $Global:outputFolder
    $files = Get-ChildItem -Path $Global:outputFolder -Filter "aws_*.tf"
    $files|Get-Content|ForEach-Object{
        if($_.StartsWith("resource"))
        {
            $resourceDetails = [regex]::Matches($_,'(?<=\").+?(?=\")').Value
            $resourceId = $resourceDetails[0] + "." +$resourceDetails[2]
            $resourceName = $resourceDetails[2]
            & "$Global:terraform" "import" "-config=""$Global:outputFolder""" "$resourceId" "$resourceName"
        }
    }
}
function main (){
    Write-Host "Beginning scan."
    renameOldFiles
    performInventory
    #performImport
}

main