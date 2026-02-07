Class dc.withLove.engine.AppFactory Extends %RegisteredObject
{

/// Creates a static HTML file in the WebApp directory.
/// Returns the URL to access the file.
ClassMethod CreateApp(pTenantId As %String, pAppName As %String, pHtmlContent As %String, pPrompt As %String = "", pModel As %String = "manual") As %String
{
    Set tAppUrl = ""
    Try {
        // --- 1. SANITIZATION ---
        // Clean App Name
        Set tCleanName = $ZStrip(pAppName, "*E", "", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        If $IsValidNum($Extract(tCleanName,1)) Set tCleanName = "App"_tCleanName
        If tCleanName="" Set tCleanName = "GeneratedApp"_$Random(10000)
        
        // Clean Tenant
        Set tCleanTenant = $ZStrip(pTenantId, "*E", "", "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        If tCleanTenant="" Set tCleanTenant = "default"
        
        // --- 2. VERSIONING (Database Storage) ---
        // We still keep the metadata in SQL for the Dashboard/History
        Set statement = ##class(%SQL.Statement).%New()
        $$$ThrowOnError(statement.%PrepareClassQuery("dc.withLove.storage.Project", "GetProjectId"))
        Set tRS = statement.%Execute(pTenantId, tCleanName)
        Do tRS.%Next()
        Set tProjId = tRS.%Get("ProjId")
        
        If (tProjId = "") {
            Set tProj = ##class(dc.withLove.storage.Project).%New()
            Set tProj.TenantID = pTenantId
            Set tProj.Name = pAppName 
            Set tProj.CodeName = tCleanName
            Set tProj.Description = "Static HTML App"
        } Else {
            Set tProj = ##class(dc.withLove.storage.Project).%OpenId(tProjId)
        }
        
        Set tProj.CurrentVersion = tProj.CurrentVersion + 1
        Set tVersion = ##class(dc.withLove.storage.AppVersion).%New()
        Set tVersion.VersionNumber = tProj.CurrentVersion
        Set tVersion.PromptUsed = pPrompt
        Set tVersion.LLMModel = pModel
        Do tVersion.SourceCode.Write(pHtmlContent)
        Do tVersion.ProjectSetObjectId(tProj.%Id())
        Do tProj.Versions.Insert(tVersion)
        Do tProj.%Save()

        // --- 3. PHYSICAL FILE GENERATION ---
        
        // Construct Filename: dc.withLove.<tenant>.apps.<AppName>.html
        Set tFilename = "dc.withLove." _ tCleanTenant _ ".apps." _ tCleanName _ ".html"
        
        // Determine Physical Path
        // Logic: Get IRIS Install Dir + "csp" + Namespace (standard convention)
        // Note: Ideally, check Security.Applications, but this covers 99% of default setups.
        Set tCSPDir = $System.Util.InstallDirectory() _ "csp" _ $System.FilePath.GetDirectorySeparator() _ $ZConvert($Namespace, "L") _ $System.FilePath.GetDirectorySeparator()
        
        // Ensure directory exists (create if not)
        If '##class(%File).DirectoryExists(tCSPDir) {
            Do ##class(%File).CreateDirectoryChain(tCSPDir)
        }
        
        Set tFullPath = tCSPDir _ tFilename
        
        // Create/Overwrite File
        Set tFile = ##class(%Stream.FileCharacter).%New()
        Set tFile.Filename = tFullPath
        Do tFile.TranslateTableSet("UTF8") // Ensure UTF-8 encoding
        Do tFile.Write(pHtmlContent)
        Set tSC = tFile.%Save()
        
        If $$$ISERR(tSC) Throw ##class(%Exception.StatusException).CreateFromStatus(tSC)
        
        // --- 4. RETURN URL ---
        // URL Pattern: /withlove/<filename> (Assumes /withlove is mapped to the CSP folder)
        Set tAppUrl = "/withlove/" _ tFilename
        
    } Catch ex {
        Set tAppUrl = "ERROR: " _ ex.DisplayString()
    }
    Return tAppUrl
}

}
