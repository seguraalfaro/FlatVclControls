unit FlatVcl.NavItem;

{ Ítem de menú lateral.

  Es la fila del panel de navegación: icono a la izquierda, rótulo al lado, y un
  fondo que solo aparece cuando la fila está seleccionada o bajo el ratón.

  No hereda de TFlatButton ni lo reusa. El botón se dibuja siempre relleno y con
  el contenido centrado como bloque, y aquí el reposo es transparente y todo va
  alineado a la izquierda; meter las dos formas en la misma rutina de dibujo era
  agregarle modos al botón que el botón no tiene por qué conocer.

  La selección es exclusiva entre los ítems que comparten padre: poner Selected
  en uno apaga a los hermanos. El grupo es el contenedor, así que un lateral con
  dos secciones separadas se arma con dos paneles.

  Colores: el fondo en reposo es el del contenedor y el del texto se decide por
  la luminancia de lo que quede debajo, así que la misma clase sirve en un
  lateral claro y en uno oscuro sin configurar nada. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.ImgList,
  FlatVcl.Paleta;

type
  TFlatNavItem = class(TGraphicControl)
  private
    FSelected: Boolean;
    FState: TFlatVisualState;
    FSelectedColor: TColor;
    FShowCaption: Boolean;
    FIndent: Integer;
    FSpacing: Integer;
    FCornerRadius: Integer;
    FImages: TCustomImageList;
    FImageIndex: System.UITypes.TImageIndex;
    procedure SetSelected(const AValor: Boolean);
    procedure SetSelectedColor(const AValor: TColor);
    procedure SetShowCaption(const AValor: Boolean);
    procedure SetIndent(const AValor: Integer);
    procedure SetSpacing(const AValor: Integer);
    procedure SetCornerRadius(const AValor: Integer);
    procedure SetImages(const AValor: TCustomImageList);
    procedure SetImageIndex(const AValor: System.UITypes.TImageIndex);
    procedure CambiarEstado(const AValor: TFlatVisualState);
    procedure ApagarHermanos;
    function ColorDetras: TColor;
    function ColorFondo: TColor;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Msg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Msg: TMessage); message CM_TEXTCHANGED;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure Click; override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    property State: TFlatVisualState read FState;
  published
    { Al ponerse en True apaga a los demás ítems del mismo padre. }
    property Selected: Boolean read FSelected write SetSelected default False;
    { clNone toma el tenue de la paleta, que es el fondo de selección. }
    property SelectedColor: TColor read FSelectedColor write SetSelectedColor
      default clNone;
    { Se apaga para el modo compacto del TSplitView: queda solo el icono,
      centrado. }
    property ShowCaption: Boolean read FShowCaption write SetShowCaption
      default True;
    property Indent: Integer read FIndent write SetIndent default 12;
    property Spacing: Integer read FSpacing write SetSpacing default 10;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius
      default 0;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: System.UITypes.TImageIndex read FImageIndex
      write SetImageIndex default -1;

    property Action;
    property Align;
    property Anchors;
    property BiDiMode;
    property Caption;
    property Constraints;
    property Cursor default crHandPoint;
    property Enabled;
    property Font;
    property Hint;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    property OnClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  Vcl.ActnList;

constructor TFlatNavItem.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csCaptureMouse, csOpaque];
  Width := 200;
  Height := 40;
  Cursor := crHandPoint;
  FState := fvIdle;
  FSelectedColor := clNone;
  FShowCaption := True;
  FIndent := 12;
  FSpacing := 10;
  FCornerRadius := 0;
  FImageIndex := -1;
end;

procedure TFlatNavItem.SetSelected(const AValor: Boolean);
begin
  if FSelected <> AValor then
  begin
    FSelected := AValor;
    if FSelected then
      ApagarHermanos;
    Invalidate;
  end;
end;

procedure TFlatNavItem.ApagarHermanos;
var
  lI: Integer;
  lOtro: TControl;
begin
  if Parent = nil then
    Exit;
  for lI := 0 to Parent.ControlCount - 1 do
  begin
    lOtro := Parent.Controls[lI];
    if (lOtro <> Self) and (lOtro is TFlatNavItem) then
      TFlatNavItem(lOtro).Selected := False;
  end;
end;

procedure TFlatNavItem.SetSelectedColor(const AValor: TColor);
begin
  if FSelectedColor <> AValor then
  begin
    FSelectedColor := AValor;
    Invalidate;
  end;
end;

procedure TFlatNavItem.SetShowCaption(const AValor: Boolean);
begin
  if FShowCaption <> AValor then
  begin
    FShowCaption := AValor;
    Invalidate;
  end;
end;

procedure TFlatNavItem.SetIndent(const AValor: Integer);
begin
  if FIndent <> AValor then
  begin
    FIndent := AValor;
    Invalidate;
  end;
end;

procedure TFlatNavItem.SetSpacing(const AValor: Integer);
begin
  if FSpacing <> AValor then
  begin
    FSpacing := AValor;
    Invalidate;
  end;
end;

procedure TFlatNavItem.SetCornerRadius(const AValor: Integer);
begin
  if FCornerRadius <> AValor then
  begin
    FCornerRadius := AValor;
    Invalidate;
  end;
end;

procedure TFlatNavItem.SetImages(const AValor: TCustomImageList);
begin
  if FImages <> AValor then
  begin
    FImages := AValor;
    if FImages <> nil then
      FImages.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TFlatNavItem.SetImageIndex(const AValor: System.UITypes.TImageIndex);
begin
  if FImageIndex <> AValor then
  begin
    FImageIndex := AValor;
    Invalidate;
  end;
end;

procedure TFlatNavItem.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    FImages := nil;
end;

procedure TFlatNavItem.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited;
  { El icono no lo trae TControlActionLink; hay que copiarlo a mano. }
  if Sender is TCustomAction then
    with TCustomAction(Sender) do
    begin
      if not CheckDefaults or (Self.ImageIndex = -1) then
        Self.ImageIndex := ImageIndex;
      if not CheckDefaults or (Self.Images = nil) then
        if Images is TCustomImageList then
          Self.Images := TCustomImageList(Images);
    end;
end;

procedure TFlatNavItem.CambiarEstado(const AValor: TFlatVisualState);
begin
  if FState <> AValor then
  begin
    FState := AValor;
    Invalidate;
  end;
end;

procedure TFlatNavItem.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  if Enabled then
    CambiarEstado(fvHover);
end;

procedure TFlatNavItem.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if Enabled then
    CambiarEstado(fvIdle);
end;

procedure TFlatNavItem.CMEnabledChanged(var Msg: TMessage);
begin
  inherited;
  if Enabled then
    CambiarEstado(fvIdle)
  else
    CambiarEstado(fvDisabled);
end;

procedure TFlatNavItem.CMTextChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TFlatNavItem.CMFontChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TFlatNavItem.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if Enabled and (Button = mbLeft) then
    CambiarEstado(fvPressed);
end;

procedure TFlatNavItem.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if Enabled and (Button = mbLeft) then
  begin
    if PtInRect(ClientRect, Point(X, Y)) then
      CambiarEstado(fvHover)
    else
      CambiarEstado(fvIdle);
  end;
end;

procedure TFlatNavItem.Click;
begin
  { Marcar antes de disparar el OnClick: el manejador suele cambiar de pantalla
    y conviene que el lateral ya esté al día. }
  Selected := True;
  inherited;
end;

function TFlatNavItem.ColorDetras: TColor;
begin
  if Parent is TWinControl then
    Result := TWinControl(Parent).Brush.Color
  else
    Result := FlatPalette.Surface;
end;

function TFlatNavItem.ColorFondo: TColor;
var
  lDetras: TColor;
begin
  lDetras := ColorDetras;

  if FSelected then
  begin
    if FSelectedColor <> clNone then
      Result := FSelectedColor
    else
      Result := FlatPalette.Kind[fkSecondary];
    Exit;
  end;

  { Hover y presionado se mezclan contra el color del texto, no contra el blanco:
    así aclaran sobre un lateral oscuro y oscurecen sobre uno claro. }
  case FState of
    fvHover:
      Result := FlatMix(lDetras, FlatTextOn(lDetras), FlatPalette.HoverPercent);
    fvPressed:
      Result := FlatMix(lDetras, FlatTextOn(lDetras),
        FlatPalette.HoverPercent + FlatPalette.PressedPercent);
  else
    Result := lDetras;
  end;
end;

procedure TFlatNavItem.Paint;
var
  lFondo: TColor;
  lTexto: string;
  lTieneIcono: Boolean;
  lX, lY, lAnchoIcono: Integer;
begin
  lFondo := ColorFondo;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := ColorDetras;
  Canvas.FillRect(ClientRect);

  Canvas.Brush.Color := lFondo;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := lFondo;
  if FCornerRadius > 0 then
    Canvas.RoundRect(ClientRect.Left, ClientRect.Top, ClientRect.Right,
      ClientRect.Bottom, FCornerRadius * 2, FCornerRadius * 2)
  else
    Canvas.Rectangle(ClientRect);

  Canvas.Font := Font;
  if Enabled then
    Canvas.Font.Color := FlatTextOn(lFondo)
  else
    Canvas.Font.Color := FlatPalette.Disabled;
  Canvas.Brush.Style := bsClear;

  lTieneIcono := (FImages <> nil) and (FImageIndex >= 0) and
    (FImageIndex < FImages.Count);
  if lTieneIcono then
    lAnchoIcono := FImages.Width
  else
    lAnchoIcono := 0;

  if FShowCaption then
    lTexto := Caption
  else
    lTexto := '';

  { Sin rótulo el icono va centrado; con rótulo, los dos alineados a la
    izquierda desde el mismo margen, para que las filas queden en columna. }
  if (lTexto = '') and lTieneIcono then
    lX := (ClientWidth - lAnchoIcono) div 2
  else
    lX := FIndent;

  if lTieneIcono then
  begin
    lY := (ClientHeight - FImages.Height) div 2;
    FImages.Draw(Canvas, lX, lY, FImageIndex, Enabled);
    Inc(lX, lAnchoIcono + FSpacing);
  end;

  if lTexto <> '' then
  begin
    lY := (ClientHeight - Canvas.TextHeight(lTexto)) div 2;
    Canvas.TextOut(lX, lY, lTexto);
  end;

  Canvas.Brush.Style := bsSolid;
end;

end.
