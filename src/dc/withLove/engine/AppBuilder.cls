Class dc.withLove.engine.AppBuilder Extends %RegisteredObject
{

/// Compila uma classe CSP gerada pela IA dinamicamente
ClassMethod DeployApp(pAppName As %String, pCodeBody As %String) As %Status
{
    Set tSC = $$$OK
    Try {
        // Define o nome da classe (ex: dc.withlove.apps.Dengue)
        Set tClassName = "dc.withlove.apps."_$ZStrip(pAppName,"*W") // Remove espaços
        
        // Cria a definição da classe programaticamente
        Set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassName)
        Set tClassDef.Super = "%CSP.Page"
        
        // Adiciona o método OnPage (que contém o HTML/JS do App)
        Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
        Set tMethod.Name = "OnPage"
        Set tMethod.ClassMethod = 1
        Set tMethod.ReturnType = "%Status"
        
        // A IA deve enviar o código HTML dentro de &html< ... >
        // Aqui injetamos o código no corpo do método
        Do tMethod.Implementation.Write(" &html<" _ pCodeBody _ "> Quit $$$OK")
        
        Do tClassDef.Methods.Insert(tMethod)
        
        // Salva e Compila
        Do tClassDef.%Save()
        Set tSC = $System.OBJ.Compile(tClassName, "ck")
        
    } Catch ex {
        Set tSC = ex.AsStatus()
    }
    Quit tSC
}

}
