Param()

# Itt állítod be a környezetek elérhetőségét és start/stop scripteket.
# Ha valamelyik script hiányzik, a futtató átugorja az indítást/megállítást, de attól még tesztel.

$Global:TestEnvs = @(
  @{
    Name     = "dev"
    BaseUrl  = "http://localhost:8080"
    Start    = ".\dev-start.bat"
    Stop     = ".\dev-stop.bat"
    BasicUser= "perf_user"
    BasicPass= "Perf_1234!"
  },
  @{
    Name     = "prod"
    BaseUrl  = "http://localhost:8082"
    Start    = ".\prod-start.bat"
    Stop     = ".\prod-stop.bat"
    BasicUser= $null
    BasicPass= $null
  },
  @{
    Name     = "portfolio"
    BaseUrl  = "http://localhost:8084"
    Start    = ".\portfolio-start.bat"
    Stop     = ".\portfolio-stop.bat"
    BasicUser= $null
    BasicPass= $null
  }
)

# Mit futtasson a csomag?
$Global:RunCI         = $true     # Gradle clean test (TC JDBC)
$Global:RunDev        = $true
$Global:RunProd       = $true
$Global:RunPortfolio  = $true
