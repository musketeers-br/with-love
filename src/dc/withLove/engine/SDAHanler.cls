Class dc.withLove.engine.SDAHanler
{

/// Receives an SDA XML Stream and returns a DynamicObject (FHIR Bundle)
ClassMethod Process(pXmlStream As %Stream.GlobalCharacter) As %DynamicObject
{
    Set tResponse = {}
    
    Try {
        // 1. Basic input validation
        If 'pXmlStream.Size {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Empty XML Stream"))
        }

        // 2. Import XML to SDA3 Container Object (Native HealthConnect)
        Set tReader = ##class(%XML.Reader).%New()
        Do tReader.OpenStream(pXmlStream)
        Do tReader.Correlate("Container", "HS.SDA3.Container")
        
        If 'tReader.Next(.tContainer, .tSC) {
            // Try to get specific XML error
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Failed to read SDA structure: " _ $System.Status.GetErrorText(tSC)))
        }
        
        // 3. Native Transformation: SDA3 -> FHIR R4
        // This creates a complete FHIR Bundle in memory
        // Requires a namespace with FHIR support enabled
        Set tBundle = ##class(HS.FHIR.DTL.Util.API.Transform.SDA3ToFHIR).Transform(tContainer, "R4", "JSON")
        
        Set tResponse = tBundle
        
    } Catch ex {
        Set tResponse = {
            "resourceType": "OperationOutcome",
            "issue": [{
                "severity": "error",
                "code": "processing",
                "diagnostics": (ex.DisplayString())
            }]
        }
    }
    
    Quit tResponse
}

}
