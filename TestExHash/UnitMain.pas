unit UnitMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,ExHashTable,Dlog,uCalcTime;

type

  TMyThreadPool = Class;

  TMyThread = class(TThread)
  private
    FServer: TMyThreadPool;
  protected
    procedure Execute; override;
  public
    constructor Create(Server: TMyThreadPool);
  end;

  TMyThreadPool = Class
  private
    m_ID:Integer;
    m_FDCount:Integer;
    m_StrList:TStringList;
    m_Hash: TExHashTable;
    m_ISRun:Boolean;
    procedure ThreadProc();
  protected
  public
    constructor Create();virtual;
    property HashObj: TExHashTable read m_Hash Write m_Hash;                    //hash��
    property Strs: TStringList read m_StrList Write m_StrList;                  //�ַ�����
    property FDCount: Integer read m_FDCount Write m_FDCount;                   //�ֶ�ѭ����
    property ID: Integer read m_ID Write m_ID;                                  //�ڴ�ߴ�
    property ISRun: Boolean read m_ISRun Write m_ISRun;                                  //�ڴ�ߴ�
  End;

  TThreadPoolArray = Array Of TObject;

  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    EditCount: TEdit;
    EditThread: TEdit;
    Button3: TButton;
    Button5: TButton;
    Button4: TButton;
    Button6: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
  private
    { Private declarations }
    m_count:Integer;
    m_ThreadCount:Integer;
    mStringList:TStringList;
    tstHash:TExHashTable;
    Progs:TThreadPoolArray;
    m_i_Count:Integer;
    procedure FreeThreads();
  public
    { Public declarations }
    procedure ForRun(Obj:TStorageObj);
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
function RandomStr():String;
var
  i:Integer;
begin
  result:='';
  for i:= 0 to 30 - 1 do
  begin
    Result:=result+Char(65+Random(26));
  end;
end;

constructor TMyThread.Create(Server: TMyThreadPool);
begin
  FServer := Server;
  FreeOnTerminate := True;
  inherited Create(False);
end;

procedure TMyThread.Execute;
begin
  FServer.ThreadProc();
end;


constructor TMyThreadPool.Create();
begin
  m_ISRun:=False;
  TMyThread.Create(Self);
end;


procedure TForm1.FreeThreads;
var
  I:Integer;
  ThreadProg:TMyThreadPool;
begin
  for I := 0 to m_ThreadCount - 1 do
  begin
   ThreadProg:=TMyThreadPool(Progs[i]);
   if ThreadProg<>nil then
   begin
     ThreadProg.Free;
     OutDebugLog('ִ�����:%d  �ͷ��߳�',[i]);
     Progs[i]:=nil;
   end;
  end;
end;


procedure TMyThreadPool.ThreadProc;
var
  IdxStart,idxEnd,I:Integer;
begin
  while (not m_ISRun) do                                                        //�ȴ� ����
  begin
    sleep(10);
  end;
    IdxStart:= m_ID*m_FDCount;
    IdxEnd:= (m_ID+1)*m_FDCount;
    for i := IdxStart to IdxEnd - 1 do
    begin
       m_Hash.I[m_StrList[i]]:=i;
    end;
    InterlockedDecrement(Form1.m_i_Count);
    OutDebugLog('ִ�����:%d  �߳̽�������',[m_ID]);

end;

procedure TForm1.Button1Click(Sender: TObject);
var
  timec:TimeAssessment;
  I:Integer;
begin
  timec:=TimeAssessment.Create;
  m_count:=StrToIntDef(EditCount.Text,1000);
  m_ThreadCount:=StrToIntDef(EditThread.Text,10);
  SetLength(Progs,m_ThreadCount);
  OutDebugLog('���� �߳���:%d',[m_ThreadCount]);

  timec.StartTimer;
  for I := 0 to m_count - 1 do
  begin
      mStringList.AddObject(RandomStr,TObject(i+1));
  end;
  timec.EndTimeer;
  Memo1.Lines.Add(Format('����:%d �ַ���  ��ʱ:%s ',
                  [m_count,timec.asstring]));
  timec.Free;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  timec:TimeAssessment;
  I:Integer;
begin
  timec:=TimeAssessment.Create;
  tstHash.Clear;
  timec.StartTimer;
  for I := 0 to m_count - 1 do
  begin
     tstHash.I[mStringList[i]]:=i;
  end;
  timec.EndTimeer;
  Memo1.Lines.Add(Format('���߳� ���:%d �ַ����� hash ��ʱ:%s �ṹ��Ϣ:%s',
                  [m_count,timec.asstring,tstHash.Info]));
  timec.Free;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  timec:TimeAssessment;
  I:Integer;
  ThreadProg:TMyThreadPool;
  isAllok:Boolean;
  haveOne:Boolean;
begin
  if mStringList.Count>0 then
  begin
  timec:=TimeAssessment.Create;
  try
    try
      if tstHash.Count>0 then
      begin
        tstHash.Clear;
      end;
      m_i_Count:=m_ThreadCount;
      timec.StartTimer;
      OutDebugLog('����  %d ���߳� ���� ����',[m_ThreadCount]);
      for I := 0 to m_ThreadCount - 1 do
      begin
        ThreadProg:=TMyThreadPool.Create();
        Progs[i]:=ThreadProg;
        ThreadProg.m_ID:=i;
        ThreadProg.HashObj:=tstHash;
        ThreadProg.Strs:=mStringList;
        ThreadProg.FDCount:=m_count div m_ThreadCount;
        ThreadProg.ISRun:=True;
        OutDebugLog('ִ�����:%d  �����߳�����',
                   [ThreadProg.m_ID]);
      end;
    except
      on E: Exception do
      begin
          OutErrorlog('���߳���� %s',[' �����쳣'],E);
      end;
    end;

    while m_i_Count>0 do
    begin
      sleep(1);
    end;
   timec.EndTimeer;
   Memo1.Lines.Add(Format('���߳� ���:%d �ַ����� hash ��ʱ:%s �ṹ��Ϣ:%s',
                [m_count,timec.asstring,tstHash.Info]));

   FreeThreads;
  finally
    timec.Free;
  end;
  end else
  begin
      Memo1.Lines.Add('�ַ����� ��û�г�ʼ�� ��Ҫ��������ֵ������ʼ����ť');
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  i:Integer;
  tmpStr:TStringList;
  Obj:TStorageObj;
begin
  tstHash.Clear;
  for I := 0 to 20- 1 do
  begin
    tstHash.I[mStringList[i]]:=i;
  end;
  tmpStr:=TStringList.Create;
  try
    tstHash.ForListValue(tmpStr);
    for i := 0 to tmpStr.count - 1 do
    begin
      Obj:=TStorageObj(tmpStr.Objects[i]);
      if Obj<>nil then
        Memo1.Lines.Add(format('���"%d Name:%s info:%s',[i,tmpStr[i],Obj.GetInfo]));
    end;
  finally
    tmpStr.Free;
  end;
end;

procedure TForm1.Button5Click(Sender: TObject);
var
 tmcurlast,tmcurorg, tmcur:Integer;
begin
  tmcurorg:=m_i_Count;
  tmcur:=InterlockedIncrement(m_i_Count);
  tmcurlast:=m_i_Count;
  Memo1.Lines.Add(format('ԭʼ��ֵ:%d ���ӵõ���ֵ:%d ������ֵ:%d',[tmcurorg,tmcur,tmcurlast]));
   Memo1.Lines.Add(format('��ǰ��hash �������:%s',[tstHash.Info]));
end;


procedure TForm1.ForRun(Obj: TStorageObj);
begin
   Memo1.Lines.Add(format('info:%s',[Obj.GetInfo]));
end;


procedure TForm1.Button6Click(Sender: TObject);
var
  i:Integer;
begin
  for I := 0 to 20- 1 do
  begin
    tstHash.I[mStringList[i]]:=i;
  end;

   tstHash.ForEach(ForRun);
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
Randomize;
mStringList:=TStringList.Create;
tstHash:= TExHashTable.Create(128);
m_i_Count:=0;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeThreads;
  if tstHash<>nil then
  begin
    FreeAndNil(tstHash);
  end;
  if mStringList<>nil then
    FreeAndNil(mStringList);
end;


end.
