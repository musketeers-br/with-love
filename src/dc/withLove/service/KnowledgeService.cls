Class dc.withLove.service.KnowledgeService Extends %RegisteredObject
{

/// Adiciona um documento à base de conhecimento (vetorização automática)
ClassMethod AddDocument(pTenantId As %String, pTitle As %String, pContent As %String) As %Status
{
    Set tSC = $$$OK
    Try {
        // 1. Gera o vetor localmente
        Set tVectorStr = ##class(dc.withLove.engine.GenAi).GenerateEmbedding(pContent)
        If tVectorStr="" Quit // Falha na vetorização
        
        // 2. Salva no banco
        Set tKB = ##class(dc.withLove.storage.KnowledgeBase).%New()
        Set tKB.TenantID = pTenantId
        Set tKB.Title = pTitle
        Set tKB.Content = pContent
        // Atribui o vetor convertido
        Set tKB.Embedding = tVectorStr 
        
        Set tSC = tKB.%Save()
        
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Return tSC
}

/// Lista documentos de um tenant
ClassMethod ListDocuments(pTenantId As %String) As %DynamicArray
{
    Set tArr = []
    Set tRS = ##class(%SQL.Statement).%ExecDirect(,"SELECT ID, Title FROM dc_withLove_storage.KnowledgeBase WHERE TenantID = ?", pTenantId)
    While tRS.%Next() {
        Do tArr.%Push({
            "id": (tRS.ID),
            "title": (tRS.Title)
        })
    }
    Return tArr
}

}
