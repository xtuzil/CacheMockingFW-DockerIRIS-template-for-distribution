Class App.Installer
{

XData setup
{
<Manifest>
  <Default Name="SourceDir" Value="#{$system.Process.CurrentDirectory()}src"/>
  <Default Name="Namespace" Value="MOCKFW"/>
  <Default Name="app" Value="mockfw"/>
  <Default Name="cspapp" Value="/api/mocks/"/>
  <Default Name="dispatchclass" Value="MockFW.REST"/>
  <Default Name="username" Value="mockuser"/>
  <Default Name="password" Value="12345"/>

  <Namespace Name="${Namespace}" Code="${Namespace}" Data="${Namespace}" Create="yes" Ensemble="no">

    <Configuration>
      <Database 
      Name="${Namespace}" 
      Dir="/opt/${app}/data" 
      Create="yes" 
      Resource="%DB_${Namespace}"
      PublicPermissions="RW"
      MountAtStartup="true"
      />

      <Import File="${SourceDir}" Flags="ck" Recurse="1"/>
    </Configuration>
    <CSPApplication Url="${cspapp}" Directory="${cspdir}${app}"  ServeFiles="1" Recurse="1" MatchRoles=":%DB_${Namespace}" AuthenticationMethods="32"
       
    />
  </Namespace>

  
  <Namespace Name="${CURRENTNS}">
  <Invoke Class="${CURRENTCLASS}" Method="SetDispatchClass" CheckStatus="true">
  <Arg Value="${cspapp}"/>
  <Arg Value="${dispatchclass}"/>
  </Invoke>
  </Namespace>

  <Namespace Name="${CURRENTNS}">
  <Invoke Class="${CURRENTCLASS}" Method="SetUser" CheckStatus="true">
  <Arg Value="${username}"/>
  <Arg Value="${password}"/>
  </Invoke>
  </Namespace>


</Manifest>
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
  do %code.WriteLine($char(9)_"set pVars(""CURRENTCLASS"")="""_%classname_"""")
  do %code.WriteLine($char(9)_"set pVars(""CURRENTNS"")="""_$namespace_"""")
  #; Let our XGL document generate code for this method. 
  Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "setup")
}

ClassMethod SetDispatchClass(pCSPName As %String = "", pDispatchClass As %String = "") As %Status
{
    new $namespace
    znspace "%SYS"
    set props("DispatchClass")=pDispatchClass
    set props("Recurse")=1
    d ##class(Security.Applications).Modify(pCSPName,.props)
    quit $$$OK
}

ClassMethod SetUser(username As %String = "", password As %String = "") As %Status
{
    new $namespace
    znspace "%SYS"
    set props("Username")=username
    set props("PasswordNeverExpires")=1
    set props("Roles")="%All"
    set props("NameSpace")="MOCKFW"
    set props("FullName")="User of Mock"
    set props("Enabled")=1
    set props("PasswordExternal")=password
    do ##class(Security.Users).Create(username,.props)
    quit $$$OK
}

}
