unit Sismais.Analytics.Models;

interface

uses
  System.Classes, System.Generics.Collections, System.Rtti, System.SysUtils,
  System.DateUtils, System.StrUtils,
  System.JSON, REST.Json;

type
  IGA4Payload = interface;

  TGA4Params = class abstract
  private
    FList: TDictionary<String, TValue>;
    procedure Validate(AParamName, AParamValue: String);  virtual;
    function _Add(AName, AValue: String): TGA4Params; overload;
    function _Add(AName: String; AValue: Integer): TGA4Params; overload;
    function _Add(AName: String; AValue: Double): TGA4Params; overload;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TGA4UserProperties = class(TGA4Params)
  private
    FOwner: IGA4Payload;
    procedure Validate(AParamName, AParamValue: String); override;
  public
    constructor Create(AOwner: IGA4Payload); reintroduce;
    /// <summary>
    ///   Max character for AName is 24, and for AValue is 36.
    /// </summary>
    function Add(AName, AValue: String): TGA4UserProperties; overload;
    function Add(AName: String; AValue: Integer): TGA4UserProperties; overload;
    function Add(AName: String; AValue: Double): TGA4UserProperties; overload;
    function &End: IGA4Payload;
  end;

  TGA4Event = class;
  TGA4EventParams = class(TGA4Params)
  private
    FOwner: TGA4Event;
    procedure Validate(AParamName, AParamValue: String); override;
  public
    constructor Create(AOwner: TGA4Event); reintroduce;
    destructor Destroy; override;
    /// <summary>
    ///   Max character for AName is 40, and for AValue is 100.
    /// </summary>
    function Add(AName, AValue: String): TGA4EventParams; overload;
    function Add(AName: String; AValue: Integer): TGA4EventParams; overload;
    function Add(AName: String; AValue: Double): TGA4EventParams; overload;
    function &End: TGA4Event;
  end;

  TGA4Event = class
  private
    FOwner: IGA4Payload;
    FName: String;
    FParams: TGA4EventParams;
    FTimestamp_Micros: Int64;
    function Name(Value: String): TGA4Event; overload;
  public
    /// <summary>
    ///   Event Name
    /// </summary>
    function Name: String; overload;
    /// <summary>
    /// (Optional) Carimbo de data/hora Unix (em microssegundos) para o horário a ser associado ao
    /// evento. Só pode ser definido para registrar eventos que aconteceram no passado,
    /// no prazo máximo de até 72 horas. Esse valor pode ser modificado com user_property ou carimbos
    /// de data/hora de eventos. Os eventos podem ser atualizados em até três dias
    /// corridos com base no fuso horário da propriedade.
    /// </summary>
    function Timestamp_Micros(Value: Int64): TGA4Event; overload;
    function Timestamp_Micros: Int64; overload;
    property Params: TGA4EventParams read FParams write FParams;
    constructor Create(AOwner: IGA4Payload; AEventName: String);
    function &End: IGA4Payload;
    destructor Destroy; override;
  end;

  TGA4Events = class
  private
    FList: TObjectList<TGA4Event>;
    FOwner: IGA4Payload;
    function GetCount: Integer;
    function GetItem(const Index: Integer): TGA4Event;
  public
    function AddNewEvent(AEventName: String): TGA4Event;
    property Count: Integer read GetCount;
    property Items[const Index: Integer]: TGA4Event read GetItem;
    constructor Create(AOwner: IGA4Payload);
    destructor Destroy; override;
    function &End: IGA4Payload;
  end;

  IGA4Payload = interface
    ['{95573404-9DCD-4367-91FA-1E807A2365DA}']
    function GetUser_Properties: TGA4UserProperties;
    function GetEvents: TGA4Events;
    function Client_ID: String; overload;
    function Client_ID(Value: String): IGA4Payload; overload;
    function User_ID: String; overload;
    function User_ID(Value: String): IGA4Payload; overload;
    property User_Properties: TGA4UserProperties read GetUser_Properties;
    property Events: TGA4Events read GetEvents;
    function ToJson(AFormatted: Boolean = False): String;
  end;

  /// <summary>
  ///   The main object to sendo to GA4 as Json.
  /// </summary>
  TGA4Payload = class (TInterfacedObject, IGA4Payload)
  private
    FClient_Id: String;
    FUser_Id: String;
    FNon_Personalized_Ads: Boolean;
    FUser_Properties: TGA4UserProperties;
    FEvents: TGA4Events;
    FApp_Instance_Id: String;
  public
    function GetEvents: TGA4Events;
    function GetUser_Properties: TGA4UserProperties;

    function Client_ID: String; overload;
    function Client_ID(Value: String): IGA4Payload; overload;
    function User_ID: String; overload;
    function User_ID(Value: String): IGA4Payload; overload;
    //property App_Instance_Id: String read FApp_Instance_Id write FApp_Instance_Id;
    //property Non_Personalized_Ads: Boolean read FNon_Personalized_Ads write FNon_Personalized_Ads;
    property User_Properties: TGA4UserProperties read GetUser_Properties;
    property Events: TGA4Events read GetEvents;

    constructor Create;
    class function New: IGA4Payload;
    destructor Destroy; override;
    function ToJson(AFormatted: Boolean = False): String;
  end;

implementation

uses
  Sismais.Analytics, Sismais.Analytics.Utils;

{ TGA4Event }

function TGA4Event.&End: IGA4Payload;
begin
  Result := Self.FOwner;
end;

constructor TGA4Event.Create(AOwner: IGA4Payload; AEventName: String);
begin
  inherited Create;
  FOwner := AOwner;
  Self.Name(AEventName);
  FParams :=  TGA4EventParams.Create(Self);
  //Preenche com valor default alguns campos:
  FTimestamp_Micros := 0; //Opcional, se for "0" não é gerado no Json. Só deve ser enviado para eventos do passado.
end;

destructor TGA4Event.Destroy;
begin
  FParams.Free;
  FOwner := nil;
  inherited;
end;

function TGA4Event.Name: String;
begin
  Result := FName;
end;

function TGA4Event.Name(Value: String): TGA4Event;
var
  I: Integer;
begin
  if Trim(Value) = '' then
    raise EAnalyticsError.Create('AParamName is empty.');

  for I := 1 to Length(Value) do
    if not (Value[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      raise EAnalyticsError.Create('Propertie name for event have invalid character. Valid: ' + SLineBreak +
        '("A".."Z", "a".."z", 0..9, "_") ');

  //https://support.google.com/analytics/answer/9267744?hl=pt-BR
  if Length(Value) > 40 then
    raise EAnalyticsError.Create('Event name does have max 40 characters. Current name: ' + Value + SLineBreak +
      'See more: https://support.google.com/analytics/answer/9267744?hl=pt-BR');
  FName := Trim(Value);

  Result := Self;
end;

function TGA4Event.Timestamp_Micros: Int64;
begin
  Result := FTimestamp_Micros;
end;

function TGA4Event.Timestamp_Micros(Value: Int64): TGA4Event;
begin
  Result := Self;
  FTimestamp_Micros := Value;
end;

{ TUserProperties }

function TGA4Params._Add(AName, AValue: String): TGA4Params;
begin
  Validate(AName, AValue);
  //Use AddOrSetValue to prevent duplicates.
  Self.FList.AddOrSetValue(AName, TValue.From<String>(AValue));
  Result := Self;
end;

function TGA4Params._Add(AName: String; AValue: Integer): TGA4Params;
begin
  Validate(AName, AValue.ToString);
  //Use AddOrSetValue to prevent duplicates.
  Self.FList.AddOrSetValue(AName, TValue.From<Integer>(AValue));
  Result := Self;
end;

function TGA4Params._Add(AName: String; AValue: Double): TGA4Params;
begin
  Validate(AName, Trunc(AValue).ToString);
  //Use AddOrSetValue to prevent duplicates.
  Self.FList.AddOrSetValue(AName, TValue.From<Double>(AValue));
  Result := Self;
end;

constructor TGA4Params.Create;
begin
  inherited Create;
  FList := TDictionary<String, TValue>.Create;
end;

destructor TGA4Params.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TGA4Params.Validate(AParamName, AParamValue: String);
var
  I: Integer;
begin
  if Trim(AParamName) = '' then
    raise EAnalyticsError.Create('AParamName is empty.');

  for I := 1 to Length(AParamName) do
    if not (AParamName[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
      raise EAnalyticsError.Create('Propertie name for event have invalid character. Valid: ' + SLineBreak +
        '("A".."Z", "a".."z", 0..9, "_") ');

  //https://support.google.com/analytics/answer/9267744?hl=pt-BR
  if FList.Count >= 25 then
    raise EAnalyticsError.Create('In the free version of Google Analytics, only 25 parameters are allowed.' + SLineBreak +
      'See more: https://support.google.com/analytics/answer/9267744?hl=pt-BR');

  {https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?hl=pt-br&client_type=gtag#reserved_parameter_names
  Nomes de parametros não podem começar com:
  _ (underscore)
  firebase_
  ga_
  google_
  gtag. }
  if AParamName.StartsWith('_', True) or AParamName.StartsWith('firebase_', True) or AParamName.StartsWith('ga_', True)
    or AParamName.StartsWith('google_', True) or AParamName.StartsWith('gtag.', True) then
    raise EAnalyticsError.Create('AParamName "'+AParamName+'" is invalid. AParamName starts with this are reserved '+
      'and could not used: ' + SLineBreak +
      '_ (underscore) ' + SLineBreak +
      'firebase_ ' + SLineBreak +
      'ga_ ' + SLineBreak +
      'google_ ' + SLineBreak +
      'gtag.');
end;

{ TGA4Payload }

function TGA4Payload.Client_ID: String;
begin
  Result := Self.FClient_Id;
end;

function TGA4Payload.Client_ID(Value: String): IGA4Payload;
begin
  Result := Self;
  FClient_ID := Value;
end;

constructor TGA4Payload.Create;
begin
  inherited Create;
  FEvents := TGA4Events.Create(Self);
  FUser_Properties := TGA4UserProperties.Create(Self);
end;

destructor TGA4Payload.Destroy;
begin
  FreeAndNil(FEvents);
  FreeAndNil(FUser_Properties);
  inherited;
end;

function TGA4Payload.GetEvents: TGA4Events;
begin
  Result := FEvents;
end;

function TGA4Payload.GetUser_Properties: TGA4UserProperties;
begin
  Result := FUser_Properties;
end;

class function TGA4Payload.New: IGA4Payload;
begin
  Result := Self.Create;
end;

function TGA4Payload.ToJson(AFormatted: Boolean = False): String;
var
  LJson, LUserProperties, LEventParams, LEventJson: TJsonObject;
  LEvents: TJsonArray;
  LParam: String;
begin
(* Converts payload Delphi object to expected Google Analytics 4 json payload.

Expected sample:
      {
          "client_id": "12345614",
          "user_id": "12345678914",
          "user_properties": {
              "user_plan": {"value": "pro"},
              "device_resolution": {"value": "1024x768"},
              "user_preference": {"value": "dark_mode"}
          },
          "events": [
              {
                  "name": "page_view",
                  "timestamp_micros": "1624898765432123",
                  "params": {
                      "page_location": "frmPrincipal",
                      "page_referrer": "NotDefined",
                      "page_title": "Gestão Mais Simples - Tela Principal 2",
                      "engagement_time_msec": 100,
                      "session_id": 1234,
                      "form_name": "frmPrincipal",
                      "app_version": "1.11.3",
                      "app_module": "GestaoMaisSimples.exe"
                  }
              }
          ]
      }

*)
  LJson := TJSONObject.Create;
  LUserProperties := TJsonObject.Create;
  LEvents := TJsonArray.Create;
  try
    for LParam in Self.User_Properties.FList.Keys do
    begin
      LUserProperties.AddPair(LParam,
        TJsonObject.Create(
          TJsonPair.Create('value', TValueToJsonValue(Self.User_Properties.FList[LParam]))
        )
      );
    end;

    for var event in Self.FEvents.FList do
    begin
      LEventParams := TJsonObject.Create;
      for LParam in event.FParams.FList.Keys do
        LEventParams.AddPair(LParam, TValueToJsonValue(event.FParams.FList[LParam]));

      LEventJson := TJsonObject.Create;
      LEventJson.AddPair('name', event.Name);
      //Opcional, usado para enviar eventos que ocorreram no passado no prazo máximo de até 72 horas.
      if event.Timestamp_Micros > 0 then
        LEventJson.AddPair('timestamp_micros', event.Timestamp_Micros);
      LEventJson.AddPair('params', LEventParams);
      LEvents.Add(LEventJson);
    end;



    LJson.AddPair('client_id', FClient_Id);
    {Id do usuário é opcional. Se estiver vazio, significa por exemplo, que o usuário
    ainda não logou no sistema/site.
    https://support.google.com/analytics/answer/9213390?hl=pt-br }
    if Trim(FUser_ID) <> '' then
      LJson.AddPair('user_id', FUser_Id);

    if Self.User_Properties.FList.Count > 0 then
      LJson.AddPair('user_properties', LUserProperties);
    LJson.AddPair('events', LEvents);

    if AFormatted then
      Result := LJson.Format()
    else
      Result := LJson.ToJSON();
  finally
    LJson.Free;
  end;
end;

function TGA4Payload.User_ID: String;
begin
  Result := FUser_ID;
end;

function TGA4Payload.User_ID(Value: String): IGA4Payload;
begin
  Result := Self;
  FUser_ID := Value;
end;

{ TGA4Events }

function TGA4Events.&End: IGA4Payload;
begin
  Result := Self.FOwner;
end;

function TGA4Events.AddNewEvent(AEventName: String): TGA4Event;
begin
  //https://developers.google.com/analytics/devguides/collection/protocol/ga4/sending-events?hl=pt-br&client_type=gtag#limitations
  if FList.Count >= 25 then
    raise EAnalyticsError.Create('In free version, only 25 events per request are allowed.');
  Result := TGA4Event.Create(Self.FOwner, AEventName);
  FList.Add(Result);
end;

constructor TGA4Events.Create(AOwner: IGA4Payload);
begin
  inherited Create;
  FOwner := AOwner;
  FList := TObjectList<TGA4Event>.Create(True);
end;

destructor TGA4Events.Destroy;
begin
  FList.Free;
  FOwner := nil;
  inherited;
end;

function TGA4Events.GetCount: Integer;
begin
  Result := Self.FList.Count;
end;

function TGA4Events.GetItem(const Index: Integer): TGA4Event;
begin
  Result := Self.FList.Items[Index];
end;

{ TGA4EventParams }

constructor TGA4EventParams.Create(AOwner: TGA4Event);
begin
  inherited Create;
  FOwner := AOwner;
end;

destructor TGA4EventParams.Destroy;
begin
  FOwner := nil;
  inherited;
end;

function TGA4EventParams.&End: TGA4Event;
begin
  Result := Self.FOwner;
end;

procedure TGA4EventParams.Validate(AParamName, AParamValue: String);
var
  LMaxLength: Integer;
begin
  inherited;
  {In free version, on Events are allowed:
  - 25 events params;
  - 40 characters for event param name;
  - 100 characters for event param value.
    Exceptions:
      O parâmetro page_title precisa ter até 300 caracteres
      O parâmetro page_referrer deve ter, no máximo, 420 caracteres
      O parâmetro page_location precisa ter até 1.000 caracteres

  Source: https://support.google.com/analytics/answer/9267744?hl=pt-BR }
  if FList.Count >= 25 then
    raise EAnalyticsError.Create('In the free version of Google Analytics, only 25 parameters are allowed.' + SLineBreak +
      'See more: https://support.google.com/analytics/answer/9267744?hl=pt-BR');

  if Length(AParamName) > 40 then
    raise EAnalyticsError.Create('Event param name must have max 40 characters: ' + AParamName);

  if Length(AParamValue) > 100 then
  begin
    case AnsiIndexStr(AParamName.ToLower, ['page_title', 'page_referrer', 'page_location']) of
      0: LMaxLength := 300;
      1: LMaxLength := 420;
      2: LMaxLength := 1000;
    else
      LMaxLength := 100;
    end;

    raise EAnalyticsError.CreateFmt('Event param value for param "%s" must have max 100 characters. ' +
      SLineBreak + 'Current content: %s ', [APAramName, AParamValue]);
  end;
end;

function TGA4EventParams.Add(AName, AValue: String): TGA4EventParams;
begin
  _Add(AName, AValue);
  Result := Self;
end;

function TGA4EventParams.Add(AName: String; AValue: Integer): TGA4EventParams;
begin
  _Add(AName, AValue);
  Result := Self;
end;

function TGA4EventParams.Add(AName: String; AValue: Double): TGA4EventParams;
begin
  _Add(AName, AValue);
  Result := Self;
end;

{ TGA4UserProperties }

function TGA4UserProperties.Add(AName, AValue: String): TGA4UserProperties;
begin
  _Add(AName, AValue);
  Result := Self;
end;

function TGA4UserProperties.Add(AName: String; AValue: Integer): TGA4UserProperties;
begin
  _Add(AName, AValue);
  Result := Self;
end;

function TGA4UserProperties.Add(AName: String; AValue: Double): TGA4UserProperties;
begin
  _Add(AName, AValue);
  Result := Self;
end;

constructor TGA4UserProperties.Create(AOwner: IGA4Payload);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TGA4UserProperties.&End: IGA4Payload;
begin
  Result := Self.FOwner;
end;

procedure TGA4UserProperties.Validate(AParamName, AParamValue: String);
begin
  inherited;
  {In free version, on User Propertie are allowed:
  - 25 user properties;
  - 24 characters for user propertie name;
  - 36 character for user propertie values;
  Source: //https://support.google.com/analytics/answer/9267744?hl=pt-BR
  }
  if FList.Count >= 25 then
    raise EAnalyticsError.Create('In the free version of Google Analytics, only 25 User Properties are allowed.' + SLineBreak +
      'See more: https://support.google.com/analytics/answer/9267744?hl=pt-BR');

  if Length(AParamName) > 24 then
    raise EAnalyticsError.Create('User propertie name must have max of 24 characters: ' + AParamName);

  if Length(AParamValue) > 36 then

    raise EAnalyticsError.CreateFmt('User propertie value for propertie "%s" must have max 36 characters. ' +
      SLineBreak + 'Current content: "%s" ', [APAramName, AParamValue]);
end;

end.
