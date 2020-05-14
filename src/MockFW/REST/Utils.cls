Class MockFW.REST.Utils Extends (%iKnow.REST.Utils, %CSP.REST, MockFW.Utils)
{

ClassMethod ReadRequestToObject(Output obj, setIfNone = "", convertToUtf8 = 1) As %Status
{
	set SC=$$$OK
	try{
		if %request.Content'=""{
			set obj=%request.Content
		} else {
			return $System.Status.Error(5001, "No request data provided.")
		}
	} catch exc {
		set SC=exc.AsStatus()
	}
	
	quit SC
}

ClassMethod WriteResponse(response, code, SC As %Status, encode As %Boolean = 0) As %Status
{
	quit:response="" SC
	set:response="NONE" response=""
	quit:SC'=$$$OK SC
	set %response.Status = code

	set stream=##class(%Stream.GlobalCharacter).%New()

	try {
		set response={}.%FromJSON(response)
	} catch {
		set res = {}
		do res.%Set("Response",response)
		set response = res
	}

	do response.%ToJSON(stream)
	do stream.Rewind()
		while stream.AtEnd=0{
		write:encode=0 stream.Read()
		write:encode=1 $zconvert(stream.Read(),"I","UTF8")
	}
	quit SC
}

ClassMethod WriteErrorResponse(mockName, methodName, SC As %Status, encode As %Boolean = 0) As %Status
{
	set %response.Status = 404
	set stream=##class(%Stream.GlobalCharacter).%New()
	set response = {}
	set error = "Metoda s URL "_methodName_" pro mock "_mockName_" s parametry nenalezena."
	do response.%Set("Error",error)
	
	do response.%ToJSON(stream)
	do stream.Rewind()
		while stream.AtEnd=0{
		write:encode=0 stream.Read()
		write:encode=1 $zconvert(stream.Read(),"I","UTF8")
	}
	quit SC
}

ClassMethod GetQuery() As %String
{
	set query = "?"
	set first = "true"
	set key = $ORDER(%request.Data(""))
	while (key '= "") {
		if first'="true" {
			set query = query_"&"

		} else {
			set first = "false" 
		}
		set val = $GET(%request.Data(key,1))
		set query = query_key_"="_val
		set key = $ORDER(%request.Data(key))
	}
	if query = "?" {
		return ""
	}
	return query
}

}
