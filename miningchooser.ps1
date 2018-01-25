function Get-Profit {
    # Will probably change soon, hence these params are good for now
    param ([string]$coin, [string]$url, [string]$regex)
    try {$site = Invoke-WebRequest $url}
    catch {"Seems like we couldn't connect (website may be down)"
        throw $_}
    $temp = $site.AllElements.outerText[1] -match $regex
    if ($temp -eq 1) {$Profit = $matches[1]}
    else {echo "Can't Find Data (regex found no match)"
        break}
    return $Profit
}

$ETHProfit = Get-Profit "ETH" "http://whattomine.com/coins/151-eth-ethash?utf8=%E2%9C%93&hr=30&p=330&fee=1&cost=0.19&hcost=0.0&commit=Calculate" 'Month.*\$([0-9\.\-]*)'
$ETCProfit = Get-Profit "ETC" "http://whattomine.com/coins/162-etc-ethash?utf8=%E2%9C%93&hr=29.7&p=330&fee=1&cost=0.19&hcost=0.0&commit=Calculate" 'Month.*\$([0-9\.\-]*)'
$XMRProfit = Get-Profit "XMR" "http://whattomine.com/coins/101-xmr-cryptonight?utf8=%E2%9C%93&hr=335&p=40&fee=2.6&cost=0.19&hcost=0.0&commit=Calculate" 'Year.*\$([0-9\.\-]*)'
echo 'ETH $ per month' $ETHProfit 'ETC $ per month' $ETCProfit 'XMR $ per year' $XMRProfit

try {
    if ($ETHProfit -lt 0 -AND $ETCProfit -lt 0) {echo "ethash mining is not profitable"
        $ethashoff = $true}
    elseif ([single]$ETHProfit -ge [single]$ETCProfit) {echo "ETH Wins!"}
    else {echo "ETC Wins!"}
    if ([single]$XMRProfit -ge 10.0) {echo "XMR on for great profit"
        $GreatProfit = $true}
    else {echo "XMR may not be worth it"
        $GreatProfit = $false}
}
catch {"Can't compare values (regex matched bad data)"}