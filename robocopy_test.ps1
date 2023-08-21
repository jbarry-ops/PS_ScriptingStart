<#

?? Use robocopy to overcome 260 character PATH limit ??

$source="C:\temp\source"
$dest="C:\temp\dest"

$what = @("/COPYALL","/B","/SEC","/MIR")
$options = @("/R:0","/W:0","/NFL","/NDL")

$cmdArgs = @("$source","$dest",$what,$options)
robocopy @cmdArgs




OR: invoke-expression "robocopy $sourceFolder $destinationFolder /MIR"  

However, if there is a space in the PATH: robocopy "\`"$sourceFolder"\`" "\`"$destinationFolder"\`" /MIR


Function Get-Ps1File {
    Param ($Path= '.\')
 
    Get-ChildItem -Path $Path | ForEach-Object {
        If ($_.Name -like "*.ps1") {
            $_.Name
        } ElseIf ($_.PSIsContainer) {
            Get-Ps1File -Path $_.FullName
        } # End If-ElseIf.
    } # End ForEach-Object.
} # End Function: Get-Ps1File.

#[Object[]]::new(1);

#>

# powershell-sample to find all "hosts"-files on Partition "c:\"

cls
Remove-Variable * -ea 0
[System.GC]::Collect()
$ErrorActionPreference = "stop"

$searchDir  = "c:\"
$searchFile = "hosts"

add-type -TypeDefinition @"
using System;
using System.IO;
using System.Linq;
using System.Collections.Concurrent;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

public class FileSearch {
    public struct WIN32_FIND_DATA {
        public uint dwFileAttributes;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftCreationTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftLastAccessTime;
        public System.Runtime.InteropServices.ComTypes.FILETIME ftLastWriteTime;
        public uint nFileSizeHigh;
        public uint nFileSizeLow;
        public uint dwReserved0;
        public uint dwReserved1;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string cFileName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)]
        public string cAlternateFileName;
    }

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    static extern IntPtr FindFirstFile(string lpFileName, out WIN32_FIND_DATA lpFindFileData);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    static extern bool FindNextFile(IntPtr hFindFile, out WIN32_FIND_DATA lpFindFileData);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Ansi)]
    static extern bool FindClose(IntPtr hFindFile);

    static IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);
    static BlockingCollection<string> dirList {get;set;}
    static BlockingCollection<string> fileList {get;set;}
    
    public static BlockingCollection<string> GetFiles(string searchDir, string searchFile) {
        bool isPattern = false;
        if (searchFile.Contains(@"?") | searchFile.Contains(@"*")) {
            searchFile = @"^" + searchFile.Replace(@".",@"\.").Replace(@"*",@".*").Replace(@"?",@".") + @"$";
            isPattern = true;
        }
        fileList = new BlockingCollection<string>();
        dirList = new BlockingCollection<string>();
        dirList.Add(searchDir);
        int[] threads = Enumerable.Range(1,Environment.ProcessorCount).ToArray();
        Parallel.ForEach(threads, (id) => {
            string path;
            IntPtr handle = INVALID_HANDLE_VALUE;
            WIN32_FIND_DATA fileData;
            if (dirList.TryTake(out path, 100)) {
                do {
                    path = path.EndsWith(@"\") ? path : path + @"\";
                    handle = FindFirstFile(path + @"*", out fileData);
                    if (handle != INVALID_HANDLE_VALUE) {
                        FindNextFile(handle, out fileData);
                        while (FindNextFile(handle, out fileData)) {
                            if ((fileData.dwFileAttributes & 0x10) > 0) {
                                string fullPath = path + fileData.cFileName;
                                dirList.TryAdd(fullPath);
                            } else {
                                if (isPattern) {
                                    if (Regex.IsMatch(fileData.cFileName, searchFile, RegexOptions.IgnoreCase)) {
                                        string fullPath = path + fileData.cFileName;
                                        fileList.TryAdd(fullPath);
                                    }
                                } else {
                                    if (fileData.cFileName == searchFile) {
                                        string fullPath = path + fileData.cFileName;
                                        fileList.TryAdd(fullPath);
                                    }
                                }
                            }
                        }
                        FindClose(handle);
                    }
                } while (dirList.TryTake(out path));
            }
        });
        return fileList;
    }
}
"@

$fileList = [fileSearch]::GetFiles($searchDir, $searchFile)
$fileList
