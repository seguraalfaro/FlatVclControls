# Flat VCL Controls

Botón y pastilla de estado planos, en VCL pura. Sin Skia, sin dependencias fuera
de `rtl` y `vcl`.

Los componentes no traen colores propios ni conocen ninguna aplicación:
preguntan a `FlatVcl.Paleta`. La aplicación anfitriona sobrescribe esa paleta al
arrancar y con eso manda en todos los controles.

## Sobre el estado de este repositorio

Esto lo escribí hace un tiempo para una aplicación propia y **hoy no le doy
mantenimiento**. Lo publico tal como quedó, por si a alguien le sirve de base o
quiere mejorarlo. No hay soporte, ni hoja de ruta, ni compromiso de responder
issues.

Se compiló e instaló con **Delphi 10.4 Sydney**, Win32. En otras versiones
debería ir —no usa nada exótico— pero no lo he comprobado.

Está bajo licencia MIT: cópielo, modifíquelo y publique su versión sin pedir
permiso. Si lo mejora, un fork es más útil que un issue.

## Contenido

| Unidad | Qué trae |
| --- | --- |
| `FlatVcl.Paleta` | La paleta viva, la mezcla de colores y el contraste del texto |
| `FlatVcl.Dibujo` | El dibujo del botón, compartido por las dos clases |
| `FlatVcl.Boton` | `TFlatButton`, gráfico |
| `FlatVcl.BotonWin` | `TFlatWinButton`, con foco y tabulación |
| `FlatVcl.Pastilla` | `TFlatBadge` |
| `FlatVcl.NavItem` | `TFlatNavItem`, la fila del menú lateral |
| `FlatVcl.Registro` | El registro en la paleta del IDE, solo en el paquete de diseño |

## Instalación

1. Abrir `FlatVclControls.groupproj`. Trae los dos paquetes, y el de diseño
   declarado como dependiente del de ejecución.
2. **Build All Projects** sobre el grupo. El orden lo resuelve la dependencia:
   primero `FlatVclControls`, después `dclFlatVclControls`.
3. Clic derecho sobre `dclFlatVclControls` → **Install**. Aparece la categoría
   *Flat VCL* en la paleta. Solo se instala ese; el de ejecución es `{$RUNONLY}`
   y el IDE ni lo ofrece.
4. En el proyecto que los use, agregar la carpeta del paquete a *Search path*.

Después de cambiar una unidad basta con **Build All Projects** y volver a
**Install**. Si el IDE tiene la bpl cargada y bloqueada, *Uninstall* primero.

Los dos `.res` que acompañan a los `.dpk` están vacíos a propósito. El IDE los
regenera con la información de versión en cuanto se compila desde ahí.

Son dos paquetes y no uno porque el de diseño enlaza `designide`, que no puede
terminar dentro de un ejecutable. El `{$DESIGNONLY}` lo impide.

## Enganchar la paleta de la aplicación

Los valores por defecto son neutros —un azul, un gris, verde, ámbar y rojo— para
que el componente se vea razonable recién sacado de la paleta del IDE. Para usar
los colores propios, una vez al arrancar, antes de crear el primer formulario:

```pascal
uses
  Vcl.Graphics, FlatVcl.Paleta;

begin
  FlatPalette.Kind[fkPrimary]   := TColor($00A06029);
  FlatPalette.Kind[fkSecondary] := TColor($00E8D9C4);
  FlatPalette.Kind[fkSuccess]   := TColor($004CAF50);
  FlatPalette.Kind[fkWarning]   := TColor($0000A5FF);
  FlatPalette.Kind[fkDanger]    := TColor($004343D3);

  FlatPalette.Status[fsPending] := TColor($0000A5FF);
  FlatPalette.Status[fsSuccess] := TColor($004CAF50);
  FlatPalette.Status[fsDanger]  := TColor($004343D3);
  FlatPalette.Status[fsInfo]    := TColor($00A06029);
  FlatPalette.Status[fsNeutral] := clSilver;

  FlatPalette.Text       := clBlack;
  FlatPalette.TextOnDark := clWhite;
  FlatPalette.Surface    := clWhite;
  FlatPalette.Border     := TColor($00E0E0E0);
  FlatPalette.Disabled   := clSilver;
end;
```

Son cinco colores y no quince porque hover y presionado se calculan mezclando el
color base hacia el blanco y hacia el negro, en el porcentaje que fijan
`HoverPercent` y `PressedPercent`. Así los tres estados de un botón nunca se
desincronizan.

Los nombres de `TFlatKind` y `TFlatStatus` son genéricos a propósito: el paquete
no sabe qué significa "aprobada" en la aplicación que lo usa. Ese mapeo lo hace
la aplicación.

## Cuál de los dos botones

`TFlatWinButton` es el de siempre. Hereda de `TButton`, así que es una ventana y
trae lo que un control gráfico no puede tener: entra en el orden de tabulación,
toma el foco, responde al Enter y a la barra espaciadora, y puede ser `Default` o
`Cancel` de un diálogo. Un `TGraphicControl` no recibe el foco de entrada porque
no tiene handle de ventana, y sin foco no hay teclado.

Para poder colorear el rótulo —`TButton` no lo permite, el botón lo dibuja
Windows— se usa la misma salida que `TBitBtn`, que no es más que un `TButton`
dibujado por el dueño: `BS_OWNERDRAW` al crear la ventana y respuesta a
`CN_DRAWITEM`.

`TFlatButton` es el gráfico, para barras de acciones y para `TControlList`, que
solo admite descendientes de `TGraphicControl`. No toma el foco. Úselo cuando el
botón no deba robarle el foco a lo que el usuario está escribiendo.

Los dos comparten propiedades y dibujo, así que cambiar de uno a otro es cambiar
la clase.

## TFlatButton

Hereda de `TGraphicControl`, como `TSpeedButton`: no consume un handle de
ventana y se puede poner sobre cualquier contenedor.

`Kind` elige la clase de botón y de ahí sale el color; hover y presionado se
calculan mezclando ese color hacia el blanco y hacia el negro, en el porcentaje
que fija la paleta. Para un color fuera de la paleta está `ColorOverride`, pero
entonces hay que mantenerlo a mano.

`fkSecondary` no es otro color: es otro dibujo. En reposo se funde con el
contenedor y deja solo el borde y el texto en azul; el relleno entra al pasar el
ratón.

`Action` está publicada, así que el botón se engancha a un `TActionList` y
recibe `Caption`, `Enabled`, `Hint`, `Visible`, el `ImageIndex` y el
`OnExecute`. El icono no lo trae `TControlActionLink`, lo copia `ActionChange`.

El color del texto no se configura: lo decide la luminancia del fondo. Por eso
el ámbar sale con texto oscuro sin que nadie tenga que acordarse.

`Images` con `ImageIndex` dibuja el icono a la izquierda del rótulo, con
`Spacing` de separación, y los dos centrados como un bloque.

`ModalResult` cierra un diálogo igual que un `TButton`.

## TFlatBadge

La misma pastilla en dos formas. Como componente, con `Status` y `Caption`, para
un formulario o un `TControlList`. Y como `TFlatBadge.DibujarEn(Canvas, Rect,
Texto, Status)` para las listas dibujadas por owner-draw, donde no se pueden
colocar controles. El `Paint` del componente llama a ese mismo procedimiento, así
que las dos no pueden divergir.

`AnchoPara` devuelve lo que mide un texto con el relleno actual, para reservarle
la columna antes de dibujarlo.

`AutoWidth` ajusta la pastilla al rótulo. Se apaga cuando varias tienen que
quedar alineadas.

## TFlatNavItem

La fila del panel de navegación: icono a la izquierda, rótulo al lado y fondo
solo cuando está seleccionada o bajo el ratón. Gráfico, como el botón.

La selección es exclusiva entre los ítems que comparten padre: poner `Selected`
en uno apaga a los demás. Un lateral con dos secciones separadas se arma con dos
paneles.

`ShowCaption` en `False` deja solo el icono centrado, que es el modo compacto del
`TSplitView`. El resto no cambia, así que el cambio es una línea en el
`OnClosing`/`OnOpening`.

`SelectedColor` en `clNone` usa `Kind[fkSecondary]`, el tenue de la paleta. El
color del texto lo decide la luminancia del fondo que queda debajo, así que la
misma clase sirve en un lateral claro y en uno oscuro sin tocar nada.

No hereda de `TFlatButton`: el botón se dibuja siempre relleno y con el contenido
centrado, y aquí el reposo es transparente y todo va a la izquierda.

## Sobre TControlList

`TControlList` solo admite descendientes de `TGraphicControl`, y estos dos lo
son, así que se pueden colocar dentro.

Con una salvedad, que vale para cualquier control con estados: la lista no
propaga los cambios de estado de un `TSpeedButton`, y por eso Embarcadero agregó
`TControlListControl` y su `TControlListButton`. Si hace falta un botón *con
hover* dentro de la lista, la clase base tiene que ser `TControlListControl`, que
llegó en 10.4.2. La pastilla no tiene ese problema: es estática.

## Licencia

MIT. Ver [LICENSE](LICENSE).
