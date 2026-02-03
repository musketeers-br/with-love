Class dc.withLove.storage.ExportLog Extends %Persistent
{

Relationship project As dc.withLove.storage.Project [ Cardinality = one, Inverse = exports, Required ];

Property exportType As %String(VALUELIST = ",IPM,XML,Git") [ Required ];

Property exportPath As %String(MAXLEN = 512);

Property version As %String(MAXLEN = 32);

Property status As %String(VALUELIST = ",pending,success,failed");

Property errorMessage As %String(MAXLEN = 2048);

Property createdAt As %TimeStamp [ Required ];

Storage Default
{
<Data name="ExportLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>project</Value>
</Value>
<Value name="3">
<Value>exportType</Value>
</Value>
<Value name="4">
<Value>exportPath</Value>
</Value>
<Value name="5">
<Value>version</Value>
</Value>
<Value name="6">
<Value>status</Value>
</Value>
<Value name="7">
<Value>errorMessage</Value>
</Value>
<Value name="8">
<Value>createdAt</Value>
</Value>
</Data>
<DataLocation>^dc.withLove.storage.ExportLogD</DataLocation>
<DefaultData>ExportLogDefaultData</DefaultData>
<IdLocation>^dc.withLove.storage.ExportLogD</IdLocation>
<IndexLocation>^dc.withLove.storage.ExportLogI</IndexLocation>
<StreamLocation>^dc.withLove.storage.ExportLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
