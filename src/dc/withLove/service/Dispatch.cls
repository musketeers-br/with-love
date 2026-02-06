Class dc.withLove.service.Dispatch Extends %CSP.REST
{

Parameter CONTENTTYPE = "application/json";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/generate-app" Method="POST" Call="GenerateApp"/>
    <Route Url="/deploy-app" Method="POST" Call="DeployApp"/>
    <Route Url="/generate-fhir" Method="POST" Call="GenerateFHIR"/>

    <Route Url="/knowledge/add" Method="POST" Call="AddKnowledge"/>
    <Route Url="/knowledge/list" Method="GET" Call="ListKnowledge"/>
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

ClassMethod GenerateApp() As %Status
{
    Try {
        Set tApiKey = ..GetAPIKey()
        
        // CORREÇÃO: Usando Return e Blocos para evitar erro de compilação
        If tApiKey="" {
            Write {"error":"Missing Authorization Header"}.%ToJSON()
            Return $$$OK
        }

        Set tPayload = {}.%FromJSON(%request.Content)
        Set tPrompt = tPayload.prompt
        Set tModel = tPayload.model
        If tModel="" Set tModel = "gpt-4o"

        // Chama a Engine GenAI
        Set tHtml = ##class(dc.withLove.engine.GenAi).Generate(tPrompt, tApiKey, tModel)
        
        Write { "html": (tHtml) }.%ToJSON()

    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

ClassMethod DeployApp() As %Status
{
    Try {
        Set tPayload = {}.%FromJSON(%request.Content)
        
        Set tTenant = ..GetTenant()
        Set tName = tPayload.appName
        Set tHtml = tPayload.html
        Set tPrompt = tPayload.prompt
        Set tModel = tPayload.model
        
        // Chama a AppFactory
        Set tUrl = ##class(dc.withLove.engine.AppFactory).CreateApp(tTenant, tName, tHtml, tPrompt, tModel)
        
        If $Extract(tUrl,1,5)="ERROR" {
            Write {"error": (tUrl)}.%ToJSON()
        } Else {
            Write {"status": "deployed", "url": (tUrl)}.%ToJSON()
        }

    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

/// Rota opcional para demo de FHIR puro
ClassMethod GenerateFHIR() As %Status
{
    Try {
        Set tApiKey = ..GetAPIKey()
        
        // Segurança: Valida header também aqui
        If tApiKey="" {
            Write {"error":"Missing Authorization Header"}.%ToJSON()
            Return $$$OK
        }

        Set tPayload = {}.%FromJSON(%request.Content)
        Set tPrompt = tPayload.prompt
        Set tModel = tPayload.model
        
        // Usa prompt de sistema customizado para FHIR
        Set tSysPrompt = "You are an expert in HL7 FHIR R4. Output ONLY raw JSON Bundle."
        Set tContent = ##class(dc.withLove.engine.GenAi).Generate(tPrompt, tApiKey, tModel, tSysPrompt)
        
        Write { "fhir": (tContent) }.%ToJSON()
    } Catch ex {
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Return $$$OK
}

/// API: POST /knowledge/add
/// Body: { "title": "Protocolo Dengue", "content": "..." }
ClassMethod AddKnowledge() As %Status
{
    Try {
        Set tTenant = ..GetTenant()
        Set tPayload = {}.%FromJSON(%request.Content)
        
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

}
