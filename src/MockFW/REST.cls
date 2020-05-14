Class MockFW.REST Extends (MockFW.REST.Base, MockFW.REST.Utils, %CSP.REST)
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/ping" Method="GET" Call="Test()" Cors="false" />
<Route Url="/:mockName/(.+)" Method="POST" Call="Dispatch" Cors="false" />
<Route Url="/:mockName/(.+)" Method="GET" Call="Dispatch" Cors="false" />
<Route Url="/:mockName/(.+)" Method="PUT" Call="Dispatch" Cors="false" />
<Route Url="/:mockName/(.+)" Method="DELETE" Call="Dispatch" Cors="false" />
</Routes>
}

ClassMethod Test()
{
	w pong
	q $$$OK
}

/// Dispatch method which is called for every endpoint. Distribute the request to the MockBase class
ClassMethod Dispatch(mockName, methodName)
{
	set SC=$$$OK
	set response={}
	set code =""
	set obj=""
	set methodName = methodName_..GetQuery()
	try{
		$$$ThrowOnError(..ReadRequestToObject(.obj))
		set method = %request.Method
		set tSC = ##class(MockFW.MockBase).GetMockedResponseREST(mockName, methodName, method, obj, .response, .code)
		if (response="") || (tSC=0) {
			    return ..WriteErrorResponse(mockName,methodName,tSC)
		}
		return ..WriteResponse(response, code, tSC)
	}catch exc{
		set tSC=exc.AsStatus()
		return ..WriteErrorResponse(mockName,methodName,tSC)
	}
	
	quit tSC
}

}
