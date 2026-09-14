unit FlatVcl.Boton;

{ Botón plano de color.

  Hereda de TGraphicControl, como TSpeedButton: no consume un handle de ventana
  y se puede colocar sobre cualquier contenedor, incluido un TControlList, que
  solo admite controles gráficos.

  El color no se escribe en el formulario. Se elige la clase de botón en Kind y
  el color sale de FlatVcl.Paleta; hover y presionado se calculan desde ese
  mismo color. Quien quiera un color fuera de la paleta tiene ColorOverride,
  pero entonces se queda a cargo de mantenerlo.

  Action está publicada: el botón se engancha a un TActionList y recibe Caption,
  Enabled, Hint, Visible, el ImageIndex y el OnExecute sin código intermedio. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.ImgList,
  FlatVcl.Paleta, FlatVcl.Dibujo;

type
  TFlatButton = class(TGraphicControl)
  private
    FKind: TFlatKind;
    FState: TFlatVisualState;
    FColorOverride: TColor;
    FCornerRadius: Integer;
    FImages: TCustomImageList;
    FImageIndex: System.UITypes.TImageIndex;
    FSpacing: Integer;
    FModalResult: TModalResult;
    procedure SetKind(const AValor: TFlatKind);
    procedure SetColorOverride(const AValor: TColor);
    procedure SetCornerRadius(const AValor: Integer);
    procedure SetImages(const AValor: TCustomImageList);
    procedure SetImageIndex(const AValor: System.UITypes.TImageIndex);
    procedure SetSpacing(const AValor: Integer);
    procedure CambiarEstado(const AValor: TFlatVisualState);
    function DatosDeDibujo: TFlatDrawInfo;
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
    property Kind: TFlatKind read FKind write SetKind default fkPrimary;
    property ColorOverride: TColor read FColorOverride write SetColorOverride
      default clNone;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius
      default 4;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: System.UITypes.TImageIndex read FImageIndex write SetImageIndex
      default -1;
    property Spacing: Integer read FSpacing write SetSpacing default 8;
    property ModalResult: TModalResult read FModalResult write FModalResult
      default mrNone;

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
    property OnDblClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

uses
  Vcl.Forms, Vcl.ActnList;

constructor TFlatButton.Create(AOwner: TComponent);
begin
  inherited;
  { csOpaque evita que la VCL borre el fondo antes de cada Paint, que es de
    donde sale el parpadeo al mover el ratón. El contorno lo apaga, porque
    necesita ver el fondo del contenedor. }
  ControlStyle := ControlStyle + [csCaptureMouse, csOpaque, csDoubleClicks];
  Width := 120;
  Height := 38;
  Cursor := crHandPoint;
  FKind := fkPrimary;
  FState := fvIdle;
  FColorOverride := clNone;
  FCornerRadius := 4;
  FImageIndex := -1;
  FSpacing := 8;
  FModalResult := mrNone;
end;

procedure TFlatButton.SetKind(const AValor: TFlatKind);
begin
  if FKind <> AValor then
  begin
    FKind := AValor;
    Invalidate;
  end;
end;

procedure TFlatButton.SetColorOverride(const AValor: TColor);
begin
  if FColorOverride <> AValor then
  begin
    FColorOverride := AValor;
    Invalidate;
  end;
end;

procedure TFlatButton.SetCornerRadius(const AValor: Integer);
begin
  if FCornerRadius <> AValor then
  begin
    FCornerRadius := AValor;
    Invalidate;
  end;
end;

procedure TFlatButton.SetImages(const AValor: TCustomImageList);
begin
  if FImages <> AValor then
  begin
    FImages := AValor;
    { Sin esto, borrar la lista de imágenes deja un puntero colgando y el
      primer repintado revienta. }
    if FImages <> nil then
      FImages.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TFlatButton.SetImageIndex(const AValor: System.UITypes.TImageIndex);
begin
  if FImageIndex <> AValor then
  begin
    FImageIndex := AValor;
    Invalidate;
  end;
end;

procedure TFlatButton.SetSpacing(const AValor: Integer);
begin
  if FSpacing <> AValor then
  begin
    FSpacing := AValor;
    Invalidate;
  end;
end;

procedure TFlatButton.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    FImages := nil;
end;

procedure TFlatButton.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited;
  { TControlActionLink trae Caption, Enabled, Hint y Visible, pero no el icono.
    CheckDefaults en True significa que solo se copia lo que el botón todavía
    no tiene puesto a mano. }
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

procedure TFlatButton.CambiarEstado(const AValor: TFlatVisualState);
begin
  if FState <> AValor then
  begin
    FState := AValor;
    Invalidate;
  end;
end;

procedure TFlatButton.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  if Enabled then
    CambiarEstado(fvHover);
end;

procedure TFlatButton.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if Enabled then
    CambiarEstado(fvIdle);
end;

procedure TFlatButton.CMEnabledChanged(var Msg: TMessage);
begin
  inherited;
  if Enabled then
    CambiarEstado(fvIdle)
  else
    CambiarEstado(fvDisabled);
end;

procedure TFlatButton.CMTextChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TFlatButton.CMFontChanged(var Msg: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TFlatButton.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if Enabled and (Button = mbLeft) then
    CambiarEstado(fvPressed);
end;

procedure TFlatButton.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if Enabled and (Button = mbLeft) then
  begin
    { Si el ratón se fue del botón antes de soltar, no hay clic y tampoco
      hover: vuelve al reposo. }
    if PtInRect(ClientRect, Point(X, Y)) then
      CambiarEstado(fvHover)
    else
      CambiarEstado(fvIdle);
  end;
end;

procedure TFlatButton.Click;
var
  lForma: TCustomForm;
begin
  { Cerrar el diálogo con ModalResult, igual que TButton. TGraphicControl no lo
    trae, así que hay que buscar el formulario a mano. }
  if FModalResult <> mrNone then
  begin
    lForma := GetParentForm(Self);
    if (lForma <> nil) and (fsModal in lForma.FormState) then
      lForma.ModalResult := FModalResult;
  end;
  inherited;
end;

function TFlatButton.DatosDeDibujo: TFlatDrawInfo;
begin
  Result.Kind := FKind;
  Result.ColorOverride := FColorOverride;
  Result.State := FState;
  Result.CornerRadius := FCornerRadius;
  Result.Caption := Caption;
  Result.Images := FImages;
  Result.ImageIndex := FImageIndex;
  Result.Spacing := FSpacing;
  { Un control grafico no toma el foco, asi que nunca lleva el anillo. }
  Result.Focused := False;

  { Con csOpaque la VCL da por hecho que el control pinta cada pixel suyo, y las
    esquinas que el redondeo deja fuera quedarian con basura. La rutina de
    dibujo las rellena con este color. }
  if Parent is TWinControl then
    Result.Behind := TWinControl(Parent).Brush.Color
  else
    Result.Behind := FlatPalette.Surface;
end;

procedure TFlatButton.Paint;
begin
  Canvas.Font := Font;
  FlatDrawButton(Canvas, ClientRect, DatosDeDibujo);
end;

end.
