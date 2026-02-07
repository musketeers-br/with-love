Class dc.withLove.engine.FHIRToSDAHandler Extends %RegisteredObject
{

/// Transforms a FHIR Bundle (JSON) into an SDA3 Container (XML)
/// and handles namespace configuration errors gracefully.
ClassMethod ProcessFHIR(pFHIRContent As %String) As %DynamicObject
{
    Set tResponse = {}
    Try {
        If '##class(%Dictionary.CompiledClass).%ExistsId("HS.FHIR.DTL.Util.API.Transform.FHIRToSDA3") {
            Throw ##class(%Exception.General).%New("System", 5001, , "Class HS.FHIR.DTL.Util.API.Transform.FHIRToSDA3 not found. Please ensure InterSystems IRIS for Health is installed.")
        }

        Set tDynObj = {}.%FromJSON(pFHIRContent)
        
        // If the input is a single Resource (e.g., Patient), wrap it in a Transaction Bundle
        // The Transformer requires a Bundle to process correctly.
        If (tDynObj.resourceType '= "Bundle") {
            Set tBundle = {
                "resourceType": "Bundle",
                "type": "transaction",
                "entry": []
            }
            // Create a POST request entry for the resource
            Set tEntry = { 
                "resource": (tDynObj),
                "request": { "method": "POST", "url": (tDynObj.resourceType) }
            }
            Do tBundle.entry.%Push(tEntry)
            Set tDynObj = tBundle
        }

        Set tTransformer = ""
        Try {
            // Attempt to initialize for FHIR R4 schema ("vR4")
            Set tTransformer = ##class(HS.FHIR.DTL.Util.API.Transform.FHIRToSDA3).%New("vR4")
            
        } Catch exNew {
            // Error 192 means the FHIR Metadata/Schema is not loaded in this Namespace
            // This happens if the Namespace is not configured as an Interoperability Foundation
            If (exNew.Code = 192) {
                Throw ##class(%Exception.General).%New("Integration", 192, , "FHIR Schema 'vR4' not loaded. This Namespace is likely not configured as a HealthConnect Foundation. Run: Do ##class(HS.Util.Installer.Foundation).Install($Namespace)")
            } Else {
                Throw exNew
            }
        }

        Set tSDAContainer = ""
        Set tSC = tTransformer.TransformBundle(tDynObj, .tSDAContainer)
        If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
        
        // Serialize SDA Result to XML
        // Converts the SDA3 Object into an XML Stream for display/transfer
        Set tXMLStream = ##class(%Stream.GlobalCharacter).%New()
        Do tSDAContainer.ToQuickXMLStream(.tXMLStream)
        
        Do tXMLStream.Rewind()
        Set tXMLString = tXMLStream.Read($$$MaxStringLength)
        
        Set tResponse = {
            "status": "success",
            "message": "FHIR successfully transformed to SDA3.",
            "sda": (tXMLString)
        }
        
    } Catch ex {
        Set tErrText = ex.DisplayString()
        
        // Improve readability for common class missing errors
        If tErrText["<class>" Set tErrText = "Dependencies missing: " _ tErrText
        
        Set tResponse = {
            "status": "error",
            "error": (tErrText)
        }
    }
    Return tResponse
}

}
