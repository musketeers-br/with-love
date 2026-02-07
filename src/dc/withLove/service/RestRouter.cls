Class dc.withLove.service.RestRouter Extends %CSP.REST
{

/// Maps the dynamic URL structure to the Dispatch Logic
XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/:tenant/:service/*" Method="GET" Call="DispatchDynamic"/>
    <Route Url="/:tenant/:service/*" Method="POST" Call="DispatchDynamic"/>
    <Route Url="/:tenant/:service/*" Method="PUT" Call="DispatchDynamic"/>
    <Route Url="/:tenant/:service/*" Method="DELETE" Call="DispatchDynamic"/>
</Routes>
}

/// Dynamically dispatches the request to the target Generated API Class
ClassMethod DispatchDynamic(pTenant As %String, pService As %String) As %Status
{
    Set tSC = $$$OK
    Try {
        // 1. Sanitize Inputs to prevent injection
        Set tCleanTenant = $ZStrip(pTenant, "*E", "", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        Set tCleanService = $ZStrip(pService, "*E", "", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        
        // 2. Construct Target Class Name
        // Convention: dc.withLove.<Tenant>.api.<Service>
        Set tTargetClass = "dc.withLove." _ tCleanTenant _ ".api." _ tCleanService
        
        // 3. Validation
        If '##class(%Dictionary.CompiledClass).%ExistsId(tTargetClass) {
            Set %response.Status = "404 Not Found"
            Write {"error": ("API Service '"_tCleanService_"' not found for tenant '"_tCleanTenant_"'. Check if the AI compiled it correctly.")}.%ToJSON()
            Quit
        }
        
        // 4. Forwarding (Delegation)
        // We invoke the 'Page' method of the target %CSP.REST class manually.
        // The '1' argument skips internal header checks, allowing the target to handle auth if needed.
        Set tSC = $ClassMethod(tTargetClass, "Page", 1)
        
    } Catch ex {
        Set %response.Status = "500 Internal Server Error"
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return tSC
}

}
