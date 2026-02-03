Class dc.withLove.storage.EndpointSpec Extends %Persistent
{

Relationship apiSpec As dc.withLove.storage.APISpec [ Cardinality = one, Inverse = endpoints, Required ];

Property httpMethod As %String(VALUELIST = ",GET,POST,PUT,PATCH,DELETE") [ Required ];

Property path As %String(MAXLEN = 512) [ Required ];

Property operationId As %String(MAXLEN = 128) [ Required ];

Property preHook As %String(MAXLEN = 256);

Property postHook As %String(MAXLEN = 256);

Property generatedMethodCode As %String(MAXLEN = "");

Storage Default
{
<Data name="EndpointSpecDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>apiSpec</Value>
</Value>
<Value name="3">
<Value>httpMethod</Value>
</Value>
<Value name="4">
<Value>path</Value>
</Value>
<Value name="5">
<Value>operationId</Value>
</Value>
<Value name="6">
<Value>preHook</Value>
</Value>
<Value name="7">
<Value>postHook</Value>
</Value>
<Value name="8">
<Value>generatedMethodCode</Value>
</Value>
</Data>
<DataLocation>^dc.withLove.sA0CD.EndpointSpecD</DataLocation>
<DefaultData>EndpointSpecDefaultData</DefaultData>
<IdLocation>^dc.withLove.sA0CD.EndpointSpecD</IdLocation>
<IndexLocation>^dc.withLove.sA0CD.EndpointSpecI</IndexLocation>
<StreamLocation>^dc.withLove.sA0CD.EndpointSpecS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
