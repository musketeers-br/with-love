Class dc.withLove.service.Dispatch Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/process-sda" Method="POST" Call="ProcessSDA"/>
</Routes>
}

ClassMethod ProcessSDA() As %Status
{
    Set tSC = $$$OK
    Try {
        Set tContent = %request.Content
        If '$IsObject(tContent) {
             Set tContent = %request.Get("content") // Fallback
        }
        
        Set tResult = ##class(dc.withLove.engine.SDAHanler).Process(tContent)
        Write tResult.%ToJSON()
        
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Return tSC
}

}
