# Change PRODUCT_CODE and PRODUCT_VERSION in version.cmake. Primarily intended
# to be used within a CI system, not for release builds.

<#
.Description
Get the current value of PRODUCT_VERSION in version.cmake. This is needed so that we can increment it. Example: 2.5.028.
#>
Function Get-ProductVersion {
    ForEach ($line in (Get-Content version.cmake)) {
        if ($line -match '^set\(PRODUCT_VERSION\s+"(.*?)"\)') {
            $ProductVersion = $Matches[1]
            break
        }
    }

    $ProductVersion
}

<#
.Description
Increment the last digit in PRODUCTION_VERSION. Only used internally.
#>
Function Increment-Counter {
    param (
        [string]$Counter
    )

    # String off leading zeroes, if any
    $Counter = $Counter -replace '^0+', ''
    $IntCounter = [int]$Counter
    $IntCounter += 1
    $Counter = [string]$IntCounter

    # Add back leading zeroes, if any
    $Counter = $Counter.PadLeft(3, '0')
    $Counter
}

<#
.Description
Create an incremented PRODUCT_VERSION (e.g. 2.5.029).
#>
Function New-ProductVersion {
    $OldProductVersion = (Get-ProductVersion) -match '(\d\.\d?)\.(\d\d\d?)'
    $Version = $Matches[1]
    $Counter = $Matches[2]
    $Counter = Increment-Counter -Counter $Counter
    "${Version}.${Counter}"
}

# Get updated values for PRODUCT_VERSION and PRODUCT_CODE
$NewProductVersion = New-ProductVersion
$NewProductCode = (New-Guid).ToString().ToUpper()

# Replace old values with the newly generated ones, overwriting version.cmake
$version_cmake = (Get-Content version.cmake)
$version_cmake -replace '^set\(PRODUCT_CODE\s+"\{.*?\}"\)', "set(PRODUCT_CODE `"{${NewProductCode}}`")" `
               -replace '^set\(PRODUCT_VERSION\s+".*?"\)', "set(PRODUCT_VERSION `"${NewProductVersion}`")" | Out-File -Encoding ASCII version.cmake
