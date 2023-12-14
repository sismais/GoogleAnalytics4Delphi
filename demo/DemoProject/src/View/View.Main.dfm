object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'GA4DemoProject - Main Form'
  ClientHeight = 559
  ClientWidth = 858
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  OnCreate = FormCreate
  DesignSize = (
    858
    559)
  TextHeight = 15
  object Label1: TLabel
    Left = 17
    Top = 428
    Width = 185
    Height = 30
    Caption = 'Test forms PageView in MainMenu navigation.'
    WordWrap = True
  end
  object btnDemoTrackClick: TButton
    Left = 17
    Top = 197
    Width = 185
    Height = 29
    Caption = 'Track Click'
    TabOrder = 0
    OnClick = btnDemoTrackClickClick
  end
  object btnPageView: TButton
    Left = 17
    Top = 156
    Width = 185
    Height = 29
    Caption = 'Track PageView'
    TabOrder = 1
    OnClick = btnPageViewClick
  end
  object Memo1: TMemo
    Left = 225
    Top = 24
    Width = 625
    Height = 509
    Anchors = [akLeft, akTop, akRight, akBottom]
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssBoth
    TabOrder = 2
    ExplicitWidth = 621
    ExplicitHeight = 508
  end
  object btnGenerateJson: TButton
    Left = 17
    Top = 65
    Width = 185
    Height = 29
    Caption = 'Generator GA4 Json Test'
    TabOrder = 3
    OnClick = btnGenerateJsonClick
  end
  object btnInitGA4: TButton
    Left = 17
    Top = 24
    Width = 185
    Height = 29
    Caption = 'Initialization'
    TabOrder = 4
    OnClick = btnInitGA4Click
  end
  object gbxCustomEvent: TGroupBox
    Left = 17
    Top = 246
    Width = 185
    Height = 144
    BiDiMode = bdLeftToRight
    Caption = 'Track Custom Event'
    ParentBiDiMode = False
    TabOrder = 5
    object btnTrackCustomEvent: TButton
      Left = 15
      Top = 92
      Width = 150
      Height = 29
      Caption = 'Track Custom Event'
      TabOrder = 0
      OnClick = btnTrackCustomEventClick
    end
    object CheckBox1: TCheckBox
      Left = 15
      Top = 24
      Width = 97
      Height = 17
      Caption = 'CheckBox1'
      TabOrder = 1
    end
    object Edit1: TEdit
      Left = 15
      Top = 54
      Width = 150
      Height = 23
      TabOrder = 2
      Text = 'Edit1'
    end
  end
  object MainMenu1: TMainMenu
    Left = 144
    Top = 10
    object este1: TMenuItem
      Caption = 'Cadastros'
      object mniCadastroCliente: TMenuItem
        Caption = 'Clientes'
        OnClick = mniCadastroClienteClick
      end
    end
  end
end
