Configuration Main
{

Param ( [string] $nodeName )

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName
  {

	WindowsFeature WebAppProxy
    {
      Name = "Web-Application-Proxy"
      Ensure = "Present"
    }
  }
}