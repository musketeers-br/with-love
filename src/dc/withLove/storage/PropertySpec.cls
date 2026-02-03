Class dc.withLove.storage.PropertySpec Extends %Persistent
{

Relationship classSpec As dc.withLove.storage.ClassSpec [ Cardinality = one, Inverse = properties, Required ];

Property name As %String(MAXLEN = 128) [ Required ];

Property type As %String(MAXLEN = 64) [ Required ];

Property required As %Boolean [ InitialExpression = 0 ];

Property maxLength As %Integer;

Property indexType As %String(VALUELIST = ",none,unique,bitmap");

Storage Default
{
<Data name="PropertySpecDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>classSpec</Value>
</Value>
<Value name="3">
<Value>name</Value>
</Value>
<Value name="4">
<Value>type</Value>
</Value>
<Value name="5">
<Value>required</Value>
</Value>
<Value name="6">
<Value>maxLength</Value>
</Value>
<Value name="7">
<Value>indexType</Value>
</Value>
</Data>
<DataLocation>^dc.withLove.sA0CD.PropertySpecD</DataLocation>
<DefaultData>PropertySpecDefaultData</DefaultData>
<IdLocation>^dc.withLove.sA0CD.PropertySpecD</IdLocation>
<IndexLocation>^dc.withLove.sA0CD.PropertySpecI</IndexLocation>
<StreamLocation>^dc.withLove.sA0CD.PropertySpecS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
