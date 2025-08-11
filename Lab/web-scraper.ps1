$url = "https://en.wikipedia.org/wiki/Eve_Online"
$outputFile = "$env:USERPROFILE\Desktop\Generated-Rule-Report-$ODS.csv"

write-host "Fetching data from $url..."
try {
   $response = Invoke-WebRequest -Uri $url 

}
catch {
   Write-Error "Failed to fetch data from ${url}: $_"
   return
}

$quoteContainers = $response.ParsedHtml.querySelectorAll(".quote")
write-host "Found $($quoteContainers.length) quotes on the page."

$results = @()

foreach ($container in $quoteContainers) {
    # Find the quote text and author within the container
    $quoteText = $container.querySelector(".text").innerText
    $authorName = $container.querySelector(".author").innerText
    
    # 6. Create a custom object and add it to our results array
    $results += [PSCustomObject]@{
        Author = $authorName
        Quote  = $quoteText
    }
}

$results | Export-Csv -Path $outputFile -NoTypeInformation
write-host "Quotes exported to $outputFile"