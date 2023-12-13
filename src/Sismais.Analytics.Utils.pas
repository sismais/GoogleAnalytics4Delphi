unit Sismais.Analytics.Utils;

interface

uses
  Winapi.Windows, System.JSON, System.RTTI, System.SysUtils, Vcl.Forms, System.Classes,
  System.IOUtils, System.IniFiles, System.StrUtils, System.DateUtils,
  System.Win.Registry;

  function UNIXTimeInMilliseconds: Int64;
  function GetUnixTimestampMicros: Int64;
  function TValueToJsonValue(const Value: TValue): TJSONValue;
  function GetAppVersion: string;
  function GetScreenResolution: string;
  /// <summary>
  ///   Get an Device ID / Client ID for identify an unique device in data analytics. <para />
  ///  Try to store in an inifile at User AppData folder (local settings), else try in application root folder,
  /// else get a random UUID.  <para />
  ///  If not exists, it create a new ID and stored it.
  /// </summary>
  function GetDeviceID(const AApplicationName: String): String;
  /// <summary>
  ///   Generate an unique Session ID number for application running instance, for use in GA4. <para />
  ///  Define your application name with no space or especial character. Use it to differ apps.
  /// If you have a modular application (many *.exe integrated) you can use same name at all *.exe,
  /// to see joined analytics data.
  /// </summary>
  function GetNewSessionID: Int64;

  /// <summary>
  ///   Get value of propertie "Name" of object. Is propertie or is empty, then try get ClassName, else return Default.
  /// </summary>
  function GetSenderNameOrClassName(Sender: TObject; ADefault: String): String;
  /// <summary>
  ///   Get value of propertie "Caption" of object. Is propertie not exists or except, return Default.
  /// </summary>
  function GetSenderCaption(Sender: TObject; ADefault: String): String;




type
  EAnalyticsError = class(Exception);

  TAnalyticsRttiUtils = record
    class function HasProperty(AObject: TObject; const APropertyName: String): Boolean;  static;
    /// <summary>
    ///   Find if propertie exists and get it's value. If properti not exists ou can't access, return TValue.From(nil);
    /// </summary>
    class function FindPropertyValue(AObject: TObject; const APropertyName: String): TValue; static;
    class function GetPropertyValue(AObject: TObject; const APropertyName: String): TValue; static;
  end;

implementation

function UNIXTimeInMilliseconds: Int64;
begin
  Result := MilliSecondsBetween(Now, UnixDateDelta);
end;

function GetUnixTimestampMicros: Int64;
begin
  Result := UNIXTimeInMilliseconds * 1000;
end;

function TValueToJsonValue(const Value: TValue): TJSONValue;
begin
  case Value.Kind of
    tkInteger:
      Result := TJSONNumber.Create(Value.AsInteger);
    tkFloat:
      if Value.IsType<Double> then
        Result := TJSONNumber.Create(Value.AsType<Double>)
      else if Value.IsType<Single> then
        Result := TJSONNumber.Create(Value.AsType<Single>)
      else
        Result := TJSONNumber.Create(Value.AsExtended);
    tkString, tkUString:
      Result := TJSONString.Create(Value.AsString);
  else
    Result := TJSONString.Create(Value.AsString);
  end;
end;

function GetAppVersion: string;
var
  Exe: string;
  Size, Handle: DWORD;
  Buffer: TBytes;
  FixedPtr: PVSFixedFileInfo;
begin
  try
    Exe := ParamStr(0);
    Size := GetFileVersionInfoSize(PChar(Exe), Handle);
    if Size = 0 then
      RaiseLastOSError;
    SetLength(Buffer, Size);
    if not GetFileVersionInfo(PChar(Exe), Handle, Size, Buffer) then
      RaiseLastOSError;
    if not VerQueryValue(Buffer, '\', Pointer(FixedPtr), Size) then
      RaiseLastOSError;
    Result := Format('%d.%d.%d.%d',
      [LongRec(FixedPtr.dwFileVersionMS).Hi,  //major
       LongRec(FixedPtr.dwFileVersionMS).Lo,  //minor
       LongRec(FixedPtr.dwFileVersionLS).Hi,  //release
       LongRec(FixedPtr.dwFileVersionLS).Lo]) //build
  except
    Result := '';
  end;
end;

function GetScreenResolution: string;
begin
  try
    Result := Screen.Width.Tostring + 'x' + Screen.Height.ToString;
  except
    Result := '';
  end;
end;

function GetDeviceID(const AApplicationName: String): String;
var
  LPath, LAppPath: String;
begin
  //ClientID = Device ID
  LPath := '';
  LAppPath := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  try
    try
      LPath := IncludeTrailingPathDelimiter(TPath.GetHomePath) + LAppPath;
      if not DirectoryExists(LPath) then
        ForceDirectories(LPath);
    except
      LPath := '';
    end;
    //Not acess AppData folder? try to create INI file in application folder.
    if LPath = '' then
      LPath := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));

    //Um único ID para todos os executáveis que o módulo utiliza.
    LPath := IncludeTrailingPathDelimiter(LPath) +
      IfThen(Trim(AApplicationName) = '', ChangeFileExt(ExtractFileName(ParamStr(0)), ''), AApplicationName) +
      '_AnalyticsData.ini';

    var iniFile := TIniFile.Create(LPath);
    try
      Result := iniFile.ReadString('AnalyticsData', 'GA_CLIENT_ID', '');
      //Create and store a new ID.
      if Trim(Result) = '' then
      begin
        Result := TGUID.NewGuid.ToString;
        iniFile.WriteString('AnalyticsData', 'GA_CLIENT_ID', Result);
      end;
    finally
      iniFile.Free;
    end;
  except
    //Gera um ID aleatório
    Result := TGUID.NewGuid.ToString;
  end;
end;

function GetNewSessionID: Int64;
begin
  {No contexto do Google Analytics 4 (GA4), o session_id é normalmente gerenciado
  automaticamente pelo GA4. No entanto, se você deseja controlar o session_id
  manualmente em um aplicativo Delphi, pode fazê-lo
  seguindo estas etapas}
  Result := DateTimeToUnix(Now, False) * 1000; // Data e hora atuais em milissegundos;
end;

function GetSenderNameOrClassName(Sender: TObject; ADefault: String): String;
var
  LValue: TValue;
begin
  try
    if Sender is TComponent then
    begin
      Result := TComponent(Sender).Name;
      if Trim(Result).IsEmpty then
        Result := Sender.ClassName;
    end
    else
    begin
      //Check if have a propertie named "Name", with RTTI.
      LValue := TAnalyticsRttiUtils.FindPropertyValue(Sender, 'Name');
      if not LValue.IsEmpty then
        Result := Trim(LValue.AsString);
    end;

    if Trim(Result).IsEmpty then
      Result := Trim(ADefault);
  except
    Result := Trim(ADefault);
  end;
end;

function GetSenderCaption(Sender: TObject; ADefault: String): String;
var
  LValue: TValue;
begin
  try
    //Check if have a propertie named "Caption", with RTTI.
    if TAnalyticsRttiUtils.HasProperty(Sender, 'Caption') then
    begin
      LValue := TAnalyticsRttiUtils.FindPropertyValue(Sender, 'Caption');
      if not LValue.IsEmpty then
        Result := Trim(LValue.AsString);
    end
    else
      Result := Trim(ADefault);
  except
    Result := Trim(ADefault);
  end;
end;


{ TAnalyticsRttiUtils }

class function TAnalyticsRttiUtils.FindPropertyValue(AObject: TObject; const APropertyName: String): TValue;
var
  eContext  : TRttiContext;
  eProperty : TRttiProperty;
begin
  Result := Nil;
  eContext := TRttiContext.create;
  try
    eProperty := eContext.GetType(AObject.ClassType).GetProperty(APropertyName);

    if Assigned(eProperty) then
      Result := eProperty.GetValue(AObject)
    else
      Result := TValue.From(nil);
  finally
    eContext.Free;
  end;
end;

class function TAnalyticsRttiUtils.GetPropertyValue(AObject: TObject; const APropertyName: String): TValue;
var
  eContext  : TRttiContext;
  eProperty : TRttiProperty;
begin
  Result := Nil;
  eContext := TRttiContext.create;
  try
    eProperty := eContext.GetType(AObject.ClassType).GetProperty(APropertyName);

    if Assigned(eProperty) then
      Result := eProperty.GetValue(AObject)
    else
      raise EAnalyticsError.Create(' "' + APropertyName + '" property not fount.' );
  finally
    eContext.Free;
  end;
end;

class function TAnalyticsRttiUtils.HasProperty(AObject: TObject; const APropertyName: String): Boolean;
var
  eContext  : TRttiContext;
  eProperty : TRttiProperty;
begin
  eContext := TRttiContext.create;
  try
    eProperty := eContext.GetType(AObject.ClassType).GetProperty(APropertyName);
    Result := Assigned(eProperty)
  finally
    eContext.Free;
  end;
end;

end.
