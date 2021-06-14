unit uCalcTime;

interface
   uses Windows,SysUtils,DLog;

type
  TimeAssessment = class
  private
     BaseTime:Int64;
     StartTime:Int64;
     EndTime:Int64;
     function GetValue:Int64;
  public
    constructor Create();
    destructor Destroy;override;
    procedure StartTimer;

    procedure EndTimeer;
    function AsString: String;
    property consume: Int64 read GetValue;
  end;

implementation

const
  _NeedTimeAssessmentD           = 0;

{ TimeAssessment }

constructor TimeAssessment.Create;
begin
  QueryPerformanceFrequency(BaseTime);
   {$IF _NeedTimeAssessmentD=1}
   OutDebugLog('实例:%x TimeAssessment.Create ',[integer(self)]);
   {$IFEND}
end;
destructor TimeAssessment.Destroy;
begin
   {$IF _NeedTimeAssessmentD=1}
   OutDebugLog('实例:%x TimeAssessment.Destroy ',[integer(self)]);
   {$IFEND}
  inherited;
end;
procedure TimeAssessment.EndTimeer;
begin
  QueryPerformanceCounter(EndTime); // 获取结束计数值
end;

function TimeAssessment.GetValue: Int64;
begin
  Result:= (EndTime - StartTime)*1000000000 div BaseTime;                             //结果是 ns
end;
function TimeAssessment.AsString: String;
var
  rtime:int64;
  rns:Int64;
  rus:Int64;
  rms:Int64;
  rs:Int64;
  rmin:int64;
  rhour:int64;
begin
  rns:=GetValue;
  if rns>1000 then
  begin
     rus:=rns div 1000;
     if rus>1000 then
     begin
        rms:=rus div 1000;
        if rms>1000 then
        begin
          rs:=rms div 1000;
          if rs>60 then
          begin
            rmin:=rs div 60;
            Result:=inttostr(rmin)+'min'+ inttostr(rs mod 1000)+'s' ;;
          end else
          begin
            Result:=inttostr(rs)+'s'+ inttostr(rms mod 1000)+'ms' ;;
          end;
        end else
        begin
          Result:=inttostr(rms)+'ms'+ inttostr(rus mod 1000)+'us' ;
        end;
     end else
     begin
       Result:=inttostr(rus)+'us' + inttostr(rns mod 1000)+'ns' ;
     end;
  end else
  begin
     Result:=inttostr(rns)+'ns';
  end;
end;

procedure TimeAssessment.StartTimer;
begin
  QueryPerformanceCounter(StartTime); // WINDOWS API 获取开始计数值
end;

end.
