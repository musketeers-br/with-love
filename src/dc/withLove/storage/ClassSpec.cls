Class dc.withLove.storage.ClassSpec Extends %Persistent
{

Relationship api As dc.withLove.storage.APISpec [ Cardinality = one, Inverse = endpoints, Required ];

Property className As %String(MAXLEN = 256) [ Required ];

Property superclass As %String(MAXLEN = 256) [ InitialExpression = "%Persistent" ];

Property tableName As %String(MAXLEN = 256);

Property generatedCode As %String(MAXLEN = "");

Relationship properties As dc.withLove.storage.PropertySpec [ Cardinality = many, Inverse = classSpec ];

Storage Default
{
<Data name="ClassSpecDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>api</Value>
</Value>
<Value name="3">
<Value>className</Value>
</Value>
<Value name="4">
<Value>superclass</Value>
</Value>
<Value name="5">
<Value>tableName</Value>
</Value>
<Value name="6">
<Value>generatedCode</Value>
</Value>
</Data>
<DataLocation>^dc.withLove.storage.ClassSpecD</DataLocation>
<DefaultData>ClassSpecDefaultData</DefaultData>
<IdLocation>^dc.withLove.storage.ClassSpecD</IdLocation>
<IndexLocation>^dc.withLove.storage.ClassSpecI</IndexLocation>
<StreamLocation>^dc.withLove.storage.ClassSpecS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
