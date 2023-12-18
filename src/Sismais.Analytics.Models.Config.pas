unit Sismais.Analytics.Models.Config;

interface

type

  IAnalyticsConfig = interface
    ['{7C922304-C7F1-4B3E-930F-7E1C3686126E}']
    /// <summary>
    ///   Optional. Application name. Eg.: The executable name without ".exe"
    ///   If not informed, is used the executable name whitout extension (".exe").
    /// </summary>
    function AppName(Value: String): IAnalyticsConfig; overload;
    function AppName: String; overload;
    /// <summary>
    ///  Get it at Google Analytic platform: <para />
    ///  At GA4 propertie: Administrator > Data flow > [Choose or Create Your Flow] >
    ///    In DataFlow header coluns search "Measurement ID" }
    /// </summary>
    function ApiSecret(Value: String): IAnalyticsConfig; overload;
    function APISecret: String; overload;
    /// <summary>
    ///   Get it at Google Analytic platform: <para />
    ///  At GA4 propertie: Administrator > Data flow > [Choose or Create Your Flow] >
    ///    Measurement Protocol API secret keys
    /// </summary>
    function MeasurementId(Value: String): IAnalyticsConfig; overload;
    function MeasurementId: String; overload;
    /// <summary>
    ///   Set GA4 ClientID (now Device ID).
    ///  Is a unique indentifier for user in device and browser (or application).
    ///  An specific user can have multiple ClientID at differente devices, browsers and/or apps.
    /// </summary>
    function ClientID(Value : string) : IAnalyticsConfig; overload;
    function ClientId: String; overload;
    /// <summary>
    ///   Optional. Company ID. Is defined, send a parameter "company_id" in all events. Customize report to extract
    /// needed data about company ID.
    ///  Note: Use anonymable data. Don't use CNPJ or other similiar document.
    /// </summary>
    function CompanyID(Value : string) : IAnalyticsConfig; overload;
    function CompanyID: String; overload;
    /// <summary>
    ///  (Optional) Set the GA4 UserID to global unique identifier for user in all yours applications.
    ///  Leave blank is user don't logged in application. Set afeter login. <para />
    ///  About: <para />
    ///  An specific user needs have an unique UserID in all devices/plataforms and all browsers/apps (if possible).
    ///  Can contains only utf-8 characters.
    ///  Obs: Controlling UserID (empty for no logged, inputed for loged) you can compare logged users vs unlogged users.
    ///  See more: https://support.google.com/analytics/answer/9213390?hl=pt-br
    /// </summary>
    function UserID(Value : string) : IAnalyticsConfig; overload;
    function UserId: String; overload;

    /// <summary>
    ///   Optional, auto generated on class start.
    /// About: No Google Analytics 4 (GA4), o session_id é um identificador único atribuído a cada sessão do usuário.
    /// Ao contrário do engagement_time_msec, o session_id pode ser enviado no payload do evento se você estiver
    /// realizando um rastreamento personalizado ou usando o Measurement Protocol.
    /// Quando enviar eventos via Measurement Protocol, você pode incluir session_id como um parâmetro no payload
    /// do evento para associar esse evento a uma sessão específica. Isso pode ser útil em análises avançadas ou
    /// cenários de rastreamento personalizado onde você está gerenciando as sessões de forma programática.
    /// </summary>
    function SessionID(Value: String): IAnalyticsConfig; overload;
    function SessionID: String; overload;

    /// <summary>
    ///   Activate the GA4 Debug Endpoint.
    ///  Obs.: Some json payload errors is not explained by the GA4 debug endpoint.
    ///  Some error's only obtained at Event Build tool: https://ga-dev-tools.google/ga4/event-builder/
    /// </summary>
    function DebugEndPoint(Value: Boolean): IAnalyticsConfig; overload;
    function DebugEndPoint: Boolean; overload;
  end;

  TAnalitycsConfig = class(TInterfacedObject, IAnalyticsConfig)
    private
      FAppName: String;
      FAPISecret: String;
      FClientId: String; //Device ID.
      FCompanyId: String;
      FUserId: String;
      FMeasurementId: String;
      FSessionID: String;
      FDebugEndPoint: Boolean;
    public
      constructor Create;
      destructor Destroy; override;
      class function New : IAnalyticsConfig;
      function AppName(Value: String): IAnalyticsConfig; overload;
      function AppName: String; overload;
      function APISecret(Value: String): IAnalyticsConfig; overload;
      function APISecret: String; overload;
      function ClientId(Value: String): IAnalyticsConfig; overload;
      function ClientId: String; overload;
      function CompanyID(Value : string) : IAnalyticsConfig; overload;
      function CompanyID: String; overload;
      function UserId(Value: String): IAnalyticsConfig; overload;
      function UserId: String; overload;
      function SessionID(Value: String): IAnalyticsConfig; overload;
      function SessionID: String; overload;
      function MeasurementId(Value: String): IAnalyticsConfig; overload;
      function MeasurementId: String; overload;
      function DebugEndPoint(Value: Boolean): IAnalyticsConfig; overload;
      function DebugEndPoint: Boolean; overload;
  end;

implementation

{ TAnalitycsConfig }

function TAnalitycsConfig.APISecret: String;
begin
  Result := FAPISecret;
end;

function TAnalitycsConfig.AppName: String;
begin
  Result := FAppName;
end;

function TAnalitycsConfig.AppName(Value: String): IAnalyticsConfig;
begin
  FAppName := Value;
  Result := Self;
end;

function TAnalitycsConfig.APISecret(Value: String): IAnalyticsConfig;
begin
  Result := Self;
  FAPISecret := Value;
end;

function TAnalitycsConfig.ClientId(Value: String): IAnalyticsConfig;
begin
  Result := Self;
  FClientId := Value;
end;

function TAnalitycsConfig.ClientId: String;
begin
  Result := FClientId;
end;

function TAnalitycsConfig.CompanyID: String;
begin
  Result := FCompanyID;
end;

function TAnalitycsConfig.CompanyID(Value: string): IAnalyticsConfig;
begin
  FCompanyId := Value;
  Result := Self;
end;

constructor TAnalitycsConfig.Create;
begin
  inherited;
  FUserId := '';
  FMeasurementId := '';
  FClientId := '';
  FCompanyId := '';
  FSessionID := '';
  FAppName := '';
  FDebugEndPoint := False;
end;

function TAnalitycsConfig.DebugEndPoint(Value: Boolean): IAnalyticsConfig;
begin
  FDebugEndPoint := Value;
end;

function TAnalitycsConfig.DebugEndPoint: Boolean;
begin
  Result := FDebugEndPoint;
end;

destructor TAnalitycsConfig.Destroy;
begin
  inherited;
end;

function TAnalitycsConfig.MeasurementId: String;
begin
  Result := FMeasurementId;
end;

function TAnalitycsConfig.MeasurementId(Value: String): IAnalyticsConfig;
begin
  Result := Self;
  FMeasurementId := Value;
end;

class function TAnalitycsConfig.New : IAnalyticsConfig;
begin
  Result := Self.Create;
end;

function TAnalitycsConfig.SessionID(Value: String): IAnalyticsConfig;
begin
  Result := Self;
  FSessionID := Value;
end;

function TAnalitycsConfig.SessionID: String;
begin
  Result := FSessionID;
end;

function TAnalitycsConfig.UserId: String;
begin
  Result := FUserId;
end;

function TAnalitycsConfig.UserId(Value: String): IAnalyticsConfig;
begin
  Result := Self;
  FUserId := Value;
end;


end.
