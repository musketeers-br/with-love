Class dc.withLove.engine.GenAi Extends %RegisteredObject
{

/// UI Agent Prompt: Specialist in Visuals (Tailwind/Alpine)
/// Critical: Embeds CSS in <head> to ensure dark mode works in the iframe
Parameter UIPROMPT = {"You are the UI Agent. Generate the HTML code for the requested App."_
    "RULES: 1. Use TailwindCSS and Alpine.js. 2. Embed this CSS in <head> for styling: "_
    "'<style> :root { --bg-color: #0f172a; --card-bg: #1e293b; --text-color: #e2e8f0; --accent: #db2777; } "_
    "body { background-color: var(--bg-color); color: var(--text-color); font-family: sans-serif; height: 100vh; display: flex; align-items: center; justify-content: center; margin: 0; } "_
    ".card { background-color: var(--card-bg); padding: 2rem; border-radius: 1rem; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1); width: 100%; max-width: 400px; border: 1px solid #334155; } "_
    "input, select { width: 100%; background: #020617; border: 1px solid #475569; color: white; padding: 0.75rem; border-radius: 0.5rem; margin-bottom: 1rem; display: block; box-sizing: border-box; } "_
    "button { width: 100%; background: linear-gradient(to right, #db2777, #e11d48); color: white; padding: 0.75rem; border-radius: 0.5rem; border: none; font-weight: bold; cursor: pointer; } "_
    "button:hover { opacity: 0.9; } </style>'"_
    "Output ONLY the raw HTML inside <body>."};

/// Backend Agent Prompt: Specialist in IRIS Persistent Classes
/// Updated for Multi-Tenancy and Safe Compilation
Parameter BACKENDPROMPT = {"You are the Backend Agent. Generate an InterSystems IRIS Persistent Class."_
    "RULES:"_
    "1. Define the class name simply (e.g., 'Patient'). The system will auto-assign the package based on the Tenant."_
    "2. Inherit from (%Persistent, %JSON.Adaptor)."_
    "3. Use simple types: %String, %Integer, %Boolean, %Date."_
    "4. CRITICAL: DO NOT generate the <Storage> XML block. The compiler will generate it automatically."_
    "5. Output ONLY the ObjectScript code. No markdown formatting."};

/// FHIR Agent Prompt: Specialist in Interoperability (Generation)
Parameter FHIRPROMPT = {"You are the FHIR Agent. Generate a FHIR R4 Bundle JSON based on the request."_
    "Output ONLY the JSON."};

/// Integration Agent Prompt: Specialist in Data Ingestion (Extraction)
Parameter INTEGRATIONPROMPT = {"You are the Integration Agent. Your job is to extract JSON content from the user message."_
    "The user will provide FHIR data. You must output ONLY the raw JSON string found."_
    "Do not explain, do not wrap in markdown."};

/// Supervisor Prompt: The Router Logic
/// Decides which worker is best suited for the user request
Parameter SUPERVISORPROMPT = {"You are the Supervisor of a Hospital Software Team. Analyze the user request and DELEGATE to a worker."_
    "CONTEXT FROM KNOWLEDGE BASE: "_
    "{{CONTEXT_DATA}}"_
    "--------------------------------"_
    "Available Workers: [UI AGENT], [BACKEND AGENT], [FHIR AGENT], [INTEGRATION AGENT]."_
    "Response Format:"_
    "- If user wants an App Interface: '[DELEGATE: UI] <instructions>'"_
    "- If user wants a Database Class (Table): '[DELEGATE: BACKEND] <instructions>'"_
    "- If user wants FHIR Data generated: '[DELEGATE: FHIR] <instructions>'"_
    "- If user wants to IMPORT/CONVERT FHIR data: '[DELEGATE: INTEGRATION] <json_content>'"_
    "- If general chat: Just answer using the Context provided."};

/// The "LangGraph" Orchestrator running in IRIS
/// Manages Session History and Routing
/// Orchestrator with RAG Support
ClassMethod AgentRun(pSessionId As %String, pTenantId As %String, pUserPrompt As %String, pApiKey As %String, pModel As %String) As %DynamicObject
{
    Set tResponse = { "type": "text", "content": "" }
    
    Try {
        // 1. Load Session
        Set tSession = ##class(dc.withLove.storage.LLMSession).SessionIdxOpen(pTenantId, pSessionId)
        If '$IsObject(tSession) {
            Set tSession = ##class(dc.withLove.storage.LLMSession).%New()
            Set tSession.SessionId = pSessionId
            Set tSession.TenantId = pTenantId
        }
        Do tSession.AddMessage("user", pUserPrompt)
        
        // --- STEP RAG: RETRIEVE CONTEXT ---
        Set tContextString = ""
        // Gera embedding da pergunta do usuário
        Set tUserVector = ..GenerateEmbedding(pUserPrompt)
        
        If (tUserVector '= "") {
            // Busca os 3 documentos mais similares no banco
            Set tContextString = ..RetrieveContext(pTenantId, tUserVector)
        }
        
        If tContextString = "" Set tContextString = "No specific documents found."
        
        // 2. Prepare Supervisor Prompt with Context
        Set tSystemPrompt = $Replace(..#SUPERVISORPROMPT, "{{CONTEXT_DATA}}", tContextString)
        
        // 3. Supervisor Decision
        Set tHistory = tSession.GetHistory()
        Set tDecision = ..PyCallLLM(tHistory.%ToJSON(), pApiKey, pModel, tSystemPrompt)
        
        // 4. Routing Logic (Mantida igual, mas agora o Supervisor é "mais esperto")
        If (tDecision [ "[DELEGATE: UI]") {
            Set tInstructions = $Piece(tDecision, "[DELEGATE: UI]", 2)
            // Passa o contexto também para o Worker UI (para ele saber cores, regras, etc)
            Set tFullInstructions = "Context: " _ tContextString _ $C(10) _ "Instructions: " _ tInstructions
            Set tCode = ..CallWorker(tFullInstructions, pApiKey, pModel, ..#UIPROMPT)
            
            Set tResponse.type = "code"
            Set tResponse.content = tCode
            Set tResponse.thought = "Supervisor used Knowledge Base to guide UI Agent."
            Do tSession.AddMessage("assistant", "Generated UI Code using Hospital Protocols.")
            
        } ElseIf (tDecision [ "[DELEGATE: BACKEND]") {
            // ... (Lógica Backend mantida igual) ...
            Set tInstructions = $Piece(tDecision, "[DELEGATE: BACKEND]", 2)
            Set tCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#BACKENDPROMPT)
            Set tDeployResult = ##class(dc.withLove.engine.ClassFactory).DeployBackend(tCode, pTenantId)
            
            If ($Extract(tDeployResult,1,5) = "ERROR") {
                Set tResponse.content = "❌ **Backend Build Failed**" _ $C(10) _ tDeployResult
            } Else {
                Set tResponse.content = "✅ **Database Table Created!**" _ $C(10) _ "Table: `" _ tDeployResult _ "`"
            }
            Set tResponse.type = "text"
            Do tSession.AddMessage("assistant", tResponse.content)

        } ElseIf (tDecision [ "[DELEGATE: INTEGRATION]") {
            // ... (Lógica Integration mantida igual) ...
            Set tRawContent = $Piece(tDecision, "[DELEGATE: INTEGRATION]", 2)
            Set tJsonData = ..CallWorker(tRawContent, pApiKey, pModel, ..#INTEGRATIONPROMPT)
            Set tResult = ##class(dc.withLove.engine.FHIRToSDAHandler).ProcessFHIR(tJsonData)
            If (tResult.status = "success") {
                Set tResponse.type = "text"
                Set tResponse.content = "✅ **Integration Successful!**" _ $C(10) _ "SDA3 XML Generated."
            } Else {
                Set tResponse.type = "text"
                Set tResponse.content = "❌ **Integration Failed:** " _ tResult.error
            }
            Do tSession.AddMessage("assistant", tResponse.content)
            
        } Else {
            // General Chat
            Set tResponse.type = "text"
            Set tResponse.content = tDecision
            Do tSession.AddMessage("assistant", tDecision)
        }
        
    } Catch ex {
        Set tResponse.type = "error"
        Set tResponse.content = ex.DisplayString()
    }
    
    Return tResponse
}

/// Helper: Calls a specific Worker Agent (One-shot)
ClassMethod CallWorker(pInstructions As %String, pApiKey As %String, pModel As %String, pSystemPrompt As %String) As %String
{
    Set tMsgs = [{"role":"system", "content":(pSystemPrompt)}, {"role":"user", "content":(pInstructions)}]
    Set tContent = ..PyCallLLM(tMsgs.%ToJSON(), pApiKey, pModel, "")
    
    // Sanitize common markdown artifacts
    Set tContent = $Replace(tContent, "```html", "")
    Set tContent = $Replace(tContent, "```objectscript", "")
    Set tContent = $Replace(tContent, "```json", "")
    Set tContent = $Replace(tContent, "```", "")
    Set tContent = $ZStrip(tContent, "<>W") // Trim whitespace
    
    Return tContent
}

/// Internal Python method to call LiteLLM
/// Supports OpenAI, Anthropic, and Gemini dynamically
ClassMethod PyCallLLM(messagesJson As %String, apiKey As %String, model As %String, systemPrompt As %String = "") As %String [ Language = python ]
{
    from litellm import completion
    import json
    import os
    
    try:
        # Dynamic Env Var configuration based on model family
        if "gpt" in model: 
            os.environ["OPENAI_API_KEY"] = apiKey
        elif "claude" in model: 
            os.environ["ANTHROPIC_API_KEY"] = apiKey
        elif "gemini" in model: 
            os.environ["GEMINI_API_KEY"] = apiKey
            
        msgs = json.loads(messagesJson)
        
        # Prepend System Prompt if provided (used by Supervisor)
        if systemPrompt and systemPrompt != "":
            if msgs[0]['role'] != 'system':
                msgs.insert(0, {"role": "system", "content": systemPrompt})
        
        response = completion(model=model, messages=msgs)
        return response.choices[0].message.content

    except Exception as e:
        return f"Error: {str(e)}"
}

ClassMethod GenerateEmbedding(pText As %String) As %String [ Language = python ]
{
    try:
        from sentence_transformers import SentenceTransformer
        import json
        
        # Carrega modelo leve (cacheado na memória se possível em prod)
        model = SentenceTransformer('all-MiniLM-L6-v2')
        
        # Gera embeddings
        embeddings = model.encode(pText)
        
        # Retorna como string JSON para o ObjectScript converter para %Vector
        return str(embeddings.tolist())
    except Exception as e:
        print(f"Embedding Error: {e}")
        return ""
}

ClassMethod RetrieveContext(pTenantId As %String, pVectorStr As %String) As %String
{
    Set tContext = ""
    Try {
        Set tVector = $ZConvert(pVectorStr, "I", "JSON")
        
        Set tQuery = "SELECT TOP 3 Title, Content FROM dc_withLove_storage.KnowledgeBase " _
                "WHERE TenantID = ? " _
                "ORDER BY VECTOR_DOT_PRODUCT(Embedding, TO_VECTOR(?, DECIMAL)) DESC"

        Set tRS = ##class(%SQL.Statement).%ExecDirect(, tQuery, pTenantId, tVector)
        
        While tRS.%Next() {
            Set tContext = tContext _ "Document: " _ tRS.Title _ $C(10) _ 
                "Content: " _ $Extract(tRS.Content, 1, 1000) _ "..." _ $C(10,10)
        }
    } Catch ex {
        Set tContext = "Error retrieving context: " _ ex.DisplayString()
    }
    Return tContext
}

}
