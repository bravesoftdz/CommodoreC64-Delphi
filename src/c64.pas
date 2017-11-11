unit c64;

{$ifdef FPC}
{$MODE Delphi}
{$ENDIF}

//------------------------------------------------------------------------------
//Commodore C-64 GFX files manipulation Delphi (7+) class, v1.38
//(c)1994, 1995, 2009-2011, 2017 Noniewicz.com, Jakub Noniewicz aka MoNsTeR/GDC
//E-mail: monster@Noniewicz.com
//WWW: http://www.Noniewicz.com
//Licence: BSD 2-Clause License
//------------------------------------------------------------------------------
//based on my own earlier work (Koala/ArtStudio/Amica/Fonts/Sprites)
//and this:
//http://codebase64.org/doku.php?id=base:c64_grafix_files_specs_list_v0.03
//FLI code - loosely based on C code from C64Gfx by Pasi 'Albert' Ojala
//------------------------------------------------------------------------------
//Supported formats:
//- Koala Painter 2 (by AUDIO LIGHT) (pc-ext: .koa;.kla;.gg) -- .gg NOT YET
//- Wigmore Artist64 (by wigmore) (pc-ext: .a64)
//- Art Studio 1.0-1.1 (by OCP) (pc-ext: .aas;.art;.hpi)
//- Hi-Eddi (by Markt & Technik Verlag) (pc-ext: .hed)
//- Doodle (by OMNI) (pc-ext: .dd;.ddl;.jj) -- .jj NOT YET
//- RunPaint (pc-ext: .rpm)
//- Image System (Hires) (.ish)
//- Image System (Multicolor) (pc-ext: .ism;.ims)
//- Amica Paint (by OLIVER STILLER/MDG) (pc-ext: .ami)
//- FLI Graph 2.2 (by blackmail) (pc-ext: .bml)
//- AFLI-editor v2.0 (by Topaz Beerline) (pc-ext: .afl)
//- some other *FLI formats -- IN PROGRESS 
//- 8x8 and 16x16 font (hires/multicolor) - YET UNFINISHED
//- sprites (hires/multicolor, also font sprited) - YET UNFINISHED
//- "logo" text format (using fonts in text mode to represent graphics)
//- Paint Magic (pc-ext: .pmg)
//- Advanced Art Studio 2.0 (by OCP) (pc-ext: .ocp;.art)  
//------------------------------------------------------------------------------
//History:
//created: somewhere in 1994-1995
//updated: 20091231 ????-????
//updated: 20100101 ????-????
//updated: 20110510 ????-????
//updated: 20171029 1715-2040
//updated: 20171029 2150-2250
//updated: 20171030 2200-2215
//updated: 20171030 2240-2310
//updated: 20171101 1630-2030
//updated: 20171101 2105-2130
//updated: 20171101 2200-2255
//updated: 20171104 1920-2000
//updated: 20171105 0020-0050
//updated: 20171105 1210-1315
//updated: 20171105 1330-1340
//updated: 20171105 1455-1520
//updated: 20171105 1550-1630
//updated: 20171105 1830-2055
//updated: 20171111 1220-1500
//updated: 20171111 1605-1745 ...

{todo:
# MAIN:
.- fnt/fntb/logo - hires v multi - FNTload(multi) / FNTBshow(hires) / LOGOshow(hires)
- fnt/fntb/mob - more/misc (eg get given one, anim?)
.- *FLI formats
.- more exotic formats
.- Lazarus - compile+check on Linux
# NEXT:
- cleanup: MOBloadHires v MOBloadMulticolor -> one call
- separate load and bmp/canvas pack (rerender w/o load)
# LATER:
- also BDS demo?
- add misc limit checks
- add deeper byte format detection
- also open source c64pas app
- pack back to C64 formats and write (colormap, dither?)
- ZX analogue (6144/768/6912)?
- C code version (so more portable) ?
}

{CHANGELOG:
# v1.00
- base stuff, old version in Turbo Pascal, so ancient
# v1.10
- slightly rewritten for Delphi (then named mob64.pas)
# v1.20
- radical code cleanup
- everything as class
- amica code integrated
- demo app
- misc
# v1.30
- added FLI formats (experimental, unfinished)
- universal loader method (file extension based)
- misc fixes/changes
# v1.31
- added Hi-Eddi (.hed) format
# v1.32
- added AAS and HPI (untested) support
# v1.33
- added support for FLI Graph 2.2 (.bml)
- added support for Doodle (dd;.ddl)
# v1.34
- added support for Wigmore Artist64 (.a64)
# v1.35
- added support for RunPaint (.rpm)
# v1.36
- added support for Image System (Hires) (.ish)
- added support for Image System (Multicolor) (.ism;.ims)
- misc fixes/updates
# v1.37
- fixed BFLI display (h=400)
- added more palletes: C64S_PAL FRODO_PAL GODOT_PAL PC64_PAL VICE_PAL
- old VICE_PAL was actually CCS64_PAL
- final RGB color - get via one common call
- fnt/fntb/logo/mob - fixed colors issue (can now set proper 4 colors)
- hires/multi mode for font/logo/sprites - param exposed
- added support for Paint Magic (pc-ext: .pmg)
- misc
# v1.38
- Lazarus compatible + Lazarus demo
- added support for Advanced Art Studio 2.0 (pc-ext: .ocp;.art)
- misc
}

interface

{$ifdef FPC}
uses LCLIntf, LCLType, LMessages, SysUtils, Classes, Graphics, Dialogs;
{$ELSE}
uses Windows, SysUtils, Classes, Graphics, Dialogs;
{$ENDIF}



type
     MOBdata = record
                 cnt: byte;
                 mob: array[1..100, 0..63] of byte;
               end;
     FNTBdata = record
                  cnt: byte;
                  fntb: array[1..255, 0..31] of byte;
                end;
     FNTdata = record
                 cnt: byte;
                 fnt: array[1..255, 0..7] of byte;
               end;
     LOGOdata = record
                  logo: array[0..$2000-$1800-1] of byte;
                  bitmap: array[0..$2800-$2000-1] of byte;
                end;
     MULTIdata = record
                   bitmap: array[0..$7f40-$6000-1] of byte;
                   ink1: array[0..$8328-$7f40-1] of byte;
                   ink2: array[0..$8710-$8328-1] of byte; // -> $d800
                   backGr: byte;
                 end;
     HIRESdata = record
                   bitmap: array[0..$3f40-$2000-1] of byte;
                   ink: array[0..$8328-$7f40-1] of byte;
                 end;
     FLIdata = record //generic, any FLI
                 gfxmem: array[0..16384-1] of byte;
                 chrmem: array[0..7, 0..2048-1] of byte;
                 colmem: array[0..1024-1] of byte;
                 bgcol: array[0..256-1] of byte;
               end;
     IFLIdata = record //IFLI
                  gfxmem1: array[0..8192-1] of byte;
                  gfxmem2: array[0..8192-1] of byte;
                  chrmem1: array[0..8192-1] of byte;
                  chrmem2: array[0..8192-1] of byte;
                  colmem: array[0..1024-1] of byte;
                end;


TC64Loader = procedure(ca: TCanvas) of object;

TAmicaBuff = array[0..32767] of byte;

TC64Pallete = (C64S_PAL, CCS64_PAL, FRODO_PAL, GODOT_PAL, PC64_PAL, VICE_PAL);  

TC64FileType = (C64_UNKNOWN,
                C64_KOALA, C64_WIGMORE, C64_RUNPAINT, C64_ISM, C64_PAINTMAGIC,
                C64_ADVARTST,
                C64_HIRES, C64_HED, C64_DDL, C64_ISH,
                C64_AMICA,
                C64_LOGO, C64_FNT, C64_FNTB, C64_MOB, C64_MBF,
                C64_FLI, C64_AFLI, C64_BFLI, C64_IFLI, C64_FFLI);

TC64 = class(TObject)
private
  f: file of byte;
  FColors4: array [0..3] of byte;
  FLastError: string;
  FPalette: TC64Pallete;
  FAsHires: boolean;

  function GenericLoader(FileName: string; callback: TC64Loader; ca: TCanvas; mode: TC64FileType): integer;

  procedure MULTICOLORshow(koala: MULTIdata; ca: TCanvas);
  procedure HIRESshow(hires: HIRESdata; ca: TCanvas);
  procedure LOGOshow(logo: LOGOdata; ca: TCanvas);
  procedure FNTshow(x0, y0: integer; fnt: FNTdata; ca: TCanvas; cnt: byte);
  procedure FNTBshow(x0, y0: integer; fntb: FNTBdata; ca: TCanvas; cnt: byte);
  procedure hMOBshow(x0, y0: integer; mob: MOBdata; ca: TCanvas; cnt: byte);
  procedure mMOBshow(x0, y0: integer; mob: MOBdata; ca: TCanvas; cnt: byte);
  procedure FLIshow(fli: FLIdata; ca: TCanvas; mode: TC64FileType);
  procedure IFLIshow(ifli: IFLIdata; ca: TCanvas);

  procedure KOALAload(ca: TCanvas);
  procedure WIGMOREload(ca: TCanvas);
  procedure RUNPAINTload(ca: TCanvas);
  procedure IMGSYSload(ca: TCanvas);
  procedure PAMAGload(ca: TCanvas);
  procedure ADVARTSTload(ca: TCanvas);

  procedure HIRESload(ca: TCanvas);
  procedure HIRESloadHED(ca: TCanvas);
  procedure HIRESloadDDL(ca: TCanvas);
  procedure HIRESloadISH(ca: TCanvas);
  procedure AMICAload(ca: TCanvas);
  procedure AMICAunpack(i_buff: TAmicaBuff; var o_buff: TAmicaBuff);
  procedure AMICA2KOALA(o_buff: TAmicaBuff; var koala: MULTIdata);
  procedure LOGOload(ca: TCanvas);
  procedure FNTload(ca: TCanvas);
  procedure FNTBload(ca: TCanvas);
  procedure MOBloadHires(ca: TCanvas);
  procedure MOBloadMulticolor(ca: TCanvas);
  procedure FLIload(ca: TCanvas);  
public
  constructor Create;
  function GetC64Color(index: integer): TColor;
  function GetC64ColorR(index: integer): byte;
  function GetC64ColorG(index: integer): byte;
  function GetC64ColorB(index: integer): byte;
  procedure Set4Colors(color0, color1, color2, color3: byte);
  function ExtMapper(ext: string): TC64FileType;

  function LoadMulticolorToBitmap(FileName: string; ca: TCanvas; mode: TC64FileType): integer;
  function LoadHiresToBitmap(FileName: string; ca: TCanvas; mode: TC64FileType): integer;
  function LoadAmicaToBitmap(FileName: string; ca: TCanvas): integer;
  function LoadLogoToBitmap(FileName: string; ca: TCanvas): integer;
  function LoadFontToBitmap(FileName: string; ca: TCanvas): integer;
  function LoadFont2x2ToBitmap(FileName: string; ca: TCanvas): integer;
  function LoadMobToBitmap(FileName: string; ca: TCanvas): integer;
  function LoadFliToBitmap(FileName: string; ca: TCanvas): integer;

  function LoadC64ToBitmap(FileName: string; ca: TCanvas): integer;  
published
  property LastError: string read FLastError;
  property Palette: TC64Pallete read FPalette write FPalette;
  property AsHires: boolean read FAsHires write FAsHires;
end;


implementation

const
//0..15 = black,white,red,cyan,magenta(purple),green,blue,yellow
//orange,brown(lt.red),pink,dk.gray,gray,lt.green,lt.blue,lt.gray

//VICE pallete c64s.vpl
  c64s_r: array[0..15] of byte = ($00,$fc,$a8,$54,$a8,$00,$00,$fc, $a8,$80,$fc,$54,$80,$54,$54,$a8);
  c64s_g: array[0..15] of byte = ($00,$fc,$00,$fc,$00,$a8,$00,$fc, $54,$2c,$54,$54,$80,$fc,$54,$a8);
  c64s_b: array[0..15] of byte = ($00,$fc,$00,$fc,$a8,$00,$a8,$00, $00,$00,$54,$54,$80,$54,$fc,$a8);

//VICE pallete ccs64.vpl
  ccs64_r: array[0..15] of byte = ($00,$ff,$e0,$60,$e0,$40,$40,$ff, $e0,$9c,$ff,$54,$88,$a0,$a0,$c0);
  ccs64_g: array[0..15] of byte = ($00,$ff,$40,$ff,$60,$e0,$40,$ff, $a0,$74,$a0,$54,$88,$ff,$a0,$c0);
  ccs64_b: array[0..15] of byte = ($00,$ff,$40,$ff,$e0,$40,$e0,$40, $40,$48,$a0,$54,$88,$a0,$ff,$c0);

//VICE pallete frodo.vpl
  frodo_r: array[0..15] of byte = ($00,$ff,$cc,$00,$ff,$00,$00,$ff, $ff,$88,$ff,$44,$88,$88,$88,$cc);
  frodo_g: array[0..15] of byte = ($00,$ff,$00,$ff,$00,$cc,$00,$ff, $88,$44,$88,$44,$88,$ff,$88,$cc);
  frodo_b: array[0..15] of byte = ($00,$ff,$00,$cc,$ff,$00,$cc,$00, $00,$00,$88,$44,$88,$88,$ff,$cc);

//VICE pallete godot.vpl
  godot_r: array[0..15] of byte = ($00,$ff,$88,$aa,$cc,$00,$00,$ee, $dd,$66,$fe,$33,$77,$aa,$00,$bb);
  godot_g: array[0..15] of byte = ($00,$ff,$00,$ff,$44,$cc,$00,$ee, $88,$44,$77,$33,$77,$ff,$88,$bb);
  godot_b: array[0..15] of byte = ($00,$ff,$00,$ee,$cc,$55,$aa,$77, $55,$00,$77,$33,$77,$66,$ff,$bb);

//VICE pallete pc64.vpl                                                                     
  pc64_r: array[0..15] of byte = ($21,$ff,$b5,$73,$b5,$21,$21,$ff, $b5,$94,$ff,$73,$94,$73,$73,$b5);
  pc64_g: array[0..15] of byte = ($21,$ff,$21,$ff,$21,$b5,$21,$ff, $73,$42,$73,$73,$94,$ff,$73,$b5);
  pc64_b: array[0..15] of byte = ($21,$ff,$21,$ff,$b5,$21,$b5,$21, $21,$21,$73,$73,$94,$73,$ff,$b5);

//VICE pallete vice.vpl                                                                     
  vice_r: array[0..15] of byte = ($00,$ff,$68,$70,$6f,$58,$35,$b8, $6f,$43,$9a,$44,$6c,$9a,$6c,$95);
  vice_g: array[0..15] of byte = ($00,$ff,$37,$a4,$3d,$8d,$28,$c7, $4f,$39,$67,$44,$6c,$d2,$5e,$95);
  vice_b: array[0..15] of byte = ($00,$ff,$2b,$b2,$86,$43,$79,$6f, $25,$00,$59,$44,$6c,$84,$b5,$95);


  pow: array[0..7] of byte = (1, 2, 4, 8, 16, 32, 64, 128);



constructor TC64.Create;
begin
  inherited;
  FPalette := CCS64_PAL;
  FAsHires := false;
  Set4Colors(0, 1, 15, 11);
end;

function TC64.GetC64Color(index: integer): TColor;
begin
  if not (index in [0..15]) then
    result := 0
  else
    case FPalette of
      C64S_PAL:  result := RGB(c64s_r[index], c64s_g[index], c64s_b[index]);
      CCS64_PAL: result := RGB(ccs64_r[index], ccs64_g[index], ccs64_b[index]);
      FRODO_PAL: result := RGB(frodo_r[index], frodo_g[index], frodo_b[index]);
      GODOT_PAL: result := RGB(godot_r[index], godot_g[index], godot_b[index]);
      PC64_PAL:  result := RGB(pc64_r[index], pc64_g[index], pc64_b[index]);
      VICE_PAL:  result := RGB(vice_r[index], vice_g[index], vice_b[index]);
      else result := 0;
    end;
end;

function TC64.GetC64ColorR(index: integer): byte;
begin
  if not (index in [0..15]) then
    result := 0
  else
    case FPalette of
      C64S_PAL:  result := c64s_r[index];
      CCS64_PAL: result := ccs64_r[index];
      FRODO_PAL: result := frodo_r[index];
      GODOT_PAL: result := godot_r[index];
      PC64_PAL:  result := pc64_r[index];
      VICE_PAL:  result := vice_r[index];
      else result := 0;
    end;
end;

function TC64.GetC64ColorG(index: integer): byte;
begin
  if not (index in [0..15]) then
    result := 0
  else
    case FPalette of
      C64S_PAL:  result := c64s_g[index];
      CCS64_PAL: result := ccs64_g[index];
      FRODO_PAL: result := frodo_g[index];
      GODOT_PAL: result := godot_g[index];
      PC64_PAL:  result := pc64_g[index];
      VICE_PAL:  result := vice_g[index];
      else result := 0;
    end;
end;

function TC64.GetC64ColorB(index: integer): byte;
begin
  if not (index in [0..15]) then
    result := 0
  else
    case FPalette of
      C64S_PAL:  result := c64s_b[index];
      CCS64_PAL: result := ccs64_b[index];
      FRODO_PAL: result := frodo_b[index];
      GODOT_PAL: result := godot_b[index];
      PC64_PAL:  result := pc64_b[index];
      VICE_PAL:  result := vice_b[index];
      else result := 0;
    end;
end;

procedure TC64.Set4Colors(color0, color1, color2, color3: byte);
begin
  FColors4[0] := color0;
  FColors4[1] := color1;
  FColors4[2] := color2;
  FColors4[3] := color3;
end;

function TC64.ExtMapper(ext: string): TC64FileType;
var e: string;
begin
  e := uppercase(ext);
  result := C64_UNKNOWN;

  //Koala Painter 2 (by AUDIO LIGHT) (pc-ext: .koa;.kla;.gg)
  if (e = '.KOA') or (e = '.KLA') then result := C64_KOALA;

  //Advanced Art Studio 2.0 (by OCP) (pc-ext: .ocp;.art)   
  if (e = '.MPIC') then result := C64_ADVARTST; //note: we use .mpic ext, not .art or other

  //Wigmore Artist64 (by wigmore) (pc-ext: .a64)
  if (e = '.A64') then result := C64_WIGMORE;

  //RunPaint (pc-ext: .rpm)
  if (e = '.RPM') then result := C64_RUNPAINT;

  //Image System (Multicolor) (pc-ext: .ism;.ims) -- Alid.ism
  if (e = '.ISM') or (e = '.IMS') then result := C64_ISM;

  //Paint Magic (pc-ext: .pmg) 
  if (e = '.PMG') then result := C64_PAINTMAGIC;

  //Art Studio 1.0-1.1 (by OCP) (pc-ext: .aas;.art;.hpi)
  if (e = '.PIC') or (e = '.ART') or (e = '.OCP') or (e = '.AAS') or (e = '.HPI') then
    result := C64_HIRES;

  //Hi-Eddi (by Markt & Technik Verlag) (pc-ext: .hed) 
  if (e = '.HED') then result := C64_HED;

  //Doodle (by OMNI) (pc-ext: .dd;.ddl;.jj)
  if (e = '.DD') or (e = '.DDL') (*or (e = '.JJ')*) then result := C64_DDL;

  //Image System (Hires) (pc-ext: .ish)
  if (e = '.ISH') then result := C64_ISH;

  //Amica Paint
  if (e = '.[B]') or (e = '.AMI') then result := C64_AMICA; //note: '[B]' invented here

  if e = '.GFX' then result := C64_LOGO;  //note: ext invented here

  //8x8 font (multi or hires)
  if e = '.FNT' then result := C64_FNT;

  //16x16 font (multi or hires)
  if e = '.FNB' then result := C64_FNTB;  //note: ext invented here

  //sprites + sprite fonts hires/multi 
  if e = '.MOB' then result := C64_MOB;   //note: ext invented here
  if e = '.MBF' then result := C64_MBF;   //note: ext invented here

  //FLI Graph 2.2 (by blackmail) (pc-ext: .bml)
  if (e = '.FLI') or (e = '.BML') then result := C64_FLI;

  //AFLI-editor v2.0 (by Topaz Beerline) (pc-ext: .afl)
  if (e = '.AFLI') or (e = '.AFL') (*or (e = '.HFC')*) then result := C64_AFLI;

  if (e = '.BFLI') then result := C64_BFLI;

  if (e = '.FFLI') then result := C64_FFLI;

  if (e = '.IFLI') or (e = '.IFL') (*or (e = '.GUN')*) then result := C64_IFLI;

(* lookup more-to-implement folder for:
Hires-Interlace v1.0 (Feniks) (pc-ext: .hlf) -- LOGOFENIKS.HLF
Drazlace (pc-ext: .drl) -- TESTPACK.Drl
Hires FLI (by Crest) (pc-ext: .hfc) -- DEMOPIC.HFC
Hires Manager (by Cosmos) (pc-ext: .him) -- logo.him / logo1.him
Funpaint 2 (by Manfred Trenz) (pc-ext: .fp2;.fun) -- KATER.fp2 / appbug.fun / Valsary.fun / Viking.fun
Gunpaint (pc-ext: .gun,.ifl) -- Gunpaint.gun / MECENARI.gun
*)  
end;

function TC64.GenericLoader(FileName: string; callback: TC64Loader; ca: TCanvas; mode: TC64FileType): integer;
var err: boolean;
begin
  result := -1;
  FLastError := 'Required parameters not assigned.';
  if not assigned(callback) or not assigned(ca) then exit;

  try
    AssignFile(f, FileName);
    reset(f);
    try
      callback(ca);
      err := false;
    except
      on E: Exception do
      begin
        FLastError := E.Message;
        err := true;
      end;
    end;
    CloseFile(f);
    if err then
      raise(Exception.Create(FLastError));
    result := 0;
    FLastError := '';
  except
    on E: Exception do FLastError := E.Message;
  end;
end;

//---

procedure TC64.MULTICOLORshow(koala: MULTIdata; ca: TCanvas);
var x, y, bit, c0, c1, c2, c3, bt, bt1, vl, vl1, vl2: byte;
    c: TColor;
    ndx, ndx2: integer;
begin
  if not assigned(ca) then exit;

  c0 := koala.backGr and $0f;
  for x := 0 to 39 do
    for y := 0 to 24 do
    begin
      ndx := x+y*40;
      ndx2 := x*8+y*320;
      c1 := (koala.ink1[ndx] and $0f);        //&5c00
      c2 := (koala.ink1[ndx] and $f0) shr 4;
      c3 := (koala.ink2[ndx] and $0f);        //&d800
      for bt := 0 to 7 do
      begin
        bt1 := koala.bitmap[ndx2+bt];
        for bit := 3 downto 0 do
        begin
          vl1 := ((bt1 and pow[bit*2]) div pow[bit*2]);
          vl2 := ((bt1 and pow[bit*2+1]) div pow[bit*2+1]);
          vl := vl1+2*vl2;
          case vl of
            3: c := GetC64Color(c3);
            2: c := GetC64Color(c1);
            1: c := GetC64Color(c2);
            else c := GetC64Color(c0);
          end;
          ca.Pixels[x*8+7-2*bit, (y*8+bt)] := c;
          ca.Pixels[x*8+8-2*bit, (y*8+bt)] := c;
        end;
      end;
    end;
end;

procedure TC64.HIRESshow(hires: HIRESdata; ca: TCanvas);
var x, y, bit, cc, c1, c2, bt, bt1: byte;
    c: TColor;
begin
  if not assigned(ca) then exit;

  for x := 0 to 39 do
    for y := 0 to 24 do
    begin
      cc := hires.ink[x+y*40];
      c1 := (cc and $0f);
      c2 := (cc and $f0) shr 4;
      for bt := 0 to 7 do
      begin
        bt1 := hires.bitmap[x*8+y*320+bt];
        for bit := 7 downto 0 do
        begin
          if (bt1 and pow[bit]) = pow[bit] then
            c := GetC64Color(c2)
          else
            c := GetC64Color(c1);
          ca.Pixels[x*8+8-bit, (y*8+bt)] := c;
        end;
      end;
    end;
end;

procedure TC64.LOGOshow(logo: LOGOdata; ca: TCanvas);
var x, y, bit, bt1, bt2, vl, vl1, vl2, bt: byte;
    c: TColor;
begin
  if not assigned(ca) then exit;

  for x := 0 to 39 do
    for y := 0 to 24 do
    begin
      bt1 := logo.logo[x+y*40];
      for bt := 0 to 7 do
      begin
        bt2 := logo.bitmap[bt1*8+bt];
        for bit := 3 downto 0 do
        begin
          vl1 := ((bt2 and pow[bit*2]) div pow[bit*2]);
          vl2 := ((bt2 and pow[bit*2+1]) div pow[bit*2+1]);
          vl := vl1+2*vl2;
          //todo: hires too
          case vl of
            0: c := GetC64Color(FColors4[0]);
            1: c := GetC64Color(FColors4[1]);
            2: c := GetC64Color(FColors4[2]);
            3: c := GetC64Color(FColors4[3]);
            else c := GetC64Color(0);
          end;
          ca.Pixels[x*8+7-2*bit, (y*8+bt)] := c;
          ca.Pixels[x*8+8-2*bit, (y*8+bt)] := c;
        end;
      end;
    end;
end;

procedure TC64.FNTshow(x0, y0: integer; fnt: FNTdata; ca: TCanvas; cnt: byte);
var y, bit, bt, vl: byte;
    c: TColor;
begin
  if not assigned(ca) then exit;

  for y := 0 to 7 do
  begin
    bt := fnt.fnt[cnt, y];
    for bit := 0 to 7 do
    begin
      vl := bt and pow[bit];
      //todo: multicolor too
      if vl = 0 then
        c := GetC64Color(FColors4[0]) //bg
      else
        c := GetC64Color(FColors4[1]); //fg
      ca.pixels[x0+8-bit, y0+y] := c;
    end;
  end;
end;

procedure TC64.FNTBshow(x0, y0: integer; fntb: FNTBdata; ca: TCanvas; cnt: byte);
var x, y, bit, bt, vl1, vl2, vl, c: byte;
    cl: TColor;
begin
  if not assigned(ca) then exit;

  for y := 0 to 15 do
    for x := 0 to 1 do
    begin
      if y >= 8 then c := 16+y-8 else c := y;
      bt := fntb.fntb[cnt, x*8+c];
      for bit := 3 downto 0 do
      begin
        vl1 := (bt and pow[bit*2]) div pow[bit*2];
        vl2 := (bt and pow[bit*2+1]) div pow[bit*2+1];
        vl := vl1+2*vl2;
        //todo: hires too
        case vl of
          0: cl := GetC64Color(FColors4[0]);
          1: cl := GetC64Color(FColors4[1]);
          2: cl := GetC64Color(FColors4[2]);
          3: cl := GetC64Color(FColors4[3]);
          else cl := GetC64Color(0);
        end;
        ca.Pixels[x0+x*8+7-2*bit, y0+y] := cl;
        ca.Pixels[x0+x*8+8-2*bit, y0+y] := cl;
      end;
    end;
end;

procedure TC64.hMOBshow(x0, y0: integer; mob: MOBdata; ca: TCanvas; cnt: byte);
var x, y, bit, bt, vl : byte;
    cl: TColor;
begin
  if not assigned(ca) then exit;

  for y := 0 to 20 do
    for x := 0 to 2 do
    begin
      bt := mob.mob[cnt, x+y*3];
      for bit := 7 downto 0 do
      begin
        vl := (bt and pow[bit]) div pow[bit];
        if vl = 0 then
          cl := GetC64Color(0)  //background (eg. black)
        else
          cl := GetC64Color(1); //foreground (eg. white)
        ca.Pixels[x0+x*8+7-bit, y0+y] := cl;
      end
    end;
end;

procedure TC64.mMOBshow(x0, y0: integer; mob: MOBdata; ca: TCanvas; cnt: byte);
var x, y, bit, bt, vl1, vl2, vl: byte;
    cl: TColor;
begin
  if not assigned(ca) then exit;

  for y := 0 to 20 do
    for x := 0 to 2 do
    begin
      bt := mob.mob[cnt,x+y*3];
      for bit := 3 downto 0 do
      begin
        vl1 := (bt and pow[bit*2]) div pow[bit*2];
        vl2 := (bt and pow[bit*2+1]) div pow[bit*2+1];
        vl := vl1+2*vl2;
        case vl of
          0: cl := GetC64Color(FColors4[0]);
          1: cl := GetC64Color(FColors4[1]);
          2: cl := GetC64Color(FColors4[2]);
          3: cl := GetC64Color(FColors4[3]);
          else cl := GetC64Color(0);
        end;
        ca.Pixels[x0+x*8+7-2*bit, y0+y] := cl;
        ca.Pixels[x0+x*8+8-2*bit, y0+y] := cl;
      end;
    end;
end;

//FLI - based on C code from C64Gfx by Pasi 'Albert' Ojala

procedure TC64.FLIshow(fli: FLIdata; ca: TCanvas; mode: TC64FileType);
const bitmask: array[0..3] of byte = ($c0, $30, $0c, $03);
      bitshift: array[0..3] of byte = ($40, $10, $04, $01);
var x, y, ind, pos, bits, ysize, xsize: integer;
    a, b: byte;
begin
  ysize := 200;
//  xsize := 160;
  b := 0;

  if (mode = C64_BFLI) then ysize := 400;
//  if (mode = C64_AFLI) then xsize := 320;

  for y := 0 to ysize-1 do
  begin
    if (mode = C64_AFLI) then
    begin
      for x := 0 to 320-1 do
      begin
        ind := x div 8 + (y div 8)*40;  //color memory index
        pos := (y mod 8) + (x div 8)*8 + (y div 8)*320;  //gfx memory byte
        bits := 7 - (x mod 8);  //bit numbers
        a := (fli.gfxmem[pos] shr bits) and 1;
        if (x < 24) then
            b := $f
        else
        begin
          if (a <> 0) then
            b := fli.chrmem[y mod 8][ind] div 16
          else
            b := fli.chrmem[y mod 8][ind] mod 16;
        end;
        ca.Pixels[x, y] := GetC64Color(b);
      end;
    end
    else
    begin
      for x := 0 to 160-1 do
      begin
        ind := x div 4 + (y div 8)*40;		//color memory index
        pos := (y mod 8)+ (x div 4)*8 + (y div 8)*320;	//gfx memory byte
        bits := (x mod 4);			//bit numbers
        a := (fli.gfxmem[pos] and bitmask[bits]) div bitshift[bits];
        if (mode = C64_FLI) then
        begin
          case a of
            0: b := fli.bgcol[y+6];
            1: if (x < 12) then b := 15 else b := fli.chrmem[y mod 8][ind] div 16;
            2: if (x < 12) then b := 15 else b := fli.chrmem[y mod 8][ind] mod 16;
            3: if (x < 12) then b := 9 else b := fli.colmem[ind] mod 16;
            else b := 0;
          end;
        end
        else if (mode = C64_BFLI) then
        begin
          case a of
            0: b := 0;
            1: if (x < 12) then b := 15 else b := fli.chrmem[y mod 8][ind] div 16;
            2: if (x < 12) then b := 15 else b := fli.chrmem[y mod 8][ind] mod 16;
            3: if (x < 12) then b := 9 else b := fli.colmem[(ind and 1023)]mod 16;
            else b := 0;
          end;
        end;
        ca.Pixels[x, y] := GetC64Color(b);
      end;
    end;
  end;
end;

procedure TC64.IFLIshow(ifli: IFLIdata; ca: TCanvas);
const bitmask: array[0..3] of byte = ($c0, $30, $0c, $03);
      bitshift: array[0..3] of byte = ($40, $10, $04, $01);
var x, y, ind, pos, bits, memind: integer;
    a0, a1: byte;
    c0, c1: byte;
    buffer: array[0..3*321] of byte;    
begin
  c0 := 0;
  c1 := 0;
  for y := 0 to 200-1 do
  begin
    buffer[0] := 0;
    buffer[1] := 0;
    buffer[2] := 0;
    for x := 0 to 160-1 do
    begin
      ind := x div 4 + (y div 8)*40;  //color memory index
      pos := (y mod 8) + (x div 4)*8 + (y div 8)*320;  //gfx memory byte
      bits := (x mod 4);  //bit numbers
      memind := 1024*(y mod 8) + ind;
	    a0 := (ifli.gfxmem1[pos] and bitmask[bits]) div bitshift[bits];
	    a1 := (ifli.gfxmem2[pos] and bitmask[bits]) div bitshift[bits];
      case a0 of
        0: c0 := 0;
        1: c0 := ifli.chrmem1[memind] div 16;
        2: c0 := ifli.chrmem1[memind] mod 16;
        3: c0 := ifli.colmem[ind] and $0f;
      end;
      case a1 of
        0: c1 := 0;
        1: c1 := ifli.chrmem2[memind] div 16;
        2: c1 := ifli.chrmem2[memind] mod 16;
        3: c1 := ifli.colmem[ind] and $0f;
      end;

	    buffer[6*x+0] := (buffer[6*x+0] + GetC64ColorR(c0)) div 2;
	    buffer[6*x+1] := (buffer[6*x+1] + GetC64ColorG(c0)) div 2;
	    buffer[6*x+2] := (buffer[6*x+2] + GetC64ColorB(c0)) div 2;

	    buffer[6*x+3] := (GetC64ColorR(c1) + GetC64ColorR(c0)) div 2;
	    buffer[6*x+4] := (GetC64ColorG(c1) + GetC64ColorG(c0)) div 2;
	    buffer[6*x+5] := (GetC64ColorB(c1) + GetC64ColorB(c0)) div 2;

	    buffer[6*x+6] := GetC64ColorR(c1);
	    buffer[6*x+7] := GetC64ColorG(c1);
	    buffer[6*x+8] := GetC64ColorB(c1);
    end;
    for x := 0 to 320-1 do
      ca.Pixels[x, y] := RGB(buffer[x*3+0], buffer[x*3+1], buffer[x*3+2]);
  end;
end;

//---

procedure TC64.KOALAload(ca: TCanvas);
var koala: MULTIdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;
  read(f, none, none);
  for g := 0 to $7f40-$6000-1 do read(f, koala.bitmap[g]);
  for g := 0 to $8328-$7f40-1 do read(f, koala.ink1[g]);
  for g := 0 to $8710-$8328-1 do read(f, koala.ink2[g]);
  read(f, koala.backGr);
  MULTICOLORshow(koala, ca);
end;

(*
Wigmore Artist64 (by wigmore) (pc-ext: .a64)
load address: $4000 - $67FF
$4000 - $5F3F 	Bitmap
$6000 - $63E7 	Screen RAM
$6400 - $67E7 	Color RAM
$67FF 	Background
*)
procedure TC64.WIGMOREload(ca: TCanvas);
var koala: MULTIdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;
  read(f, none, none);
  for g := 0 to 7999 do read(f, koala.bitmap[g]);
  for g := 0 to $6000-$5F3F-1-1 do read(f, none); //?
  for g := 0 to 999 do read(f, koala.ink1[g]);
  for g := 0 to $6400-$63E7-1-1 do read(f, none); //?
  for g := 0 to 999 do read(f, koala.ink2[g]);
  read(f, koala.backGr); //todo: chk this one
  MULTICOLORshow(koala, ca);
end;

(*
RunPaint (pc-ext: .rpm)
load address: $6000 - $8710
$6000 - $7F3F 	Bitmap
$7F40 - $8327 	Screen RAM
$8328 - $870F 	Color RAM
$8710 	Background
*)
procedure TC64.RUNPAINTload(ca: TCanvas);
var koala: MULTIdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;
  read(f, none, none);
  for g := 0 to 7999 do read(f, koala.bitmap[g]);
  for g := 0 to 999 do read(f, koala.ink1[g]);
  for g := 0 to 999 do read(f, koala.ink2[g]);
  read(f, koala.backGr); 
  MULTICOLORshow(koala, ca);
end;

(*
Image System (Multicolor) (pc-ext: .ism;.ims)
load address: $3C00 - $63E8
$3C00 - $3FE7 	Color RAM
$4000 - $5F3F 	Bitmap
$5FFF 	Background
$6000 - $63E7 	Screen RAM
*)
procedure TC64.IMGSYSload(ca: TCanvas);
var koala: MULTIdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;
  read(f, none, none);
  for g := 0 to 999 do read(f, koala.ink2[g]);
  for g := 0 to 23 do read(f, none); //?
  for g := 0 to 7999 do read(f, koala.bitmap[g]);
  for g := 0 to 191-1 do read(f, none); //10218-2-1000-1000-24-8000-1 = 191
  read(f, koala.backGr);
  for g := 0 to 999 do read(f, koala.ink1[g]);
  MULTICOLORshow(koala, ca);
end;

(*
Paint Magic (pc-ext: .pmg)
load address: $3F8E - $63FF
$3F8E - $3FFF 	Display Routine
$4000 - $5F3F 	Bitmap
$5F40 	Background
$5F43 	Color RAM Byte
$5F44 	Border
$6000 - $63E7 	Screen RAM
*)
procedure TC64.PAMAGload(ca: TCanvas);
var data: MULTIdata;
    g: word;
    c, none: byte;
begin
  if not assigned(ca) then exit;
  read(f, none, none);
  for g := 0 to $3FFF-$3F8E-1+(1) do read(f, none); //display routine
  for g := 0 to 7999 do read(f, data.bitmap[g]);
  read(f, data.backGr);
  read(f, none, none); //skip
  read(f, c); //Color RAM Byte
  read(f, none); //border - ignore
  for g := 0 to 999 do data.ink2[g] := c;
  for g := 0 to $6000-$5F45-1 do read(f, none); //skip
  for g := 0 to 999 do read(f, data.ink1[g]);
  MULTICOLORshow(data, ca);
end;

(*
Advanced Art Studio 2.0 (by OCP) (pc-ext: .ocp;.art) -- Frontpic.art / gfartist.art / MONALISA.ART / PRODIGY.ART / SIANO.ART
load address: $2000 - $471F
$2000 - $3F3F 	Bitmap
$3F40 - $4327 	Screen RAM
$4328 	Border
$4329 	Background
$4338 - $471F 	Color RAM
*)
procedure TC64.ADVARTSTload(ca: TCanvas);
var data: MULTIdata;
    g: word;
    c, none: byte;
begin
  if not assigned(ca) then exit;
  read(f, none, none);
  for g := 0 to 7999 do read(f, data.bitmap[g]);
  for g := 0 to 999 do read(f, data.ink1[g]);
  read(f, none);
  read(f, data.backGr);
  for g := 0 to $4338-$432A-1 do read(f, none); //skip
  for g := 0 to 999 do read(f, data.ink2[g]);
  MULTICOLORshow(data, ca);
end;

procedure TC64.HIRESload(ca: TCanvas);
var HIRES: HIRESdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;
  {9009 bytes - what's that!?}
  read(f, none, none);
  for g := 0 to $3f40-$2000-1 do read(f, hires.bitmap[g]);
  for g := 0 to $4328-$3f40-1 do read(f, hires.ink[g]);
  HIRESshow(hires, ca);
end;

procedure TC64.HIRESloadHED(ca: TCanvas);
var HIRES: HIRESdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;
  read(f, none, none);
  for g := 0 to $3f3f-$2000-1 do read(f, hires.bitmap[g]);
  for g := 0 to $4000-$3f3f-1 do read(f, none);
  for g := 0 to $43e7-$4000-1 do read(f, hires.ink[g]);
  HIRESshow(hires, ca);
end;

procedure TC64.HIRESloadDDL(ca: TCanvas);
var HIRES: HIRESdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;

  for g := 0 to 999 do hires.ink[g] := 0;  //todo: common
  for g := 0 to 7999 do hires.bitmap[g] := 0;  //todo: common
//9218-1000-8000 = 218
  read(f, none, none);
  for g := 0 to 999 do read(f, hires.ink[g]);
  for g := 0 to 7+8+8 do read(f, none); //but why???
  for g := 0 to $7f3f-$6000-1+1 do read(f, hires.bitmap[g]);
  HIRESshow(hires, ca);
end;

(*
Image System (Hires) (pc-ext: .ish)
load address: $4000 - $63e7
$4000 - $5f3f 	Bitmap
$6000 - $63e7 	Screen RAM
*)
procedure TC64.HIRESloadISH(ca: TCanvas);
var HIRES: HIRESdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;

  for g := 0 to 999 do hires.ink[g] := 0;  //todo: common
  for g := 0 to 7999 do hires.bitmap[g] := 0;  //todo: common
  read(f, none, none);
  for g := 0 to 7999 do read(f, hires.bitmap[g]);
  for g := 0 to 999 do read(f, hires.ink[g]);
  HIRESshow(hires, ca);
end;

procedure TC64.AMICAload(ca: TCanvas);
var koala: MULTIdata;
    i_buff, o_buff: TAmicaBuff;
    b, i: integer;
    c: byte;
begin
  if not assigned(ca) then exit;

  b := 0;
  while not eof(f) and (b < 32768) do
  begin
    read(f, c);
    i_buff[b] := c;
    inc(b);
  end;

  for i := 0 to high(o_buff) do o_buff[i] := 0;
  AMICAunpack(i_buff, o_buff);
  AMICA2KOALA(o_buff, koala);
  MULTICOLORshow(koala, ca);
end;

//------------------------------------------------------------------------------
//NOTE: that used to be old amica.pas file
//'AMICA PAINT' C-64 FORMAT SCREEN UNPACKER
//FROM MY ORIGINAL 'SHOWPIX' RESOURCED BY MONSTER/GDC (c)1992
//6502 ASM -> PAS coversion (c)2009 MONSTER/GDC, Noniewicz.com
//this code is kinda lame (labels) because it's direct translation from ASM
//created: 20091230
//updated: 20171029 (nice(r) code, as part of this object)
//------------------------------------------------------------------------------

procedure TC64.AMICAunpack(i_buff: TAmicaBuff; var o_buff: TAmicaBuff);
label unpack, hop, ret2;
var i, x, a: byte;
    _FBC, _FDE: integer;

    procedure SUB1; begin o_buff[_FBC] := a; INC(_FBC); end;
    procedure SUB2; begin a := i_buff[_FDE]; INC(_FDE); end;
begin
  _FBC := 0;
  _FDE := 0+2;
unpack:
  SUB2;
  if a = $c2 then goto hop;
  SUB1;
  goto unpack;
hop:
  SUB2;
  if a = 0 then goto ret2;
  x := a;
  SUB2;
  for i := 1 to x do SUB1;
  goto unpack;
ret2:
end;

procedure TC64.AMICA2KOALA(o_buff: TAmicaBuff; var koala: MULTIdata);
var i: integer;
begin
  for i := 0 to 8000-1 do koala.bitmap[i] := o_buff[i]; //320*200/8 = 8000
  for i := 0 to 1000-1 do koala.ink1[i] := o_buff[8000+i];   
  for i := 0 to 1000-1 do koala.ink2[i] := o_buff[8000+1000+i]; //$D800
  koala.backGr := o_buff[$F710-$c000] and $0f;
end;

//---

procedure TC64.LOGOload(ca: TCanvas);
var logo: LOGOdata;
    g: word;
    none: byte;
begin
  if not assigned(ca) then exit;
  read(f, none, none);
  for g := 0 to $1c00-$1800-1 do
    read(f,logo.logo[g]);
  for g := $1800-$1800 to $2000-$1c00-1 do
    read(f,none);
  for g := $2000-$2000 to $2800-$2000-1 do
    read(f,logo.bitmap[g]);
  LOGOshow(logo, ca);
end;

procedure TC64.FNTload(ca: TCanvas);
var fnt: FNTdata;
    g, h: byte;
begin
  if not assigned(ca) then exit;

  for g := 1 to 255 do for h := 0 to 7 do fnt.fnt[g, h] := 0;

  read(f, g, g);
  for g := 1 to 64 do
    for h := 0 to 7 do
      read(f, fnt.fnt[g, h]);
  for h := 1 to 40 do
    FNTshow(h*8-8, 0, fnt, ca, (h));
  for h := 1 to 24 do
    FNTshow(h*8-8, 8, fnt, ca, (40+h));
end;

procedure TC64.FNTBload(ca: TCanvas);
var fntb: FNTBdata;
    g, h, none: byte;
begin
  if not assigned(ca) then exit;

  read(f, none, none);
  for g := 1 to 64 do for h := 0 to 7 do read(f, fntb.fntb[g, h]);
  for g := 1 to 64 do for h := 0 to 7 do read(f, fntb.fntb[g, h+8]);
  for g := 1 to 64 do for h := 0 to 7 do read(f, fntb.fntb[g, h+16]);
  for g := 1 to 64 do for h := 0 to 7 do read(f, fntb.fntb[g, h+24]);

  for h := 1 to 20 do
    FNTBshow(h*16-16, 0, fntb, ca, (h));
  for h := 1 to 20 do
    FNTBshow(h*16-16, 16, fntb, ca, (20+h));
  for h := 1 to 20 do
    FNTBshow(h*16-16, 32, fntb, ca, (40+h));
  for h := 1 to 4 do
    FNTBshow(h*16-16, 48, fntb, ca, (60+h));
end;

procedure TC64.MOBloadHires(ca: TCanvas);
var mob: MOBdata;
    g: byte;
begin
  if not assigned(ca) then exit;

  mob.cnt := 1;
  read(f, g, g);
  while not eof(f) do
  begin
    for g := 0 to 63 do
    begin
      if not eof(f) then
        read(f, mob.mob[mob.cnt, g])
      else
        mob.mob[mob.cnt, g] := 0;
    end;
    inc(mob.cnt)
  end;
  dec(mob.cnt);

  for g := 1 to 13 do
    if g <= mob.cnt then
      hMOBshow(g*24-24, 0, mob, ca, (g)); //todo: more
end;

procedure TC64.MOBloadMulticolor(ca: TCanvas);
var mob: MOBdata;
    g: byte;
begin
  if not assigned(ca) then exit;

  mob.cnt := 1;
  read(f, g, g);
  while not eof(f) do
  begin
    for g := 0 to 63 do
    begin
      if not eof(f) then
        read(f, mob.mob[mob.cnt, g])
      else
        mob.mob[mob.cnt, g] := 0;
    end;
    inc(mob.cnt)
  end;
  dec(mob.cnt);

  for g := 1 to 13 do
    if g <= mob.cnt then
      mMOBshow(g*24-24, 0, mob, ca, (g)); //todo: more
end;

procedure TC64.FLIload(ca: TCanvas);
var fli: FLIdata;
    ifli: IFLIdata;
    temp: array[0..9] of byte;
    i, j: integer;
begin
  if not assigned(ca) then exit;

  read(f, temp[0], temp[1]);

	if (temp[0] = 0) and (temp[1] = $40) then //AFLI file
  begin
    showmessage('DEBUG: AFLI detected');
    for j := 0 to 7 do
      for i := 0 to 1023 do
        read(f, fli.chrmem[j][i]); //buff 2048 but 1024 loaded
    i := 0;
    while not eof(f) and (i < 16384) do // >= 8000 but max 16384
    begin
      read(f, fli.gfxmem[i]);
      inc(i);
    end;
    //if (i >= 8000) - ok, else file too short
    FLIshow(fli, ca, C64_AFLI);
    exit;
  end;

	if (temp[0] = 0) and ((temp[1] = $3b) or (temp[1] = $3c)) then  //FLI
  begin
    showmessage('DEBUG: FLI detected');  
    if (temp[1] = $3b) then //FLI file with background colors
    begin
      for i := 0 to 255 do read(f, fli.bgcol[i]);
    end;
    if (temp[1] = $3c) then //FLI file without background colors
    begin
      for i := 0 to 255 do fli.bgcol[i] := 0;
    end;
    for i := 0 to 1023 do
      read(f, fli.colmem[i]);
    for j := 0 to 7 do
      for i := 0 to 1023 do
        read(f, fli.chrmem[j][i]); //buff 2048 but 1024 loaded
    for i := 0 to 8000-1 do
      read(f, fli.gfxmem[i]);
    //if (i>=8000) ???
    FLIshow(fli, ca, C64_FLI);
    exit;
  end;

  if (temp[0] = $ff) and (temp[1] = $3b) then //BFLI or FFLI
  begin
    read(f, temp[2]);
    if (temp[2] = ord('b')) then //BFLI file
    begin
      showmessage('DEBUG: BFLI detected');

      for i := 0 to 1023 do read(f, fli.colmem[i]);  //Color mem is strange? why?

      //1st FLI color mem
      for i := 0 to 1000-1 do read(f, fli.chrmem[0][i]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 1000-1 do read(f, fli.chrmem[1][i]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 1000-1 do read(f, fli.chrmem[2][i]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 1000-1 do read(f, fli.chrmem[3][i]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 1000-1 do read(f, fli.chrmem[4][i]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 1000-1 do read(f, fli.chrmem[5][i]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 1000-1 do read(f, fli.chrmem[6][i]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 1000-1 do read(f, fli.chrmem[7][i]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);

      //1st gfx mem
      for i := 0 to 8000-1 do read(f, fli.gfxmem[i]);
      for i := 0 to 192-1 do read(f, fli.bgcol[i]);

      //2nd FLI color mem
      for i := 0 to 976-1 do read(f, fli.chrmem[0][i+1024]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 24-1 do read(f, fli.chrmem[0][i+1000]);
      
      for i := 0 to 976-1 do read(f, fli.chrmem[1][i+1024]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 24-1 do read(f, fli.chrmem[1][i+1000]);

      for i := 0 to 976-1 do read(f, fli.chrmem[2][i+1024]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 24-1 do read(f, fli.chrmem[2][i+1000]);

      for i := 0 to 976-1 do read(f, fli.chrmem[3][i+1024]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 24-1 do read(f, fli.chrmem[3][i+1000]);

      for i := 0 to 976-1 do read(f, fli.chrmem[4][i+1024]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 24-1 do read(f, fli.chrmem[4][i+1000]);

      for i := 0 to 976-1 do read(f, fli.chrmem[5][i+1024]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 24-1 do read(f, fli.chrmem[5][i+1000]);

      for i := 0 to 976-1 do read(f, fli.chrmem[6][i+1024]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 24-1 do read(f, fli.chrmem[6][i+1000]);

      for i := 0 to 976-1 do read(f, fli.chrmem[7][i+1024]);
      for i := 0 to 24-1 do read(f, fli.bgcol[i]);
      for i := 0 to 24-1 do read(f, fli.chrmem[7][i+1000]);

      //2nd gfx mem
      for i := 0 to 7808-1 do read(f, fli.gfxmem[i+8192]);
      for i := 0 to 192-1 do read(f, fli.bgcol[i]);
      for i := 0 to 192-1 do read(f, fli.gfxmem[i+8000]);

      FLIshow(fli, ca, C64_BFLI);
      exit;
    end
    else if (temp[2] = ord('f')) then //FFLI
    begin
      showmessage('DEBUG: FFLI detected');
      raise(Exception.Create('Can not convert FFLI pictures (yet)'));
    end
    else
    begin //unknown
      raise(Exception.Create('Unknown FLI file format ID '+inttostr(temp[2])));
    end;
  end;

(* Gunpaint IFLI format
		Start address = $4000, end = $c341
		$4000 - $6000     FLI screenmaps 1
		$6000 - $7f40     FLI bitmap 1
		$8000 - $8400     Colourmap  ($d800 colours)
		$8400 - $a400     FLI screenmaps 2
		$a400 - $c340     FLI bitmap 2
		$c341             ???   (doesn't seem to be important..)
*)

//IFLI based on: C64 Horizontal 'Interlaced' FLI By Pasi 'Albert' Ojala © 1991-1998

  if (temp[0] = $0) and (temp[1] = $3f) then //IFLI
  begin
    read(f, temp[2]);
    if (temp[2] = ord('I')) then //IFLI file
    begin
      showmessage('DEBUG: IFLI detected');

      for i := 0 to 8192-1 do read(f, ifli.chrmem1[i]);
      for i := 0 to 8192-1 do read(f, ifli.gfxmem1[i]);
      for i := 0 to 1024-1 do read(f, ifli.colmem[i]);
      for i := 0 to 8192-1 do read(f, ifli.chrmem2[i]);
      for i := 0 to 8192-1 do read(f, ifli.gfxmem2[i]); //...
	    //if (i) ok else fprintf(stderr, "Short file!\n");

      IFLIshow(ifli, ca);
    end
    else
      raise(Exception.Create('Unknown IFLI file format ID '+inttostr(temp[2])));
  end;

  raise(Exception.Create('Unknown FLI format (' + inttohex(temp[0], 2) + inttohex(temp[1], 2) + ')'));
end;

//---

function TC64.LoadMulticolorToBitmap(FileName: string; ca: TCanvas; mode: TC64FileType): integer;
begin
  case mode of
    C64_KOALA:      result := GenericLoader(FileName, KOALAload, ca, mode);
    C64_WIGMORE:    result := GenericLoader(FileName, WIGMOREload, ca, mode);
    C64_RUNPAINT:   result := GenericLoader(FileName, RUNPAINTload, ca, mode);
    C64_ISM:        result := GenericLoader(FileName, IMGSYSload, ca, mode);
    C64_PAINTMAGIC: result := GenericLoader(FileName, PAMAGload, ca, mode);
    C64_ADVARTST:   result := GenericLoader(FileName, ADVARTSTload, ca, mode);
    else result := -1;
  end;
end;

function TC64.LoadHiresToBitmap(FileName: string; ca: TCanvas; mode: TC64FileType): integer;
begin
  case mode of
    C64_HIRES : result := GenericLoader(FileName, HIRESload, ca, mode);
    C64_HED: result := GenericLoader(FileName, HIRESloadHED, ca, mode);
    C64_DDL: result := GenericLoader(FileName, HIRESloadDDL, ca, mode);
    C64_ISH: result := GenericLoader(FileName, HIRESloadISH, ca, mode);
    else result := -1;
  end;
end;

function TC64.LoadAmicaToBitmap(FileName: string; ca: TCanvas): integer;
begin
  result := GenericLoader(FileName, AMICAload, ca, C64_AMICA);
end;

function TC64.LoadLogoToBitmap(FileName: string; ca: TCanvas): integer;
begin
  result := GenericLoader(FileName, LOGOload, ca, C64_LOGO);
end;

function TC64.LoadFontToBitmap(FileName: string; ca: TCanvas): integer;
begin
  result := GenericLoader(FileName, FNTload, ca, C64_FNT);
end;

function TC64.LoadFont2x2ToBitmap(FileName: string; ca: TCanvas): integer;
begin
  result := GenericLoader(FileName, FNTBload, ca, C64_FNTB);
end;

function TC64.LoadMobToBitmap(FileName: string; ca: TCanvas): integer;
var loader: TC64Loader;
begin
  if FAsHires then
    loader := MOBloadHires 
  else
    loader := MOBloadMulticolor;
  result := GenericLoader(FileName, loader, ca, C64_MOB);
end;

function TC64.LoadFliToBitmap(FileName: string; ca: TCanvas): integer;
begin
  result := GenericLoader(FileName, FLIload, ca, C64_FLI);
end;

//---

function TC64.LoadC64ToBitmap(FileName: string; ca: TCanvas): integer;
var mode: TC64FileType;
begin
  FLastError := 'Unknown format extension';
  mode := ExtMapper(ExtractFileExt(FileName));
  case mode of
    C64_UNKNOWN:  result := -1;
    C64_KOALA,
    C64_WIGMORE,
    C64_RUNPAINT,
    C64_ISM,
    C64_PAINTMAGIC,
    C64_ADVARTST: result := LoadMulticolorToBitmap(FileName, ca, mode);
    C64_HIRES,
    C64_HED,
    C64_DDL,
    C64_ISH:      result := LoadHiresToBitmap(FileName, ca, mode);
    C64_AMICA:    result := LoadAmicaToBitmap(FileName, ca);
    C64_LOGO:     result := LoadLogoToBitmap(FileName, ca);
    C64_FNT:      result := LoadFontToBitmap(FileName, ca);
    C64_FNTB:     result := LoadFont2x2ToBitmap(FileName, ca);
    C64_MOB:      result := LoadMobToBitmap(FileName, ca);
    C64_MBF:      result := LoadMobToBitmap(FileName, ca);
    C64_FLI,
    C64_AFLI,
    C64_BFLI,
    C64_IFLI,
    C64_FFLI:     result := LoadFliToBitmap(FileName, ca);
    else
      result := -1;
  end;
end;

end.

