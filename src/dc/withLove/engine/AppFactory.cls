Class dc.withLove.engine.AppFactory Extends %RegisteredObject
{

ClassMethod CreateApp(pTenantId As %String, pAppName As %String, pHtmlContent As %String, pPrompt As %String, pModel As %String) As %String
{
    Set tAppUrl = ""
    Try {
        TSTART
        
        Set tCleanName = $ZStrip(pAppName,"*W")
        Set tClassName = "dc.withlove.apps."_tCleanName
        
        // 1. Storage Management (Multi-Tenant)
        Set tProjId = ""
        &sql(SELECT ID INTO :tProjId FROM dc_withLove_storage.Project WHERE TenantID = :pTenantId AND CodeName = :tCleanName)
        
        If (tProjId = "") {
            Set tProj = ##class(dc.withLove.storage.Project).%New()
            Set tProj.TenantID = pTenantId
            Set tProj.Name = pAppName
            Set tProj.CodeName = tCleanName
        } Else {
            Set tProj = ##class(dc.withLove.storage.Project).%OpenId(tProjId)
        }
        
        // 2. Versioning
        Set tProj.CurrentVersion = tProj.CurrentVersion + 1
        Set tVersion = ##class(dc.withLove.storage.AppVersion).%New()
        Set tVersion.VersionNumber = tProj.CurrentVersion
        Set tVersion.PromptUsed = pPrompt
        Set tVersion.LLMModel = pModel
        Do tVersion.SourceCode.Write(pHtmlContent)
        
        Do tVersion.ProjectSetObjectId(tProj.%Id())
        Do tProj.Versions.Insert(tVersion)
        
        Do tProj.%Save()
        
        // 3. Dynamic Compilation
        If ##class(%Dictionary.ClassDefinition).%ExistsId(tClassName) {
            Do $System.OBJ.Delete(tClassName)
        }
        
        Set tClassDef = ##class(%Dictionary.ClassDefinition).%New(tClassName)
        Set tClassDef.Super = "%CSP.Page"
        
        Set tParam = ##class(%Dictionary.ParameterDefinition).%New()
        Set tParam.Name = "CHARSET"
        Set tParam.Default = "utf-8"
        Do tClassDef.Parameters.Insert(tParam)

        Set tMethod = ##class(%Dictionary.MethodDefinition).%New()
        Set tMethod.Name = "OnPage"
        Set tMethod.ClassMethod = 1
        Set tMethod.ReturnType = "%Status"
        
        Do tMethod.Implementation.WriteLine(" &html<")
        Do tMethod.Implementation.WriteLine(pHtmlContent)
        Do tMethod.Implementation.WriteLine(" >")
        Do tMethod.Implementation.WriteLine(" Quit $$$OK")
        
        Do tClassDef.Methods.Insert(tMethod)
        Do tClassDef.%Save()
        
        Set tSC = $System.OBJ.Compile(tClassName, "ck")
        If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
        
        TCOMMIT
        
        Set tAppUrl = "/csp/"_$Namespace_"/"_tClassName_".cls"
        
    } Catch ex {
        TROLLBACK
        Set tAppUrl = "ERROR: " _ ex.DisplayString()
    }
    Return tAppUrl
}

}
