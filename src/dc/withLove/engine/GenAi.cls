Class dc.withLove.engine.GenAi Extends %RegisteredObject
{

/// =========================================================
/// 1. AGENT PROMPTS (SYSTEM INSTRUCTIONS)
/// =========================================================
Parameter UIPROMPT = {"You are the UI Agent. Generate a complete, standalone HTML5 file."_
    "RULES:"_
    "1. Structure: <!DOCTYPE html> <html> <head> ... <body> ..."_
    "2. Include TailwindCSS: <script src='https://cdn.tailwindcss.com'></script>"_
    "3. Include Alpine.js: <script defer src='https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js'></script>"_
    "4. MANDATORY STYLE: Copy this exact <style> block into the <head>: "_
    "'<style> :root { --bg-color: #0f172a; --card-bg: #1e293b; --text-color: #e2e8f0; --accent: #db2777; } "_
    "body { background-color: var(--bg-color); color: var(--text-color); font-family: sans-serif; height: 100vh; display: flex; align-items: center; justify-content: center; margin: 0; } "_
    ".card { background-color: var(--card-bg); padding: 2rem; border-radius: 1rem; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1); width: 100%; max-width: 400px; border: 1px solid #334155; } "_
    "input, select, textarea { width: 100%; background: #020617; border: 1px solid #475569; color: white; padding: 0.75rem; border-radius: 0.5rem; margin-bottom: 1rem; display: block; box-sizing: border-box; } "_
    "button { width: 100%; background: linear-gradient(to right, #db2777, #e11d48); color: white; padding: 0.75rem; border-radius: 0.5rem; border: none; font-weight: bold; cursor: pointer; } "_
    "button:hover { opacity: 0.9; } </style>'"_
    "5. Output ONLY the raw HTML code. Do not wrap in markdown blocks."};

Parameter BACKENDPROMPT = {"You are the Backend Agent. Generate an InterSystems IRIS Persistent Class."_
    "RULES:"_
    "1. Define the class name simply (e.g., 'Patient'). The system will auto-assign the package."_
    "2. Inherit from (%Persistent, %JSON.Adaptor)."_
    "3. Use simple types: %String, %Integer, %Boolean, %Date."_
    "4. CRITICAL: DO NOT generate the <Storage> XML block. The compiler will generate it automatically."_
    "5. Output ONLY the ObjectScript code."};

Parameter APIPROMPT = {"You are the API Agent. Generate an InterSystems IRIS REST Class (%CSP.REST)."_
    "RULES:"_
    "1. Inherit from %CSP.REST."_
    "2. Define the UrlMap XData block mapping routes to ClassMethods."_
    "3. Create ClassMethods for GET/POST/PUT/DELETE actions."_
    "4. Return JSON using Dynamic Object ({}.%ToJSON())."_
    "5. ERROR HANDLING: Use '$System.Status.GetErrorText(sc)' to get error messages."_
    "6. HEADERS: Use '%response.SetHeader'. Do NOT use '..SetResponse'."_
    "7. BODY: Read json using '{}.%FromJSON(%request.Content)'."_
    "8. NO MANUAL IDs: Do not manage IDs or use $increment. Let IRIS handle identity columns."_
    "9. NO EMBEDDED SQL: Use Object Access (##class(Package).%New(), .%Save()). DO NOT use &sql()."_
    "10. Output ONLY the ObjectScript code."};

Parameter INTEROPPROMPT = {"You are the Interoperability Agent. Generate InterSystems IRIS Interoperability components."_
    "RULES:"_
    "1. For Data Transformations, generate a Class extending 'Ens.DataTransformDTL'."_
    "2. CRITICAL: In the <transform> tag, ALWAYS include: xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'."_
    "3. For Operations, generate a Class extending 'Ens.BusinessOperation' with MessageMap."_
    "4. Output ONLY the ObjectScript code."};

Parameter FHIRPROMPT = {"You are the FHIR Agent. Generate a FHIR R4 Bundle JSON based on the request."_
    "Output ONLY the JSON."};

Parameter INTEGRATIONPROMPT = {"You are the Integration Agent. Your job is to extract JSON content from the user message."_
    "The user will provide FHIR data. You must output ONLY the raw JSON string found."_
    "Do not explain, do not wrap in markdown."};

/// Supervisor: The Router. Now strictly enforced.
Parameter SUPERVISORPROMPT = {"You are a STRICT Router. You do NOT write code. You only route tasks to workers."_
    "You MUST start your response with a tag like [DELEGATE: ...]."_
    "CONTEXT: {{CONTEXT_DATA}}"_
    "--------------------------------"_
    "ROUTING RULES:"_
    "1. For Visuals/Screens/HTML/App/UI -> '[DELEGATE: UI] <instructions>'."_
    "2. For Database/Tables/SQL/Classes -> '[DELEGATE: BACKEND] <instructions>'."_
    "3. For REST API/Endpoints -> '[DELEGATE: API] <instructions>'."_
    "4. For Interop/DTL/HL7 -> '[DELEGATE: INTEROP] <instructions>'."_
    "5. For JSON Data/Mock -> '[DELEGATE: FHIR] <instructions>'."_
    "6. For Data Import -> '[DELEGATE: INTEGRATION] <content>'."_
    "7. If no code is needed -> Just answer the user."};

/// =========================================================
/// 2. ORCHESTRATOR LOGIC (LANGGRAPH-LITE)
/// =========================================================
ClassMethod AgentRun(pSessionId As %String, pTenantId As %String, pUserPrompt As %String, pApiKey As %String, pModel As %String) As %DynamicObject
{
    Set tResponse = { "type": "text", "content": "" }
    
    Try {
        Set tSession = ##class(dc.withLove.storage.LLMSession).SessionIdxOpen(pTenantId, pSessionId)
        If '$IsObject(tSession) {
            Set tSession = ##class(dc.withLove.storage.LLMSession).%New()
            Set tSession.SessionId = pSessionId
            Set tSession.TenantId = pTenantId
        }

        // --- HITL PHASE 1: EXECUTION ---
        If (pUserPrompt = "CONFIRM_APPROVE") && (tSession.CurrentState = "AWAITING_APPROVAL") {
            Set tCode = tSession.DraftCode.Read($$$MaxStringLength)
            Set tType = tSession.DraftType
            Set tDeployResult = ""

            If (tType = "BACKEND") {
                Set tDeployResult = ##class(dc.withLove.engine.ClassFactory).DeployBackend(tCode, pTenantId)
                If ($Extract(tDeployResult,1,5) = "ERROR") { Set tResponse.content = "❌ **Deploy Failed:** " _ tDeployResult } Else { Set tResponse.content = "✅ **Deployed!** Table: `" _ tDeployResult _ "` created." }
            } ElseIf (tType = "API") {
                Set tClassName = ##class(dc.withLove.engine.ApiFactory).DeployApi(tCode, pTenantId)
                If ($Extract(tClassName,1,5) = "ERROR") { Set tResponse.content = "❌ **Deploy Failed:** " _ tClassName } Else { Set tService = $Piece(tClassName, ".", *) Set tUrl = "/withlove/services/" _ pTenantId _ "/" _ tService Set tResponse.content = "✅ **Deployed!** API available at: `" _ tUrl _ "`" }
            } ElseIf (tType = "UI") {
                Set tAppName = "App" _ $Random(100000)
                Set tUrl = ##class(dc.withLove.engine.AppFactory).CreateApp(pTenantId, tAppName, tCode)
                Set tResponse.content = "✅ **Deployed!** App URL: `" _ tUrl _ "`"
            } ElseIf (tType = "INTEROP") {
                 Set tClassName = ##class(dc.withLove.engine.InteropFactory).DeployComponent(tCode, pTenantId)
                 Set tResponse.content = "✅ **Deployed!** Interop Component: `" _ tClassName _ "`"
            }
            Do tSession.ClearDraft() 
            Set tResponse.type = "text"
            Do tSession.AddMessage("assistant", tResponse.content)
            Return tResponse
        }
        
        If (pUserPrompt = "CANCEL_DRAFT") && (tSession.CurrentState = "AWAITING_APPROVAL") {
            Do tSession.ClearDraft()
            Set tResponse.content = "❌ Draft discarded."
            Set tResponse.type = "text"
            Do tSession.AddMessage("assistant", tResponse.content)
            Return tResponse
        }

        If (tSession.CurrentState = "AWAITING_APPROVAL") {
             Set tDraft = tSession.DraftCode.Read($$$MaxStringLength)
             Set pUserPrompt = "I have this draft code: " _ $C(10) _ tDraft _ $C(10,10) _ "Please apply this change: " _ pUserPrompt
        }

        // --- HITL PHASE 2: GENERATION ---
        Do tSession.AddMessage("user", pUserPrompt)
        
        Set tContextString = ""
        Set tUserVector = ..GenerateEmbedding(pUserPrompt)
        If (tUserVector '= "") { Set tContextString = ..RetrieveContext(pTenantId, tUserVector) }
        If tContextString = "" Set tContextString = "No specific documents found."

        Set tSystemPrompt = $Replace(..#SUPERVISORPROMPT, "{{CONTEXT_DATA}}", tContextString)
        Set tDecision = ..PyCallLLM(tSession.GetHistory().%ToJSON(), pApiKey, pModel, tSystemPrompt)
        
        // --- ROUTING & DRAFTING ---
        
        Set tGenCode = ""
        Set tAgentType = ""
        Set tThought = ""

        If (tDecision [ "[DELEGATE: UI]") {
            Set tInstructions = $Piece(tDecision, "[DELEGATE: UI]", 2)
            Set tFullInstructions = "Context: " _ tContextString _ $C(10) _ "Instructions: " _ tInstructions
            Set tGenCode = ..CallWorker(tFullInstructions, pApiKey, pModel, ..#UIPROMPT)
            Set tAgentType = "UI"
            Set tThought = "I have designed the UI. Preview generated."
        } ElseIf (tDecision [ "[DELEGATE: BACKEND]") {
            Set tInstructions = $Piece(tDecision, "[DELEGATE: BACKEND]", 2)
            Set tGenCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#BACKENDPROMPT)
            Set tAgentType = "BACKEND"
            Set tThought = "I have generated the SQL Class."
        } ElseIf (tDecision [ "[DELEGATE: API]") {
            Set tInstructions = $Piece(tDecision, "[DELEGATE: API]", 2)
            Set tGenCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#APIPROMPT)
            Set tAgentType = "API"
            Set tThought = "I have generated the REST API."
        } ElseIf (tDecision [ "[DELEGATE: INTEROP]") {
            Set tInstructions = $Piece(tDecision, "[DELEGATE: INTEROP]", 2)
            Set tGenCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#INTEROPPROMPT)
            Set tAgentType = "INTEROP"
            Set tThought = "I have generated the Interop Component."
        } ElseIf (tDecision [ "[DELEGATE: INTEGRATION]") {
            Set tRawContent = $Piece(tDecision, "[DELEGATE: INTEGRATION]", 2)
            Set tJsonData = ..CallWorker(tRawContent, pApiKey, pModel, ..#INTEGRATIONPROMPT)
            Set tResult = ##class(dc.withLove.engine.FHIRToSDAHandler).ProcessFHIR(tJsonData)
            Set tResponse.content = "Integration Result: " _ tResult.status
        }
        
        // --- FALLBACK ROUTING (Se o LLM falhar em usar a tag, tentamos inferir) ---
        If (tGenCode = "") && (tDecision '[ "[DELEGATE:") {
            Set tLowerDecision = $ZConvert(tDecision, "L")
            Set tLowerPrompt = $ZConvert(pUserPrompt, "L")
            
            // Se o usuário pediu UI/Tela/Page mas o LLM só conversou
            If (tLowerPrompt [ "ui") || (tLowerPrompt [ "page") || (tLowerPrompt [ "screen") || (tLowerPrompt [ "frontend") {
                Set tGenCode = ..CallWorker(pUserPrompt, pApiKey, pModel, ..#UIPROMPT)
                Set tAgentType = "UI"
                Set tThought = "I have designed the UI (Fallback)."
            }
            // Se o usuário pediu API/Rest
            ElseIf (tLowerPrompt [ "api") || (tLowerPrompt [ "rest") || (tLowerPrompt [ "endpoint") {
                Set tGenCode = ..CallWorker(pUserPrompt, pApiKey, pModel, ..#APIPROMPT)
                Set tAgentType = "API"
                Set tThought = "I have generated the API (Fallback)."
            }
        }

        // --- RESPONSE PACKAGING ---
        If (tGenCode '= "") {
            Do tSession.DraftCode.Clear()
            Do tSession.DraftCode.Write(tGenCode)
            Set tSession.DraftType = tAgentType
            Set tSession.CurrentState = "AWAITING_APPROVAL"
            Do tSession.%Save()

            // --- TYPE DETECTION (Case Insensitive) ---
            Set tLowerCode = $ZConvert(tGenCode, "L")
            If (tLowerCode [ "<!doctype html") || (tLowerCode [ "<html") {
                Set tResponse.type = "code" // Forces Canvas Preview
                Set tResponse.thought = "✅ I have generated the App UI."
            } Else {
                Set tResponse.type = "review"
                Set tResponse.thought = tThought
            }
            
            Set tResponse.content = "<![CDATA[" _ $C(10) _ tGenCode _ $C(10) _ "]]>"
            Do tSession.AddMessage("assistant", tResponse.thought)
            
        } Else {
            // General Chat
            Set tResponse.type = "text"
            If tResponse.content = "" Set tResponse.content = tDecision
            Do tSession.AddMessage("assistant", tDecision)
        }
        
    } Catch ex {
        Set tResponse.type = "error"
        Set tResponse.content = ex.DisplayString()
    }
    
    Return tResponse
}

// ... (Métodos Auxiliares mantidos iguais) ...

ClassMethod CallWorker(pInstructions As %String, pApiKey As %String, pModel As %String, pSystemPrompt As %String) As %String
{
    Set tMsgs = [{"role":"system", "content":(pSystemPrompt)}, {"role":"user", "content":(pInstructions)}]
    Set tContent = ..PyCallLLM(tMsgs.%ToJSON(), pApiKey, pModel, "")
    // Cleanup markdown
    Set tContent = $Replace(tContent, "```html", "")
    Set tContent = $Replace(tContent, "```objectscript", "")
    Set tContent = $Replace(tContent, "```json", "")
    Set tContent = $Replace(tContent, "```", "")
    Set tContent = $ZStrip(tContent, "<>W") 
    Return tContent
}

ClassMethod PyCallLLM(messagesJson As %String, apiKey As %String, model As %String, systemPrompt As %String = "") As %String [ Language = python ]
{
    from litellm import completion
    import json
    import os
    try:
        if "gpt" in model: os.environ["OPENAI_API_KEY"] = apiKey
        elif "claude" in model: os.environ["ANTHROPIC_API_KEY"] = apiKey
        elif "gemini" in model: os.environ["GEMINI_API_KEY"] = apiKey
        msgs = json.loads(messagesJson)
        if systemPrompt and systemPrompt != "":
            if msgs[0]['role'] != 'system': msgs.insert(0, {"role": "system", "content": systemPrompt})
        response = completion(model=model, messages=msgs)
        return response.choices[0].message.content
    except Exception as e: return f"Error: {str(e)}"
}

ClassMethod GenerateEmbedding(pText As %String) As %String [ Language = python ]
{
    try:
        from sentence_transformers import SentenceTransformer
        model = SentenceTransformer('all-MiniLM-L6-v2')
        embeddings = model.encode(pText)
        return str(embeddings.tolist())
    except Exception as e: return ""
}

ClassMethod RetrieveContext(pTenantId As %String, pVectorStr As %String) As %String
{
    Set tContext = ""
    Try {
        Set tVector = $ZConvert(pVectorStr, "I", "JSON")
        Set statement = ##class(%SQL.Statement).%New()
        $$$ThrowOnError(statement.%PrepareClassQuery("dc.withLove.storage.KnowledgeBase", "RetrieveContext"))
        Set tRS = statement.%Execute(pTenantId, tVector)
        While tRS.%Next() { Set tContext = tContext _ "Document: " _ tRS.%Get("Title") _ $C(10) _ "Content: " _ $Extract(tRS.%Get("Content"), 1, 1000) _ "..." _ $C(10,10) }
    } Catch ex { Set tContext = "Error retrieving context: " _ ex.DisplayString() }
    Return tContext
}

}
