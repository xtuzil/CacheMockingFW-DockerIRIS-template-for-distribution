Class MockFW.Utils Extends %RegisteredObject
{

/// Method, which add multiple $$$TAB to line of generated code
ClassMethod Tabs(count)
{
	set res = ""
	for i=1:1:count {
		set res = res_$$$TAB
	}
	return res
}

/// Auxiliary method for retrieving from .csv.
/// Cut extra double quotes to corect saving
ClassMethod CutExtraQuotes(string As %String) As %String
{
	set n = $Length(string)
	set result = ""
	For i=1:1:n {
		Set piece = $Extract(string,i, i)
		if piece = """" {
			if $Extract(string,i+1, i+1) = """" {
				set result = result_piece
			}
		} else {
			set result = result_piece	
		}
	}
	
	return result
}

/// Compare two strings (potentionally objects)
ClassMethod Compare(savedObject, params) As %Integer
{
	
	if savedObject = params {
		return 1
	}

	try { // try transform string to object
		if ('$ISOBJECT(savedObject)) {
			set savedObject={}.%FromJSON(savedObject)
		}
		if ('$ISOBJECT(params)) {
			set params={}.%FromJSON(params)
		}
		return ..CompareObjects(savedObject, params)

	} catch errobj { // one of string can not be tranform to object
		return 0
	}
}

/// Method compare two dynamic objects
ClassMethod CompareObjects(savedObject, params) As %Status
{
		if ((..CountAtributes(savedObject)) '= (..CountAtributes(params))) {
			quit 0
		}

		set iterator = params.%GetIterator()
    	while iterator.%GetNext(.key, .value) {
			if ($ISOBJECT(value)) {
				set valueS = savedObject.%Get(key)
				if (('$ISOBJECT(valueS)) || ($CLASSNAME(value)'=$CLASSNAME(valueS))) {
					return 0
				}

				if ($CLASSNAME(value)="%Library.DynamicObject") { // compare nested objects
					if ('..CompareObjects(value, valueS)) {
						return 0
					}
				} else {
				 	if ('..CompareArrays(value, valueS)) { // compare nested arrays
						return 0
					}
				}
			} else {
    			if (savedObject.%Get(key) '= value) {
    				return 0
    			}
			}
   
		}
	quit 1
}

/// Method compare two dynamic arrays
ClassMethod CompareArrays(saved, params) As %Status
{
	if (saved.%Size() '= params.%Size()) {
		return 0
	}

	set iterator = params.%GetIterator()

	while iterator.%GetNext(.key, .value) {
		set iteratorS = saved.%GetIterator()
		set found = "false"
		while iteratorS.%GetNext(.keyS, .valueS) {
			if ($ISOBJECT(value) && '$ISOBJECT(valueS)) || ('$ISOBJECT(value) && $ISOBJECT(valueS)) {
				continue
			}

			if ($ISOBJECT(value)) {
				if ($CLASSNAME(value)="%Library.DynamicObject") { // compare nested objects
					if (..CompareObjects(value, valueS)) {
						set found = "true"
						quit
					}
				} else {
				 	if (..CompareArrays(value, valueS)) { // compare nested arrays
						set found = "true"
						quit
					}
				}
			} else {
				if value=valueS {
					set found = "true"
					quit
				}
			}	
		}
		if found="false" {
			return 0
		}
	}
	quit 1
}

/// Return '1' if the string can be transformed to the object, else '0'
/// Use regex syntax. Work right only for 2-3 layers of json object 
ClassMethod CanConvertToJSON(json) As %Integer
{
	set jsonWithoutSpaces = $ZSTRIP(json,"*W")
	set item = "(\""[:alnum:]+\"")"
	set itemValue = "((\""[:alnum:]+\"")|([:digit:]+))"
	set element = item_"\:"_itemValue
	set object = "\{("_element_"\,)*"_element_"\}"
	set array = "((\[((("_element_"\,)*"_element_")|(("_object _"\,)*"_object_")|(("_itemValue _"\,)*"_itemValue_"))\])|(\[\]))"

	set objectInObject = item_"\:"_object
	set arrayInObject = item_"\:"_array

	set regex = "\{((("_element_")|("_objectInObject_")|("_arrayInObject_"))\,)*(("_element_")|("_objectInObject_")|("_arrayInObject_"))\}"
	
	return $match(jsonWithoutSpaces, regex)
}

/// Auxiliary method. Count the atributes of object
ClassMethod CountAtributes(obj) As %Integer
{
	#dim count As %Integer = 0 
	set iterator = obj.%GetIterator()
    
    while iterator.%GetNext(.key, .value) {
    	set count = count + 1
    }
    
    return count
}

/// Transfrom arguments to the list as %ListOfDataTypes
ClassMethod TransformArgsToList(args...) As %List
{
   // Create a %ListOfDataTypes even though it may contain objects.
   #dim listArgs = ##class(%ListOfDataTypes).%New()
   #dim i AS %Integer
   for i = 1 : 1 : $get(args, 0)
   {
      do listArgs.Insert($get(args(i)))
   }
   
   quit listArgs
}

}
