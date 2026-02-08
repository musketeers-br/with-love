Class dc.withLove.engine.ApiFactory Extends %RegisteredObject
{

ClassMethod DeployApi(pSourceCode As %String, pTenantId As %String) As %String
{
    Set tResult = ""
    Try {
        // 1. Sanitization
        Set pSourceCode = $Replace(pSourceCode, "```objectscript", "")
        Set pSourceCode = $Replace(pSourceCode, "```", "")
        
        // Fix 1-8 (Macros, Headers, Body, Verbs, Signatures, IDs)
        If (pSourceCode [ "$$$GETERRORTEXT") Set pSourceCode = $Replace(pSourceCode, "$$$GETERRORTEXT", "$System.Status.GetErrorText")
        If (pSourceCode [ "%SetResponse") Set pSourceCode = $Replace(pSourceCode, "..%SetResponse", "%response.SetHeader")
        If (pSourceCode [ "%SetContentType") Set pSourceCode = $Replace(pSourceCode, "Do ..%SetContentType", "Set %response.ContentType = ")
        If (pSourceCode [ "%GetEventReader") Set pSourceCode = $Replace(pSourceCode, "..%GetEventReader()", "%request.Content")
        
        If (pSourceCode [ "OnPreDispatch") && (pSourceCode '[ "As %Status") {
            Set tMatcher = ##class(%Regex.Matcher).%New("(ClassMethod OnPreDispatch.*?)(\s*\{)")
            Set tMatcher.Text = pSourceCode
            If tMatcher.Locate() {
                Set tFixedSig = tMatcher.Group(1) _ " As %Status " _ tMatcher.Group(2)
                Set pSourceCode = $Replace(pSourceCode, tMatcher.Group(0), tFixedSig)
            }
        }

        Set pSourceCode = $Replace(pSourceCode, "Method=""LIST""", "Method=""GET""")
        Set pSourceCode = $Replace(pSourceCode, "Method=""UPDATE""", "Method=""PUT""")
        Set pSourceCode = $Replace(pSourceCode, "Method=""CREATE""", "Method=""POST""")
        Set pSourceCode = $Replace(pSourceCode, "Method=""PATCH""", "Method=""PUT""")

        If (pSourceCode [ "Set %response.Body =") Set pSourceCode = $Replace(pSourceCode, "Set %response.Body =", "Write ")
        If (pSourceCode [ "Do %response.Body.Write") Set pSourceCode = $Replace(pSourceCode, "Do %response.Body.Write", "Write ")
        If (pSourceCode [ "%response.Body.Write") Set pSourceCode = $Replace(pSourceCode, "%response.Body.Write", "Write ")
        Set pSourceCode = $Replace(pSourceCode, "Do Write", "Write")
        
        If (pSourceCode [ "$$$NORECORD") Set pSourceCode = $Replace(pSourceCode, "$$$NORECORD", "$System.Status.Error(5001, ""Record not found"")")

        Set tMatcher = ##class(%Regex.Matcher).%New("(?i)\$increment\s*\([^)]+\)")
        Set tMatcher.Text = pSourceCode
        Set pSourceCode = tMatcher.ReplaceAll("0")

        // Fix 10: HTTP Macros
        Set pSourceCode = $Replace(pSourceCode, "$$$HTTPStatusOK", """200 OK""")
        Set pSourceCode = $Replace(pSourceCode, "$$$HTTPStatusCreated", """201 Created""")
        Set pSourceCode = $Replace(pSourceCode, "$$$HTTPStatusNoContent", """204 No Content""")
        Set pSourceCode = $Replace(pSourceCode, "$$$HTTPStatusBadRequest", """400 Bad Request""")
        Set pSourceCode = $Replace(pSourceCode, "$$$HTTPStatusNotFound", """404 Not Found""")
        Set pSourceCode = $Replace(pSourceCode, "$$$HTTPStatusInternalServerError", """500 Internal Server Error""")

        // AI writes "Set list.%Push(x)" instead of "Do list.%Push(x)"
        // Regex: Finds 'Set' followed by spaces, then anything ending in .%Push(
        // Replaces 'Set' with 'Do' for that specific pattern.
        If (pSourceCode [ ".%Push(") {
            Set tMatcher = ##class(%Regex.Matcher).%New("Set\s+([a-zA-Z0-9\.]+\.%Push\()")
            Set tMatcher.Text = pSourceCode
            Set pSourceCode = tMatcher.ReplaceAll("Do $1")
        }

        // 2. Class Name & Package Logic
        Set tMatcher = ##class(%Regex.Matcher).%New("Class\s+([\w\.]+)\s+Extends")
        Set tMatcher.Text = pSourceCode
        If 'tMatcher.Locate() Throw ##class(%Exception.General).%New("Parser", 500, , "Could not identify Class Name.")
        Set tOriginalName = tMatcher.Group(1)
        
        Set tCleanTenant = $ZStrip(pTenantId, "*E", "", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        If tCleanTenant="" Set tCleanTenant = "default"
        
        Set tApiPkg = "dc.withLove." _ tCleanTenant _ ".api"
        Set tDataPkg = "dc.withLove." _ tCleanTenant _ ".data"
        
        Set tShortName = $Piece(tOriginalName, ".", *)
        Set tNewName = tApiPkg _ "." _ tShortName
        
        // Fix Package References (MyApp -> Tenant Package)
        Set pSourceCode = $Replace(pSourceCode, tOriginalName, tNewName)
        Set pSourceCode = $Replace(pSourceCode, "MyApp.", tDataPkg _ ".")
        Set pSourceCode = $Replace(pSourceCode, "User.", tDataPkg _ ".")
        
        // 4. Cleanup & Compile
        If ##class(%Dictionary.ClassDefinition).%ExistsId(tNewName) {
            Do $System.OBJ.Delete(tNewName, "-d")
        }
        
        Set tStream = ##class(%Stream.GlobalCharacter).%New()
        Do tStream.Write(pSourceCode)
        Do tStream.Rewind()
        
        Set tSC = $System.OBJ.LoadStream(tStream, "ck-d", .tErr)
        If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
        
        Set tResult = tNewName
        
    } Catch ex {
        Set tResult = "ERROR: " _ ex.DisplayString()
    }
    Return tResult
}

}
