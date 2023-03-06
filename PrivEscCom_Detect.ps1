#
# Created by Sina Tamari
#

function Lookup-HKLM
{
    Param([string]$clsid,[string]$inDLL)
    $CLSID_KEY = 'HKLM:\SOFTWARE\Classes\CLSID';
    If ( Test-Path $CLSID_KEY\$clsid )
    {
        $name = ( Get-ItemProperty -Path $CLSID_KEY\$clsid ).'(default)';
        $dll  = ( Get-ItemProperty -Path $CLSID_KEY\$clsid\InProcServer32 ).'(default)';
    }
    ELSE {
        return $false;
    }
    return $dll -ne $inDLL
}
function Enum-HKCU
{
    Get-ChildItem -Path Registry::HKEY_CURRENT_USER\Software\Classes\CLSID -Depth 1 -ErrorAction SilentlyContinue | Where-Object { 
            (Split-Path $_.name -Leaf) -eq "LocalServer32" -or (Split-Path $_.name -Leaf) -eq "InprocServer32" 
    } | Foreach-Object { 
            $Output = "" | Select Name, CLSID, Type, Value, Key, is_malicious
            $Output.CLSID = Split-Path $_.PSParentPath -Leaf
            $Output.Type = $_.PSChildName
            $Output.Name = (Get-ItemProperty -Path HKCU:\SOFTWARE\Classes\CLSID\$($Output.CLSID) -Name "(Default)" -ErrorAction SilentlyContinue).("(Default)")
            $Output.Value = (Get-ItemProperty -Path HKCU:\SOFTWARE\Classes\CLSID\$($Output.CLSID)\$($Output.Type) -Name "(Default)" -ErrorAction SilentlyContinue).("(Default)")
            $Output.is_malicious = Lookup-HKLM "$($Output.CLSID)" "$($Output.Value)"
            $Output.Key = $_.Name
            IF ( $Output.is_malicious ){
                $Output
            }
    } 
}
Enum-HKCU
