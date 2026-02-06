Class dc.withLove.storage.LLMSession Extends %Persistent
{

Property SessionId As %String(MAXLEN = 128) [ Required ];

Property TenantId As %String(MAXLEN = 128);

/// JSON Array of messages: [{"role":"user", "content":"..."}, {"role":"assistant", "content":"..."}]
Property History As %Stream.GlobalCharacter;

/// Current State of the Agent (e.g., "GATHERING_REQS", "CODING", "REVIEW")
Property CurrentState As %String [ InitialExpression = "GATHERING_REQS" ];

Property CreatedAt As %DateTime [ InitialExpression = {$ZDateTime($Horolog, 3)} ];

Index SessionIdx On (TenantId, SessionId) [ Unique ];

/// Helper to append a message
Method AddMessage(pRole As %String, pContent As %String) As %Status
{
    Set tSC = $$$OK
    Try {
        // Load current history or init array
        Set tJson = []
        If ..History.Size > 0 {
            Set tJson = {}.%FromJSON(..History)
        }
        
        // Push new message
        Do tJson.%Push({ "role": (pRole), "content": (pContent) })
        
        // Save back to stream
        Do ..History.Clear()
        Do ..History.Write(tJson.%ToJSON())
        Set tSC = ..%Save()
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Return tSC
}

/// Helper to get history as dynamic object
Method GetHistory() As %DynamicArray
{
    If ..History.Size = 0 Return []
    Return {}.%FromJSON(..History)
}

Storage Default
{
<Data name="LLMSessionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>SessionId</Value>
</Value>
<Value name="3">
<Value>TenantId</Value>
</Value>
<Value name="4">
<Value>History</Value>
</Value>
<Value name="5">
<Value>CurrentState</Value>
</Value>
<Value name="6">
<Value>CreatedAt</Value>
</Value>
</Data>
<DataLocation>^dc.withLove.stoA0CD.LLMSessionD</DataLocation>
<DefaultData>LLMSessionDefaultData</DefaultData>
<IdLocation>^dc.withLove.stoA0CD.LLMSessionD</IdLocation>
<IndexLocation>^dc.withLove.stoA0CD.LLMSessionI</IndexLocation>
<StreamLocation>^dc.withLove.stoA0CD.LLMSessionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
