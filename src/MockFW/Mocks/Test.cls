Class MockFW.Mocks.Test Extends (%RegisteredObject, MockFW.MockBase)
{


ClassMethod %DispatchClassMethod(Class As %String, methodName As %String, Args...)
{
  set mockName = $PIECE(Class,".",3) 
  quit ##class(MockFW.MockBase).MethodCalled(mockName, methodName, Args...)
}

Method %DispatchMethod(methodName As %String, Args...)
{
  set mockName = $PIECE($CLASSNAME(),".",3) 
  quit ##class(MockFW.MockBase).MethodCalled(mockName, methodName, Args...)
}

ClassMethod SaveMethod(methodName As %String, params, return, restMethod As %String = "", code = 200, delay = 0, force = 0) As %Status
{
  set mockName = $PIECE($CLASSNAME(),".",3) 
  do ##super(mockName, methodName, params, return, restMethod, code, delay, force)
}

}
