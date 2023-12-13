unit Sismais.Analytics.ApiClient;

interface

uses
  System.SysUtils, System.Classes, Sismais.Analytics.Models, System.JSON, VCL.Forms,
  RESTRequest4D;


  procedure SendEvent(const ADebugApi, AUseThread: Boolean; const AJson, AMeasurementId, AApiSecret: String);

implementation

uses
  System.DateUtils, Sismais.Analytics.Utils;

type
  TPostThread = class(TThread)
  private
    FDebugApi: Boolean;
    FJson: String;
    FMeasurementId: String;
    FApiSecret: String;
    procedure Execute; override;
  public
    constructor Create(const ADebugApi: Boolean; const AJson, AMeasurementID, AApiScret: String); reintroduce;
  end;

procedure SendEvent(const ADebugApi, AUseThread: Boolean; const AJson, AMeasurementId, AApiSecret: String);
begin
  if AUseThread then
  begin
    TPostThread.Create(ADebugApi, AJson, AMeasurementId, AApiSecret).Start;
  end
  else
    //Execute with no Thread.
    TPostThread.Create(ADebugApi, AJson, AMeasurementId, AApiSecret).Execute;
end;

{ TPostThread }

constructor TPostThread.Create(const ADebugApi: Boolean; const AJson, AMeasurementID, AApiScret: String);
begin
  inherited Create(True); //Create suspended.
  FDebugApi := ADebugApi;
  Priority := tpLower;
  FJson := AJson;
  FMeasurementId := AMeasurementID;
  FApiSecret := AApiScret;
  Self.FreeOnTerminate := True;
end;

procedure TPostThread.Execute;
const
  BASE_URL = 'https://www.google-analytics.com';
  DEBUG_ENDPOINT = '/debug';
  COLLECT_ENDPOINT = '/mp/collect?measurement_id=%s&api_secret=%s';
var
  LUrl: String;
  LResponse: IResponse;
  I: Integer;
  LText: String;
  LValidationMessages: TJsonArray;
begin
  try
    NameThreadForDebugging('TPostThread (Analytics API Request Sender)');

    if FDebugApi then
      LUrl := BASE_URL + DEBUG_ENDPOINT + Format(COLLECT_ENDPOINT, [FMeasurementId, FAPISecret])
    else
      LUrl := BASE_URL + Format(COLLECT_ENDPOINT, [FMeasurementId, FAPISecret]);

    LResponse := TRequest.New.BaseURL(LUrl)
      .ContentType('application/json')
      .Accept('application/json')
      .AddBody(FJson)
      .Post;

    if FDebugApi then
    begin
      if not ((LResponse.StatusCode >= 200) and (LResponse.StatusCode <= 299)) then
        raise EAnalyticsError.CreateFmt('Send request return not expected response: %d - %s %s%s',
          [LResponse.StatusCode, LResponse.StatusText, SLineBreak, LResponse.Content]);

      (*
      O Measurement Protocol sempre retornará um código de status 2xx se a solicitação HTTP tiver sido recebida.
      O Measurement Protocol não vai retornar um código de erro se os dados de payload tiverem a formatação incorreta,
      se estiverem errados ou não tiverem sido processados pelo Google Analytics.

      Exemplo de retorno:
        {
            "validationMessages": [
                {
                    "fieldPath": "events",
                    "description": "Event at index: [0] has invalid name [_page_view]. Names must start with an alphabetic character.",
                    "validationCode": "NAME_INVALID"
                }
            ]
        }

        Retorno OK (sem erros):

        {
            "validationMessages": []
        }

       *)
       LText := '';
       if LResponse.JSONValue.FindValue('validationMessages') <> nil then
       begin
         LValidationMessages := LResponse.JSONValue.GetValue<TJsonArray>('validationMessages');
         for I := 0 to LValidationMessages.Count - 1 do
           LText := LText + Format('- fieldPath: %s. validationCode: %s, description: %s %s',
            [LValidationMessages.Items[I].GetValue<String>('fieldPath', ''),
            LValidationMessages.Items[I].GetValue<String>('validationCode', ''),
            LValidationMessages.Items[I].GetValue<String>('description', ''),
            SLineBreak]);
       end;
       if Trim(LText) <> '' then
        raise EAnalyticsError.Create('validationMessages: ' + SLineBreak + LText);


    end;
  except
    on E:Exception do
    begin
      if FDebugApi then
      begin
        E.Message := 'Analytics send request error: ' + SLineBreak + E.Message;
        TThread.Synchronize(TThread.CurrentThread,
          procedure
          begin
            Application.ShowException(E);
          end)
      end;
    end;
  end;
end;

end.
