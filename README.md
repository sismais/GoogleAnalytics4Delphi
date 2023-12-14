# GoogleAnalytics4Delphi

Library to abstract integration with Google Analytics for use in Delphi Applications.

"Contribute by sending pull requests with fixes and enhancements.

DONATE to help maintain the library:

* MercadoPago [R$ 10,00](https://mpago.la/2zYaQeV)  |  [R$ 30,00](https://mpago.la/2FKwwH9)  |  [R$ 50,00](https://mpago.la/1WThavk)
* PIX: 30fcfe7d-3d00-41d1-8273-9dcae8e2d5ac   (Maicon J. S. Oliveira)

# Install

## Boss install

Use [boss](https://github.com/HashLoad/boss) to install the package and it's dependencies:

`boss install https://github.com/sismais/GoogleAnalytics4Delphi.git`

## Manual installation

For manual installation, you need to install these dependencies:

* [RestRequest4Delphi](https://github.com/viniciussanchez/RESTRequest4Delphi)

## How to use?

See the project at [demo/DemoProject](/demo/DemoProject) to see how to configure and send.

**Sample codes:

```delphi
uses
  Sismais.Analytics;

...

procedure ConfigAnalytics;
const
  APP_NAME = 'AppName';
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
  LDeviceId := Sismais.Analytics.GetDeviceID(APP_NAME);

  TAnalytics.Instance
    .Config
      .MeasurementId(MEASUREMENT_ID)
      .ApiSecret(API_SECRET)
      .ClientID(LDeviceId)
      .CompanyID(LCompanyID)
      //Opcional. Deixe em branco enquanto o usuário não fizer login. Preencha após o usuário efetuar o login.
      .UserID(LUserId)
      .DebugEndPoint(False);
end;

```

**Send PageView**

```delphi
procedure TfrmMain.btnPageViewClick(Sender: TObject);
begin
  Memo1.Lines.Text := TAnalytics.Instance.SendPageView(Self.ClassName, Self.Caption).ToJson(True);
  {In this sample i capture result Json in a TMemo to debug. In production, you can use with no return.
    Eg.:
    TAnalytics.Instance.SendPageView(Self.ClassName, Self.Caption);
  }
end;
```

**Send element click (button, control, label, etc.)**

```
procedure TfrmMain.btnDemoTrackClickClick(Sender: TObject);
begin
  TAnalytics.Instance.SendClick(
    Self.ClassName,
    Self.Caption,
    GetSenderNameOrClassName(Sender, 'DefaultName'),
    GetSenderCaption(Sender, 'DefaultCaption'));
end;
```

**Send custom events**

Note: Before sending the event, the private method "TAnalytics.BeforePost(APayload)" is called to insert some required/recommended user properties and event parameters. If necessary, you can create a new class inherited from TAnalytics and override the BeforePost method to edit the payload, inserting or modifying the added event parameters and user properties.

```delphi
procedure TfrmMain.btnTrackCustomEventClick(Sender: TObject);
var
  LPayload: IGA4Payload;
begin
  {Observations:
  - Custom events have several rules. If not respected, events not registered.
    Please read links before create custom events.
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

  {Note: Before sending the event, the private method "TAnalytics.BeforePost(APayload)" 
  is called to insert some required/recommended user properties and event parameters. 
  If necessary, you can create a new class inherited from TAnalytics and override the 
  BeforePost method to edit the payload, inserting or modifying the added event parameters 
  and user properties.}  
  TAnalytics.Instance.SendCustomEvents(Self.ClassName, Self.Caption, LPayload);

  Memo1.Lines.Text := LPayload.ToJson(True);
end;
```

**Tests in Postmand**

You can use the Postman to validate and undertand the format of body GA4 Payload (Json):

[<img src="https://run.pstmn.io/button.svg" alt="Run In Postman" style="width: 128px; height: 32px;">](https://app.getpostman.com/run-collection/3415784-465b3505-e6da-4fc8-9c69-735784f1583c?action=collection%2Ffork&source=rip_markdown&collection-url=entityId%3D3415784-465b3505-e6da-4fc8-9c69-735784f1583c%26entityType%3Dcollection%26workspaceId%3D5b0baa99-1535-4316-854d-321fecc6bb6f)

# FAQ

### My events not appear in Realtime report

See this steps:

* Send JSON through Postman (or another REST debugger tool). If it doesn't appear in the Real Time Report option within a few moments, then something is wrong. Try the steps below;
* Use the DebugView endpoint to find out if something is wrong;
* Use Event Build to generate an event with the same conditions as the generated JSON and validate.

### How to capture user and device information (Platform, App Version, Screen Resolution, etc.)?

In the link below (home page) about integration via Measurement Protocol (a way that we can use in Delphi) it is made clear that collecting data using this way has limitations in terms of reporting possibilities:

https://developers.google.com/analytics/devguides/collection/protocol/ga4?hl=pt-br
Excerpt:
*Although it is possible to send events to Google Analytics using Measurement Protocol alone, only partial reports may be available. The goal of Measureme****nt Protocol is to increase events collected with gtag, GTM, or Firebase. Some event and parameter names are reserved for use with automatic collection and cannot be sent by Measurement Protocol.*

In the link below, a user experienced the same problems as me, trying to implement the sending of basic information such as Windows version, screen resolution, etc. :

https://stackoverflow.com/questions/68636233/ga4-measurement-protocol-does-not-display-user-data-location-screen-resolution

There was only one response, highlighting the excerpt below:

*The measurement protocol for ga4 is extremely limited it will not let you send all of the reserved events sent by firebase, google tag Manager or any other google created systems.*

#### So, what's the solution?

Configure custom dimensions and metrics and then include it in needed reports or create custom reports.

# Understanding how to GA4 and Measurement Protocol works

To extract the maximum resources of GA4, you need to learn the basics about GA4 Analytics and their event posts.

Some links about GA4:

(Content is in pt-br, change URL part "hl=pt-br" to "hl=en" to english.)

- [GA4 Measurement Protocol: Turning Data Precision into Success](https://www.owox.com/blog/articles/ga4-measurement-protocol/)
- [Measurement Protocol (Google Analytics 4)](https://developers.google.com/analytics/devguides/collection/protocol/ga4?hl=pt-br)
- [User_Properties / Propriedades do usuário](https://developers.google.com/analytics/devguides/collection/protocol/ga4/user-properties?hl=pt-br&client_type=gtag)
- [Como enviar eventos para o GA4](https://developers.google.com/analytics/devguides/collection/protocol/ga4/sending-events?hl=pt-br&client_type=firebase#required_parameters)
- [Como validar eventos?](https://developers.google.com/analytics/devguides/collection/protocol/ga4/validating-events?hl=pt-br&client_type=gtag)
- [Nomes de eventos e parâmetros reservados. QUE NÃO DEVEM SER USADOS](https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?hl=pt-br&client_type=gtag#reserved_names)
- [Estrutura do JSON](https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?hl=pt-br&client_type=gtag#payload_post_body)
- [Práticas recomendadas ao criar dimensões personalizadas (propriedades do usuário ou do evento)](https://support.google.com/analytics/answer/10075209?hl=pt&utm_id=ad#best-practices)
- [Como validar eventos](https://developers.google.com/analytics/devguides/collection/protocol/ga4/validating-events?hl=pt-br&client_type=gtag)
- [Criador de eventos (criar e validar eventos)](https://ga-dev-tools.web.app/ga4/event-builder/)
- [JSON Post Body](https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?hl=pt-br&client_type=gtag#payload_post_body)
- Práticas recomendadas ao criar dimensões personalizadas (propriedades do usuário ou do evento):
