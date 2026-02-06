Class dc.withLove.engine.GenAi Extends %RegisteredObject
{

/// UI Agent Prompt: Especialista em Visual (Tailwind/Alpine)
Parameter UIPROMPT = {"You are the UI Agent. Generate the HTML code for the requested App."_
    "RULES: 1. Use TailwindCSS and Alpine.js. 2. Embed this CSS in <head> for styling: "_
    "'<style> :root { --bg-color: #0f172a; --card-bg: #1e293b; --text-color: #e2e8f0; --accent: #db2777; } "_
    "body { background-color: var(--bg-color); color: var(--text-color); font-family: sans-serif; height: 100vh; display: flex; align-items: center; justify-content: center; margin: 0; } "_
    ".card { background-color: var(--card-bg); padding: 2rem; border-radius: 1rem; box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1); width: 100%; max-width: 400px; border: 1px solid #334155; } "_
    "input, select { width: 100%; background: #020617; border: 1px solid #475569; color: white; padding: 0.75rem; border-radius: 0.5rem; margin-bottom: 1rem; display: block; box-sizing: border-box; } "_
    "button { width: 100%; background: linear-gradient(to right, #db2777, #e11d48); color: white; padding: 0.75rem; border-radius: 0.5rem; border: none; font-weight: bold; cursor: pointer; } "_
    "button:hover { opacity: 0.9; } </style>'"_
    "Output ONLY the raw HTML inside <body>."};

/// Backend Agent Prompt: Especialista em Classes IRIS
Parameter BACKENDPROMPT = {"You are the Backend Agent. Generate an InterSystems IRIS Persistent Class."_
    "Output ONLY the ObjectScript code."};

/// FHIR Agent Prompt: Especialista em Interoperabilidade
Parameter FHIRPROMPT = {"You are the FHIR Agent. Generate a FHIR R4 Bundle JSON based on the request."_
    "Output ONLY the JSON."};

/// Supervisor Prompt: O Roteador
Parameter SUPERVISORPROMPT = {"You are the Supervisor of a Hospital Software Team. Analyze the user request and DELEGATE to a worker."_
    "Available Workers: [UI AGENT], [BACKEND AGENT], [FHIR AGENT]."_
    "Response Format:"_
    "- If user wants an App Interface: '[DELEGATE: UI] <instructions>'"_
    "- If user wants a Database Class: '[DELEGATE: BACKEND] <instructions>'"_
    "- If user wants FHIR Data: '[DELEGATE: FHIR] <instructions>'"_
    "- If general chat: Just answer."};

ClassMethod AgentRun(pSessionId As %String, pTenantId As %String, pUserPrompt As %String, pApiKey As %String, pModel As %String) As %DynamicObject
{
    Set tResponse = { "type": "text", "content": "" }
    
    Try {
        // 1. Session & History
        Set tSession = ##class(dc.withLove.storage.LLMSession).SessionIdxOpen(pTenantId, pSessionId)
        If '$IsObject(tSession) {
            Set tSession = ##class(dc.withLove.storage.LLMSession).%New()
            Set tSession.SessionId = pSessionId
            Set tSession.TenantId = pTenantId
        }
        Do tSession.AddMessage("user", pUserPrompt)
        
        // 2. Supervisor Decision
        Set tHistory = tSession.GetHistory()
        Set tDecision = ..PyCallLLM(tHistory.%ToJSON(), pApiKey, pModel, ..#SUPERVISORPROMPT)
        
        // 3. Routing (Graph Logic)
        If (tDecision [ "[DELEGATE: UI]") {
            // ---> CALL UI AGENT
            Set tInstructions = $Piece(tDecision, "[DELEGATE: UI]", 2)
            Set tCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#UIPROMPT)
            
            Set tResponse.type = "code"
            Set tResponse.content = tCode
            Set tResponse.thought = "Supervisor: Delegated to UI Agent to build interface."
            Do tSession.AddMessage("assistant", "Generated UI Code.")
            
        } ElseIf (tDecision [ "[DELEGATE: BACKEND]") {
            // ---> CALL BACKEND AGENT
            Set tInstructions = $Piece(tDecision, "[DELEGATE: BACKEND]", 2)
            Set tCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#BACKENDPROMPT)
            
            Set tResponse.type = "text"
            Set tResponse.content = "```objectscript" _ $C(10) _ tCode _ $C(10) _ "```"
            Do tSession.AddMessage("assistant", tResponse.content)
            
        } ElseIf (tDecision [ "[DELEGATE: FHIR]") {
            // ---> CALL FHIR AGENT
            Set tInstructions = $Piece(tDecision, "[DELEGATE: FHIR]", 2)
            Set tCode = ..CallWorker(tInstructions, pApiKey, pModel, ..#FHIRPROMPT)
            
            Set tResponse.type = "text"
            Set tResponse.content = "```json" _ $C(10) _ tCode _ $C(10) _ "```"
            Do tSession.AddMessage("assistant", tResponse.content)
            
        } Else {
            // ---> GENERAL CHAT
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

/// Generic Worker Caller
ClassMethod CallWorker(pInstructions As %String, pApiKey As %String, pModel As %String, pSystemPrompt As %String) As %String
{
    Set tMsgs = [{"role":"system", "content":(pSystemPrompt)}, {"role":"user", "content":(pInstructions)}]
    Set tContent = ..PyCallLLM(tMsgs.%ToJSON(), pApiKey, pModel, "")
    
    // Cleanup common markdown artifacts
    Set tContent = $Replace(tContent, "```html", "")
    Set tContent = $Replace(tContent, "```objectscript", "")
    Set tContent = $Replace(tContent, "```json", "")
    Set tContent = $Replace(tContent, "```", "")
    Return tContent
}

/// Low-level Python Call
ClassMethod PyCallLLM(messagesJson As %String, apiKey As %String, model As %String, systemPrompt As %String = "") As %String [ Language = python ]
{
    from litellm import completion
    import json
    import os
    
    try:
        if "gpt" in model: 
            os.environ["OPENAI_API_KEY"] = apiKey
        elif "claude" in model: 
            os.environ["ANTHROPIC_API_KEY"] = apiKey
        elif "gemini" in model: 
            os.environ["GEMINI_API_KEY"] = apiKey
            
        msgs = json.loads(messagesJson)
        if systemPrompt and systemPrompt != "":
            if msgs[0]['role'] != 'system':
                msgs.insert(0, {"role": "system", "content": systemPrompt})
        
        response = completion(model=model, messages=msgs)
        return response.choices[0].message.content
    except Exception as e:
        return f"Error: {str(e)}"
}

}
