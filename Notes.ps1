<#
ARRAYS:

To prevent the unwrapping of an array:
    PS> Write-Output -NoEnumerate $data | Get-Member
    TypeName: System.Object[]
    ...

Initialize a new array:

$data = [Object[]]::new(4)


ITERATING:

$data = @("test,", "test2", "test4")

for ( $index = 0; $index -lt $data.count; $index++)
{
    "Item: [{0}]" -f $data[$index]
}

for ( $index = 0; $index -lt $data.count; $index++ )
{
    $data[$index] = "Item: [{0}]" -f $data[$index]
}

foreach ( $node in $data )
{
    "Item: [$node]"
}

$data.foreach{"ScriptBlock"}


LOGIC:


while(($inp = Read-Host -Prompt "Select a command") -ne "Q"){
switch($inp){
   L {"File will be deleted"}
   A {"File will be displayed"}
   R {"File will be write protected"}
   Q {"End"}
   default {"Invalid entry"}
   }
}





# [System.IO.Directory]::EnumerateFiles('c:\temp', '*.*', 'AllDirectories') | % {[System.IO.FileInfo]$_}

# (Get-Item $Path1).EnumerateFiles("*$Extension", 'AllDirectories').Where({$_.LastWriteTime -le $DelDate})

# foreach ($FILE in Get-ChildItem -Path $DIR_START){}
#$file.GetType().Name -> DirectoryInfo OR FileInfo

#[System.IO.Directory]::EnumerateFiles('c:\temp', '*.*', 'AllDirectories') | % {[System.IO.FileInfo]$_}


#>