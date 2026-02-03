Class dc.withLove.storage.LLMSession Extends %Persistent
{

Property sessionId As %String(MAXLEN = 128) [ Required ];

Property projectId As %String(MAXLEN = 128);

Property conversationHistory As %String(MAXLEN = "");

Property currentState As %String(MAXLEN = 64);

Property pendingApproval As %Boolean [ InitialExpression = 0 ];

Property createdAt As %TimeStamp [ Required ];

Index SessionIdx On sessionId [ Unique ];

Storage Default
{
<Data name="LLMSessionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>sessionId</Value>
</Value>
<Value name="3">
<Value>projectId</Value>
</Value>
<Value name="4">
<Value>conversationHistory</Value>
</Value>
<Value name="5">
<Value>currentState</Value>
</Value>
<Value name="6">
<Value>pendingApproval</Value>
</Value>
<Value name="7">
<Value>createdAt</Value>
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
