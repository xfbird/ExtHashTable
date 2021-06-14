unit DLog;
interface
uses
  Windows,SysUtils,Classes,Log4D;
//procedure DebugOutStr(Msg: string; boWriteDate: Boolean = True);overload;
//procedure DebugOutStr(Msg: Ansistring; boWriteDate: Boolean = True);overload;

//procedure Debug(Msg: string);
//procedure Error(Msg: string);
//procedure Fatal(Msg: string);
//procedure Trace(Msg: string);
//procedure Warn(Msg: string);
procedure SetLogLevel(lv: string);
function PrintCallStack(): string;
function getIntHex( a, len: integer): string;

procedure OutErrorLog(const sError: string; const Param: array of const; E: Exception); overload;
procedure OutErrorLog(const sError: string; E: Exception); overload;
procedure OutErrorLog(const sError: string; const Param: array of const); overload;
procedure OutErrorLog(const sError: string); overload;

procedure OutDebugLog(const sLog: string; const Param: array of const); overload;
procedure OutDebugLog(const sLog: string); overload;

procedure OutDataLog(const sLog: string; const Param: array of const); overload;
procedure OutDataLog(const sLog: string); overload;

//procedure OutSaveLog(HumanRCD: THumDataInfo; btWhere: byte; ID: integer);
procedure OutClickLog(const sLog: string);


var
  Log: Log4D.TLogLogger;

implementation

uses
Forms;

procedure OutErrorLog(const sError: string; const Param: array of const; E: Exception);
var
  dt1               : TDateTime;
  info, str1        : string;
begin
  try
    str1 := Format(sError, Param);      //�����쳣
  except
    str1 := 'Format_Err: ' + sError;
  end;

//  if Trim(sError) <> '' then
//  begin
//    dt1 := Now;
//    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + str1;
//    if E <> nil then
//      info := info + ' Except��' + E.Message + GetExceptStr;
//
    Log.Error(info);
//  end;
end;
//
procedure OutErrorLog(const sError: string; E: Exception);
var
  dt1               : TDateTime;
  info              : string;
begin
//  if Trim(sError) <> '' then
//  begin
//    dt1 := Now;
//    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + sError;
//    if E <> nil then
//      info := info + ' Except��' + E.Message + GetExceptStr;
//
    Log.Error(info+E.Message);
//  end;
end;

procedure OutErrorLog(const sError: string);
var
  dt1               : TDateTime;
  info              : string;
begin
  if Trim(sError) <> '' then
  begin
    dt1 := Now;
    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + sError;
   Log.Error(info);
  end;
end;

procedure OutErrorLog(const sError: string; const Param: array of const);
//var
//  dt1               : TDateTime;
//  info, str1        : string;
begin
//  try
//    str1 := Format(sError, Param);      //�����쳣
//  except
//    str1 := 'Format_Err: ' + sError;
//  end;
//
//  if Trim(sError) <> '' then
//  begin
//    dt1 := Now;
//    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + str1;
//   Log.Error(info);
//  end;
  Log.Error(sError,Param);
end;

procedure OutDebugLog(const sLog: string; const Param: array of const);
var
  dt1               : TDateTime;
  info, str1        : string;
begin
//  try
//    str1 := Format(sLog, Param);        //�����쳣
//  except
//    str1 := 'Format_Err: ' + sLog;
//  end;
//
//  if Trim(sLog) <> '' then
//  begin
//    dt1 := Now;
//    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + str1;
//
//    Log.Error(info);
//  end;
  Log.Debug(sLog,Param);
end;

procedure OutDebugLog(const sLog: string);
var
  dt1               : TDateTime;
  info              : string;
begin
  if Trim(sLog) <> '' then
  begin
    dt1 := Now;
    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + sLog;
    Log.Debug(info);
  end;
end;

procedure OutDataLog(const sLog: string; const Param: array of const);
var
  dt1               : TDateTime;
  info, str1        : string;
begin
  try
    str1 := Format(sLog, Param);        //�����쳣
  except
    str1 := 'Format_Err: ' + sLog;
  end;

  if Trim(sLog) <> '' then
  begin
    dt1 := Now;
    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + str1;

    Log.Debug(info);
  end;
end;

procedure OutDataLog(const sLog: string);
var
  dt1               : TDateTime;
  info              : string;
begin
  if Trim(sLog) <> '' then
  begin
    dt1 := Now;
    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + sLog;
    Log.Debug(info);
  end;
end;

procedure OutClickLog(const sLog: string);
var
  dt1               : TDateTime;
  info              : string;
begin
  if Trim(sLog) <> '' then
  begin
    dt1 := Now;
    info := '[' + FormatDateTime('yyyy-mm-dd hh:nn:ss:zzzz', dt1) + '] ' + sLog;
    Log.Debug(info);
  end;
end;


//
//procedure DebugOutStr(Msg: Ansistring; boWriteDate: Boolean);
//begin
//  {$IFDEF DEBUG}
//   DebugOutStr(String(Msg),boWriteDate);
//  {$ENDIF}
//end;
//
//procedure DebugOutStr(Msg: string; boWriteDate: Boolean);
//begin
//  {$IFDEF DEBUG}
//    Log.Debug('%s',[MSG]);
//  {$ENDIF}
//end;
//
//procedure Debug(Msg: string);
//begin
//  Log.Debug('%s',[MSG]);
//end;
//
//
//procedure Error(Msg: string);
//begin
//  Log.Error('%s',[MSG]);
//end;
//
//procedure Fatal(Msg: string);
//begin
//  Log.Fatal('%s',[MSG]);
//end;
//
//procedure Trace(Msg: string);
//begin
//  Log.Trace('%s',[MSG]);
//end;
//
//procedure Warn(Msg: string);
//begin
//  Log.Warn('%s',[MSG]);
//end;

procedure SetLogLevel(lv: string) ;
begin
   if  lv ='all' then Log.Level:=Log4D.All;
   if  lv =   'trace' then Log.Level:=Log4D.Trace;
   if  lv =   'debug' then Log.Level:=Log4D.Debug;
   if  lv =   'info' then Log.Level:=Log4D.Info;
   if  lv =   'warn' then Log.Level:=Log4D.Warn;
   if  lv =   'error' then Log.Level:=Log4D.Error;
   if  lv =   'fatal' then Log.Level:=Log4D.Fatal;
   if  lv =   'off' then Log.Level:=Log4D.Off;
//  Log.Level:=Log4D.All;
end;


function getIntHex(a, len: integer): string;//����ת��HEX�ַ���
var
  d: pchar;
  i: Integer;
begin
  getmem(d, len * 2);
  binToHex(@a, d, len);
  result := '';
  for i := len - 1 downto 0 do
    result := result + d[i * 2] + d[i * 2 + 1];
  freemem(d);
end;

function PrintCallStack(): string;
var
  curEBP, nextEBP, val1, val3: Cardinal;
  p: ^Cardinal;
begin
  asm
       mov curEBP,ebp  ;//ȡ�õ�ǰEBP
       mov eax,dword ptr ss:[ebp];
       mov  nextEBP,eax;//��һ���EBP
  end;
  val3 := 0;
  result := '';
  repeat
    p := Pointer(curEBP + 4);
    val1 := p^; //��һ��ĵ��ú����Ķϵ㣨��һ����ַ��
    val3 := val3 + 1;
    result := result + '= No.' + IntToStr(val3) + ' ==';
    result := result + '��ǰEBP:' + getIntHex(curEBP, SizeOf(curEBP))+' ';// + #13#10;
    result := result + '��һEBP:' + getIntHex(nextEBP, SizeOf(nextEBP))+' ';// + #13#10;
    result := result + '��һ�ϵ㣺' + getIntHex(val1, SizeOf(val1))+ #13#10;
    p := Pointer(curEBP);
    curEBP := p^;
    p := Pointer(curEBP);
    nextEBP := p^;
  until (nextEBP = 0) or (DWORD(p) >= $0012FFFC) ;//��ջ������
end;


procedure InitializeLog();
var
  cfg:   TStringList;
  fpath: string;
begin
  cfg:=TStringList.Create();

  fpath:= ExtractFilePath(Application.ExeName)+'Log\';
  if not DirectoryExists(fpath) then ForceDirectories(fpath);
  cfg.Add('log4d.configDebug=false');
  cfg.Add('log4d.threshold=all');
  cfg.Add('log4d.loggerFactory=TLogDefaultLoggerFactory');
  cfg.Add('log4d.rootLogger=all,ODS');
  cfg.Add('log4d.logger.AppLog=all,Mem1,FileLog');
  cfg.Add('log4d.appender.ODS=TLogODSAppender');
  cfg.Add('log4d.appender.ODS.layout=TLogSimpleLayout');
  cfg.Add('log4d.appender.Mem1=TMemoAppender');
  cfg.Add('log4d.appender.Mem1.memo=memLog');
  cfg.Add('log4d.appender.Mem1.layout=TLogPatternLayout');
  cfg.Add('log4d.appender.Mem1.layout.pattern=[%d %5p %6t %m%n]');
  cfg.Add('log4d.appender.Mem1.layout.dateFormat=dd.mm.yyyy hh:nn:ss.zzz');

  cfg.Add('log4d.appender.FileLog=TLogFileAppender');
  cfg.Add('log4d.appender.FileLog.append=true');
  cfg.Add('log4d.appender.FileLog.fileName='+fpath+ChangeFileExt(ExtractFileName(Application.ExeName),'.log')); //.\LogFiles\rLog4D.log');
  cfg.Add('log4d.appender.FileLog.errorHandler=TLogOnlyOnceErrorHandler');
  cfg.Add('log4d.appender.FileLog.layout=TLogPatternLayout');
  cfg.Add('log4d.appender.FileLog.layout.dateFormat=dd.mm.yyyy hh:nn:ss.zzz');
  cfg.Add('log4d.appender.FileLog.layout.pattern=[%d %5p %6t] %m%n');

  TLogPropertyConfigurator.Configure(cfg); //��ʱlog4d.props��exe������ͬһĿ¼
  Log := TLogLogger.GetLogger('AppLog'); //���ǻ��log4d.logger.testlog4d=error,File1��ע�����Ʊ���һ������д����
  cfg.Free();
//  FreeAndNil(cfg);
end;

initialization
  InitializeLog();
  Log.Debug('��־ϵͳ����');
finalization
//  FreeAndNil(Log);
end.
