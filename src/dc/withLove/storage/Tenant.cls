Class dc.withLove.storage.Tenant Extends %Persistent
{

/// Hospital or Client Name
Property Name As %String [ Required ];

/// Domain for resolution (e.g., hospital-a.local)
/// Renamed from 'Domain' to avoid SQL reserved word conflict
Property DomainName As %String [ Required ];

/// Namespace where the real clinical data resides (HealthConnect)
Property TargetNamespace As %String [ InitialExpression = {$Namespace} ];

/// Unique index for fast lookup during login
Index DomainNameIdx On DomainName [ Unique ];

Storage Default
{
<Data name="TenantDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>DomainName</Value>
</Value>
<Value name="4">
<Value>TargetNamespace</Value>
</Value>
</Data>
<DataLocation>^dc.withLove.storage.TenantD</DataLocation>
<DefaultData>TenantDefaultData</DefaultData>
<IdLocation>^dc.withLove.storage.TenantD</IdLocation>
<IndexLocation>^dc.withLove.storage.TenantI</IndexLocation>
<StreamLocation>^dc.withLove.storage.TenantS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
