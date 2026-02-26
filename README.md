# lazarus 扩展MainMenu功能
lazarus菜单栏在 Windows/macOS/GTK/Qt 下使用操作系统原生菜单，在linux，特别是国产的银河麒麟系统，菜单的背景颜色默认是灰黑色的，和应用程序界面颜色明显不搭。  
如采用自绘菜单栏，但自绘只在Windows下有效，为了实现跨平台（Windows/Linux）且不依赖系统原生渲染，需要完全抛弃系统菜单栏的渲染机制，改用自定义控件（TCustomControl）来模拟菜单栏，并用一个无边框窗体（TForm）来模拟弹出菜单。  
并充分利用原有的MainItem进行菜单设置，用一个单元文件 StyledMenuUnit.pas，你可以将其放到窗体上，绑定原有的 TMainMenu，即可实现自定义背景色和项目样式。  
只需要有MainMenu的单元添加红代码部分就可以实现自定义背景、字体，高亮颜色及字体大小及菜单栏位置(Align支持alTop / alBottom)等。  
下图是银河麒麟使用原生菜单栏：  
<img width="552" height="243" alt="image" src="https://github.com/user-attachments/assets/6a80ee39-d610-4524-84f4-6001694ea6ba" />  
下图是银河麒麟使用菜单扩展功能后：  
<img width="556" height="214" alt="image" src="https://github.com/user-attachments/assets/b7bab6bb-3e94-4f0f-ae5d-8e4e0e9cdd89" />  
下图是在Ubuntu截图的：  
<img width="457" height="180" alt="image" src="https://github.com/user-attachments/assets/3916d59c-84f1-4df8-8524-e6ad1ebb483a" />  
<img width="371" height="242" alt="image" src="https://github.com/user-attachments/assets/6e7ab77c-2b39-474d-ac5b-0d2c63220ac9" />  
<img width="776" height="434" alt="image" src="https://github.com/user-attachments/assets/4e7e3852-f91f-4cbc-a674-6d5fd6d56fc2" />  
# demo：    
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
  private
    FStyleBar:TStyledMenuBar;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

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
