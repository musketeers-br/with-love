Class dc.withLove.service.Dispatch Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/simulate-ai" Method="POST" Call="SimulateAI"/>
    <Route Url="/process-sda" Method="POST" Call="ProcessSDA"/>
</Routes>
}

/// Endpoint auxiliar para o MVP: Devolve um XML SDA complexo para demonstração
ClassMethod SimulateAI() As %Status
{
    Set tResponse = {
        "sda": ("<Container>"_
        "<Patient>"_
            "<Name><FamilyName>Garcia</FamilyName><GivenName>Maria</GivenName></Name>"_
            "<Gender><Code>F</Code></Gender>"_
            "<BirthTime>1985-04-12T00:00:00</BirthTime>"_
        "</Patient>"_
        "<Encounters>"_
            "<Encounter>"_
                "<Description>Primary Care Visit - Diabetes Checkup</Description>"_
                "<Diagnoses>"_
                "<Diagnosis>"_
                    "<DiagnosisCode><Code>E11.9</Code><Description>Type 2 diabetes mellitus</Description></DiagnosisCode>"_
                "</Diagnosis>"_
                "</Diagnoses>"_
            "</Encounter>"_
        "</Encounters>"_
        "<Medications>"_
            "<Medication>"_
                "<DrugName>Metformin 500mg</DrugName>"_
            "</Medication>"_
        "</Medications>"_
        "</Container>")
    }
    Write tResponse.%ToJSON()
    Return $$$OK
}

/// Endpoint Real: Chama a Engine de Interoperabilidade
ClassMethod ProcessSDA() As %Status
{
    Set tSC = $$$OK
    Try {
        Set tContent = %request.Content
        If '$IsObject(tContent) {
            Set tStr = tContent
            Set tContent = ##class(%Stream.GlobalCharacter).%New()
            Do tContent.Write(tStr)
        }
        
        Set tResult = ##class(dc.withLove.engine.SDAHandler).Process(tContent)
        Write tResult.%ToJSON()
        
    } Catch ex {
        Set tSC = ex.AsStatus()
        Set tErr = {"error": ($System.Status.GetErrorText(tSC))}
        Write tErr.%ToJSON()
    }
    Return tSC
}

}
