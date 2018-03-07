$MeasureStart = Get-Date
# Set profit timespan preference for each currency here
$CoinTime = @{
"ETH" = "Month";
"ETC" = "Month";
"XMR" = "Year"}

$EthashRate = "29"
$ElecCost = "0.19"
$GPUpower = "270"
$PoolFee = "1"
$XMRFee = "2.6"
$CryptonightRate = "320"
$CPUpower = "40"

$CoinURL = @{
"ETH" = "http://whattomine.com/coins/151-eth-ethash?utf8=%E2%9C%93&hr=$EthashRate&p=$GPUpower&fee=$PoolFee&cost=$ElecCost&hcost=0.0&commit=Calculate";
"ETC" = "http://whattomine.com/coins/162-etc-ethash?utf8=%E2%9C%93&hr=$EthashRate&p=$GPUpower&fee=$PoolFee&cost=$ElecCost&hcost=0.0&commit=Calculate";
"XMR" = "http://whattomine.com/coins/101-xmr-cryptonight?utf8=%E2%9C%93&hr=$CryptonightRate&p=$CPUpower&fee=$XMRFee&cost=$ElecCost&hcost=0.0&commit=Calculate"}
$CoinRegex = '.*\s(\-)?\$([0-9\.\,]*)'
$CoinStr = @{}
$TimeSpans = @("Hour", "Day", "Week", "Month", "Year")
$XMRWeighting = @{"Year"=10.0;"Month"=(10.0/12);"Week"=(10.0/52.1786);"Day"=(10.0/365.25);"Hour"=(10.0/8766)}
$ProfitTable = @()

Foreach ($Currency in $CoinURL.Keys) {
    Write-Host "Checking profit for $Currency..."
    $CoinObject = New-Object PsObject
    $CoinObject | Add-Member -MemberType NoteProperty -Name "Currency" -Value $Currency
    Try {$Site = Invoke-WebRequest $CoinURL.$Currency}
    Catch {
        Write-Warning "Seems like we couldn't connect (website may be down)"
        Throw $_
    }
    Foreach ($Time in $TimeSpans) {
        $Regex = ($Time+$CoinRegex)
        $Temp = $Site.AllElements.outerText[1] -match $Regex
        If ($Temp -eq 0) {
            Write-Warning "Can't find data (regex found no match for $Currency using pattern $Regex)"
            $CoinObject | Add-Member -MemberType NoteProperty -Name $Time -Value "-"
        }
        Else {
            $VarProfit = $Matches[1] + $Matches[2]
            $CoinObject | Add-Member -MemberType NoteProperty -Name $Time -Value $VarProfit
            If ($Time -eq $CoinTime.$Currency) {
                # Auto create/set profit variable by timespan pref e.g. ETH = $ETHProfit, XMR = $XMRProfit
                Set-Variable -Name $Currency`Profit -Value $VarProfit
                $TimeStr = $CoinTime.$Currency
                $CoinStr.$Currency = "$Currency $ per $TimeStr`: $VarProfit"
            }
        }
    }
    $ProfitTable += $CoinObject
}

# Show profit table and selected timespans
$ProfitTable | FT -AutoSize
Foreach ($Currency in $CoinURL.Keys) {Write-Host $CoinStr.$Currency}
Write-Host

# Evaluation
Try {
    If ($CoinTime."ETC" -ne $CoinTime."ETH") {
        Write-Warning "ETC & ETH timespans do not match"
        Write-Host "ETC profit is measuring timespan:" $CoinTime."ETC"
        Write-Host "ETH profit is measuring timespan:" $CoinTime."ETH"
        Write-Host "No ETC/ETH evaluation will be performed until timespans are corrected to match"
    }
    Else {
        If ($ETHProfit -lt 0 -AND $ETCProfit -lt 0) {Write-Host "ethash mining is not profitable" -ForegroundColor Red # Weighting for ETH/ETC?
            $ethashoff = $True}
        Elseif ([single]$ETHProfit -ge [single]$ETCProfit) {Write-Host "ETH Wins!" -ForegroundColor Green}
        Else {Write-Host "ETC Wins!" -ForegroundColor Green}
    }
    If ([single]$XMRProfit -ge $XMRWeighting.($CoinTime."XMR")) {Write-Host "XMR on for great profit" -ForegroundColor Green
        $GreatProfit = $True}
    Else {Write-Host "XMR may not be worth it" -ForegroundColor Red
        $GreatProfit = $False}
}
Catch {Write-Warning "Can't compare values (regex matched bad data)"}
$RunTime = (Get-Date)-$MeasureStart
Write-Host
Write-Host "Total script runtime (H:M:S) - "$RunTime.Hours":"$RunTime.Minutes":"$RunTime.Seconds -Separator ""
