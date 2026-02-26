unit StyledMenuUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Menus, LCLType, Dialogs,
  LCLIntf, LMessages, ExtCtrls, StdCtrls, GraphType, imglist, lclproc, ComCtrls;

type
  { 前向声明 }
  TStyledMenuBar = class;

  { TStyledMenuPopup }
  TStyledMenuPopup = class(TCustomForm)
  private
    FMenuItems: TMenuItem;
    FImages: TCustomImageList;
    FHoverIndex: Integer;
    FOnClosePopup: TNotifyEvent;

    FMaxTextWidth: Integer;
    FMaxShortcutWidth: Integer;
    FItemHeight: Integer;
    FTextIndent: Integer;

    FChildPopup: TStyledMenuPopup;
    FParentPopup: TStyledMenuPopup;
    FMenuBar: TStyledMenuBar;

    FActiveSubMenuIndex: Integer;

    procedure SetMenuItems(AValue: TMenuItem);
    procedure CalculateLayout;
    procedure PaintItem(Index: Integer; ARect: TRect; IsHover: Boolean);
    procedure CMMouseLeave(var Msg: TLMessage); message CM_MOUSELEAVE;

    function GetPopupColor: TColor;
    function GetPopupBorderColor: TColor;
    function GetItemHoverColor: TColor;
    function GetTextColor: TColor;
    function GetTextHoverColor: TColor;
    function GetDisabledTextColor: TColor;

    procedure ShowSubMenu(Index: Integer);
    procedure HideSubMenu;
    procedure CloseAllPopups;

    function IsPointInChildPopup(P: TPoint): Boolean;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoHide; override;
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
    destructor Destroy; override;

    property MenuItems: TMenuItem read FMenuItems write SetMenuItems;
    property Images: TCustomImageList read FImages write FImages;
    property OnClosePopup: TNotifyEvent read FOnClosePopup write FOnClosePopup;
    property ParentPopup: TStyledMenuPopup read FParentPopup write FParentPopup;
  end;

  { TStyledMenuBar }
  TStyledMenuBar = class(TCustomControl)
  private
    FIconSize:Integer;
    FMainMenu: TMainMenu;
    FHotIndex: Integer;
    FPressedIndex: Integer;
    FPopupForm: TStyledMenuPopup;

    FOwnerForm: TCustomForm;
    FOldFormChangeBounds: TNotifyEvent;
    FOldAppShortCut: TShortCutEvent;

    FBarColor: TColor;
    FItemHoverColor: TColor;
    FTextColor: TColor;
    FTextHoverColor: TColor;
    FPopupColor: TColor;
    FPopupBorderColor: TColor;
    FDisabledTextColor: TColor;

    procedure SetMainMenu(AValue: TMainMenu);
    function GetItemRect(Index: Integer): TRect;
    function GetItemWidth(Index: Integer): Integer;

    procedure ShowPopupForm(P: TPoint; Items: TMenuItem; Images: TCustomImageList);
    procedure HidePopup;
    procedure DoPopupClose(Sender: TObject);

    procedure HookEvents;
    procedure UnhookEvents;

    procedure DoFormChangeBounds(Sender: TObject);
    procedure DoAppShortCut(var Msg: TLMKey; var Handled: Boolean);

    function FindMenuItemByShortCut(Items: TMenuItem; ShortCut: TShortCut): TMenuItem;
  protected
    procedure Paint; override;
    procedure CalculatePreferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;

    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseLeave; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Popup(X, Y: Integer; APopupMenu: TPopupMenu);
  published
    property Align default alTop;
    property Font;
    property AutoSize;

    property IconSize: Integer read FIconSize write FIconSize default 24;
    property BarColor: TColor read FBarColor write FBarColor default clBtnFace;
    property ItemHoverColor: TColor read FItemHoverColor write FItemHoverColor default clHighlight;
    property TextColor: TColor read FTextColor write FTextColor default clBtnText;
    property TextHoverColor: TColor read FTextHoverColor write FTextHoverColor default clHighlightText;
    property PopupColor: TColor read FPopupColor write FPopupColor default clWhite;
    property PopupBorderColor: TColor read FPopupBorderColor write FPopupBorderColor default clGray;
    property DisabledTextColor: TColor read FDisabledTextColor write FDisabledTextColor default clGray;

    property MainMenu: TMainMenu read FMainMenu write SetMainMenu;
  end;

procedure Register;

implementation

uses
  Math;

procedure Register;
begin
  RegisterComponents('Additional', [TStyledMenuBar]);
end;

{ TStyledMenuPopup }

constructor TStyledMenuPopup.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);
  BorderStyle := bsNone;
  FormStyle := fsSystemStayOnTop;
  ShowInTaskBar := stNever;
  FHoverIndex := -1;
  FActiveSubMenuIndex := -1;
  Color := clWhite;
  DoubleBuffered := True;

  if AOwner is TStyledMenuBar then
    FMenuBar := TStyledMenuBar(AOwner)
  else if AOwner is TStyledMenuPopup then
    FMenuBar := TStyledMenuPopup(AOwner).FMenuBar;
end;

destructor TStyledMenuPopup.Destroy;
begin
  if FChildPopup <> nil then
  begin
    FChildPopup.Free;
    FChildPopup := nil;
  end;
  inherited Destroy;
end;

procedure TStyledMenuPopup.DoHide;
begin
  HideSubMenu;
  inherited DoHide;
end;

function TStyledMenuPopup.GetPopupColor: TColor;
begin
  if FMenuBar <> nil then
    Result := FMenuBar.PopupColor
  else
    Result := clWhite;
end;

function TStyledMenuPopup.GetPopupBorderColor: TColor;
begin
  if FMenuBar <> nil then
    Result := FMenuBar.PopupBorderColor
  else
    Result := clGray;
end;

function TStyledMenuPopup.GetItemHoverColor: TColor;
begin
  if FMenuBar <> nil then
    Result := FMenuBar.ItemHoverColor
  else
    Result := clHighlight;
end;

function TStyledMenuPopup.GetTextColor: TColor;
begin
  if FMenuBar <> nil then
    Result := FMenuBar.TextColor
  else
    Result := clBtnText;
end;

function TStyledMenuPopup.GetTextHoverColor: TColor;
begin
  if FMenuBar <> nil then
    Result := FMenuBar.TextHoverColor
  else
    Result := clHighlightText;
end;

function TStyledMenuPopup.GetDisabledTextColor: TColor;
begin
  if FMenuBar <> nil then
    Result := FMenuBar.DisabledTextColor
  else
    Result := clGray;
end;

function TStyledMenuPopup.IsPointInChildPopup(P: TPoint): Boolean;
begin
  Result := False;
  if (FChildPopup <> nil) and (FChildPopup.Visible) then
  begin
    Result := PtInRect(FChildPopup.ClientRect, FChildPopup.ScreenToClient(P));
  end;
end;

procedure TStyledMenuPopup.CalculateLayout;
var
  i: Integer;
  Item: TMenuItem;
  ShortCutText: String;
  MaxImgWidth, MaxImgHeight: Integer;
  IconSize,MaxIconSize:Integer;
begin
  FMaxTextWidth := 0;
  FMaxShortcutWidth := 0;
  FItemHeight := 0;
  FTextIndent := 0;

  if FMenuItems = nil then Exit;

  if FMenuBar <> nil then
    Canvas.Font.Assign(FMenuBar.Font)
  else
    Canvas.Font := Screen.MenuFont;

  MaxImgWidth := 0;
  MaxImgHeight := 0;
  MaxIconSize := 0;
  if FMenuBar <> nil then
    IconSize := FMenuBar.IconSize
  else
    IconSize := 24;

  if IconSize=0 then
  begin
    for i := 0 to FMenuItems.Count - 1 do
    begin
      Item := FMenuItems[i];
      if (Item.Bitmap <> nil) and (not Item.Bitmap.Empty) then
      begin
          MaxIconSize:=Min(Item.Bitmap.Width,Item.Bitmap.Height);
          IconSize:=Max(MaxIconSize,IconSize);
      end;
    end;
  end;

  if (IconSize=0) and (FImages <> nil) then
    IconSize:=Min(FImages.Width,FImages.Height);

  if IconSize=0 then
    IconSize:=24;
  if (FImages <> nil) and (FImages.Count > 0) then
  begin
    MaxImgWidth := Min(FImages.Width, IconSize);
    MaxImgHeight := Min(FImages.Height, IconSize);
  end;

  for i := 0 to FMenuItems.Count - 1 do
  begin
    Item := FMenuItems[i];
    if (Item.Bitmap <> nil) and (not Item.Bitmap.Empty) then
    begin
      MaxImgWidth := Max(MaxImgWidth, Min(Item.Bitmap.Width, IconSize));
      MaxImgHeight := Max(MaxImgHeight, Min(Item.Bitmap.Height, IconSize));
    end;
  end;

  if MaxImgWidth > 0 then
    FTextIndent := 4 + IconSize + 6
  else
    FTextIndent := 10;

  for i := 0 to FMenuItems.Count - 1 do
  begin
    Item := FMenuItems[i];
    if Item.Caption <> '-' then
    begin
      FMaxTextWidth := Max(FMaxTextWidth, Canvas.TextWidth(StringReplace(Item.Caption, '&', '', [rfReplaceAll])));
      ShortCutText := ShortCutToText(Item.ShortCut);
      if ShortCutText = 'Unknown' then ShortCutText := '';
      if ShortCutText <> '' then
        FMaxShortcutWidth := Max(FMaxShortcutWidth, Canvas.TextWidth(ShortCutText));
    end;
  end;

  FItemHeight := Max(IconSize, Canvas.TextHeight('Wg')) + 6;
end;

procedure TStyledMenuPopup.SetMenuItems(AValue: TMenuItem);
var
  i: Integer;
  TotalHeight, TotalWidth: Integer;
begin
  if FMenuItems <> AValue then
    HideSubMenu;

  FMenuItems := AValue;
  FHoverIndex := -1;
  FActiveSubMenuIndex := -1;

  if FMenuItems = nil then Exit;

  CalculateLayout;

  // 修改宽度计算：增加右侧预留空间 (+30 改为 +40)，确保箭头不被截断
  TotalWidth := FTextIndent + FMaxTextWidth + 20 + FMaxShortcutWidth + 40;
  if TotalWidth < 150 then TotalWidth := 150;

  TotalHeight := 4;
  for i := 0 to FMenuItems.Count - 1 do
  begin
    if FMenuItems[i].Caption = '-' then
      TotalHeight := TotalHeight + 6
    else
      TotalHeight := TotalHeight + FItemHeight;
  end;
  TotalHeight := TotalHeight + 2;

  ClientWidth := TotalWidth;
  ClientHeight := TotalHeight;
end;

procedure TStyledMenuPopup.PaintItem(Index: Integer; ARect: TRect; IsHover: Boolean);
var
  Item: TMenuItem;
  IconX, IconY: Integer;
  TextX: Integer;
  ShortCutText: String;
  IconIdx: Integer;
  ShortCutX: Integer;
  IconWidth, IconHeight: Integer;
  Bmp: TBitmap;
  DrawEffect: TGraphicsDrawEffect;
  HasSubMenu: Boolean;
  IconSize: Integer;
begin
  Item := FMenuItems[Index];
  HasSubMenu := (Item.Count > 0);

  if Item.Enabled then
  begin
    if IsHover then
    begin
      Canvas.Brush.Color := GetItemHoverColor;
      Canvas.Font.Color := GetTextHoverColor;
    end
    else
    begin
      Canvas.Brush.Color := GetPopupColor;
      Canvas.Font.Color := GetTextColor;
    end;
    DrawEffect := gdeNormal;
  end
  else
  begin
    Canvas.Brush.Color := GetPopupColor;
    Canvas.Font.Color := GetDisabledTextColor;
    DrawEffect := gdeDisabled;
  end;

  Canvas.FillRect(ARect);

  if Item.Caption = '-' then
  begin
    Canvas.Pen.Color := clGray;
    Canvas.Line(ARect.Left + 2, ARect.Top + 2, ARect.Right - 2, ARect.Top + 2);
    Exit;
  end;

  IconWidth := 0;
  IconHeight := 0;
  IconIdx := Item.ImageIndex;
  if FMenuBar <> nil then
    IconSize := FMenuBar.IconSize
  else
    IconSize := 24;

  if (FImages <> nil) and (IconIdx >= 0) and (IconIdx < FImages.Count) then
  begin
    if IconSize=0 then
    begin
      IconSize:=Min(FImages.Width,FImages.Height);
    end
    else
      IconSize:=24;
    IconWidth := Min(FImages.Width, IconSize);
    IconHeight := Min(FImages.Height, IconSize);
    IconX := ARect.Left + 4;
    IconY := ARect.Top + (ARect.Height - IconHeight) div 2;

    if (IconWidth = FImages.Width) and (IconHeight = FImages.Height) then
    begin
      FImages.Draw(Canvas, IconX, IconY, IconIdx, dsTransparent, itImage, DrawEffect);
    end
    else
    begin
      Bmp := TBitmap.Create;
      try
        Bmp.Width := FImages.Width;
        Bmp.Height := FImages.Height;
        FImages.Draw(Bmp.Canvas, 0, 0, IconIdx, dsTransparent, itImage, DrawEffect);
        Bmp.Transparent := True;
        Canvas.StretchDraw(Rect(IconX, IconY, IconX + IconWidth, IconY + IconHeight), Bmp);
      finally
        Bmp.Free;
      end;
    end;
  end
  else if (Item.Bitmap <> nil) and (not Item.Bitmap.Empty) then
  begin
    if IconSize=0 then
    begin
      IconSize:=Min(Item.Bitmap.Width,Item.Bitmap.Height);
      if IconSize=0 then IconSize:=24;
    end;
    IconWidth := Min(Item.Bitmap.Width, IconSize);
    IconHeight := Min(Item.Bitmap.Height, IconSize);
    IconX := ARect.Left + 4;
    IconY := ARect.Top + (ARect.Height - IconHeight) div 2;
    Item.Bitmap.Transparent := True;
    Canvas.StretchDraw(Rect(IconX, IconY, IconX + IconWidth, IconY + IconHeight), Item.Bitmap);
  end;

  TextX := ARect.Left + FTextIndent;
  Canvas.Brush.Style := bsClear;
  Canvas.TextRect(ARect, TextX, ARect.Top + (ARect.Height - Canvas.TextHeight('Wg')) div 2,
                  StringReplace(Item.Caption, '&', '', [rfReplaceAll]));

  ShortCutText := ShortCutToText(Item.ShortCut);
  if ShortCutText = 'Unknown' then ShortCutText := '';
  if ShortCutText <> '' then
  begin
    // 调整 ShortCut 位置，向左移动一点，为箭头腾出更多空间
    ShortCutX := ARect.Right - Canvas.TextWidth(ShortCutText) - 25;
    Canvas.TextRect(ARect, ShortCutX, ARect.Top + (ARect.Height - Canvas.TextHeight('Wg')) div 2, ShortCutText);
  end;

  if HasSubMenu then
  begin
    Canvas.Font.Size:=10;
    Canvas.Pen.Color := Canvas.Font.Color;
    // 调整箭头位置：向左移动 (Right - 15)，确保完整显示且不贴边
    IconX := ARect.Right - 15;
    IconY := ARect.Top + (ARect.Height - Canvas.TextHeight('Wg')) div 2;
    //IconY := ARect.Top + ARect.Height div 2;
    // 绘制箭头 (三角形)
    Canvas.TextOut(IconX,IconY, '>');
    //Canvas.Line(IconX, IconY - 3, IconX + 4, IconY);
    //Canvas.Line(IconX, IconY + 3, IconX + 4, IconY);
  end;
end;

procedure TStyledMenuPopup.Paint;
var
  i: Integer;
  R: TRect;
  CurY: Integer;
begin
  inherited Paint;

  Canvas.Pen.Color := GetPopupBorderColor;
  Canvas.Brush.Color := GetPopupColor;
  Canvas.Rectangle(0, 0, ClientWidth, ClientHeight);

  if FMenuItems = nil then Exit;

  if FMenuBar <> nil then
    Canvas.Font.Assign(FMenuBar.Font)
  else
    Canvas.Font := Screen.MenuFont;

  CurY := 2;

  for i := 0 to FMenuItems.Count - 1 do
  begin
    if FMenuItems[i].Caption = '-' then
      R := Rect(1, CurY, ClientWidth - 1, CurY + 6)
    else
      R := Rect(1, CurY, ClientWidth - 1, CurY + FItemHeight);

    PaintItem(i, R, (i = FHoverIndex));
    CurY := R.Bottom;
  end;
end;

procedure TStyledMenuPopup.CMMouseLeave(var Msg: TLMessage);
begin
  inherited;
end;

procedure TStyledMenuPopup.ShowSubMenu(Index: Integer);
var
  Item: TMenuItem;
  P: TPoint;
  R: TRect;
  CurY: Integer;
  ScreenRect: TRect;
  i: Integer;
begin
  if (Index < 0) or (Index >= FMenuItems.Count) then Exit;

  Item := FMenuItems[Index];
  if (Item.Count = 0) then Exit;

  if (FChildPopup <> nil) and (FActiveSubMenuIndex = Index) then Exit;

  HideSubMenu;

  FActiveSubMenuIndex := Index;

  CurY := 2;
  for i := 0 to Index - 1 do
  begin
    if FMenuItems[i].Caption = '-' then
      CurY := CurY + 6
    else
      CurY := CurY + FItemHeight;
  end;

  R := Rect(1, CurY, ClientWidth - 1, CurY + FItemHeight);
  P := ClientToScreen(Point(R.Right, R.Top));

  FChildPopup := TStyledMenuPopup.CreateNew(Self, 0);
  FChildPopup.ParentPopup := Self;
  FChildPopup.Images := FImages;
  FChildPopup.MenuItems := Item;

  ScreenRect := Screen.MonitorFromPoint(P).WorkareaRect;
  if P.X + FChildPopup.Width > ScreenRect.Right then
    P.X := ClientToScreen(Point(R.Left, 0)).X - FChildPopup.Width;
  if P.Y + FChildPopup.Height > ScreenRect.Bottom then
    P.Y := ScreenRect.Bottom - FChildPopup.Height;

  FChildPopup.SetBounds(P.X, P.Y, FChildPopup.Width, FChildPopup.Height);
  FChildPopup.Show;
end;

procedure TStyledMenuPopup.HideSubMenu;
begin
  if FChildPopup <> nil then
  begin
    FChildPopup.Hide;
    FChildPopup.Release;
    FChildPopup := nil;
    FActiveSubMenuIndex := -1;
  end;
end;

procedure TStyledMenuPopup.CloseAllPopups;
begin
  Hide;

  if FParentPopup <> nil then
    FParentPopup.CloseAllPopups
  else if Assigned(FOnClosePopup) then
    FOnClosePopup(Self);
end;

procedure TStyledMenuPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  R: TRect;
  CurY: Integer;
  NewIndex: Integer;
  ScreenP: TPoint;
  BarP: TPoint;
  Bar: TStyledMenuBar;
begin
  inherited MouseMove(Shift, X, Y);

  ScreenP := ClientToScreen(Point(X, Y));

  if IsPointInChildPopup(ScreenP) then
  begin
    Exit;
  end;

  if (Owner is TStyledMenuBar) and (FParentPopup = nil) then
  begin
    Bar := TStyledMenuBar(Owner);
    BarP := Bar.ScreenToClient(ScreenP);

    if (BarP.Y >= 0) and (BarP.Y < Bar.ClientHeight) then
    begin
      for i := 0 to Bar.MainMenu.Items.Count - 1 do
      begin
        if PtInRect(Bar.GetItemRect(i), BarP) then
        begin
          if i <> Bar.FPressedIndex then
          begin
            Bar.HidePopup;
            Bar.FPressedIndex := i;
            Bar.FHotIndex := i;
            Bar.ShowPopupForm(Bar.ClientToScreen(Point(Bar.GetItemRect(i).Left, Bar.ClientHeight)), Bar.MainMenu.Items[i], Bar.MainMenu.Images);
            Bar.Invalidate;
          end;
          Exit;
        end;
      end;
    end;
  end;

  NewIndex := -1;
  CurY := 2;

  for i := 0 to FMenuItems.Count - 1 do
  begin
    if FMenuItems[i].Caption = '-' then
      R := Rect(1, CurY, ClientWidth - 1, CurY + 6)
    else
      R := Rect(1, CurY, ClientWidth - 1, CurY + FItemHeight);

    if PtInRect(R, Point(X, Y)) then
    begin
      NewIndex := i;
      Break;
    end;
    CurY := R.Bottom;
  end;

  if NewIndex <> FHoverIndex then
  begin
    FHoverIndex := NewIndex;
    Invalidate;

    if (NewIndex <> FActiveSubMenuIndex) then
    begin
      HideSubMenu;
    end;

    if (NewIndex >= 0) and (FMenuItems[NewIndex].Count > 0) then
    begin
      ShowSubMenu(NewIndex);
    end;
  end;
end;

procedure TStyledMenuPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  R: TRect;
  CurY: Integer;
  Item: TMenuItem;
  ScreenP: TPoint;
  BarP: TPoint;
  Bar: TStyledMenuBar;
  ClickedItem: Boolean;
  ChildP: TPoint;
begin
  inherited MouseDown(Button, Shift, X, Y);

  ScreenP := ClientToScreen(Point(X, Y));

  if (FChildPopup <> nil) and (FChildPopup.Visible) then
  begin
    ChildP := FChildPopup.ScreenToClient(ScreenP);
    if PtInRect(FChildPopup.ClientRect, ChildP) then
    begin
      FChildPopup.MouseDown(Button, Shift, ChildP.X, ChildP.Y);
      Exit;
    end;
  end;

  if (Owner is TStyledMenuBar) and (FParentPopup = nil) then
  begin
    Bar := TStyledMenuBar(Owner);
    BarP := Bar.ScreenToClient(ScreenP);

    if (BarP.Y >= 0) and (BarP.Y < Bar.ClientHeight) then
    begin
      for i := 0 to Bar.MainMenu.Items.Count - 1 do
      begin
        if PtInRect(Bar.GetItemRect(i), BarP) then
        begin
          if i = Bar.FPressedIndex then
            Bar.HidePopup
          else
          begin
            Bar.HidePopup;
            Bar.FPressedIndex := i;
            Bar.FHotIndex := i;
            Bar.ShowPopupForm(Bar.ClientToScreen(Point(Bar.GetItemRect(i).Left, Bar.ClientHeight)), Bar.MainMenu.Items[i], Bar.MainMenu.Images);
            Bar.Invalidate;
          end;
          Exit;
        end;
      end;
    end;
  end;

  ClickedItem := False;
  CurY := 2;
  for i := 0 to FMenuItems.Count - 1 do
  begin
    if FMenuItems[i].Caption = '-' then
      R := Rect(1, CurY, ClientWidth - 1, CurY + 6)
    else
      R := Rect(1, CurY, ClientWidth - 1, CurY + FItemHeight);

    if PtInRect(R, Point(X, Y)) then
    begin
      Item := FMenuItems[i];
      if (Item.Caption <> '-') and Item.Enabled then
      begin
        if Item.Count = 0 then
        begin
          CloseAllPopups;
          Item.Click;
        end
        else
        begin
          ShowSubMenu(i);
        end;
      end;
      ClickedItem := True;
      Break;
    end;
    CurY := R.Bottom;
  end;

  if not ClickedItem then
  begin
     CloseAllPopups;
  end;
end;

{ TStyledMenuBar }

constructor TStyledMenuBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Align := alTop;
  AutoSize := True;
  DoubleBuffered := True;

  FHotIndex := -1;
  FPressedIndex := -1;

  FBarColor := clBtnFace;
  FItemHoverColor := clHighlight;
  FTextColor := clBtnText;
  FTextHoverColor := clHighlightText;
  FPopupColor := clWhite;
  FIconSize:=24;
  FPopupBorderColor := clGray;
  FDisabledTextColor := clGray;
end;

destructor TStyledMenuBar.Destroy;
begin
  UnhookEvents;
  inherited Destroy;
end;

procedure TStyledMenuBar.CalculatePreferredSize(var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  inherited CalculatePreferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
  Canvas.Font.Assign(Self.Font);
  PreferredHeight := Canvas.TextHeight('Wg') + 6;
  PreferredWidth := 0;
end;

procedure TStyledMenuBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) then
  begin
    if AComponent = FMainMenu then FMainMenu := nil;
    if AComponent = FOwnerForm then
    begin
      if not (csDestroying in ComponentState) then
        UnhookEvents;
      FOwnerForm := nil;
    end;
  end;
end;

procedure TStyledMenuBar.HookEvents;
begin
  if FOwnerForm = nil then
  begin
    if (MainMenu <> nil) and (MainMenu.Owner is TCustomForm) then
      FOwnerForm := TCustomForm(MainMenu.Owner)
    else
      FOwnerForm := GetParentForm(Self);
  end;

  if (FOwnerForm <> nil) and not (csDesigning in ComponentState) then
  begin
    FOldFormChangeBounds := FOwnerForm.OnChangeBounds;
    FOwnerForm.OnChangeBounds := @DoFormChangeBounds;
    FOwnerForm.FreeNotification(Self);
  end;

  if not (csDesigning in ComponentState) then
  begin
    FOldAppShortCut := Application.OnShortCut;
    Application.OnShortCut := @DoAppShortCut;
  end;
end;

procedure TStyledMenuBar.UnhookEvents;
begin
  if (FOwnerForm <> nil) then
  begin
    FOwnerForm.OnChangeBounds := FOldFormChangeBounds;
  end;

  if not (csDesigning in ComponentState) then
  begin
    Application.OnShortCut := FOldAppShortCut;
  end;
end;

procedure TStyledMenuBar.DoFormChangeBounds(Sender: TObject);
begin
  if Assigned(FOldFormChangeBounds) then
    FOldFormChangeBounds(Sender);
  HidePopup;
end;

function TStyledMenuBar.FindMenuItemByShortCut(Items: TMenuItem; ShortCut: TShortCut): TMenuItem;
var
  i: Integer;
  ChildItem: TMenuItem;
begin
  Result := nil;
  for i := 0 to Items.Count - 1 do
  begin
    if (Items[i].ShortCut = ShortCut) and Items[i].Enabled then
    begin
      Result := Items[i];
      Exit;
    end;

    if Items[i].Count > 0 then
    begin
      ChildItem := FindMenuItemByShortCut(Items[i], ShortCut);
      if ChildItem <> nil then
      begin
        Result := ChildItem;
        Exit;
      end;
    end;
  end;
end;

procedure TStyledMenuBar.DoAppShortCut(var Msg: TLMKey; var Handled: Boolean);
var
  Key: Word;
  ShiftState: TShiftState;
  SC: TShortCut;
  Item: TMenuItem;
begin
  if Assigned(FOldAppShortCut) then
    FOldAppShortCut(Msg, Handled);

  if Handled then Exit;
  if FMainMenu = nil then Exit;

  Key := Msg.CharCode;

  ShiftState := [];
  if GetKeyState(VK_SHIFT) < 0 then Include(ShiftState, ssShift);
  if GetKeyState(VK_CONTROL) < 0 then Include(ShiftState, ssCtrl);
  if GetKeyState(VK_MENU) < 0 then Include(ShiftState, ssAlt);

  SC := Menus.ShortCut(Key, ShiftState);

  Item := FindMenuItemByShortCut(FMainMenu.Items, SC);

  if Item <> nil then
  begin
    if (FPopupForm <> nil) and (FPopupForm.Visible) then
      HidePopup;

    Item.Click;
    Handled := True;
    Msg.Result := 1;
  end;
end;

procedure TStyledMenuBar.SetMainMenu(AValue: TMainMenu);
begin
  if FMainMenu = AValue then Exit;

  UnhookEvents;
  if FMainMenu <> nil then FMainMenu.RemoveFreeNotification(Self);

  FMainMenu := AValue;

  if FMainMenu <> nil then
  begin
    FMainMenu.FreeNotification(Self);
    if (FMainMenu.Owner is TCustomForm) then
      TCustomForm(FMainMenu.Owner).Menu := nil;
  end;

  HookEvents;
  Invalidate;
end;

function TStyledMenuBar.GetItemWidth(Index: Integer): Integer;
begin
  if (FMainMenu = nil) or (Index < 0) or (Index >= FMainMenu.Items.Count) then
    Exit(0);

  Canvas.Font.Assign(Self.Font);
  Result := Canvas.TextWidth(FMainMenu.Items[Index].Caption) + 20;
end;

function TStyledMenuBar.GetItemRect(Index: Integer): TRect;
var
  i, curX: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  if (FMainMenu = nil) or (Index < 0) or (Index >= FMainMenu.Items.Count) then Exit;

  curX := 0;
  for i := 0 to Index - 1 do
    curX := curX + GetItemWidth(i);

  Result.Left := curX;
  Result.Top := 0;
  Result.Right := curX + GetItemWidth(Index);
  Result.Bottom := ClientHeight;
end;

procedure TStyledMenuBar.Paint;
var
  i: Integer;
  R: TRect;
  Item: TMenuItem;
begin
  inherited Paint;

  Canvas.Brush.Color := FBarColor;
  Canvas.FillRect(ClientRect);

  if FMainMenu = nil then Exit;

  Canvas.Font.Assign(Self.Font);

  for i := 0 to FMainMenu.Items.Count - 1 do
  begin
    Item := FMainMenu.Items[i];
    R := GetItemRect(i);

    if i = FPressedIndex then
    begin
      Canvas.Brush.Color := FPopupBorderColor;
      Canvas.Font.Color := FTextHoverColor;
    end
    else if i = FHotIndex then
    begin
      Canvas.Brush.Color := FItemHoverColor;
      Canvas.Font.Color := FTextHoverColor;
    end
    else
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Font.Color := FTextColor;
    end;

    if (i = FPressedIndex) or (i = FHotIndex) then
      Canvas.FillRect(R)
    else
      Canvas.Brush.Style := bsClear;

    Canvas.TextRect(R, R.Left + 5, R.Top + (R.Height - Canvas.TextHeight(Item.Caption)) div 2, Item.Caption);
  end;
end;

procedure TStyledMenuBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  R: TRect;
  NewHot: Integer;
begin
  inherited MouseMove(Shift, X, Y);

  if (FPopupForm = nil) or (not FPopupForm.Visible) then
  begin
    NewHot := -1;
    if FMainMenu <> nil then
    begin
      for i := 0 to FMainMenu.Items.Count - 1 do
      begin
        R := GetItemRect(i);
        if PtInRect(R, Point(X, Y)) then
        begin
          NewHot := i;
          Break;
        end;
      end;
    end;

    if NewHot <> FHotIndex then
    begin
      FHotIndex := NewHot;
      Invalidate;
    end;
  end;
end;

procedure TStyledMenuBar.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: Integer;
  R: TRect;
  P: TPoint;
begin
  inherited MouseDown(Button, Shift, X, Y);

  if FMainMenu = nil then Exit;

  for i := 0 to FMainMenu.Items.Count - 1 do
  begin
    R := GetItemRect(i);
    if PtInRect(R, Point(X, Y)) then
    begin
      if (FPopupForm <> nil) and (FPopupForm.Visible) then
        HidePopup
      else
      begin
        FPressedIndex := i;
        if FMainMenu.Items[i].Count > 0 then
        begin
          P := ClientToScreen(Point(R.Left, ClientHeight));
          ShowPopupForm(P, FMainMenu.Items[i], FMainMenu.Images);
        end;
      end;
      Invalidate;
      Break;
    end;
  end;
end;

procedure TStyledMenuBar.MouseLeave;
begin
  inherited MouseLeave;
  if (FPopupForm = nil) or (not FPopupForm.Visible) then
  begin
    FHotIndex := -1;
    Invalidate;
  end;
end;

procedure TStyledMenuBar.ShowPopupForm(P: TPoint; Items: TMenuItem; Images: TCustomImageList);
var
  screenRect: TRect;
begin
  if Items = nil then Exit;

  if FPopupForm = nil then
  begin
    FPopupForm := TStyledMenuPopup.CreateNew(Self, 0);
    FPopupForm.OnClosePopup := @DoPopupClose;
  end;

  FPopupForm.Images := Images;
  FPopupForm.MenuItems := Items;

  screenRect := Screen.MonitorFromPoint(P).WorkareaRect;
  if P.X + FPopupForm.Width > screenRect.Right then
    P.X := screenRect.Right - FPopupForm.Width;
  if P.Y + FPopupForm.Height > screenRect.Bottom then
    P.Y := screenRect.Bottom - FPopupForm.Height;

  FPopupForm.SetBounds(P.X, P.Y, FPopupForm.Width, FPopupForm.Height);
  FPopupForm.Show;

  SetCapture(FPopupForm.Handle);
end;

procedure TStyledMenuBar.HidePopup;
begin
  if FPopupForm <> nil then
  begin
    FPopupForm.Hide;
  end;
  FPressedIndex := -1;
  FHotIndex := -1;
  Invalidate;
end;

procedure TStyledMenuBar.DoPopupClose(Sender: TObject);
begin
  ReleaseCapture;
  if FPopupForm <> nil then
  begin
    FPopupForm.Release;
    FPopupForm := nil;
  end;
  FPressedIndex := -1;
  FHotIndex := -1;
  Invalidate;
end;

procedure TStyledMenuBar.Popup(X, Y: Integer; APopupMenu: TPopupMenu);
begin
  if APopupMenu = nil then Exit;
  HidePopup;
  ShowPopupForm(Point(X, Y), APopupMenu.Items, APopupMenu.Images);
end;

end.

