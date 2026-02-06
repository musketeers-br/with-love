Class dc.withLove.storage.AppVersion Extends %Persistent
{

Relationship Project As dc.withLove.storage.Project [ Cardinality = parent, Inverse = Versions ];

/// Número da versão (1, 2, 3...)
Property VersionNumber As %Integer [ Required ];

/// O Prompt que gerou esta versão ("Adicione campo de CPF...")
Property PromptUsed As %String(MAXLEN = "");

/// O HTML/CSP gerado pela IA (Snapshot do código)
Property SourceCode As %Stream.GlobalCharacter;

/// Data desta versão
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
</Data>
<DataLocation>{%%PARENT}("Versions")</DataLocation>
<DefaultData>AppVersionDefaultData</DefaultData>
<IdLocation>^dc.withLove.storage.ProjectC("Versions")</IdLocation>
<IndexLocation>^dc.withLove.stoA0CD.AppVersionI</IndexLocation>
<StreamLocation>^dc.withLove.stoA0CD.AppVersionS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
