Class dc.withLove.storage.Project Extends %Persistent
{

Property name As %String(MAXLEN = 128) [ Required ];

Property description As %String(MAXLEN = 512);

Property namespace As %String(MAXLEN = 64);

Property version As %String(MAXLEN = 32) [ InitialExpression = "1.0.0" ];

Property createdAt As %TimeStamp [ Required ];

Relationship apis As dc.withLove.storage.APISpec [ Cardinality = many, Inverse = project ];

Relationship exports As dc.withLove.storage.APISpec [ Cardinality = many, Inverse = project ];

Property lastModified As %TimeStamp;

Index NameIdx On name [ Unique ];

Storage Default
{
<Data name="ProjectDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>name</Value>
</Value>
<Value name="3">
<Value>description</Value>
</Value>
<Value name="4">
<Value>namespace</Value>
</Value>
<Value name="5">
<Value>version</Value>
</Value>
<Value name="6">
<Value>createdAt</Value>
</Value>
<Value name="7">
<Value>lastModified</Value>
</Value>
</Data>
<DataLocation>^dc.withLove.storage.ProjectD</DataLocation>
<DefaultData>ProjectDefaultData</DefaultData>
<IdLocation>^dc.withLove.storage.ProjectD</IdLocation>
<IndexLocation>^dc.withLove.storage.ProjectI</IndexLocation>
<StreamLocation>^dc.withLove.storage.ProjectS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
