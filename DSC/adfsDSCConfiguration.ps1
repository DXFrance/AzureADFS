Configuration Main
{
Param ( [string] $nodeName )

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName
  {
    WindowsFeature ADFS
    {
      Name = "ADFS-Federation"
      Ensure = "Present"
    }
  }
}