unit FlatVcl.Paleta;

{ Paleta del paquete.

  Los componentes no traen colores propios ni saben de ninguna aplicación:
  preguntan aquí. La aplicación anfitriona sobrescribe la paleta una vez al
  arrancar y con eso manda en todos los controles, sin tocar cada formulario.

  Los valores por defecto son neutros —un azul, un gris, verde, ámbar y rojo—
  para que el componente se vea razonable recién sacado de la paleta del IDE,
  no porque sean los definitivos de nadie.

  Hover y presionado no se configuran color por color: se calculan mezclando el
  color base hacia el blanco y hacia el negro. Así una paleta nueva son cinco
  valores y no quince, y los tres estados de un botón nunca se desincronizan. }

interface

uses
  Vcl.Graphics;

type
  { Clase de botón. Los nombres son genéricos a propósito: el paquete no sabe
    qué significa "aprobar" en la aplicación que lo usa. }
  TFlatKind = (fkPrimary, fkSecondary, fkSuccess, fkWarning, fkDanger);

  { Estado visual de un boton. Vive aqui, y no en la unidad del componente,
    porque lo comparten el boton grafico, el de ventana y la rutina de dibujo. }
  TFlatVisualState = (fvIdle, fvHover, fvPressed, fvDisabled);

  { Estado de una pastilla. El mapeo a los estados del dominio —borrador,
    pendiente, aprobada— lo hace la aplicación. }
  TFlatStatus = (fsNeutral, fsPending, fsSuccess, fsDanger, fsInfo);

  TFlatPalette = record
    Kind: array [TFlatKind] of TColor;
    Status: array [TFlatStatus] of TColor;
    Surface: TColor;
    Border: TColor;
    Text: TColor;
    TextOnDark: TColor;
    Disabled: TColor;
    DisabledText: TColor;
    { Cuánto se aclara al pasar el ratón y cuánto se oscurece al presionar. }
    HoverPercent: Byte;
    PressedPercent: Byte;
    procedure Reset;
  end;

{ La paleta viva. Es una variable y no una función para que la aplicación pueda
  cambiar un solo campo sin copiar el registro entero. }
var
  FlatPalette: TFlatPalette;

function FlatMix(AColor, AHacia: TColor; APorciento: Byte): TColor;
function FlatHover(ABase: TColor): TColor;
function FlatPressed(ABase: TColor): TColor;

{ Blanco o texto oscuro, según lo que se lea mejor sobre el fondo. Resuelve solo
  el caso del ámbar, donde el blanco no alcanza el contraste. }
function FlatTextOn(AFondo: TColor): TColor;

implementation

uses
  Winapi.Windows;

procedure TFlatPalette.Reset;
begin
  Kind[fkPrimary] := TColor($00A06029); // #2960A0
  Kind[fkSecondary] := TColor($00F5E4D6); // #D6E4F5
  Kind[fkSuccess] := TColor($005EC522); // #22C55E
  Kind[fkWarning] := TColor($000B9EF5); // #F59E0B
  Kind[fkDanger] := TColor($004444EF); // #EF4444

  Status[fsNeutral] := TColor($00C1B8B0); // #B0B8C1
  Status[fsPending] := TColor($000B9EF5); // #F59E0B
  Status[fsSuccess] := TColor($005EC522); // #22C55E
  Status[fsDanger] := TColor($004444EF); // #EF4444
  Status[fsInfo] := TColor($00A06029); // #2960A0

  Surface := clWhite;
  Border := TColor($00E4DED9); // #D9DEE4
  Text := TColor($001E1C1C); // #1C1C1E
  TextOnDark := clWhite;
  Disabled := TColor($00C1B8B0); // #B0B8C1
  DisabledText := clWhite;

  HoverPercent := 12;
  PressedPercent := 12;
end;

function FlatMix(AColor, AHacia: TColor; APorciento: Byte): TColor;
var
  lA, lB: LongInt;
begin
  { Mezcla lineal en RGB. ColorToRGB resuelve antes los colores del sistema,
    como clBtnFace, que no traen componentes reales. }
  lA := ColorToRGB(AColor);
  lB := ColorToRGB(AHacia);
  Result := TColor(RGB(GetRValue(lA) + (GetRValue(lB) - GetRValue(lA)) *
    APorciento div 100, GetGValue(lA) + (GetGValue(lB) - GetGValue(lA)) *
    APorciento div 100, GetBValue(lA) + (GetBValue(lB) - GetBValue(lA)) *
    APorciento div 100));
end;

function FlatHover(ABase: TColor): TColor;
begin
  Result := FlatMix(ABase, clWhite, FlatPalette.HoverPercent);
end;

function FlatPressed(ABase: TColor): TColor;
begin
  Result := FlatMix(ABase, clBlack, FlatPalette.PressedPercent);
end;

function FlatTextOn(AFondo: TColor): TColor;
var
  lRGB: LongInt;
  lLuz: Integer;
begin
  { Luminancia percibida con los pesos habituales de la recomendación 601. El
    ojo ve el verde mucho más claro que el azul al mismo valor, así que un
    promedio simple daría texto blanco sobre amarillos. }
  lRGB := ColorToRGB(AFondo);
  lLuz := (GetRValue(lRGB) * 299 + GetGValue(lRGB) * 587 + GetBValue(lRGB) * 114)
    div 1000;
  if lLuz > 150 then
    Result := FlatPalette.Text
  else
    Result := FlatPalette.TextOnDark;
end;

initialization

FlatPalette.Reset;

end.
