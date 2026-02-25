# lazarus 扩展MainMenu功能
lazarus菜单栏在 Windows/macOS/GTK/Qt 下使用操作系统原生菜单，在linux，特别是国产的银河麒麟系统，菜单的背景颜色默认是灰黑色的，和应用程序界面颜色明显不搭。  
如采用自绘菜单栏，但自绘只在Windows下有效，为了实现跨平台（Windows/Linux）且不依赖系统原生渲染，需要完全抛弃系统菜单栏的渲染机制，改用自定义控件（TCustomControl）来模拟菜单栏，并用一个无边框窗体（TForm）来模拟弹出菜单。  
并充分利用原有的MainItem进行菜单设置，用一个单元文件 StyledMenuUnit.pas，你可以将其放到窗体上，绑定原有的 TMainMenu，即可实现自定义背景色和项目样式。  
只需要有MainMenu的单元添加红代码部分就可以实现自定义背景、字体，高亮颜色及字体大小及菜单栏位置(Align支持alTop / alBottom)等。  
下图是在Ubuntu截图的：
<img width="457" height="180" alt="image" src="https://github.com/user-attachments/assets/3916d59c-84f1-4df8-8524-e6ad1ebb483a" />
  
```
unit menu_unit;

{$mode objfpc}{$H+}
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, clipbrd,
  Menus,Messages, Buttons, ExtCtrls, ComCtrls,
  MATH,Spin,CheckLst, LazUTF8, LazUtils, cp936,LConvEncoding,
  LazUnicode, LazUTF16, LazSysUtils, LazUtilities,Types, Grids,StyledMenuUnit;

type

  { TForm1 }

  TForm1 = class(TForm)
    Label1: TLabel;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
  private
    FStyleBar:TStyledMenuBar;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function abnorm_menu(var ni:integer; var Sigma : double):Boolean;
//接近零不合格过程控制
var
  Form            : TForm;
  SigmaOpts       : Tradiogroup;
  optionx         : TGroupBox;
  DialogUnits     : TPoint;
  i,ButtonTop, ButtonWidth, ButtonHeight: Integer;
  Pedit           : TSpinEdit;
  pt,pt0          : TLabel;
begin
  Sigma := 0.05;
  ni:=10000;
  result:=false;
  Form := TForm.Create(Application);
  with Form do
    try
      Form.Color:=$00F8E7DF;
      Canvas.Font := Font;
      BorderStyle := bsDialog;
      Caption := '接近零不合格过程控制参数设置   ';
      ClientWidth := 255;
      ClientHeight :=138;
      Position := poScreenCenter;
      SigmaOpts := TRadiogroup.Create(Form);
      with SigmaOpts do
        begin
          Parent := Form;
          Left := 10;
          Top :=  10;
          Columns:=3;
          height:=40;
          width:= 235;
          Caption:= '显著水平:    ';
          items.add('0.05   ');
          items.add('0.01   ');
          items.add('0.005  ');
          itemindex:=0;
        end;
      pt := TLabel.Create(Form);
      with pt do
        begin
          Parent := form;
          Left := 10;
          Top := 60;
          caption:= '不合格品期望率(1/N), N=    ';
        end;
     pedit := TSpinEdit.Create(Form);
     with pedit do
       begin
         Parent := form;
         Left := 155;
         Top := 60;
         height:=15;
         width:=88;
         value:=10000;
         minvalue:=100;
         maxvalue:=100000000;
         Increment:=10000;
        end;
      ButtonTop := 100;
      ButtonWidth := 108;
      ButtonHeight := 28;
      with TButton.Create(Form) do
        begin
          Parent := Form;
          Caption := '确定';
          ModalResult := mrOk;
          Default := True;
          SetBounds(105, ButtonTop, ButtonWidth,ButtonHeight);
        end;
      if ShowModal = mrOk then
        begin
          ni:=pEdit.value;
          case SigmaOpts.ItemIndex of
             0:Sigma := 0.05;
             1:Sigma := 0.01;
             2:Sigma := 0.005;
          end;
          result:=true;
        end;
    finally
      Form.Free;
    end;
end;



procedure TForm1.MenuItem5Click(Sender: TObject);
var
  ni : Integer;
  si : Double;
begin
  if abnorm_menu(ni,si) then  ShowMessage(IntToStr(ni)+'   '+FloatToStr(si));
  Memo1.Lines.Clear;
  Memo1.Lines.Add(IntToStr(ni));
  Memo1.Lines.Add(floatToStr(si));
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

  FStyleBar:=TStyledMenuBar.Create(Self);
  FStyleBar.parent:=Self;
  //FStyleBar.Align:=alBottom;// alTop;
  FStyleBar.BarColor:=$00F8E7DA;//clSkyblue;
  FStyleBar.MainMenu:=MainMenu1;
  //FStyleBar.TextColor:=clBlack;
  //FStyleBar.ItemHoverColor:=clhighlight;
  //FStyleBar.TextHoverColor:=clYellow;
  //FStyleBar.PopupColor:=clGreen;
  FStyleBar.Font.Size := 10;
  FStyleBar.Font.Name := '微软雅黑';

end;

end.
```
