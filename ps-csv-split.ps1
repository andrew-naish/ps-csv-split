param(
    [Parameter(Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true,
        HelpMessage="Path to CSV which will be split")]
    [ValidateNotNullOrEmpty()]
    [string] $CSVPath,

    [Parameter(Mandatory=$false, HelpMessage="How man lines each file should be.")]
    [int] $ChunkSize=50,

    [Parameter(Mandatory=$false, HelpMessage="The name of each chunk, will be appended with an incrementing number.")]
    [string] $NewBasename
)

## Init
$csv_path = (Resolve-Path $CSVPath).Path
$csv_fullfile = [IO.File]::ReadAllLines($csv_path, [System.Text.Encoding]::Default)
$csv_headers = $csv_fullfile[0]

# generate output path
$out_location = $csv_path | Split-Path -Parent
$out_filename_extension = (Get-Item $csv_path).Extension
$out_filename_base = if ( -not ([String]::IsNullOrEmpty($NewBasename)) ) 
{ $NewBasename } else { (Get-Item $csv_path).BaseName }

## Main

# create stack ready for processing
$csv_data_stack = New-Object System.Collections.Stack
$csv_fullfile | Select-Object -Skip 1 | ForEach-Object {
    $csv_data_stack.Push($_)
}

# calculate itterations by dividing and then rounding up to nearest whole number
$itterations = [System.Math]::Ceiling($csv_data_stack.Count/$ChunkSize)

# start
for ($i=1; $i -le $itterations; $i++) {

    $new_file = @($csv_headers)

    for ($ii=1; $ii -le $ChunkSize; $ii++) {
        if ($csv_data_stack.Count -eq 0) {break}
        $new_file += $csv_data_stack.Pop()
    }

    $location = "$($out_location)\$($out_filename_base)_SPLIT$i$($out_filename_extension)"
    [IO.File]::WriteAllLines($location, $new_file, [System.Text.Encoding]::UTF8)

}