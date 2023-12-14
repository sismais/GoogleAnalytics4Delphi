program DemoProject;

uses
  Vcl.Forms,
  View.Main in 'src\View\View.Main.pas' {frmMain},
  Sismais.Analytics.ApiClient in '..\..\src\Sismais.Analytics.ApiClient.pas',
  Sismais.Analytics.Models in '..\..\src\Sismais.Analytics.Models.pas',
  Sismais.Analytics in '..\..\src\Sismais.Analytics.pas',
  Sismais.Analytics.Utils in '..\..\src\Sismais.Analytics.Utils.pas',
  Sismais.Analytics.Models.Config in '..\..\src\Sismais.Analytics.Models.Config.pas',
  View.Cliente in 'src\View\View.Cliente.pas' {frmCliente};

{$R *.res}

begin
  Application.Initialize;
  //ReportMemoryLeaksOnShutdown := True;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
