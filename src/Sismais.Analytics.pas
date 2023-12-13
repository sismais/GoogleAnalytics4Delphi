{
  This unit is an class utils to send application statistics to
  Google Analytics 4 (formely GA4).

  Links:
  - GA4 free courses (oficially recomended by Google).
    https://skillshop.exceedlms.com/student/catalog/list?category_ids=6431-google-analytics-4
  - GA4 Video Tutorials by Google (in english).
    https://www.youtube.com/playlist?list=PLI5YfMzCfRtZ4bHJJDl_IJejxMwZFiBwz
  - GA4 Glossary
    https://support.google.com/analytics/topic/9355633?hl=en&ref_topic=14090456&sjid=17864771951946920467-SA
}
unit Sismais.Analytics;

interface

uses
  System.Classes, System.IOUtils, System.IniFiles,
  System.SysUtils, System.DateUtils, System.StrUtils,

  Sismais.Analytics.ApiClient,
  Sismais.Analytics.Models,
  Sismais.Analytics.Models.Config,
  Sismais.Analytics.Utils;

  /// <summary>
  ///   Get value of propertie "Name" of object. Is propertie or is empty, then try get ClassName, else return Default.
  /// </summary>
  function GetSenderNameOrClassName(AObject: TObject; ADefault: String): String;
  /// <summary>
  ///   Get value of propertie "Caption" of object. Is propertie not exists or except, return Default.
  /// </summary>
  function GetSenderCaption(AObject: TObject; ADefault: String): String;

  /// <summary>
  ///   Get an Device ID / Client ID for identify an unique device in data analytics. <para />
  ///  Try to store in an inifile at User AppData folder (local settings), else try in application root folder,
  /// else get a random UUID.  <para />
  ///  If not exists, it create a new ID and stored it.
  /// </summary>
  function GetDeviceID(const AApplicationName: String): String;



type
  IGA4Payload = Sismais.Analytics.Models.IGA4Payload;

  TAnalytics = class
    protected
      FConfig: IAnalyticsConfig;
      class var FInstance : TAnalytics;
      constructor CreatePrivate;
      class destructor Finish;
      class function GetInstance : TAnalytics; static;
      procedure InternalSendEvent(APayload: IGA4Payload);
    private
      /// <summary>
      ///   If needs, override it and adjust all you need in TGA4PayLoad.
      /// </summary>
      procedure BeforePost(const APayload: IGA4Payload);
    public
      constructor Create;
      destructor Destroy; override;
      /// <summary>
      ///   Get unique instance of TAnalytics. (Singleton Pattern)
      /// </summary>
      class property Instance: TAnalytics read GetInstance;

      property Config: IAnalyticsConfig read FConfig;

      /// <summary>
      ///   Send "page_view" event. <para />
      ///  More: https://developers.google.com/analytics/devguides/collection/ga4/views?hl=pt-br
      /// </summary>
      /// <param name="AFormClassName_PageLocation: String">
      ///   Form class name. This is equivalent to web url endpoint. Eg.: "/products"
      ///   If you have tabbet form, you can use: "/products/tributs" for eg. to map tab navigation (in GA: "Measure
      /// virtual page views".)
      /// </param>
      function SendPageView(const AFormClassName_PageLocation, AFormTitle: String;
        AOriginReferrerFormClass: String = ''): IGA4Payload;

      /// <summary>
      ///   Send button or any element click.
      /// </summary>
      function SendClick(const AFormClassName_PageLocation, AFormTitle, AElementClassName,
        AElementCaption: String): IGA4Payload;

      /// <summary>
      ///  Send payload with one or more events customized to GA4. <para />
      /// To get a instance of IGA4Payload, use TAnalytics.NewPayload; <para />
      ///  Before send, event is prepared and validated in BeforeSend() method. <para />
      ///  More about events: <para />
      ///  - https://www.semrush.com/blog/google-analytics-4-events  <para />
      ///  - https://developers.google.com/analytics/devguides/collection/protocol/ga4/sending-events
      /// </summary>
      function SendCustomEvents(const AFormClassName_PageLocation, AFormTitle: String;
        APayload: IGA4Payload): IGA4Payload;

      /// <summary>
      ///   Get a new payload instance interface. Use it to mount custom events.
      /// </summary>
      class function NewPayload: IGA4Payload;
  end;

implementation



  function GetSenderNameOrClassName(AObject: TObject; ADefault: String): String;
  begin
    Result := Sismais.Analytics.Utils.GetSenderNameOrClassName(AObject, ADefault);
  end;

  function GetSenderCaption(AObject: TObject; ADefault: String): String;
  begin
    Result := Sismais.Analytics.Utils.GetSenderCaption(AObject, ADefault);
  end;

  function GetDeviceID(const AApplicationName: String): String;
  begin
    Result := Sismais.Analytics.Utils.GetDeviceID(AApplicationName);
  end;

{ TAnalytics }

constructor TAnalytics.Create;
begin
  raise Exception.Create('This is a singleton class. Please, get instance invoking TAnalytics.Instance');
end;

constructor TAnalytics.CreatePrivate;
var
  LSessionID: Int64;
begin
  FConfig := TAnalitycsConfig.New;

  FConfig
    .SessionID(GetNewSessionID.ToString); //An unique SessionID by application running instance.
end;

destructor TAnalytics.Destroy;
begin
  //FConfig.Free; is interfaced. No destroy needed.
  inherited;
end;

function TAnalytics.SendCustomEvents(const AFormClassName_PageLocation, AFormTitle: String;
  APayload: IGA4Payload): IGA4Payload;
var
  I: Integer;
begin
//  if APayload.Events.Count <= 0 then
//    raise EAnalyticsError.Create('Payload Events could not empty. Please insert 1(one) or more event.');

  for I := 0 to Pred(APayload.Events.Count) do
  begin
    with APayload.Events.Items[I] do
    begin
      if not Trim(AFormTitle).IsEmpty then
        //tamamho máximo para valor de page_title é 300.
        Params.Add('page_title', Copy(Trim(AFormTitle), 1, 300));
      if not Trim(AFormClassName_PageLocation).IsEmpty then
        //Tamanho máximo para valor de page_location é 1000
        Params.Add('page_location', Copy(Trim(AFormClassName_PageLocation), 1, 1000) );
    end;
  end;

  //Return Payload if needs to debug.
  InternalSendEvent(APayload);
  Result := APayload;
end;

class destructor TAnalytics.Finish;
begin
  if Assigned(FInstance) then
    FInstance.Free;
end;

class function TAnalytics.GetInstance: TAnalytics;
begin
  if not Assigned(TAnalytics.Finstance) then
    TAnalytics.FInstance := TAnalytics.CreatePrivate;
  Result := TAnalytics.FInstance;
end;

function TAnalytics.SendClick(const AFormClassName_PageLocation, AFormTitle, AElementClassName,
  AElementCaption: String): IGA4Payload;
var
  LPayload: IGA4Payload;
  LEvent: TGA4Event;
begin
  LPayload := TGA4Payload.New;

  LEvent := LPayload.Events.AddNewEvent('control_click');
  LEvent
      .Params
        .Add('control_name', AElementClassName)
        .Add('control_class', AElementCaption)
        //tamamho máximo para valor de page_title é 300.
        .Add('page_title', Copy(Trim(AFormTitle), 1, 300))
        //Tamanho máximo para valor de page_location é 1000
        .Add('page_location', Copy(Trim(AFormClassName_PageLocation), 1, 1000) );

  InternalSendEvent(LPayload);
  //Return Payload if needs to debug.
  Result := LPayload;
end;

function TAnalytics.SendPageView(const AFormClassName_PageLocation, AFormTitle: String;
  AOriginReferrerFormClass: String = ''): IGA4Payload;
var
  LPayload: IGA4Payload;
  LEvent: TGA4Event;
begin
  {Sobre:
  https://developers.google.com/analytics/devguides/collection/ga4/page-view?hl=pt-br
  https://developers.google.com/analytics/devguides/collection/ga4/views?hl=pt-br&client_type=gtag
  }
  LPayload := TGA4Payload.New;

  LEvent := LPayload.Events.AddNewEvent('page_view');
  LEvent
    .Params
      //tamamho máximo para valor de page_title é 300.
      .Add('page_title', Copy(Trim(AFormTitle), 1, 300))
      //Tamanho máximo para valor de page_location é 1000
      .Add('page_location', Copy(Trim(AFormClassName_PageLocation), 1, 1000));

  if Trim(AOriginReferrerFormClass) <> '' then
    LEvent.Params.Add('page_referrer', AOriginReferrerFormClass);

  InternalSendEvent(LPayload);
  //Return Payload if needs to debug.
  Result := LPayload;
end;

procedure TAnalytics.InternalSendEvent(APayload: IGA4Payload);
begin
  Self.BeforePost(APayload);

  Sismais.Analytics.ApiClient.SendEvent(
    FConfig.DebugEndPoint,
    True, //Send in thread.
    APayload.ToJson(),
    FConfig.MeasurementId,
    FConfig.APISecret);
end;

class function TAnalytics.NewPayload: IGA4Payload;
begin
  Result := TGA4Payload.New;
end;

procedure TAnalytics.BeforePost(const APayload: IGA4Payload);
var
  I: Integer;
  LOsVersion: String;
  LEvent: TGA4Event;
begin
  //Valida algumas configurações obrigatórias.
  if Trim(FConfig.MeasurementId) = '' then
    raise EAnalyticsError.Create('MeasurementId not informed in TAnalytics.Config.MeasurementId()');
  if Trim(FConfig.APISecret) = '' then
    raise EAnalyticsError.Create('APISecret not informed in TAnalytics.Config.APISecret()');
  if Trim(FConfig.ClientID) = '' then
    raise EAnalyticsError.Create('ClientID not informed in TAnalytics.Config.ClientID()');


  {Propriedades adicionadas em todos os métodos.
  IMPORTANTE: Se fizer o Override deste método, não deixe de usar o inherited antes de suas alterações.}
  LOsVersion := Format('%d.%d.%d',[Integer(TOSVersion.Major), Integer(TOSVersion.Minor), Integer(TOSVersion.Build)]);

  APayload
    .Client_Id(FConfig.ClientId)
    .User_Id(FConfig.UserId)
    .User_Properties
      {TODO -oMaicon -cGA4 : Enviar esses dados como User Properties ou Event Params?}
      .Add('app_version', GetAppVersion)
      .Add('system_platform', Copy(TOSVersion.Name, 1, 34))  //Windows 10, Windows 11, etc.
      .Add('system_platform_vlabel', Copy(Win32OSVersion, 1, 34))
      .Add('system_platform_version', Copy(LOsVersion, 1, 34))
      .Add('screen_resolution', GetScreenResolution);

  //Add SessionID to all events params
  {TODO -oMaicon Saraiva -cGA4 Eventos : Na documentação abaixo, alguns parâmetros de eventos são coletados
  automaticamente em qualquer evento enviado:
  https://support.google.com/analytics/answer/9234069?hl=pt-br
  }
  for I := 0 to Pred(APayload.Events.Count) do
  begin
    LEvent := APayload.Events.Items[I];
    LEvent
      //Deixa zerado (não enviar no Json). ToDo: E se precisar armazenar os logs offline e depois enviar?
      //.Timestamp_Micros(GetUnixTimestampMicros)
      .Timestamp_Micros(0)
      .Params
        {Para que a atividade do usuário seja mostrada em relatórios padrão, como o Relatório de tempo real,
        é necessário enviar engagement_time_msec e session_id como parte dos params para um event.
        https://support.google.com/analytics/answer/11109416?hl=en
        https://developers.google.com/analytics/devguides/collection/protocol/ga4/sending-events?hl=pt-br&client_type=gtag#recommended_parameters_for_reports


        }
        {TODO -oMaicon -cGA4 : Como impleemntar o campo : "engagement_time_msec"
                Como implementar?
        https://sismais.atlassian.net/wiki/spaces/DES/pages/2600927247/Funcionamento+do+Engajamento+de+Usu+rios+no+Google+Analytics+4+engagement+time+msec}
        .Add('engagement_time_msec', 100) //Obrigatório para exibir os dados na página.
        .Add('session_id', FConfig.SessionID) //Parâmetro deve ser enviado em todas as requisições.
        .Add('app_version', GetAppVersion)
        .Add('screen_resolution', GetScreenResolution);

    if Trim(FConfig.CompanyID) <> '' then
      LEvent.Params.Add('company_id', FConfig.CompanyID);

    //Check if event name is not empty.
    if Trim(LEvent.Name).IsEmpty then
      raise EAnalyticsError.Create('Event Name can''t be empty.');
  end;

  {Exemplos de propriedades que podem ser adicionadas fazendo override deste método:
  inherited;
  APayload
    .User_Properties
      .Add('user_plan', 'pro')
      .Add('user_preference', 'dark_mode')
  }
end;

end.
