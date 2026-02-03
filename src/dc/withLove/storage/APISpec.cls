Class dc.withLove.storage.APISpec Extends %Persistent
{

Property resourceName As %String(MAXLEN = 128) [ Required ];

Property targetClassName As %String(MAXLEN = 256) [ Required ];

Property version As %String(MAXLEN = 16) [ InitialExpression = "v1" ];

Property generatedCode As %String(MAXLEN = "");

Property llmPrompt As %String(MAXLEN = "");

Property status As %String(VALUELIST = ",draft,generated,exported") [ InitialExpression = "draft" ];

Relationship project As dc.withLove.storage.Project [ Cardinality = one, Inverse = apis, Required ];

Relationship endpoints As dc.withLove.storage.EndpointSpec [ Cardinality = many, Inverse = apiSpec ];

Relationship persistentClass As dc.withLove.storage.ClassSpec [ Cardinality = one, Inverse = api ];

Storage Default
{
<Data name="APISpecDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>resourceName</Value>
</Value>
<Value name="3">
<Value>targetClassName</Value>
</Value>
<Value name="4">
<Value>version</Value>
</Value>
<Value name="5">
<Value>generatedCode</Value>
</Value>
<Value name="6">
<Value>llmPrompt</Value>
</Value>
<Value name="7">
<Value>status</Value>
</Value>
<Value name="8">
<Value>project</Value>
</Value>
<Value name="9">
<Value>persistentClass</Value>
</Value>
</Data>
<DataLocation>^dc.withLove.storage.APISpecD</DataLocation>
<DefaultData>APISpecDefaultData</DefaultData>
<IdLocation>^dc.withLove.storage.APISpecD</IdLocation>
<IndexLocation>^dc.withLove.storage.APISpecI</IndexLocation>
<StreamLocation>^dc.withLove.storage.APISpecS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
