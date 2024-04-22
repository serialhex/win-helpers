

# based on http://stackoverflow.com/questions/22988384/powershell-change-owner-of-files-and-folders


# prepare for folders
If (Test-Path C:\PTemp) { Remove-Item C:\PTemp }
New-Item -type directory -Path C:\PTemp
$Acl = Get-Acl -Path C:\PTemp
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("BUILTIN\Administrators","FullControl","Allow")
$Acl.SetAccessRule($Ar)
$AdjustTokenPrivileges = @"
using System;
using System.Runtime.InteropServices;
 public class TokenManipulator
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  [DllImport("kernel32.dll", ExactSpelling = true)]
  internal static extern IntPtr GetCurrentProcess();
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid{
   public int Count;
   public long Luid;
   public int Attr;
  }
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool AddPrivilege(string privilege){
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_ENABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
 }
"@
add-type $AdjustTokenPrivileges
[void][TokenManipulator]::AddPrivilege("SeRestorePrivilege") 
[void][TokenManipulator]::AddPrivilege("SeBackupPrivilege") 
[void][TokenManipulator]::AddPrivilege("SeTakeOwnershipPrivilege") 
$NewOwnerACL = New-Object System.Security.AccessControl.DirectorySecurity
$Admin = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators")
$NewOwnerACL.SetOwner($Admin)


foreach ($Target in $Script:args) {
  if (test-path -path $Target) {
    # Change FOLDER owners to Admin
    $Folders = @(Get-ChildItem -Path $Target -Directory -Recurse | Select-Object -ExpandProperty FullName)
    foreach ($Item1 in $Folders) {
      $Folder = Get-Item $Item1
      $Folder.SetAccessControl($NewOwnerACL)
      # Add folder Admins to ACL with Full Control to descend folder structure
      Set-Acl $Item1 $Acl
    } 


    # prepare for files
    $Account = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators")
    $FileSecurity = new-object System.Security.AccessControl.FileSecurity
    $FileSecurity.SetOwner($Account)
    If (Test-Path C:\PFile) { Remove-Item C:\PFile }
    New-Item -type file -Path C:\PFile
    $PAcl = Get-Acl -Path C:\PFile
    $PAr = New-Object  system.security.accesscontrol.filesystemaccessrule("BUILTIN\Administrators","FullControl","Allow")
    $PAcl.SetAccessRule($PAr)


    # Change FILE owners to Admin
    $Files = @(Get-ChildItem -Path $Target -File -Recurse | Select-Object -ExpandProperty FullName)
    foreach ($Item2 in $Files){
      # Action
      [System.IO.File]::SetAccessControl($Item2, $FileSecurity)
      # Add file Admins to ACL with Full Control and activate inheritance
      Set-Acl $Item2 $PAcl
    } 
  } else {
    Write-Host "Path '$Target' does not exsist"
  }
}



# Clean-up junk
Remove-Item C:\PTemp
Remove-Item C:\PFile
