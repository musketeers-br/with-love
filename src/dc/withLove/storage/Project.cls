Class dc.withLove.storage.Project Extends %Persistent
{

/// Multi-Tenant Isolation
Property TenantID As %String [ Required ];

Property Name As %String [ Required ];

Property CodeName As %String [ Required ];

Property Description As %String(MAXLEN = "");

Property Owner As %String;

Property CreatedAt As %DateTime [ InitialExpression = {$ZDateTime($Horolog, 3)} ];

/// Optional: Store project-specific API Key (Encrypted)
Property EncryptedAPIKey As %String(MAXLEN = 512);

Property CurrentVersion As %Integer [ InitialExpression = 0 ];

Relationship Versions As dc.withLove.storage.AppVersion [ Cardinality = children, Inverse = Project ];

/// Unique index per Tenant
Index TenantIdx On (TenantID, CodeName) [ Unique ];

Query GetProjectId(pTenantId As %String, pCodeName As %String) As %SQLQuery(COMPILEMODE = "IMMEDIATE", ROWSPEC = "ProjId:%String", SELECTMODE = "RUNTIME") [ SqlProc ]
{
    SELECT ID as ProjId
    FROM dc_withLove_storage.Project 
    WHERE TenantID = :pTenantId AND CodeName = :pCodeName
}

Storage Default
{
<Data name="ProjectDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>CodeName</Value>
</Value>
<Value name="4">
<Value>Description</Value>
</Value>
<Value name="5">
<Value>Owner</Value>
</Value>
<Value name="6">
<Value>CreatedAt</Value>
</Value>
<Value name="7">
<Value>CurrentVersion</Value>
</Value>
<Value name="8">
<Value>TenantID</Value>
</Value>
<Value name="9">
<Value>EncryptedAPIKey</Value>
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
