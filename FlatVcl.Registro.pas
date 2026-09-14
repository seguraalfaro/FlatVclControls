unit FlatVcl.Registro;

{ Registro en la paleta del IDE.

  Va en una unidad aparte y solo la contiene el paquete de diseño. Si estuviera
  dentro del componente, la aplicación terminaría enlazando designide al
  ejecutable. }

interface

procedure Register;

implementation

uses
  System.Classes, FlatVcl.Boton, FlatVcl.BotonWin, FlatVcl.Pastilla,
  FlatVcl.NavItem;

procedure Register;
begin
  RegisterComponents('Flat VCL', [TFlatWinButton, TFlatButton, TFlatBadge,
    TFlatNavItem]);
end;

end.
