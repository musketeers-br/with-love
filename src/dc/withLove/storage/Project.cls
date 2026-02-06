Class dc.withLove.storage.Project Extends %Persistent
{

/// Nome amigável (ex: "Triagem Dengue")
Property Name As %String [ Required ];

/// Nome técnico da classe gerada (ex: "DengueTriage")
Property CodeName As %String [ Required ];

/// Descrição do que o app faz
Property Description As %String(MAXLEN = "");

/// Quem criou (Tenant/Usuário)
Property Owner As %String;

/// Data de criação
Property CreatedAt As %DateTime [ InitialExpression = {$ZDateTime($Horolog, 3)} ];

/// Última versão implantada
Property CurrentVersion As %Integer [ InitialExpression = 0 ];

/// Relacionamento com as versões do código
Relationship Versions As dc.withLove.storage.AppVersion [ Cardinality = children, Inverse = Project ];

Index NameIdx On Name [ Unique ];

Index CodeNameIdx On CodeName [ Unique ];

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
</Data>
<DataLocation>^dc.withLove.storage.ProjectD</DataLocation>
<DefaultData>ProjectDefaultData</DefaultData>
<IdLocation>^dc.withLove.storage.ProjectD</IdLocation>
<IndexLocation>^dc.withLove.storage.ProjectI</IndexLocation>
<StreamLocation>^dc.withLove.storage.ProjectS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
