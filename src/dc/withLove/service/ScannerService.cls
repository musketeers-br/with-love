Class dc.withLove.service.ScannerService Extends %RegisteredObject
{

/// Lists all Persistent Classes (Tables) belonging to the user/tenant.
/// Filters out system classes and libraries to reduce noise.
ClassMethod ListUserAssets(pTenantId As %String) As %DynamicArray
{
    Set tArr = []
    Try {
        // Query the Class Dictionary to find user classes
        Set tQuery = "SELECT ID, Super FROM %Dictionary.ClassDefinition " _
                    "WHERE Name NOT LIKE '%Lib%' " _ 
                    "AND Name NOT LIKE '%System%' " _
                    "AND Name NOT LIKE 'Ens%' " _
                    "AND Name NOT LIKE 'HS%' " _
                    "AND Name NOT LIKE 'dc.withLove.engine%' " // Ignore the engine itself
        Set tRS = ##class(%SQL.Statement).%ExecDirect(, tQuery)
        
        While tRS.%Next() {
            // Filter by Tenant ID if the naming convention is used (dc.withLove.<tenant>...)
            // If pTenantId is provided, we only show assets containing that string
            If (pTenantId'="") && (tRS.ID '[ pTenantId) Continue
            
            Do tArr.%Push({
                "name": (tRS.ID),
                "type": "class",
                "super": (tRS.Super)
            })
        }
    } Catch ex {
        // Silently fail loop on error
    }
    Return tArr
}

/// Retrieves the full source code (UDL) of a given asset.
/// Used by the AI to analyze structure and suggest improvements.
ClassMethod GetAssetContent(pAssetName As %String) As %String
{
    Set tContent = ""
    Try {
        // Check if class exists
        If ##class(%Dictionary.ClassDefinition).%ExistsId(pAssetName) {
            Set tStream = ##class(%Stream.GlobalCharacter).%New()
            // Export class definition to stream
            Do ##class(%Dictionary.ClassDefinition).%OpenId(pAssetName).ExportToStream(.tStream)
            Do tStream.Rewind()
            Set tContent = tStream.Read($$$MaxStringLength)
        } Else {
            Set tContent = "Class not found: " _ pAssetName
        }
    } Catch ex {
        Set tContent = "Error retrieving content: " _ ex.DisplayString()
    }
    Return tContent
}

}
