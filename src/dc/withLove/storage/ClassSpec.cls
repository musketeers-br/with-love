Class dc.withLove.storage.ClassSpec Extends %Persistent
{

/// Link com o Projeto
Property Project As dc.withLove.storage.Project;

/// Nome da classe persistente (ex: dc.withlove.apps.DengueData)
Property ClassName As %String;

/// Definição JSON dos campos (ex: [{"name":"Temp","type":"%Float"}])
/// Isso ajuda a IA a entender o banco de dados em edições futuras
Property FieldsJSON As %String(MAXLEN = "");

Index ProjectIdx On Project;

Storage Default
{
<Data name="ClassSpecDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Project</Value>
</Value>
<Value name="3">
<Value>ClassName</Value>
</Value>
<Value name="4">
<Value>FieldsJSON</Value>
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
