unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls;

type

  { TFormMain }

  TFormMain = class(TForm)
    TimerGlitch: TTimer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormPaint(Sender: TObject);
    procedure TimerGlitchTimer(Sender: TObject);
  private
    Screenshot: TBitmap;
  public

  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

uses
  LCLType, LCLIntf
  {$ifdef LCLCocoa}
    CGContext, CocoaGDIObjects
  {$endif};

function TakeScreenshot: TBitmap;
var
  ScreenDC: HDC;
  ScreenBitmap: TBitmap;
begin
  Result := nil;
  ScreenDC := 0;
  // создаем ScreenBitmap для захвата экрана
  ScreenBitmap := TBitmap.Create;
  try
    // получаем контекст экрана
    ScreenDC := GetDC(0);
    // загружаем в ScreenBitmap скриншот экрана
    ScreenBitmap.LoadFromDevice(ScreenDC);
    // создаем Result для хранения скриншота, в "нативном" формате lcl.
    // т.к. на linux/osx формат изображения захваченного с помощью LoadFromDevice
    // может быть не "нативным" для lcl => его отрисовка может быть медленной.
    Result := TBitmap.Create;
    try
      // ресайзим Result под размер скриншота
      Result.SetSize(ScreenBitmap.Width, ScreenBitmap.Height);
      // отрисовываем скриншот на Result
      Result.Canvas.Draw(0, 0, ScreenBitmap);
    except
      // что-то пошло не так, уничтожаем Result, и перевозбуждаем исключение
      Result.Free;
      raise;
    end;
  finally
    ScreenBitmap.Free;
    ReleaseDC(0, ScreenDC);
  end;
end;

{ TFormMain }

procedure TFormMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caNone;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Sleep(5000);

  // снимаем скриншот экрана
  Screenshot := TakeScreenshot;

  // отключаем бордюр у формы
  BorderStyle := bsNone;
  // делаем окно на весь экран
  WindowState := wsFullScreen;
  // делаем окно поверх всех окон
  FormStyle := fsSystemStayOnTop;
  // отключаем курсор
  Cursor := crNone;
  // задаем черный цвет для формы
  Color := clBlack;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  Screenshot.Free;
end;

procedure TFormMain.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  if (Key = VK_Z) and (ssCtrl in Shift) then
    Halt;
end;

procedure TFormMain.FormPaint(Sender: TObject);
var
  I, J: Integer;
  SpanX, SpanY, SpanHeight: Integer;
  {$ifdef LCLCocoa}
  Context: CGContextRef;
  {$endif}
begin
  {$ifdef LCLCocoa}
  Context := CGContextRef(TCocoaContext(Canvas.Handle).CGContext);
  CGContextSaveGState(Context);
  CGContextScaleCTM(Context, 1 / GetCanvasScaleFactor, 1 / GetCanvasScaleFactor);
  {$endif}

  // рисуем фон
  if Random(31) <> 0 then
    Canvas.Draw(Random(11) - 5, 0, Screenshot)
  else
  begin
    Canvas.Brush.Color := clFuchsia;
    Canvas.FillRect(0, 0, Screenshot.Width, Screenshot.Height);
  end;

  // рисуем отрезки
  Canvas.Brush.Color := clBlack;
  for I := 0 to 11 do
  begin
    SpanHeight := 4 + Random(120);
    if Random(5) = 0 then
      SpanX := Random(121) - 60
    else
      SpanX := Random(31) - 15;
    SpanY := Random(Screenshot.Height);

    Canvas.FillRect(
      0, SpanY, // x1 y1
      Screenshot.Width, SpanY + SpanHeight // x2 y2
    );

    BitBlt(
      Canvas.Handle,// 1куда рисуем (назначение)
      SpanX, SpanY,// 23x и y в назначении
      Screenshot.Width, SpanHeight, //45 ширина и высота нарисованного кусочка изображения
      Screenshot.Canvas.Handle, //6 откуда рисуем (источник)
      0, SpanY, //78 x и y в источнике
      cmSrcCopy //9 просто копируем пикселы из источника в назначение
    );
  end;

  // глючные линии
  for J := 0 to Random(7) do
  begin
    SpanY := Random(Screenshot.Height);

    if Random(5) = 0 then
      Canvas.Pen.Color := clFuchsia
    else
      Canvas.Pen.Color := clLime;

    for I := 0 to Random(40) do
    begin
      if Random(3) = 0 then
        Canvas.Line(
          0, SpanY + I, // x1 y1
          Screenshot.Width, SpanY + I // x2 y2
        );
    end;
  end;

  Canvas.Font.Size := 20;
  Canvas.Font.Color := clRed;
  Canvas.Brush.Color := clBlack;
  Canvas.TextOut(0, 0, 'Ctrl+Z - Exit');

  {$ifdef LCLCocoa}
  CGContextRestoreGState(Context);
  {$endif}
end;

procedure TFormMain.TimerGlitchTimer(Sender: TObject);
begin
  ShowOnTop;
  Invalidate;
end;

end.

