unit FlatVcl.Dibujo;

{ Dibujo del botón, en un solo lugar.

  Lo comparten TFlatButton, que es gráfico, y TFlatWinButton, que es una ventana
  y por eso puede tomar el foco. Son dos clases con dos ancestros distintos y
  una sola pintura: si el dibujo viviera en cada una, en la tercera corrección
  ya se verían distintos.

  Los parámetros van en un registro y no como quince argumentos sueltos, para
  que agregar uno nuevo no obligue a tocar las dos llamadas. }

interface

uses
  Winapi.Windows, System.Types, Vcl.Graphics, Vcl.ImgList, FlatVcl.Paleta;

type
  TFlatDrawInfo = record
    Kind: TFlatKind;
    ColorOverride: TColor;
    State: TFlatVisualState;
    CornerRadius: Integer;
    Caption: string;
    Images: TCustomImageList;
    ImageIndex: Integer;
    Spacing: Integer;
    { Se conserva por compatibilidad; el dibujo ya no lo usa. }
    Focused: Boolean;
    { Color del contenedor, para las esquinas que el redondeo deja fuera. }
    Behind: TColor;
  end;

function FlatEsContorno(const AInfo: TFlatDrawInfo): Boolean;
function FlatColorBase(const AInfo: TFlatDrawInfo): TColor;
function FlatColorFondo(const AInfo: TFlatDrawInfo): TColor;
function FlatColorBorde(const AInfo: TFlatDrawInfo): TColor;
function FlatColorTexto(const AInfo: TFlatDrawInfo): TColor;

procedure FlatDrawButton(ACanvas: TCanvas; const ARect: TRect;
  const AInfo: TFlatDrawInfo);

implementation

function FlatEsContorno(const AInfo: TFlatDrawInfo): Boolean;
begin
  { El secundario no es otro color: es otro dibujo. Fondo del contenedor, borde
    y texto de acento, y el relleno entra al pasar el ratón. }
  Result := (AInfo.Kind = fkSecondary) and (AInfo.ColorOverride = clNone);
end;

function FlatColorBase(const AInfo: TFlatDrawInfo): TColor;
begin
  if AInfo.ColorOverride <> clNone then
    Result := AInfo.ColorOverride
  else
    Result := FlatPalette.Kind[AInfo.Kind];
end;

function FlatColorFondo(const AInfo: TFlatDrawInfo): TColor;
begin
  if AInfo.State = fvDisabled then
    Exit(FlatPalette.Disabled);

  if FlatEsContorno(AInfo) then
  begin
    case AInfo.State of
      fvHover:
        Result := FlatColorBase(AInfo);
      fvPressed:
        Result := FlatPressed(FlatColorBase(AInfo));
    else
      Result := AInfo.Behind;
    end;
    Exit;
  end;

  case AInfo.State of
    fvHover:
      Result := FlatHover(FlatColorBase(AInfo));
    fvPressed:
      Result := FlatPressed(FlatColorBase(AInfo));
  else
    Result := FlatColorBase(AInfo);
  end;
end;

function FlatColorBorde(const AInfo: TFlatDrawInfo): TColor;
begin
  if AInfo.State = fvDisabled then
    Result := FlatPalette.Disabled
  else if FlatEsContorno(AInfo) then
    Result := FlatPalette.Status[fsInfo]
  else
    Result := FlatColorFondo(AInfo);
end;

function FlatColorTexto(const AInfo: TFlatDrawInfo): TColor;
begin
  if AInfo.State = fvDisabled then
    Result := FlatPalette.DisabledText
  else if FlatEsContorno(AInfo) and (AInfo.State = fvIdle) then
    Result := FlatPalette.Status[fsInfo]
  else
    { El ámbar no admite texto blanco y el azul no admite texto oscuro; la
      luminancia del fondo decide sin que haya que acordarse. }
    Result := FlatTextOn(FlatColorFondo(AInfo));
end;

procedure FlatDrawButton(ACanvas: TCanvas; const ARect: TRect;
  const AInfo: TFlatDrawInfo);
var
  lTexto: string;
  lAnchoTexto, lAnchoIcono, lTotal, lX, lY: Integer;
  lTieneIcono: Boolean;
begin
  { El redondeo deja cuatro triángulos fuera de la forma. Si no se rellenan
    antes, en un control opaco se ve lo que hubiera debajo. }
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := AInfo.Behind;
  ACanvas.FillRect(ARect);

  ACanvas.Brush.Color := FlatColorFondo(AInfo);
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Color := FlatColorBorde(AInfo);

  if AInfo.CornerRadius > 0 then
    ACanvas.RoundRect(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom,
      AInfo.CornerRadius * 2, AInfo.CornerRadius * 2)
  else
    ACanvas.Rectangle(ARect);

  lTexto := AInfo.Caption;
  lTieneIcono := (AInfo.Images <> nil) and (AInfo.ImageIndex >= 0) and
    (AInfo.ImageIndex < AInfo.Images.Count);

  ACanvas.Font.Color := FlatColorTexto(AInfo);
  ACanvas.Brush.Style := bsClear;

  lAnchoTexto := ACanvas.TextWidth(lTexto);
  if lTieneIcono then
    lAnchoIcono := AInfo.Images.Width
  else
    lAnchoIcono := 0;

  lTotal := lAnchoTexto + lAnchoIcono;
  if lTieneIcono and (lTexto <> '') then
    Inc(lTotal, AInfo.Spacing);

  { Icono y texto van como un bloque, centrados juntos; centrarlos por separado
    descoloca el conjunto en cuanto cambia el rótulo. }
  lX := ARect.Left + (ARect.Width - lTotal) div 2;

  if lTieneIcono then
  begin
    lY := ARect.Top + (ARect.Height - AInfo.Images.Height) div 2;
    AInfo.Images.Draw(ACanvas, lX, lY, AInfo.ImageIndex,
      AInfo.State <> fvDisabled);
    Inc(lX, lAnchoIcono);
    if lTexto <> '' then
      Inc(lX, AInfo.Spacing);
  end;

  if lTexto <> '' then
  begin
    lY := ARect.Top + (ARect.Height - ACanvas.TextHeight(lTexto)) div 2;
    ACanvas.TextOut(lX, lY, lTexto);
  end;

  ACanvas.Brush.Style := bsSolid;
end;

end.
