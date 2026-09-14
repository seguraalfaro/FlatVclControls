unit FlatVcl.BotonWin;

{ Botón de color con foco y tabulación.

  Hereda de TButton, así que es una ventana de verdad y trae lo que un control
  gráfico no puede tener: entra en el orden de tabulación, toma el foco,
  responde al Enter y a la barra espaciadora, y puede ser Default o Cancel de un
  diálogo. TSpeedButton y cualquier otro TGraphicControl no pueden hacer nada de
  eso, porque sin handle de ventana no hay foco de entrada.

  TButton, por su parte, no deja cambiar el color del rótulo: el botón lo dibuja
  Windows. La salida es la misma que usa TBitBtn, que no es otra cosa que un
  TButton dibujado por el dueño: se agrega BS_OWNERDRAW al crear la ventana y se
  responde a CN_DRAWITEM.

  El dibujo es el de FlatVcl.Dibujo, el mismo del botón gráfico. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.StdCtrls,
  Vcl.ImgList, FlatVcl.Paleta, FlatVcl.Dibujo;

type
  TFlatWinButton = class(TButton)
  private
    FKind: TFlatKind;
    FColorOverride: TColor;
    FCornerRadius: Integer;
    FImages: TCustomImageList;
    FImageIndex: System.UITypes.TImageIndex;
    FSpacing: Integer;
    FRaton: Boolean;
    procedure SetKind(const AValor: TFlatKind);
    procedure SetColorOverride(const AValor: TColor);
    procedure SetCornerRadius(const AValor: Integer);
    procedure SetImages(const AValor: TCustomImageList);
    procedure SetImageIndex(const AValor: System.UITypes.TImageIndex);
    procedure SetSpacing(const AValor: Integer);
    function DatosDeDibujo(const AEstado: Cardinal): TFlatDrawInfo;
    procedure CNDrawItem(var Msg: TWMDrawItem); message CN_DRAWITEM;
    procedure CMMouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMStyleChanged(var Msg: TMessage); message CM_STYLECHANGED;
    procedure WMSetFocus(var Msg: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Msg: TWMKillFocus); message WM_KILLFOCUS;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure SetButtonStyle(ADefault: Boolean); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure ActionChange(Sender: TObject; CheckDefaults: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
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
  end;

implementation

uses
  Vcl.ActnList;

constructor TFlatWinButton.Create(AOwner: TComponent);
begin
  inherited;
  Width := 120;
  Height := 38;
  Cursor := crHandPoint;
  FKind := fkPrimary;
  FColorOverride := clNone;
  FCornerRadius := 4;
  FImageIndex := -1;
  FSpacing := 8;
  { Con los estilos VCL activos el gancho del botón dibuja encima y el
    CN_DRAWITEM no llega a verse. }
  StyleElements := [];
end;

procedure TFlatWinButton.CreateParams(var Params: TCreateParams);
begin
  inherited;
  { Le dice a Windows que el contenido del botón lo pinta la aplicación. Es lo
    mismo que hace TBitBtn. }
  Params.Style := Params.Style or BS_OWNERDRAW;
end;

procedure TFlatWinButton.WMSetFocus(var Msg: TWMSetFocus);
begin
  inherited;
  Invalidate;
end;

procedure TFlatWinButton.WMKillFocus(var Msg: TWMKillFocus);
begin
  inherited;
  { Sin esto el anillo de foco queda dibujado: al anular SetButtonStyle el boton
    ya no recibe el BM_SETSTYLE que provocaba el repintado. }
  Invalidate;
end;

procedure TFlatWinButton.SetButtonStyle(ADefault: Boolean);
begin
  { A proposito vacio. El heredado manda BM_SETSTYLE para marcar el boton
    predeterminado, y ese mensaje reescribe el estilo de la ventana y borra el
    BS_OWNERDRAW: desde el primer foco lo dibujaria Windows. TBitBtn hace lo
    mismo por la misma razon. El estado de predeterminado se dibuja igual, con
    el anillo de foco. }
end;

procedure TFlatWinButton.CreateWnd;
begin
  inherited;
  { El gancho de estilos se instala al crear la ventana, y ahi dibuja el boton
    de Windows encima del CN_DRAWITEM. Ponerlo en el constructor no alcanza: si
    el handle se recrea, vuelve. }
  StyleElements := [];
end;

procedure TFlatWinButton.CMStyleChanged(var Msg: TMessage);
begin
  inherited;
  { Cambiar de estilo VCL en caliente reengancha los controles. }
  StyleElements := [];
  Invalidate;
end;

procedure TFlatWinButton.SetKind(const AValor: TFlatKind);
begin
  if FKind <> AValor then
  begin
    FKind := AValor;
    Invalidate;
  end;
end;

procedure TFlatWinButton.SetColorOverride(const AValor: TColor);
begin
  if FColorOverride <> AValor then
  begin
    FColorOverride := AValor;
    Invalidate;
  end;
end;

procedure TFlatWinButton.SetCornerRadius(const AValor: Integer);
begin
  if FCornerRadius <> AValor then
  begin
    FCornerRadius := AValor;
    Invalidate;
  end;
end;

procedure TFlatWinButton.SetImages(const AValor: TCustomImageList);
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

procedure TFlatWinButton.SetImageIndex(const AValor: System.UITypes.TImageIndex);
begin
  if FImageIndex <> AValor then
  begin
    FImageIndex := AValor;
    Invalidate;
  end;
end;

procedure TFlatWinButton.SetSpacing(const AValor: Integer);
begin
  if FSpacing <> AValor then
  begin
    FSpacing := AValor;
    Invalidate;
  end;
end;

procedure TFlatWinButton.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    FImages := nil;
end;

procedure TFlatWinButton.ActionChange(Sender: TObject; CheckDefaults: Boolean);
begin
  inherited;
  { TControlActionLink trae Caption, Enabled, Hint y Visible, pero no el icono.
    CheckDefaults en True significa copiar solo lo que el botón no tenga ya
    puesto a mano. }
  if Sender is TCustomAction then
    with TCustomAction(Sender) do
    begin
      if not CheckDefaults or (Self.ImageIndex = -1) then
        Self.ImageIndex := ImageIndex;
      if not CheckDefaults or (Self.Images = nil) then
        Self.Images := Images;
    end;
end;

procedure TFlatWinButton.CMMouseEnter(var Msg: TMessage);
begin
  inherited;
  FRaton := True;
  if Enabled then
    Invalidate;
end;

procedure TFlatWinButton.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  FRaton := False;
  if Enabled then
    Invalidate;
end;

function TFlatWinButton.DatosDeDibujo(const AEstado: Cardinal): TFlatDrawInfo;
begin
  Result.Kind := FKind;
  Result.ColorOverride := FColorOverride;
  Result.CornerRadius := FCornerRadius;
  Result.Caption := Caption;
  Result.Images := FImages;
  Result.ImageIndex := FImageIndex;
  Result.Spacing := FSpacing;

  { El estado lo manda Windows en el itemState del CN_DRAWITEM; el hover no
    viaja ahí y se lleva aparte. }
  if (AEstado and ODS_DISABLED <> 0) or not Enabled then
    Result.State := fvDisabled
  else if AEstado and ODS_SELECTED <> 0 then
    Result.State := fvPressed
  else if FRaton then
    Result.State := fvHover
  else
    Result.State := fvIdle;

  { En el disenador el foco no significa nada y el anillo solo estorba. }
  Result.Focused := (AEstado and ODS_FOCUS <> 0) and
    not (csDesigning in ComponentState);

  if Parent <> nil then
    Result.Behind := Parent.Brush.Color
  else
    Result.Behind := FlatPalette.Surface;
end;

procedure TFlatWinButton.CNDrawItem(var Msg: TWMDrawItem);
var
  lDatos: TDrawItemStruct;
  lLienzo: TCanvas;
begin
  lDatos := Msg.DrawItemStruct^;
  { El DC lo presta Windows y hay que devolverlo como estaba, así que el lienzo
    es temporal y se le suelta el Handle antes de liberarlo. }
  lLienzo := TCanvas.Create;
  try
    lLienzo.Handle := lDatos.hDC;
    lLienzo.Font := Font;
    FlatDrawButton(lLienzo, lDatos.rcItem, DatosDeDibujo(lDatos.itemState));
    lLienzo.Handle := 0;
  finally
    lLienzo.Free;
  end;
  Msg.Result := 1;
end;

end.
