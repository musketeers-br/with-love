Class dc.withLove.storage.KnowledgeBase Extends %Persistent
{

Property TenantID As %String [ Required ];

/// Title of the document (e.g., "Dengue Protocol 2026")
Property Title As %String(MAXLEN = 255);

/// The actual content chunk
Property Content As %String(MAXLEN = "");

/// IRIS Native Vector Storage (requires IRIS 2024.1+)
/// Vetor 384 dimensions (all-MiniLM-L6-v2)
Property Embedding As %Vector(DATATYPE = "DECIMAL", LEN = 384);

Index TenantIdx On TenantID;

Query RetrieveContext(pTenantId As %String, pVectorStr As %String) As %SQLQuery(COMPILEMODE = "IMMEDIATE", ROWSPEC = "Title:%String, Content:%String", SELECTMODE = "RUNTIME") [ SqlProc ]
{
    SELECT TOP 3 Title, Content FROM dc_withLove_storage.KnowledgeBase
    WHERE TenantID = :pTenantId
    ORDER BY VECTOR_DOT_PRODUCT(Embedding, TO_VECTOR(:pVectorStr, DECIMAL)) DESC
}

Storage Default
{
<Data name="KnowledgeBaseDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TenantID</Value>
</Value>
<Value name="3">
<Value>Title</Value>
</Value>
<Value name="4">
<Value>Content</Value>
</Value>
<Value name="5">
<Value>Embedding</Value>
</Value>
</Data>
<DataLocation>^dc.withLoveA0CD.KnowledgeBaseD</DataLocation>
<DefaultData>KnowledgeBaseDefaultData</DefaultData>
<IdLocation>^dc.withLoveA0CD.KnowledgeBaseD</IdLocation>
<IndexLocation>^dc.withLoveA0CD.KnowledgeBaseI</IndexLocation>
<StreamLocation>^dc.withLoveA0CD.KnowledgeBaseS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
