Class dc.withLove.service.Dispatch Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/agent/chat" Method="POST" Call="AgentChat"/>
    <Route Url="/deploy-app" Method="POST" Call="DeployApp"/>
    <Route Url="/generate-fhir" Method="POST" Call="GenerateFHIR"/>

    <Route Url="/knowledge/add" Method="POST" Call="AddKnowledge"/>
    <Route Url="/knowledge/list" Method="GET" Call="ListKnowledge"/>

    <Route Url="/scanner/assets" Method="GET" Call="ListAssets"/>
    <Route Url="/scanner/analyze" Method="POST" Call="AnalyzeAsset"/>
</Routes>
}

/// Helper: Extrai API Key do Header "Authorization: Bearer sk-..."
ClassMethod GetAPIKey() As %String
{
    Set tAuth = %request.GetCgiEnv("HTTP_AUTHORIZATION")
    If tAuth="" Return ""
    // Retorna a segunda parte da string (o token)
    Return $Piece(tAuth, " ", 2)
}

/// Helper: Extrai Tenant do Header
ClassMethod GetTenant() As %String
{
    Set tTenant = %request.GetCgiEnv("HTTP_X_TENANT_ID")
    If tTenant="" Return "default_tenant"
    Return tTenant
}

/// Endpoint: Conversational Agent (LangGraph-lite)
ClassMethod AgentChat() As %Status
{
    Try {
        Set tApiKey = ..GetAPIKey()
        If tApiKey="" { Write {"error":"Missing API Key"}.%ToJSON() Return $$$OK }

        Set tPayload = {}.%FromJSON(%request.Content)
        Set tPrompt = tPayload.prompt
        Set tSessionId = tPayload.sessionId
        Set tTenantId = "hospital-main" // In prod get from header
        Set tModel = tPayload.model

        // Call Agent
        Set tResult = ##class(dc.withLove.engine.GenAi).AgentRun(tSessionId, tTenantId, tPrompt, tApiKey, tModel)
        
        Write tResult.%ToJSON()

    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

/// Endpoint: Deploy (Compilation)
/// FIXED: Removed any potential raw "Write" calls that caused the SyntaxError
ClassMethod DeployApp() As %Status
{
    Try {
        Set tApiKey = ..GetAPIKey()
        If tApiKey="" { Write {"error":"Missing API Key"}.%ToJSON() Return $$$OK }
        
        Set tPayload = {}.%FromJSON(%request.Content)
        
        Set tTenant = "hospital-main"
        Set tName = tPayload.appName
        Set tHtml = tPayload.html
        Set tPrompt = "Deployed via API"
        Set tModel = "manual"
        
        Set tUrl = ##class(dc.withLove.engine.AppFactory).CreateApp(tTenant, tName, tHtml, tPrompt, tModel)
        
        If $Extract(tUrl,1,5)="ERROR" {
            Write {"error": (tUrl)}.%ToJSON()
        } Else {
            Write {"status": "deployed", "url": (tUrl)}.%ToJSON()
        }

    } Catch ex {
        // This catches the 'Compilação...' error if it was an exception and formats it as JSON
        Write {"error": ("Exception: " _ ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

/// Endpoint: Pure FHIR Generation (Optional Demo)
ClassMethod GenerateFHIR() As %Status
{
    Try {
        Set tApiKey = ..GetAPIKey()
        If tApiKey="" { Write {"error":"Missing Authorization Header"}.%ToJSON() Return $$$OK }

        Set tPayload = {}.%FromJSON(%request.Content)
        Set tPrompt = tPayload.prompt
        Set tModel = tPayload.model
        
        // Custom system prompt for FHIR expertise
        Set tSysPrompt = "You are an expert in HL7 FHIR R4. Output ONLY raw JSON Bundle."
        Set tContent = ##class(dc.withLove.engine.GenAi).CallWorker(tPrompt, tApiKey, tModel, tSysPrompt)
        
        Write { "fhir": (tContent) }.%ToJSON()
    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

/// Endpoint: Add Document to Knowledge Base
/// Body: { "title": "Dengue Protocol", "content": "..." }
ClassMethod AddKnowledge() As %Status
{
    Try {
        Set tTenant = ..GetTenant()
        Set tPayload = {}.%FromJSON(%request.Content)
        
        // Delegates to KnowledgeService (which handles embedding generation)
        Set tSC = ##class(dc.withLove.service.KnowledgeService).AddDocument(tTenant, tPayload.title, tPayload.content)
        
        If $$$ISERR(tSC) {
            Write {"error": ($System.Status.GetErrorText(tSC))}.%ToJSON()
        } Else {
            Write {"status": "created"}.%ToJSON()
        }
    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

/// API: GET /knowledge/list
ClassMethod ListKnowledge() As %Status
{
    Try {
        Set tTenant = ..GetTenant()
        Set tList = ##class(dc.withLove.service.KnowledgeService).ListDocuments(tTenant)
        Write tList.%ToJSON()
    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

/// Endpoint: Scanner - List User Assets (Tables/Classes)
ClassMethod ListAssets() As %Status
{
    Try {
        Set tTenant = ..GetTenant()
        Set tList = ##class(dc.withLove.service.ScannerService).ListUserAssets(tTenant)
        Write tList.%ToJSON()
    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

/// Endpoint: Scanner - Analyze Asset with AI
/// Body: { "assetName": "dc.withLove.data.Patient" }
ClassMethod AnalyzeAsset() As %Status
{
    Try {
        Set tApiKey = ..GetAPIKey()
        Set tPayload = {}.%FromJSON(%request.Content)
        Set tName = tPayload.assetName
        
        // 1. Retrieve Source Code
        Set tCode = ##class(dc.withLove.service.ScannerService).GetAssetContent(tName)
        
        // 2. Analyze using GenAI
        Set tSuggestions = ##class(dc.withLove.engine.GenAi).AnalyzeLegacy(tCode, tApiKey, "gpt-4o")
        
        Write tSuggestions.%ToJSON()
        
    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

}
