Class MockFW.MockManager Extends (%RegisteredObject, MockFW.Utils)
{

/// Creates new mock class if does not exist already. 
/// Generates class definition in 'MockFW.Mocks' to be possible calling methods on this class.
ClassMethod CreateMock(className As %String) As %Status
{
	set fullClassName = "MockFW.Mocks."_className
	
	If (##class(%Dictionary.CompiledClass).%ExistsId(fullClassName)) {
		w "Mock with this name already exists!"
		quit '$$$OK
	}
	
	set classDef=##class(%Dictionary.ClassDefinition).%New()
	set classDef.Name=fullClassName
	set classDef.ProcedureBlock=1
	set classDef.Super = "MockFW.MockBase"
	
	set methodDef = ##class(%Dictionary.MethodDefinition).%New()
	set methodDef.Name = "SaveMethod"	
	set methodDef.ClassMethod = "1"
	set methodDef.ReturnType = "%Status"
	set methodDef.FormalSpec="methodName:%String,params,return,restMethod:%String="""",code=200,delay=0,force=0"	
	do methodDef.Implementation.WriteLine($$$TAB_" set mockName = $PIECE($CLASSNAME(),""."",3) ")
	do methodDef.Implementation.WriteLine($$$TAB_" do ##super(mockName, methodName, params, return, restMethod, code, delay, force)")
	do classDef.Methods.Insert(methodDef)
	
	set methodDef = ##class(%Dictionary.MethodDefinition).%New()
	set methodDef.Name = "%DispatchClassMethod"	
	set methodDef.ClassMethod = "1"
	set methodDef.FormalSpec="Class:%String,methodName:%String,Args..."
	do methodDef.Implementation.WriteLine($$$TAB_" set mockName = $PIECE(Class,""."",3) ")
	do methodDef.Implementation.WriteLine($$$TAB_" quit ##class(MockFW.MockBase).MethodCalled(mockName, methodName, Args...)")
	do classDef.Methods.Insert(methodDef)
	
	
	set methodDef = ##class(%Dictionary.MethodDefinition).%New()
	set methodDef.Name = "%DispatchMethod"	
	set methodDef.FormalSpec="methodName:%String,Args..."
	do methodDef.Implementation.WriteLine($$$TAB_" set mockName = $PIECE($CLASSNAME(),""."",3) ")
	do methodDef.Implementation.WriteLine($$$TAB_" quit ##class(MockFW.MockBase).MethodCalled(mockName, methodName, Args...)")
	do classDef.Methods.Insert(methodDef)
	
	do classDef.%Save()
   	quit ##class(%SYSTEM.OBJ).Compile(fullClassName)
}

/// Save method of the certain mock to the global if the method with same parameters does not already exist
/// To overwrite existing record adjust parametr force to 1
ClassMethod SaveMethod(mockName As %String, methodName As %String, params, response, restMethod As %String = "", code As %Integer = 200, delay = 0, force = 0) As %Status
{
	quit ##class(MockFW.MockBase).SaveMethod(mockName, methodName, params, response, restMethod, code, delay, force)
}

/// Import mock and mocks data from .csv file
/// Import proccess from the second line with  'format 
/// Name of the Mock; Method(endpoint); parameters; Response; Rest method; Return code, delay, force'
ClassMethod SaveMethodsFromCSV(filePath As %String)
{
	set saved = 0
	set count = 0
   	set stream=##class(%Stream.FileCharacter).%New()
   	set sc=stream.LinkToFile(filePath)
   	do stream.Rewind()
   	while 'stream.AtEnd {
		set line=stream.ReadLine()
     	set mockName = $PIECE(line,";",1)
     	set methodName = $PIECE(line,";",2)
     	set params = $PIECE(line,";",3)
     	set response = $PIECE(line,";",4)
     	set restMethod = $PIECE(line,";",5)
     	set code = $PIECE(line,";",6)
     	set delay = $PIECE(line,";",7)
     	set force = $PIECE(line,";",8)
     
     	//Convert to objects because of way how we are saving
     	set params =  ..CutExtraQuotes(params)
     	set response =  ..CutExtraQuotes(response)

     	if mockName'= "Name of the Mock" { // We do not want to take first line
		 	set count = count + 1
     		set sc = ##class(MockFW.MockBase).SaveMethod(mockName, methodName, params, response, restMethod, code, delay, force)                  
			if sc=$$$OK {
				set saved = saved + 1
			}
		}
   	}
	write !, "It was saved ", saved, " methods from ", count, !
	quit $$$OK
}

/// Is used when closing REST API into Docker
/// Export Mock class and Mock data as a two files (.xml a .gof)
/// dirPath = directory where you have folder with Iris docker + /durable/src
/// mockName = e.g. MyMock
ClassMethod ExportMock(mockName As %String, dirPath As %String, inContainer As %Integer = 0) As %Status
{
	if inContainer {
		set dirPath = "/opt/mockfw/export/"
	} else {
		set dirPath = dirPath_"\"
	}

	do ..ExportMockData(mockName, dirPath)

	set className = "MockFW.Mocks."_mockName
	set exist=##class(%Dictionary.CompiledClass).%ExistsId(className)
	if 'exist {
		write "The class definition of mock "_mockName_" does not exist. Only global exported (might be empty)."
		quit '$$$OK
	}
	do ..ExportMockClass(mockName, dirPath)

	quit $$$OK
}

/// Auxiliary method, exports Mocks data
ClassMethod ExportMockData(mockName As %String, dirPath As %String) As %Status [ Private ]
{
	set global = "MockMat("_mockName
	set filePath = dirPath_mockName_"Global.gof"
	quit ##class(%Library.Global).Export(,global,filePath)
}

/// Auxiliary method, exports Mock class
ClassMethod ExportMockClass(mockName As %String, dirPath As %String) As %Status [ Private ]
{
	set fullClassName = "MockFW.Mocks."_mockName_".cls"
	set filePath = dirPath_mockName_"MockClass.xml"
	quit $system.OBJ.Export(fullClassName, filePath)
}

/// Return all mocks as a %ListOfDataTypes and also write the list
ClassMethod GetAllMocks()
{
	#dim listMocks = ##class(%ListOfDataTypes).%New()
	set key = $Order(^MockMat(""))
 	while (key '= "") {
		 do listMocks.Insert(key)
     	s key = $Order(^MockMat(key)) // next subscript
 	}
	zwrite listMocks 
	quit listMocks
}

/// Return all Mock methods as a %ListOfDataTypes and also write the list
ClassMethod GetAllMethods(mockName As %String)
{
	#dim listMethods = ##class(%ListOfDataTypes).%New()
	set key = $Order(^MockMat(mockName,""))
 	while (key '= "") {
		 do listMethods.Insert(key)
     	s key = $Order(^MockMat(mockName,key)) // next subscript
 	}
	zwrite listMethods
	quit listMethods
}

/// Delete specific method from specific mock (All records with different parameters)
ClassMethod DeleteMethod(mockName As %String, methodName As %String)
{
	kill ^MockMat(mockName, methodName)
	write "The method ", methodName, " from mock ", mockName, " no longer exist.", !
	quit $$$OK
}

/// Delete specific method from specific mock with specific parameters
ClassMethod DeleteMethodWithParametr(mockName As %String, methodName As %String, params, restMethod As %String = "")
{
	if ($ISOBJECT(params)) {
		set params = params.%ToJSON()
	}

	if restMethod="" {
		kill ^MockMat(mockName, methodName, params)
	} else {
		kill ^MockMat(mockName, methodName, restMethod, params)
	}

	write "The method ", methodName, " from mock ", mockName, "with parameters ", params, " no longer exist.", !
}

/// Delete Mock class definition and also clean global from this Mock (Mocks data)
ClassMethod DeleteMock(mockName As %String)
{
	Kill ^MockMat(mockName)
	quit ##class(%SYSTEM.OBJ).Delete("MockFW.Mocks."_mockName)
	write "The mock ", mockName, "no longer exists",!
}

/// Delete all of the records and data
ClassMethod CleanAll()
{
	Kill ^MockMat
	quit ##class(%SYSTEM.OBJ).DeletePackage("MockFW.Mocks")
}

/// Initialize mock name for testing purpose (parse mock name from instance of full class name)
ClassMethod InitMockForTest(serviceInstance)
{
	quit $PIECE($CLASSNAME(serviceInstance),".",3)
}

/// This method generates documentation for the certain mock
/// Format of the documentation is XML for simple transformation to DocBook via XMLmind or other tools
ClassMethod GenerateDocumentation(mockName As %String, dirPath As %String, inContainer As %Integer = 0) As %Status
{
	if inContainer {
		set filePath = "/opt/mockfw/export/"
	}
	set filePath = filePath_mockName_"Doc.xml"

	write "Generating documentation of the mock ", mockName, " to specified path",!

	set file=##class(%File).%New(filePath)
	do file.Open("WSN")
	do file.WriteLine("<?xml version=""1.0"" encoding=""UTF-8""?>")
	do file.WriteLine("<!DOCTYPE book PUBLIC ""-//OASIS//DTD DocBook XML V4.5//EN""")
	do file.WriteLine("""http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd"">")
	do file.WriteLine("<book>")
	do file.WriteLine($$$TAB_"<bookinfo>")
	do file.WriteLine(..Tabs(2)_"<title>"_mockName_" - Mock documentation</title>")
	do file.WriteLine(..Tabs(2)_"<author>")
	do file.WriteLine(..Tabs(3)_"<firstname>"_$USERNAME_"</firstname>")
	do file.WriteLine(..Tabs(2)_"</author>")
	do file.WriteLine(..Tabs(2)_"<pubdate>"_$PIECE($ZDATETIME($ZTIMESTAMP,4,1,2)," ", 1)_"</pubdate>")
	do file.WriteLine($$$TAB_"</bookinfo>")
	
	
	do file.WriteLine($$$TAB_"<chapter>")
	do file.WriteLine(..Tabs(2)_"<title>MockFW.Mocks."_mockName_"</title>")
	

	// first local mocked methods
	set local = "false"
	
	#dim listMethods = ##class(%ListOfDataTypes).%New()
	set key = $Order(^MockMat(mockName,""))
 	while (key '= "") {
		do listMethods.Insert(key)
     	s key = $Order(^MockMat(mockName,key)) // next subscript
 	}
	set listMethodswithREST = ##class(%ListOfDataTypes).%New()
	for i=1:1:listMethods.Count() {
    	set method = listMethods.GetAt(i)
    	set first = "true"
    	set firstREST = "true"
    	
    	set key = $Order(^MockMat(mockName, method, ""))
 		while (key '= "") {
		 	if (key '= "GET") &&  (key '= "POST") && (key '= "PUT") && (key '= "DELETE") {
			 	if local = "false" {
				 	set local = "true"
			 		do file.WriteLine(..Tabs(2)_"<section>")
					do file.WriteLine(..Tabs(3)_"<title>Local mocked methods</title>")
					do file.WriteLine(..Tabs(3)_"<itemizedlist mark=""opencircle"">")
			 	}
			 	if first="true" {
				 	set first="false"
		    		do file.WriteLine(..Tabs(4)_"<listitem>")
    				do file.WriteLine(..Tabs(5)_"<para>"_method_"()</para>")
    				do file.WriteLine(..Tabs(5)_"<table frame=""all"">")
    				do file.WriteLine(..Tabs(6)_"<tgroup align=""left"" cols=""2"">")
    				do file.WriteLine(..Tabs(7)_"<colspec colname=""c1""/>")
    				do file.WriteLine(..Tabs(7)_"<colspec colname=""c2""/>")
    				do file.WriteLine(..Tabs(7)_"<thead>")
    				do file.WriteLine(..Tabs(8)_"<row>")
    				do file.WriteLine(..Tabs(9)_"<entry>Parameters</entry>")
    				do file.WriteLine(..Tabs(9)_"<entry>Response</entry>")
    				do file.WriteLine(..Tabs(8)_"</row>")
    				do file.WriteLine(..Tabs(7)_"</thead>")
    				do file.WriteLine(..Tabs(7)_"<tbody>")	 		
			 	}
			 	
			 	do file.WriteLine(..Tabs(8)_"<row>")
			 	do file.WriteLine(..Tabs(9)_"<entry>"_key_"</entry>")
			 	set response = ^MockMat(mockName, method, key)
			 	do file.WriteLine(..Tabs(9)_"<entry>"_response_"</entry>")
			 	do file.WriteLine(..Tabs(8)_"</row>")
			 		
		 	} else {
			 	if firstREST="true" {
				 	set firstRest="false"
		 			if listMethodswithREST.Find(method) = "" {
		 				do listMethodswithREST.Insert(method)
					}
			 	}
		 	}
		 	s key = $Order(^MockMat(mockName, method, key)) // next subscript
 		}
    	
    	if first="false" {
    		do file.WriteLine(..Tabs(7)_"</tbody>")
    		do file.WriteLine(..Tabs(6)_"</tgroup>")
    		do file.WriteLine(..Tabs(5)_"</table>")
    		do file.WriteLine(..Tabs(4)_"</listitem>")
    	}
 	} 
	if local = "true" {
		do file.WriteLine(..Tabs(3)_"</itemizedlist>")
		do file.WriteLine(..Tabs(2)_"</section>")
	}
	
	// second REST mocked methods
	set port = "9092"
	set url = "http://localhost:"_port_"/api/mockfw/"_mockName_"/"
	
	do file.WriteLine(..Tabs(2)_"<section>")
	do file.WriteLine(..Tabs(3)_"<title>REST mocked methods</title>")
	do file.WriteLine(..Tabs(3)_"<itemizedlist mark=""opencircle"">")
	
	
	for i=1:1:listMethodswithREST.Count() {
    	set method = listMethodswithREST.GetAt(i)
    	
    	do file.WriteLine(..Tabs(4)_"<listitem>")
    	do file.WriteLine(..Tabs(5)_"<para>"_url_method_"</para>")
    	do file.WriteLine(..Tabs(5)_"<table frame=""all"">")
    	do file.WriteLine(..Tabs(6)_"<tgroup align=""left"" cols=""5"">")
    	do file.WriteLine(..Tabs(7)_"<colspec colname=""c1"" colwidth=""1*""/>")
    	do file.WriteLine(..Tabs(7)_"<colspec colname=""c2"" colwidth=""3*""/>")
    	do file.WriteLine(..Tabs(7)_"<colspec colname=""c3"" colwidth=""3*""/>")
    	do file.WriteLine(..Tabs(7)_"<colspec colname=""c4"" colwidth=""1*""/>")
    	do file.WriteLine(..Tabs(7)_"<colspec colname=""c5"" colwidth=""1*""/>")
    	do file.WriteLine(..Tabs(7)_"<thead>")
    	do file.WriteLine(..Tabs(8)_"<row>")
    	do file.WriteLine(..Tabs(9)_"<entry>HTTP method</entry>")
    	do file.WriteLine(..Tabs(9)_"<entry>Body</entry>")
    	do file.WriteLine(..Tabs(9)_"<entry>Response</entry>")
    	do file.WriteLine(..Tabs(9)_"<entry>Return code</entry>")
    	do file.WriteLine(..Tabs(9)_"<entry>Delay(s)</entry>")
    	do file.WriteLine(..Tabs(8)_"</row>")
    	do file.WriteLine(..Tabs(7)_"</thead>")
    	do file.WriteLine(..Tabs(7)_"<tbody>")
    	
    	set restmethod = $Order(^MockMat(mockName, method, ""))
 		while (restmethod '= "") {
	 		
			set param = $Order(^MockMat(mockName, method, restmethod, ""))
			while (param '= "") {
				do file.WriteLine(..Tabs(8)_"<row>")
				do file.WriteLine(..Tabs(9)_"<entry>"_restmethod_"</entry>")
				if param '= "GET" {
				do file.WriteLine(..Tabs(9)_"<entry>"_param_"</entry>")
				} else {
				do file.WriteLine(..Tabs(9)_"<entry></entry>")
				}			
				set response = ^MockMat(mockName, method, restmethod, param)
				do file.WriteLine(..Tabs(9)_"<entry>"_response_"</entry>")
				set code = ^MockMat(mockName, method, restmethod, param, "code")
				do file.WriteLine(..Tabs(9)_"<entry>"_code_"</entry>")
				set delay = ^MockMat(mockName, method, restmethod, param, "delay")
				do file.WriteLine(..Tabs(9)_"<entry>"_delay_"</entry>")
				do file.WriteLine(..Tabs(8)_"</row>")
			
				s param = $Order(^MockMat(mockName, method, restmethod, param)) // next params
			}
			s restmethod = $Order(^MockMat(mockName, method, restmethod)) // next restmethod
			 	
 		}
    	do file.WriteLine(..Tabs(7)_"</tbody>")
    	do file.WriteLine(..Tabs(6)_"</tgroup>")
    	do file.WriteLine(..Tabs(5)_"</table>")
    	do file.WriteLine(..Tabs(4)_"</listitem>")
 	} 
	do file.WriteLine(..Tabs(3)_"</itemizedlist>")
	do file.WriteLine(..Tabs(2)_"</section>")


	do file.WriteLine($$$TAB_"</chapter>")
	do file.WriteLine("</book>")
	

	return $$$OK
}

}
