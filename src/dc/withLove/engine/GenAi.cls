Class dc.withLove.engine.GenAi Extends %RegisteredObject
{

// =========================================================

// 1. AGENT PROMPTS (SYSTEM INSTRUCTIONS)

// =========================================================

/// UI Agent: Specialist in Frontend generation using TailwindCSS and Alpine.js.
/// It embeds the necessary CSS in the <head> to ensure proper styling within the iframe.
Parameter UIPROMPT = {"You are the UI Agent. Generate the HTML code for the requested App."_
    "RULES: 1. Use TailwindCSS and Alpine.js. 2. Embed this CSS in <head> for styling: "_
    "'<style> :root { --bg-color: #0f172a; --card-bg: #1e293b; --text-color: #e2e8f0; --accent: #db2777; } "_
    "body { background-color: var(--bg-color); color: var(--text-color); font-family: sans-serif; height: 100vh; display: flex; align-items: center; justify-content: center; margin: 0; } "_
    ".card { background-color: var(--card-bg); padding: 2rem; border-radius: 1rem; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1); width: 100%; max-width: 400px; border: 1px solid #334155; } "_
    "input, select { width: 100%; background: #020617; border: 1px solid #475569; color: white; padding: 0.75rem; border-radius: 0.5rem; margin-bottom: 1rem; display: block; box-sizing: border-box; } "_
    "button { width: 100%; background: linear-gradient(to right, #db2777, #e11d48); color: white; padding: 0.75rem; border-radius: 0.5rem; border: none; font-weight: bold; cursor: pointer; } "_
    "button:hover { opacity: 0.9; } </style>'"_
    "Output ONLY the raw HTML inside <body>."};

/// Backend Agent: Specialist in IRIS Persistent Classes (SQL Tables).
/// Ensures Multi-Tenancy and Safe Compilation (forbids manual Storage generation).
Parameter BACKENDPROMPT = {"You are the Backend Agent. Generate an InterSystems IRIS Persistent Class."_
    "RULES:"_
    "1. Define the class name simply (e.g., 'Patient'). The system will auto-assign the package based on the Tenant."_
    "2. Inherit from (%Persistent, %JSON.Adaptor)."_
    "3. Use simple types: %String, %Integer, %Boolean, %Date."_
    "4. CRITICAL: DO NOT generate the <Storage> XML block. The compiler will generate it automatically."_
    "5. Output ONLY the ObjectScript code. No markdown formatting."};

/// API Agent: Specialist in creating REST APIs (%CSP.REST).
/// Defines routes and methods for JSON data access.
Parameter APIPROMPT = {"You are the API Agent. Generate an InterSystems IRIS REST Class (%CSP.REST)."_
    "RULES:"_
    "1. Inherit from %CSP.REST."_
    "2. Define the UrlMap XData block mapping routes to ClassMethods."_
    "3. Create ClassMethods for GET/POST/PUT/DELETE actions."_
    "4. Return JSON using Dynamic Object ({}.%ToJSON())."_
    "5. Use package 'dc.withLove.api' (system will auto-assign tenant)."_
    "6. Output ONLY the ObjectScript code."};

/// Interop Agent: Specialist in Ensemble/Interoperability Components.
/// Generates DTLs (Transformations), Business Operations, and Services.
Parameter INTEROPPROMPT = {"You are the Interoperability Agent. Generate InterSystems IRIS Interoperability components."_
    "RULES:"_
    "1. For Data Transformations, generate a Class extending 'Ens.DataTransformDTL'."_
    "2. CRITICAL: For DTLs, include the <XData name='DTL'> block with proper XML namespace."_
    "3. For Operations, generate a Class extending 'Ens.BusinessOperation' with MessageMap."_
    "4. Use package 'dc.withLove.interop' (system will adjust tenant)."_
    "5. Output ONLY the ObjectScript code."};

Parameter SUGGESTIONPROMPT = {"You are a Senior Software Architect analyzing legacy InterSystems IRIS code."_
    "Analyze the provided Class Definition and suggest 3 modernization actions."_
    "Output format: JSON Array of objects with 'title', 'action_type' and 'description'."_
    "Action Types: 'create_api', 'create_frontend', 'create_interop', 'optimize_sql'."_
    "Example: [{""title"": ""Create REST API"", ""action_type"": ""create_api"", ""description"": ""Expose this table via JSON REST services.""}]"_
    "Output ONLY the JSON array."};

/// Suggestion Agent: Analyzes Legacy Code (Brownfield Scanner).
/// Suggests modernization actions like creating APIs or UI for existing classes.
/// FHIR Agent: Generates synthetic FHIR R4 JSON data for testing.
Parameter FHIRPROMPT = {"You are the FHIR Agent. Generate a FHIR R4 Bundle JSON based on the request."_
    "Output ONLY the JSON."};

/// Integration Agent: Extracts JSON content from user messages for ingestion.
Parameter INTEGRATIONPROMPT = {"You are the Integration Agent. Your job is to extract JSON content from the user message."_
    "The user will provide FHIR data. You must output ONLY the raw JSON string found."_
    "Do not explain, do not wrap in markdown."};

/// Supervisor Prompt: The Router Logic.
/// It is RAG-Aware (receives Context) and delegates tasks to the correct Worker.
Parameter SUPERVISORPROMPT = {"You are the Supervisor of a Hospital Software Team. Analyze the user request and DELEGATE to a worker."_
    "CONTEXT FROM KNOWLEDGE BASE: "_
    "{{CONTEXT_DATA}}"_
    "--------------------------------"_
    "Available Workers: [UI AGENT], [BACKEND AGENT], [API AGENT], [INTEROP AGENT], [FHIR AGENT], [INTEGRATION AGENT]."_
    "Response Format:"_
    "- If user wants an App Interface: '[DELEGATE: UI] <instructions>'"_
    "- If user wants a Database Class (Table): '[DELEGATE: BACKEND] <instructions>'"_
    "- If user wants a REST API/Service: '[DELEGATE: API] <instructions>'"_
    "- If user wants Interop/DTL/HL7: '[DELEGATE: INTEROP] <instructions>'"_
    "- If user wants FHIR Data generated: '[DELEGATE: FHIR] <instructions>'"_
    "- If user wants to IMPORT/CONVERT FHIR data: '[DELEGATE: INTEGRATION] <json_content>'"_
    "- If general chat: Just answer using the Context provided."};

// =========================================================

// 2. ORCHESTRATOR LOGIC (LANGGRAPH-LITE)

// =========================================================

/// Main Entry Point. Manages Session, RAG Context, and Agent Routing.
ClassMethod AgentRun(pSessionId As %String, pTenantId As %String, pUserPrompt As %String, pApiKey As %String, pModel As %String) As %DynamicObject
{
    Set tResponse = { "type": "text", "content": "" }
    
    Try {
        // 1. Load or Create Session (Short-Term Memory)
        Set tSession = ##class(dc.withLove.storage.LLMSession).SessionIdxOpen(pTenantId, pSessionId)
        If '$IsObject(tSession) {
            Set tSession = ##class(dc.withLove.storage.LLMSession).%New()
            Set tSession.SessionId = pSessionId
            Set tSession.TenantId = pTenantId
        }
        Do tSession.AddMessage("user", pUserPrompt)
        
        // --- RAG STEP: RETRIEVE CONTEXT ---
        Set tContextString = ""
        // Generate Vector Embedding for the user prompt
        Set tUserVector = ..GenerateEmbedding(pUserPrompt)
        
        If (tUserVector '= "") {
            // Retrieve top relevant documents from KnowledgeBase using Vector Search
            Set tContextString = ..RetrieveContext(pTenantId, tUserVector)
        }
        
        If tContextString = "" Set tContextString = "No specific documents found."
        
        // 2. Prepare Supervisor System Prompt with injected Context
        Set tSystemPrompt = $Replace(..#SUPERVISORPROMPT, "{{CONTEXT_DATA}}", tContextString)
        
        // 3. Supervisor Decision (LLM Call)
        Set tHistory = tSession.GetHistory()
        Set tDecision = ..PyCallLLM(tHistory.%ToJSON(), pApiKey, pModel, tSystemPrompt)
        
        // 4. Routing Logic based on Supervisor Decision
        
        If (tDecision [ "[DELEGATE: UI]") {
            // ---> UI AGENT (Frontend)
            Set tInstructions = $Piece(tDecision, "[DELEGATE: UI]", 2)
            // Pass the RAG Context to the UI Agent so it knows about colors, protocols, etc.
            Set tFullInstructions = "Context: " _ tContextString _ $C(10) _ "Instructions: " _ tInstructions
            Set tCode = ..CallWorker(tFullInstructions, pApiKey, pModel, ..#UIPROMPT)
            
            Set tResponse.type = "code"
            Set tResponse.content = tCode
            Set tResponse.thought = "Supervisor used Knowledge Base to guide UI Agent."
            Do tSession.AddMessage("assistant", "Generated UI Code.")
            
        } ElseIf (tDecision [ "[DELEGATE: BACKEND]") {
            // ---> BACKEND AGENT (SQL Tables)
            Set tInstructions = $Piece(tDecision, "[DELEGATE: BACKEND]", 2)
            Set tCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#BACKENDPROMPT)
            
            // Deploy using ClassFactory
            Set tDeployResult = ##class(dc.withLove.engine.ClassFactory).DeployBackend(tCode, pTenantId)
            
            If ($Extract(tDeployResult,1,5) = "ERROR") {
                Set tResponse.content = "❌ **Backend Build Failed**" _ $C(10) _ tDeployResult
            } Else {
                Set tResponse.content = "✅ **Database Table Created!**" _ $C(10) _ "Table: `" _ tDeployResult _ "`"
            }
            Set tResponse.type = "text"
            Do tSession.AddMessage("assistant", tResponse.content)

        } ElseIf (tDecision [ "[DELEGATE: API]") {
            // ---> API AGENT (REST Services)
            Set tInstructions = $Piece(tDecision, "[DELEGATE: API]", 2)
            Set tCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#APIPROMPT)
            
            // Deploy using ApiFactory
            Set tClassName = ##class(dc.withLove.engine.ApiFactory).DeployApi(tCode, pTenantId)
            
            If ($Extract(tClassName,1,5) = "ERROR") {
                Set tResponse.content = "❌ **API Build Failed**" _ $C(10) _ tClassName
            } Else {
                // Construct the dynamic endpoint URL
                Set tService = $Piece(tClassName, ".", *)
                Set tUrl = "/withlove/services/" _ pTenantId _ "/" _ tService
                
                Set tResponse.content = "✅ **REST Service Deployed!**" _ $C(10) _ 
                                        "Endpoint: `" _ tUrl _ "`" _ $C(10) _
                                        "Class: `" _ tClassName _ "`"
            }
            Set tResponse.type = "text"
            Do tSession.AddMessage("assistant", tResponse.content)

        } ElseIf (tDecision [ "[DELEGATE: INTEROP]") {
            // ---> INTEROP AGENT (Ensemble Components)
            Set tInstructions = $Piece(tDecision, "[DELEGATE: INTEROP]", 2)
            Set tCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#INTEROPPROMPT)
            
            // Deploy using InteropFactory
            Set tClassName = ##class(dc.withLove.engine.InteropFactory).DeployComponent(tCode, pTenantId)
            
            If ($Extract(tClassName,1,5) = "ERROR") {
                Set tResponse.content = "❌ **Interop Build Failed**" _ $C(10) _ tClassName
            } Else {
                Set tResponse.content = "✅ **Interop Component Created!**" _ $C(10) _ "Class: `" _ tClassName _ "`"
            }
            Set tResponse.type = "text"
            Do tSession.AddMessage("assistant", tResponse.content)

        } ElseIf (tDecision [ "[DELEGATE: INTEGRATION]") {
            // ---> INTEGRATION AGENT (Data Ingestion)
            Set tRawContent = $Piece(tDecision, "[DELEGATE: INTEGRATION]", 2)
            Set tJsonData = ..CallWorker(tRawContent, pApiKey, pModel, ..#INTEGRATIONPROMPT)
            
            // Transform FHIR to SDA3
            Set tResult = ##class(dc.withLove.engine.FHIRToSDAHandler).ProcessFHIR(tJsonData)
            
            If (tResult.status = "success") {
                Set tResponse.type = "text"
                Set tResponse.content = "✅ **FHIR Ingested!**" _ $C(10) _ "SDA3 Generated."
            } Else {
                 Set tResponse.type = "text"
                 Set tResponse.content = "❌ **Integration Failed:** " _ tResult.error
            }
            Do tSession.AddMessage("assistant", tResponse.content)
            
        } Else {
            // ---> GENERAL CONVERSATION (Chat)
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

// =========================================================

// 3. HELPER METHODS & PYTHON BRIDGES

// =========================================================

/// Calls a specific Worker Agent with a defined System Prompt.
ClassMethod CallWorker(pInstructions As %String, pApiKey As %String, pModel As %String, pSystemPrompt As %String) As %String
{
    Set tMsgs = [{"role":"system", "content":(pSystemPrompt)}, {"role":"user", "content":(pInstructions)}]
    Set tContent = ..PyCallLLM(tMsgs.%ToJSON(), pApiKey, pModel, "")
    
    // Sanitize common markdown artifacts to return clean code/json
    Set tContent = $Replace(tContent, "```html", "")
    Set tContent = $Replace(tContent, "```objectscript", "")
    Set tContent = $Replace(tContent, "```json", "")
    Set tContent = $Replace(tContent, "```", "")
    Set tContent = $ZStrip(tContent, "<>W") 
    
    Return tContent
}

/// Dedicated method for Legacy Code Analysis (Brownfield Scanner).
/// Returns a JSON Array of suggestions.
ClassMethod AnalyzeLegacy(pCode As %String, pApiKey As %String, pModel As %String) As %DynamicArray
{
    Set tResponse = []
    Try {
        Set tInstructions = "Analyze this code and suggest improvements: " _ $C(10) _ pCode
        Set tJsonStr = ..CallWorker(tInstructions, pApiKey, pModel, ..#SUGGESTIONPROMPT)
        Set tResponse = {}.%FromJSON(tJsonStr)
    } Catch ex {
        Do tResponse.%Push({"title": "Error", "description": (ex.DisplayString())})
    }
    Return tResponse
}

/// Internal Python method to call LiteLLM.
/// Supports OpenAI, Anthropic, and Gemini dynamically.
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

/// Generates Vector Embeddings for RAG.
/// Requires 'sentence-transformers' pip package.
ClassMethod GenerateEmbedding(pText As %String) As %String [ Language = python ]
{
    try:
        from sentence_transformers import SentenceTransformer
        import json
        
        # Load model (cached if possible)
        model = SentenceTransformer('all-MiniLM-L6-v2')
        
        # Generate embeddings
        embeddings = model.encode(pText)
        
        # Return as JSON string for ObjectScript to convert to %Vector
        return str(embeddings.tolist())
    except Exception as e:
        print(f"Embedding Error: {e}")
        return ""
}

/// Retrieves Context from KnowledgeBase using IRIS Vector Search.
/// Uses the Class Query defined in dc.withLove.storage.KnowledgeBase.
ClassMethod RetrieveContext(pTenantId As %String, pVectorStr As %String) As %String
{
    Set tContext = ""
    Try {
        // Convert JSON string to IRIS Vector
        Set tVector = $ZConvert(pVectorStr, "I", "JSON")
        
        // Execute Class Query defined in KnowledgeBase
        Set statement = ##class(%SQL.Statement).%New()
        $$$ThrowOnError(statement.%PrepareClassQuery("dc.withLove.storage.KnowledgeBase", "RetrieveContext"))
        Set tRS = statement.%Execute(pTenantId, tVector)
        
        While tRS.%Next() {
            Set tContext = tContext _ "Document: " _ tRS.%Get("Title") _ $C(10) _ 
                        "Content: " _ $Extract(tRS.%Get("Content"), 1, 1000) _ "..." _ $C(10,10)
        }
    } Catch ex {
        Set tContext = "Error retrieving context: " _ ex.DisplayString()
    }
    Return tContext
}

}
