Class dc.withLove.storage.AppVersion Extends %Persistent
{

Relationship Project As dc.withLove.storage.Project [ Cardinality = parent, Inverse = Versions ];

Property VersionNumber As %Integer [ Required ];

Property PromptUsed As %String(MAXLEN = "");

/// Snapshot of the code
Property SourceCode As %Stream.GlobalCharacter;

/// Model used (e.g., gpt-4o, claude-3-5-sonnet)
Property LLMModel As %String;

Property CreatedAt As %DateTime [ InitialExpression = {$ZDateTime($Horolog, 3)} ];

Index VersionIdx On (Project, VersionNumber) [ Unique ];

Storage Default
{
<Data name="AppVersionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>VersionNumber</Value>
</Value>
<Value name="3">
<Value>PromptUsed</Value>
</Value>
<Value name="4">
<Value>SourceCode</Value>
</Value>
<Value name="5">
<Value>CreatedAt</Value>
</Value>
<Value name="6">
<Value>LLMModel</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("Versions")</DataLocation>
<DefaultData>AppVersionDefaultData</DefaultData>
<IdLocation>^dc.withLove.storage.ProjectC("Versions")</IdLocation>
<IndexLocation>^dc.withLove.stoA0CD.AppVersionI</IndexLocation>
<StreamLocation>^dc.withLove.stoA0CD.AppVersionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
