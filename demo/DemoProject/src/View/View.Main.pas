unit View.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.DateUtils,
  Sismais.Analytics, Vcl.Menus;

type
  TfrmMain = class(TForm)
    btnDemoTrackClick: TButton;
    btnPageView: TButton;
    Memo1: TMemo;
    btnGenerateJson: TButton;
    btnInitGA4: TButton;
    MainMenu1: TMainMenu;
    este1: TMenuItem;
    mniCadastroCliente: TMenuItem;
    gbxCustomEvent: TGroupBox;
    btnTrackCustomEvent: TButton;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    btnTestSingleEvent: TButton;
    Label2: TLabel;
    procedure btnPageViewClick(Sender: TObject);
    procedure btnGenerateJsonClick(Sender: TObject);
    procedure btnDemoTrackClickClick(Sender: TObject);
    procedure btnTrackCustomEventClick(Sender: TObject);
    procedure mniCadastroClienteClick(Sender: TObject);
    procedure btnTestSingleEventClick(Sender: TObject);
    procedure Label2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  GlobalAnalytics: TAnalytics = nil;

implementation

{$R *.dfm}

uses View.Cliente;

procedure TfrmMain.btnPageViewClick(Sender: TObject);
begin
  Memo1.Lines.Text := GlobalAnalytics.SendPageView(Self.ClassName, Self.Caption).ToJson(True);
  {In production, you can use without return. Eg.:
    GlobalAnalytics.SendPageView(Self.ClassName, Self.Caption);
  }
end;

procedure TfrmMain.btnTestSingleEventClick(Sender: TObject);
begin
  //Send a single event to Analytics.
  GlobalAnalytics.SendEvent('user_login');
end;

procedure TfrmMain.btnTrackCustomEventClick(Sender: TObject);
var
  LPayload: IGA4Payload;
begin
  {Observations:
  - Custom events have several rules. If not respected, events not registered.
    Please read links before create custom events.

  Links:

  - User_Properties / Propriedades do usu�rio (in pt-br, change url query "hl=pt-br" to "hl=en" to english.)
    https://developers.google.com/analytics/devguides/collection/protocol/ga4/user-properties?hl=pt-br&client_type=gtag

  - Como validar eventos?
    https://developers.google.com/analytics/devguides/collection/protocol/ga4/validating-events?hl=pt-br&client_type=gtag

  - Nomes de eventos e par�metros reservados. QUE N�O DEVEM SER USADOS
    https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?hl=pt-br&client_type=gtag#reserved_names

  - Estrutura do JSON:
    https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?hl=pt-br&client_type=gtag#payload_post_body

  - Pr�ticas recomendadas ao criar dimens�es personalizadas (propriedades do usu�rio ou do evento)
    https://support.google.com/analytics/answer/10075209?hl=pt&utm_id=ad#best-practices

  - Como validar eventos:
    https://developers.google.com/analytics/devguides/collection/protocol/ga4/validating-events?hl=pt-br&client_type=gtag

  - Criador de eventos (criar e validar eventos)
    https://ga-dev-tools.web.app/ga4/event-builder/
  }

  //Send a custom event with custom user properties and custom event params.
  LPayload := TAnalytics.NewPayload;
  LPayload
    .User_Properties
      //User propertie name must have max of 24 character, and it's value must have max of 36 character.
      .Add('user_dashboard_prefer', 'Dashboard 1')
      .&End
    //OBS.: Event name can have only 40 characters and only this characters: "a..z", "0..9", "_"
    .Events.AddNewEvent('my_custom_event_name1')
      .Params
        //Event params name must have max of 40 characters, and it's value must have max os 100 characters.
        .Add('my_custom_event_param', 'My Custom Event Param Value')
        .Add('checkbox_checked', CheckBox1.Checked.ToInteger)
        .Add('edit1_is_empty', Trim(Edit1.Text).IsEmpty.ToInteger)
        .&End
      .&End
    //On payload, you can send 1..25 events. Any event can have 0..25 individual params.
    .Events.AddNewEvent('my_custom_event_name2')
    ;

  {Note: Before sending the event, the private method "TAnalytics.BeforeSend(APayload)"
  is called to insert some required/recommended user properties and event parameters.
  If necessary, you can create a new class inherited from TAnalytics and override the
  BeforeSend method to edit the payload, inserting or modifying the added event parameters
  and user properties.}
  GlobalAnalytics.SendEvents(Self.ClassName, Self.Caption, LPayload);

  Memo1.Lines.Text := LPayload.ToJson(True);
end;

procedure TfrmMain.Label2Click(Sender: TObject);
begin
{
  By Maicon Saraiva:
  You can use DDetours Delphi library to Hook methods and intercepts all form shows
  and controls click without edit any actual file.
  See the library to understand the possibilities:
  https://github.com/MahdiSafsafi/DDetours

  If you need save time, contact-me to get an built-in unit ("plug and play") to:
  start track with only 1 (one) code line.

  Obs: Service payed: Only $100.
  (To make it running automatic and stable with DDetours i'm work for ~30 hours.
  Save this time for an fraction of costs)

  Contacte-me at:

  Instagram: maiconsaraiva
  LinkedIn: maiconsaraiva
  Facebook: maiconsaraiva

  or in our

  https://sismais.com

  Thank you!
}
end;

procedure TfrmMain.mniCadastroClienteClick(Sender: TObject);
var
  LViewCliente: TfrmCliente;
begin
  LViewCliente := TfrmCliente.Create(Self);
  try
    GlobalAnalytics.SendPageView(LViewCliente.ClassName, LViewCliente.Caption);
    LViewCliente.ShowModal;
  finally
    LViewCliente.Release;
  end;
end;

function UNIXTimeInMilliseconds: Int64;
begin
  Result := MilliSecondsBetween(Now, UnixDateDelta);
end;

procedure TfrmMain.btnDemoTrackClickClick(Sender: TObject);
begin
  {$IFDEF DEBUG}
  Memo1.Lines.Text := GlobalAnalytics.SendClick(
    Self.ClassName,
    Self.Caption,
    GetObjectIndentify(Sender, 'DefaultName'),
    GetObjectCaption(Sender, 'DefaultCaption')).ToJson(True);
  {$ELSE}
  GlobalAnalytics.SendClick(
    Self.ClassName,
    Self.Caption,
    GetObjectIndentify(Sender, 'DefaultName'),
    GetObjectCaption(Sender, 'DefaultCaption'));
  {$ENDIF}
end;

procedure TfrmMain.btnGenerateJsonClick(Sender: TObject);
var
  LPayload: IGA4Payload;
begin
  {Teste de gera��o de JSON a partir da classe TGA4Payload.}
  LPayload := TAnalytics.NewPayload;
  LPayload
    .Client_Id('12345614')
    .User_Id('12345678914')
    .User_Properties
      .Add('user_plan', 'pro')
      .Add('device_resolution', '1024x768')
      .Add('user_preference', 'dark_mode')
      .Add('app_version', '1.11.3')
      .&End
    .Events.AddNewEvent('page_view')
      //.Timestamp_Micros(Sismais.Analytics.Utils.GetUnixTimestampMicros) (Optional, send only to past corred events.)
      .Params
        .Add('engagement_time_msec', 100)
        .Add('session_id', '1234' )
        .Add('page_location', 'frmPrincipal')
        .Add('page_referrer', 'frmLogin')
        .Add('page_title', 'Gest�o Mais Simples - Tela Principal');

  Memo1.Text := LPayload.ToJson(True {Format Json});
end;

procedure InitialConfigAnalytics;
const
  //If you have many applications integrating an unique ERP, set here the main ERP name.
  MAIN_APP_NAME = 'GestaoMaisSimples';
  MEASUREMENT_ID = 'G-**********';
  API_SECRET = 'Your Api Secret Key';
var
  LDeviceId, LCompanyId, LUserId: String;
begin
  { Read more about settings in method XML Doc. }

  //Use to identify app users. See XML Doc for more info.
  LUserId := '83114586-0fb0-4a60-b6ed-5d90462b4539';
  //Optional. Use it to identify an user company (Needs customize GA4 reports.)
  LCompanyId := 'A6A63A91-1F21-4AC3-BF2F-3049EC61B1D0';
  LDeviceId := Sismais.Analytics.GetDeviceID(MAIN_APP_NAME);
  GlobalAnalytics := TAnalytics.Create;
  GlobalAnalytics
    .Config
      {Optional. If not informed, is used the application executable name (without extension).
      This information is send to GA in all events as param "app_name".}
      //.AppName('OptionalAppName')
      .MeasurementId(MEASUREMENT_ID)
      .ApiSecret(API_SECRET)
      .ClientID(LDeviceId)
      //Optional. Leave blank on start application. Set after user logon and/or set company tier.
      .CompanyID(LCompanyID)
      //Optional. Leave blank if user not logger. Set after user login.
      .UserID(LUserId)
      .DebugEndPoint(False);
end;

initialization
  InitialConfigAnalytics;

finalization
  if Assigned(GlobalAnalytics) then
    FreeAndNil(GlobalAnalytics)


end.
