Class MockFW.REST.Base Extends %CSP.REST
{

Parameter CHARSET = "utf-8";

Parameter CONTENTTYPE = "application/json";

Parameter HandleCorsRequest = 1;

Parameter PAGESIZE As INTEGER = 20;

ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
  Set tSC = $$$OK
  try {
    
    // Set the return type according to the Accept type in the request. Default is application/json.
    if ('..AcceptsContentType(..#CONTENTTYPEJSON)) {
      set tSC = ..ReportHttpStatusCode(..#HTTP406NOTACCEPTABLE), pContinue=0
      quit 
        } else {   
      // This always returns json
      set %response.ContentType=..#CONTENTTYPEJSON
        }
        
        
        // read request object into %DynamicObject format
    if ((pMethod'="POST") && (pMethod'="PUT")) || (%request.Content="") {
      set %request.Content = {}
    } else {
      if '$isobject(%request.Content) {
        set tContent = %request.Content
      } else {
        set tContent = ""
        while '%request.Content.AtEnd {
          set tContent = tContent_%request.Content.Read()
        }
      }
      if (tContent="") {
        set %request.Content = {}
      } else {
        set tContent = $zconvert(tContent, "I", "UTF8")
        set %request.Content = ##class(%Library.DynamicObject).%FromJSON(tContent)
      }
    }
        
  } catch ex {
    set tSC = ex.AsStatus()
  }
  quit ##class(%iKnow.REST.Base).%ErrorHandler(tSC, .pContinue)
}

}
