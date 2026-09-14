unit FlatVcl.Pastilla;

{ Pastilla de estado.

  Etiqueta redondeada de fondo sólido, del tipo que acompaña a un registro para
  decir en qué estado está.

  Viene en dos formas de la misma cosa. Como componente, para un formulario. Y
  como procedimiento de clase, DibujarEn, para las listas que se pintan por
  owner-draw, donde no se pueden colocar controles. El Paint del componente
  llama a ese mismo procedimiento, así que las dos formas no pueden divergir.

  Hereda de TCustomControl y no de TGraphicControl: así tiene ventana propia y
  su Canvas existe siempre. Un control gráfico saca el contexto de dibujo de su
  padre, y el diseñador le pone el Caption antes de asignarle padre. El costo es
  un handle por pastilla, y que no entra en un TControlList, que solo admite
  controles gráficos; ahí va DibujarEn. }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, Vcl.Graphics, Vcl.Controls, FlatVcl.Paleta;

type
  TFlatBadge = class(TCustomControl)
  private
    FStatus: TFlatStatus;
    FPaddingH: Integer;
    FAutoWidth: Boolean;
    procedure SetStatus(const AValor: TFlatStatus);
    procedure SetPaddingH(const AValor: Integer);
    procedure SetAutoWidth(const AValor: Boolean);
    procedure Ajustar;
    procedure CMTextChanged(var Msg: TMessage); message CM_TEXTCHANGED;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;

    { Para listas dibujadas a mano. El color sale de la paleta igual que en el
      componente; el llamador solo pone el rectángulo y el texto. }
    class procedure DibujarEn(ACanvas: TCanvas; const ARect: TRect;
      const ATexto: string; AStatus: TFlatStatus);

    { Ancho que necesita un texto con el relleno actual, para reservarle sitio
      en una columna antes de dibujarlo. }
    class function AnchoPara(ACanvas: TCanvas; const ATexto: string;
      APaddingH: Integer = 10): Integer;
  published
    property Status: TFlatStatus read FStatus write SetStatus default fsNeutral;
    property PaddingH: Integer read FPaddingH write SetPaddingH default 10;
    { Con AutoWidth la pastilla se ajusta al rótulo; se apaga cuando varias
      tienen que quedar alineadas en columna. }
    property AutoWidth: Boolean read FAutoWidth write SetAutoWidth default True;

    property Align;
    property Anchors;
    property Caption;
    property Constraints;
    property Enabled;
    property Font;
    property Hint;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property Visible;

    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
  end;

implementation

constructor TFlatBadge.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  Width := 88;
  Height := 22;
  FStatus := fsNeutral;
  FPaddingH := 10;
  FAutoWidth := True;
end;

procedure TFlatBadge.SetStatus(const AValor: TFlatStatus);
begin
  if FStatus <> AValor then
  begin
    FStatus := AValor;
    Invalidate;
  end;
end;

procedure TFlatBadge.SetPaddingH(const AValor: Integer);
begin
  if FPaddingH <> AValor then
  begin
    FPaddingH := AValor;
    Ajustar;
    Invalidate;
  end;
end;

procedure TFlatBadge.SetAutoWidth(const AValor: Boolean);
begin
  if FAutoWidth <> AValor then
  begin
    FAutoWidth := AValor;
    Ajustar;
  end;
end;

procedure TFlatBadge.Ajustar;
var
  lBmp: TBitmap;
begin
  if not FAutoWidth then
    Exit;

  { Se mide sobre un mapa de bits: no depende de que la ventana del control ya
    exista, y al soltar el componente el Caption cambia antes que eso. }
  lBmp := TBitmap.Create;
  try
    lBmp.Canvas.Font := Font;
    Width := AnchoPara(lBmp.Canvas, Caption, FPaddingH);
  finally
    lBmp.Free;
  end;
end;

procedure TFlatBadge.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  { El Paint cubre todo el control; dejar que Windows borre antes solo produce
    parpadeo. }
  Msg.Result := 1;
end;

procedure TFlatBadge.CMTextChanged(var Msg: TMessage);
begin
  inherited;
  Ajustar;
  Invalidate;
end;

procedure TFlatBadge.CMFontChanged(var Msg: TMessage);
begin
  inherited;
  Ajustar;
  Invalidate;
end;

class function TFlatBadge.AnchoPara(ACanvas: TCanvas; const ATexto: string;
  APaddingH: Integer): Integer;
begin
  Result := ACanvas.TextWidth(ATexto) + APaddingH * 2;
end;

class procedure TFlatBadge.DibujarEn(ACanvas: TCanvas; const ARect: TRect;
  const ATexto: string; AStatus: TFlatStatus);
var
  lFondo: TColor;
  lRadio, lX, lY: Integer;
begin
  lFondo := FlatPalette.Status[AStatus];

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := lFondo;
  { Sin pluma el borde saldría del color anterior del lienzo, que en una lista
    es el de la fila y cambia con la selección. }
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Color := lFondo;

  { Radio igual a la mitad del alto: la pastilla queda con los extremos
    redondos, no con esquinas suaves. }
  lRadio := (ARect.Bottom - ARect.Top) div 2;
  ACanvas.RoundRect(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom,
    lRadio * 2, lRadio * 2);

  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Color := FlatTextOn(lFondo);
  lX := ARect.Left + ((ARect.Right - ARect.Left) - ACanvas.TextWidth(ATexto))
    div 2;
  lY := ARect.Top + ((ARect.Bottom - ARect.Top) - ACanvas.TextHeight(ATexto))
    div 2;
  ACanvas.TextOut(lX, lY, ATexto);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TFlatBadge.Paint;
begin
  { Lo que el redondeo deja fuera se rellena con el color del contenedor, o esas
    esquinas quedarian sin pintar. }
  Canvas.Brush.Style := bsSolid;
  if Parent <> nil then
    Canvas.Brush.Color := Parent.Brush.Color
  else
    Canvas.Brush.Color := FlatPalette.Surface;
  Canvas.FillRect(ClientRect);

  Canvas.Font := Font;
  DibujarEn(Canvas, ClientRect, Caption, FStatus);
end;

end.
