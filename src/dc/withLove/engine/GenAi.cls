Class dc.withLove.engine.GenAi Extends %RegisteredObject
{

/// Forces Dark Mode, Slate Grays, and Pink/Rose Accents to match the IDE
Parameter APPSYSTEMPROMPT = {"You are an expert UI/UX Engineer building Micro-Apps for InterSystems IRIS Health. "_
    "Your goal is to generate a single-file Web App (HTML+JS) that is beautiful, responsive, and 'Loveable'. " _
    
    "STRICT DESIGN SYSTEM RULES:"_
    "1. STACK: Use HTML5, TailwindCSS (CDN), and Alpine.js."_
    "2. THEME: Dark Mode Enterprise. Background: `bg-slate-950`. Text: `text-slate-300`."_
    "3. TYPOGRAPHY: Use `font-sans` (Inter/system-ui). NEVER use serif fonts."_
    "4. CONTAINERS: Use `max-w-md mx-auto` for mobile apps or `max-w-4xl` for dashboards."_
    "5. CARDS: Use `bg-slate-900 border border-slate-800 rounded-2xl shadow-xl`."_
    "6. INPUTS: Use `w-full bg-slate-950 border border-slate-700 rounded-lg px-4 py-3 focus:border-pink-500 focus:ring-1 focus:ring-pink-500 outline-none transition`."_
    "7. BUTTONS: Primary: `bg-gradient-to-r from-pink-600 to-rose-600 hover:from-pink-500 hover:to-rose-500 text-white font-bold py-3 rounded-xl shadow-lg shadow-pink-900/20`. Secondary: `bg-slate-800 hover:bg-slate-700 text-slate-200`."_
    "8. LOGIC: Use Alpine.js `x-data` for state management."_
    
    "OUTPUT FORMAT:"_
    "Return ONLY the raw code inside the <body> tag. Do not include <html>, <head>, or markdown blocks."};

/// Generates Code/Text using the chosen provider
ClassMethod Generate(pPrompt As %String, pApiKey As %String, pModel As %String = "gpt-4o", pSystemPrompt As %String = "") As %String
{
    Set tContent = ""
    Try {
        If (pApiKey="") $$$ThrowStatus($$$ERROR($$$GeneralError, "API Key is required"))
        
        // Use the Design System Prompt if none provided
        If (pSystemPrompt="") Set pSystemPrompt = ..#APPSYSTEMPROMPT
        
        // Call Python
        Set tContent = ..PyGenerate(pPrompt, pApiKey, pModel, pSystemPrompt)
        
        // Sanitize Markdown
        Set tContent = $Replace(tContent, "```html", "")
        Set tContent = $Replace(tContent, "```json", "")
        Set tContent = $Replace(tContent, "```", "")
        Set tContent = $ZStrip(tContent, "<>W")
        
    } Catch ex {
        Set tContent = "<div class='text-red-500'>Error generating AI code: " _ ex.DisplayString() _ "</div>"
    }
    Return tContent
}

/// Python wrapper for LiteLLM
ClassMethod PyGenerate(userPrompt As %String, apiKey As %String, model As %String, systemPrompt As %String) As %String [ Language = python ]
{
    from litellm import completion
    import os

    try:
        # Dynamic Env Var setting for LiteLLM based on Model Family
        # This allows using one field for any provider
        if "gpt" in model or "o1" in model:
            os.environ["OPENAI_API_KEY"] = apiKey
        elif "claude" in model:
            os.environ["ANTHROPIC_API_KEY"] = apiKey
        elif "gemini" in model:
            os.environ["GEMINI_API_KEY"] = apiKey
            
        messages = [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userPrompt}
        ]

        response = completion(
            model=model, 
            messages=messages
        )

        return response.choices[0].message.content

    except Exception as e:
        return f"LiteLLM Error: {str(e)}"
}

/// RAG Helper: Finds relevant context using Local Vector Search
ClassMethod GetContext(pTenantId As %String, pPrompt As %String) As %String
{
    Set tContext = ""
    Try {
        // 1. Generate Embedding locally (No API Key needed)
        Set tVector = ..GenerateEmbedding(pPrompt)
        
        // 2. Perform Vector Search
        // Syntax: ORDER BY VECTOR_DOT_PRODUCT(Embedding, TO_VECTOR(?, DECIMAL))
        Set tSql = "SELECT TOP 3 Content FROM dc_withLove_storage.KnowledgeBase " _
                "WHERE TenantID = ? ORDER BY VECTOR_DOT_PRODUCT(Embedding, TO_VECTOR(?, DECIMAL)) DESC"
        
        Set tRS = ##class(%SQL.Statement).%ExecDirect(, tSql, pTenantId, tVector)
        
        While tRS.%Next() {
            Set tContext = tContext _ "- " _ tRS.Content _ $Char(10)
        }
    } Catch ex {
        // Log error silently
    }
    Return tContext
}

ClassMethod GenerateEmbedding(pText As %String) As %String
{
    Set tVectorStr = ""
    Try {
        Set tModel = ##class(%Embedding.SentenceTransformers).%New("all-MiniLM-L6-v2")
        
        // Gera o vetor (retorna um %Vector object)
        Set tVector = tModel.Embed(pText)
        
        // Converte para string para uso em SQL dinâmico
        Set tVectorStr = ##class(%Vector).ToString(tVector)
        
    } Catch ex {
        // Fallback ou erro
        Set tVectorStr = ""
    }
    Return tVectorStr
}

}
