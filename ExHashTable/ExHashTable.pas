
unit ExHashTable;
//================================================================================
//* 软件名称：开发包基础库
//* 单元名称：高性能 Hash 表单元
//* 单元作者：王琨改进于 CnVcl 的hashtable
//* 备    注：储存单元 支持 各种基本数据类型 存储的对象能够在自动释放，内存指针 也可以释放
//* 备    注：储存单元 支持 各种基本数据类型 标准指针 Pointer 释放是使用者责任
//* 备    注：本哈希 能够自动扩展需要的空间来 提升性能
//* 备    注：和标准的Map 不同在于，桶一级 使用排序数据来管理对象，搜索定位对象使用二分搜索
//* 备    注：如果 添加的对象 是当前有存储的，那么用新值覆盖。对象 内存指针 分别用Free FreeMem
//* 备    注：老的值 会释放。如果是标准指针，需要使用者 先释放，再添加。
//* 备    注：
//================================================================================
interface

{$DEFINE SUPPORT_INLINE}
uses
  SysUtils, Classes,Windows,uCalcTime{$IFDEF DEBUG},Dlog{$ENDIF};

const
  DefaultAutoRehashPoint = $100;                                                //每一个桶的容量  初始规模设置为 桶极限的
  DefaultDivNum          = 4;                                                   //默认 初始化 桶容量 为1/4
  //ExtendSizeMul        = 1;                                                 //每次扩展容量，扩展为以前的2倍  也就是 * 2
  CheckTimeWait          =2000000;                                              //2ms
  KeyNotFind    = $FFFFFFFF;
  _NeedExtHashD           = 1;

var
  MaxBucketsCount: Integer = $1000000;                                          //桶最大规模  16M
  MinBucketsCount: Integer = $10;                                               //桶最小规模 16

type
  TExHashTable = class;
  TStorageObj  = class;

  TQSortStringList = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  public
    constructor Create(const InitCapacity: Integer);

    function AddObject(const S: string; AObject: TObject): Integer; override;
    //function EnsureAddObject(const S: string; AObject: TObject): Integer;
  end;

  TExObjForeach = procedure(Obj:TStorageObj) of object;
  TExObjForeach1 = procedure(Obj:TStorageObj; param: Pointer) of object;        //遍历到 执行参数 就停止
  TExObjForeach2 = function(Obj:TStorageObj;param: Pointer): Boolean of object; //遍历到 就停止

  TExObjForeachL = procedure(Obj:TStorageObj);
  TExObjForeachL1 = procedure(Obj:TStorageObj; param: Pointer);
  TExObjForeachL2 = function(Obj:TStorageObj;param: Pointer): Boolean;          //遍历到 就停止

  TLHashForeach = procedure(key: string; value: Integer) of object;
  TLHashForeach1 = procedure(key: string; value: Integer; param: Pointer) of object;
  TLHashForeach2 = function(key: string; value: Integer; param: Pointer): Boolean of object; //遍历到 就停止

  TLHashForeachL = procedure(key: string; value: Integer);
  TLHashForEachL1 = procedure(key: string; value: Integer; param: Pointer);
  TLHashForEachL2 = function(key: string; value: Integer; param: Pointer): Boolean; //遍历到 就停止

  TStorageObjType = (tsBoolean,tsInteger,tsChar,tsWideChar,tsInt64,tsSingle,tsDouble,tsExtended,tsCurrency,tsPointer,tsObject,tsString,tsMemory);

  //存储对象 目标是 提供不同基础类型的 读写能力  两个主要标识  ID 是名字的hash 值
  TStorageObj  = class                                                          //存储对象
    private
      m_ID   : Cardinal;                                                        //标识符Hash
      m_Name  : String;                                                         //字符串标识符
      m_Type : TStorageObjType;                                                 //数据类型
      m_Value : record
         case TStorageObjType of
            tsBoolean: (m_boolean: boolean);
            tsChar:(m_char: char);
            tsWideChar:(m_WideChar: WideChar);
            tsSingle:(m_Single: Single);
            tsDouble:(m_Double: Double);
            tsExtended: (m_Extended: Extended);
            tsCurrency: (m_currency: Currency);
            tsInteger: (m_integer: Integer);
            tsInt64: (m_int64: Int64);
            tsObject: (m_object: TObject);
            tsMemory:(m_memp:Pointer);
            tsPointer:(m_Pointer:Pointer);
      end;                                                                      //存储空间，存放各类值
      m_String :string;                                                         //存放字符串
    public
      constructor Create(id: Cardinal; bt: TStorageObjType=tsInteger;name:String='');  //创建 整形Key
      destructor Destroy; override;
      class function GetMemorySize():Integer;                                          //内存尺寸
      function  GetInfo():String;

      function  AsStrBool():String;
      function  AsString():String;
      function  AsInteger():Integer;
      function  AsInt64():Int64;
      function  AsObject():TObject;
      function  AsPointer():Pointer;
      function  AsBoolean():Boolean;
      function  AsChar():Char;
      function  AsWideChar():WideChar;
      function  AsSingle():Single;
      function  AsDouble():Double;
      function  AsExtended():Extended;
      function  AsCurrency():Currency;
      function  AsMemory():Pointer;

      procedure SetValue(Value:String);overload;                                //字符串。
      procedure SetValue(Value:Int64);overload;                                 //整形Int64
      procedure SetValue(Value:Integer);overload;                               //整形
      procedure SetValue(Value:Boolean);overload;                               //布尔
      procedure SetValue(Value:Char);overload;                                  //字符
      procedure SetValue(Value:WideChar);overload;                              //宽字符
      procedure SetValue(Value:Single);overload;                                //单精度
      procedure SetDouble(Value:Double);                                        //双精度
      procedure SetExtended(Value:Extended);                                    //扩展
      procedure SetCurrency(Value:Currency);                                    //金融
      procedure SetValue(Value:TObject);overload;                               //对象 自动释放
      procedure SetValue(Value:Pointer);overload;                               //指针 由 使用者 自行释放
      procedure SetMemory(Value:Pointer);                                       //内存指针

      property ID: Cardinal read m_ID;                                          //Hash
      property Name: String read m_Name;                                        //名字
      property ObjType: TStorageObjType read m_Type;                            //类型

      //property MemorySize: Integer read GetMemorySize;                        //内存尺寸
   end;
  //桶对象，实现 一个二分排序表 构成的存储对象桶。
  //新加入的对象，如果Key 存在，那么比较名字，如果不同，添加在该对象后面
  //两个 字符串 hash 值相同，就算碰撞了。桶可以存储 碰撞的两个不同的字符串
  //hash 值相同，后增加的对象 插在 前面。
  TExtBucket = class(TPersistent)                                               //桶对象
    private
      m_List:  TList;                                                           //
      m_RWSync: TMREWSync;                                                      //
      m_Owner:  TExHashTable;                                                   //管理者
      {$IFDEF DEBUG}
      m_Time:TimeAssessment;
      {$ENDIF}
      procedure  IncOwnerCount;
      procedure  DecOwnerCount;

      function  GetCount:Integer;
      function GetCapacity():Integer;
      procedure AddObjInternal(Obj:TStorageObj);                                //对内无锁版
      procedure DeleteInternal(idx:Integer);                                    //对内的不带锁版本
      procedure ClearNoFree();
      function ExGetMemorySize:Integer;                                         //
      procedure Lock; virtual;
      procedure UnLock; virtual;                                                //解锁
      procedure RLock; virtual;
      procedure UnRLock; virtual;                                               //解锁
      function FindID(ID: Cardinal;var FindOk:Boolean): Integer;                //内存不操作 不加锁
    protected
    public
      constructor Create(owner:TExHashTable;InitCapacity:integer);              //创建 需要有父类管理对象 可以空
      destructor Destroy; override;                                             //释放
      class function GetMemorySize():Integer;                                   //内存尺寸
      procedure Clear;
      procedure Delete(idx:Integer);overload;                                   //删除 idx 位置处的对象
      function  Delete(S:String):Boolean;overload;                              //对外的 带锁版本
      function  DeleteKey(Key: Cardinal;S:String):Boolean;                      //对外的 带锁版本

      procedure ForEach(fn: TExObjForeach); overload;
      procedure ForEach(fn: TExObjForeach1; param: Pointer = nil); overload;
      function  ForEach(fn: TExObjForeach2; param: Pointer = nil):Boolean; overload;

      procedure ForEach(fn: TExObjForeachL); overload;
      procedure ForEach(fn: TExObjForeachL1; param: Pointer = nil); overload;
      function ForEach(fn: TExObjForeachL2; param: Pointer = nil):Boolean; overload;


      procedure ForEach(fn: TLHashForeach); overload;
      procedure ForEach(fn: TLHashForeach1; param: Pointer = nil); overload;
      function ForEach(fn: TLHashForeach2; param: Pointer = nil):Boolean; overload;

      procedure ForEach(fn: TLHashForEachL); overload;
      procedure ForEach(fn: TLHashForEachL1; param: Pointer = nil); overload;
      function ForEach(fn: TLHashForEachL2; param: Pointer = nil):boolean; overload;

      procedure ForListValue(var lstItems: TList);overload;
      procedure ForListValue(var lstItems: TStringList);overload;

      //function AddKey(Key:Cardinal;sid:string):TStorageObj;                   //添加一个 Key Sid
      //procedure AddObj(Obj:TStorageObj);                                      //添加对象 到内部
      function GetObj(Key:Cardinal;sid:string):TStorageObj;                     //仅获得对象，不存在就返回空
      function GetOrAddObj(Key: Cardinal; sid: string):TStorageObj;             //带锁的 获得,如果不存在就添加对象

      function GetIndexObj(idx: Cardinal):TStorageObj;

      function FindIndex(ID: Cardinal;var FindOk:Boolean): Integer;

      property Count: Integer read GetCount;
      property Capacity: Integer read GetCapacity;
      property MemorySize: Integer read ExGetMemorySize;                        //内存尺寸
    end;

  TDynArrayBucket = array of TExtBucket;
  //带扩展的哈希管理对象  使用快速的 哈希算法：MurmurHash
  //桶能够自动扩展  存储的单元 使用 改造的 TStorageObj 能够 存储 各种基本数据类型
  //使用 TMREWSync 来做锁，多个 读请求 不会锁住 对象，可以并发。但是 写入 会锁住所有读
  //因此 只要不是 重新hash 在表层面 其实多个线程可以同时操作。
  //到 桶的级别，如果不是插入，原则上 每一个桶上 也是并发的
  //当 有一个桶需要写入，此时需要等当前所有的读锁和写锁都解开。
  TExHashTable = class
  private
    FBuckets: TDynArrayBucket;                                                  //桶数组
    FBucketCount: Integer;                                                      //桶总数
    FElementCount: Integer;                                                     //总共的元素总数
    FAutoRehashPoint: Integer;                                                  //桶的容量 超过此数值，引发 重新Hash
    FInitCap        : integer;                                                  //默认 初始化 桶容量 为1/4
    FExtendRateBit  : integer;                                                  //每次扩展容量，扩展为以前的2倍  也就是 * 2
    m_RWSync: TMREWSync;                                                        //多线程锁
    {$IFDEF DEBUG}
      m_Time:TimeAssessment;
    {$ENDIF}

    procedure DoRehash(const iCount: Integer); {$IFDEF SUPPORT_INLINE} inline; {$ENDIF}
    procedure Rehash;
    procedure SetCapacity(value:Integer);

    function GetObj(const Index: string;NeedNew:Boolean=False):TStorageObj;     //获得一个对象，NeedNew 为True 那么 不存在对象，会创建
    procedure AddObjNoLock(Obj:TStorageObj);

    function GetString(const Index: string): string;
    procedure SetString(const Index: string; const Value: string);

    function GetStObj(const Index: string): TStorageObj;
    procedure SetStObj(const Index: string; const Value: TStorageObj);

    function GetInteger(const Index: string): Integer;
    procedure SetInteger(const Index: string; const Value: Integer);

    function GetObject(const Index: string): TObject;
    procedure SetObject(const Index: string; Value: TObject);

    function GetPointer(const Index: string): Pointer;
    procedure SetPointer(const Index: string; Value: Pointer);

    function GetMemory(const Index: string): Pointer;
    procedure SetMemory(const Index: string; Value: Pointer);

    function GetBoolean(const Index: string): Boolean;
    procedure SetBoolean(const Index: string; Value: Boolean);

    function GetInt64(const Index: string): Int64;
    procedure SetInt64(const Index: string; Value: Int64);

    function GetChar(const Index: string): Char;
    procedure SetChar(const Index: string; Value: Char);

    function GetWideChar(const Index: string): WideChar;
    procedure SetWideChar(const Index: string; Value: WideChar);

    function GetSingle(const Index: string): Single;
    procedure SetSingle(const Index: string; Value: Single);

    function GetDouble(const Index: string): Double;
    procedure SetDouble(const Index: string; Value: Double);
    function GetExtended(const Index: string): Extended;
    procedure SetExtended(const Index: string; Value: Extended);
    function GetCurrency(const Index: string): Currency;
    procedure SetCurrency(const Index: string; Value: Currency);
    function ExGetMemorySize:Integer;
    procedure Lock; virtual;
    procedure UnLock; virtual;                                                  //解锁
    procedure RLock; virtual;
    procedure UnRLock; virtual;                                                 //解锁
  protected
    FRehashCount: Integer;
    function GetCount: Integer; virtual;                                        //
    function GetNewBucketCount(OldSize: Integer): Integer; virtual;             //
    function FindBucket(const S: string;var Key:Cardinal): TExtBucket;overload; {$IFDEF SUPPORT_INLINE} inline; {$ENDIF}
    function HashOf(const S: string): Cardinal;virtual;
    function HashOfKey(Key: Cardinal): Cardinal;overload;
    function LimitBucketCount(I: Integer): Integer; virtual;
    procedure RehashTo(NewSize: Integer; const InitCapacity: Integer = 0); virtual;
  public
    //初始化默认值  桶 16个 最小，扩展容量极限 32（桶规模超过32 扩展） //初始化容量比率为 1/4容量 0 表示 初始化容量为0 //扩张 率 是 1 也就是 2倍 2表示 4倍。
    constructor Create(const BucketSize:integer=16;ExtendLimit:integer=32;InitCapRate:integer=4;ExtendRateBit:Integer=1);
    destructor Destroy; override;
    function GetMemorySize: Integer;                                            //内存尺寸
    class function Hash(const S: string): Cardinal;                             //计算Hash 32位的值

    procedure Clear; virtual;
    procedure Delete(const S: string);
    function Exists(const S: string): Boolean;                                  //检查是否存在 S 的存储对象
    function Info: string; virtual;

    procedure ForEach(fn: TExObjForeach); overload;
    procedure ForEach(fn: TExObjForeach1; param: Pointer = nil); overload;
    procedure ForEach(fn: TExObjForeach2; param: Pointer = nil); overload;

    procedure ForEach(fn: TExObjForeachL); overload;
    procedure ForEach(fn: TExObjForeachL1; param: Pointer = nil); overload;
    procedure ForEach(fn: TExObjForeachL2; param: Pointer = nil); overload;

    procedure ForEach(fn: TLHashForeach); overload;
    procedure ForEach(fn: TLHashForeach1; param: Pointer = nil); overload;
    procedure ForEach(fn: TLHashForeach2; param: Pointer = nil); overload;

    procedure ForEach(fn: TLHashForEachL); overload;
    procedure ForEach(fn: TLHashForEachL1; param: Pointer = nil); overload;
    procedure ForEach(fn: TLHashForEachL2; param: Pointer = nil); overload;

    procedure ForListValue(var lstItems: TList); overload;
    procedure ForListValue(var lstItems:TStringList);overload;
    procedure ForListValue(var lstItems:TQSortStringList);overload;

    property AutoRehashPoint: Integer read FAutoRehashPoint write FAutoRehashPoint default DefaultAutoRehashPoint;
    property Count: Integer read GetCount;
    property Capacity :Integer Read FBucketCount Write SetCapacity;

    property SO[const Index: string]: TStorageObj read GetStObj write SetStObj; default;  //获得存储对象
    property O[const Index: string]: TObject read GetObject write SetObject;              //存储和 取出 外部对象
    property P[const Index: string]: Pointer read GetPointer write SetPointer;            //春初 和取出 指针
    property S[const Index: string]: string read GetString write SetString;               //字符串
    property M[const Index: string]: Pointer read GetMemory write SetMemory;              //内存指针  会自动释放
    property B[const Index: string]: boolean read GetBoolean write SetBoolean;            //布尔
    property I[const Index: string]: Integer read GetInteger write SetInteger;
    property IE[const Index: string]: Int64 read GetInt64 write SetInt64;

    property CC[const Index: string]: Char read GetChar write SetChar;
    property CW[const Index: string]: WideChar read GetWideChar write SetWideChar;
    //
    property FS[const Index: string]: Single read GetSingle write SetSingle;
    property FD[const Index: string]: Double read GetDouble write SetDouble;
    property FE[const Index: string]: Extended read GetExtended write SetExtended;
    property FC[const Index: string]: Currency read GetCurrency write SetCurrency;
    property MemorySize: Integer read ExGetMemorySize;                          //内存尺寸

  end;

implementation

function sfMurmurHash(const Key: PAnsichar; Len: Integer): Cardinal;
const
  m: Cardinal = $5BD1E995;
  r: Integer = 24;
  seed: Integer = 97;
var
  h, k: Cardinal;
  data: PAnsichar;
  A: array [0 .. 3] of Byte;
begin
  h := seed xor Len;
  data := Key;
  while (Len >= 4) do
  begin
    k := PCardinal(data)^;
    k := k * m;
    k := k xor (k shr r);
    k := k * m;
    h := h * m;
    h := h xor k;
    Inc(data, 4);
    Dec(Len, 4);
  end;
  case Len of
    3:
      begin
        Integer(A) := PInteger(data)^;
        A[3] := 0;
        h := h xor Integer(A);
        h := h * m;
      end;
    2:
      begin
        h := h xor PWord(data)^;
        h := h * m;
      end;
    1:
      begin
        h := h xor PByte(data)^;
        h := h * m;
      end;
  end;
  h := h xor (h shr 13);
  h := h * m;
  h := h xor (h shr 15);
  Result := h;
end;

function QuickCompareStrings(const S1, S2: string): Integer;
type
  PByte = ^Byte;
  TByteArray = array[0..0] of Byte;
  PByteArray = ^TByteArray;
  PInteger = ^Integer;
var
  LStr1, LStr2, LStr1Char1, LStr2Char1, LLength1, LLength2,
    LCompInd, LLengthDif, LChars1, LChars2: Integer;
begin
  LStr1 := Integer(S1);
  LStr2 := Integer(S2);
  if LStr1 <> LStr2 then
  begin
    if LStr1 <> 0 then
    begin
      if LStr2 <> 0 then
      begin
        LStr1Char1 := PByte(LStr1)^;
        LStr2Char1 := PByte(LStr2)^;
        if LStr1Char1 <> LStr2Char1 then  // 比较首字节，可能要改成 Unicode 下比较首字符？
        begin
          Result := LStr1Char1 - LStr2Char1;
        end
        else
        begin
          LLength1 := PInteger(LStr1 - SizeOf(Integer))^;
          LLength2 := PInteger(LStr2 - SizeOf(Integer))^;
          LLengthDif := LLength1 - LLength2;
          if LLengthDif >= 0 then
            LCompInd := - LLength2 * SizeOf(Char)
          else
            LCompInd := - LLength1 * SizeOf(Char); // 往前找，根据各自的字符长度比较

          if LCompInd < 0 then
          begin
            Dec(LStr1, LCompInd);
            Dec(LStr2, LCompInd);
            repeat
              LChars1 := PInteger(@PByteArray(LStr1)[LCompInd])^;
              LChars2 := PInteger(@PByteArray(LStr2)[LCompInd])^;
              if LChars1 <> LChars2 then
              begin
                if SmallInt(LChars1) <> SmallInt(LChars2) then
                begin
                  Result := (Byte(LChars1) shl 8) + Byte(LChars1 shr 8)
                    - (Byte(LChars2) shl 8) - Byte(LChars2 shr 8);
                  Exit;
                end
                else
                begin
                  if LCompInd > -3 then
                    Break;
                  Result := (LChars1 shr 24) + ((LChars1 shr 8) and $ff00)
                    - (LChars2 shr 24) - ((LChars2 shr 8) and $ff00);
                  Exit;
                end;
              end;
              Inc(LCompInd, SizeOf(Integer));
            until LCompInd >= 0;
          end;
          Result := LLengthDif;
        end;
      end
      else
      begin
        Result := PInteger(LStr1 - SizeOf(Integer))^;
      end;
    end
    else
    begin
      Result := LStr1 - PInteger(LStr2 - SizeOf(Integer))^;
    end;
  end
  else
  begin
    Result := 0;
  end;
end;

{ TStorageObj }
procedure TStorageObj.SetValue(Value: Int64);
begin
 m_Value.m_int64:=Value;
 m_Type:=tsInt64;
end;

procedure TStorageObj.SetValue(Value: String);
begin
    m_Type:=tsString;                                                           //设置字符串类型
    m_String:=Value;
end;

procedure TStorageObj.SetValue(Value: TObject);
begin
 m_Value.m_object:=Value;
 m_Type:=tsObject;                                                              //设置字符串类型
end;

procedure TStorageObj.SetMemory(Value: Pointer);
begin
 m_Value.m_memp:=Value;
 m_Type:=tsMemory;
end;

procedure TStorageObj.SetValue(Value: Pointer);
begin
 m_Value.m_Pointer:=Value;
 m_Type:=tsPointer;                                                             //设置字符串类型
end;

constructor TStorageObj.Create(id: Cardinal; bt: TStorageObjType=tsInteger;name:String='');
begin
  inherited Create;
  m_ID:=id;                                                                     //标识符
  m_type :=bt;                                                                  //数据类型
  m_Name:=name;
  case m_type of
    tsBoolean:m_Value.m_boolean:=false;
    tsInteger:m_Value.m_integer:=0;
    tsChar:m_Value.m_char:=#0;
    tsWideChar:m_Value.m_WideChar:=#0;
    tsInt64:m_Value.m_int64:=0;
    tsExtended:m_Value.m_Extended:=0.0;
    tsCurrency:m_Value.m_currency:=0.0;
    tsPointer:m_Value.m_Pointer:=nil;
    tsObject:m_Value.m_object:=nil;
    tsMemory:m_Value.m_memp:=nil;
    tsString:m_Value.m_int64:=0;
  end;
  m_String:='';
end;

destructor TStorageObj.Destroy;
begin
    case m_type of
      tsObject:
      begin
          if m_Value.m_object<>nil then
          begin;
            FreeAndNil(m_Value.m_object);
          end;
      end;
      tsMemory:
      begin
        if m_Value.m_memp<>nil then
          FreeMem(m_Value.m_memp);
      end;
    end;
  if m_String<>'' then m_String:='';
  if m_Name<>'' then m_Name:='';
  inherited Destroy;
end;

function TStorageObj.GetInfo: String;
var
  tmpList:TList;
  i:Integer;
begin
    case m_Type of
      tsBoolean:Result:=Format('ID:%u Name:%s 布尔:%s',[m_ID,m_Name,AsStrBool]);
      tsInteger:Result:=Format('ID:%u Name:%s 整形:%d',[m_ID,m_Name,m_Value.m_integer]);
      tsChar:Result:=Format('ID:%u Name:%s 字符#:%d',[m_ID,m_Name,m_Value.m_char]);
      tsWideChar:Result:=Format('ID:%u Name:%s 宽字符#:%d',[m_ID,m_Name,integer(m_Value.m_WideChar)]);
      tsInt64:Result:=Format('ID:%u Name:%s 64位整形:%d',[m_ID,m_Name,m_Value.m_int64]);
      tsSingle:Result:=Format('ID:%u Name:%s 单精度#:%f',[m_ID,m_Name,m_Value.m_Single]);
      tsDouble:Result:=Format('ID:%u Name:%s 双精度字符#:%f',[m_ID,m_Name,m_Value.m_Double]);
      tsExtended:Result:=Format('ID:%u Name:%s 扩展精度#:%f',[m_ID,m_Name,m_Value.m_Extended]);
      tsCurrency:Result:=Format('ID:%u Name:%s 金融精度#:%f',[m_ID,m_Name,m_Value.m_Currency]);
      tsPointer:Result:=Format('ID:%u Name:%s 指针:%x',[m_ID,m_Name,m_Value.m_Pointer]);
      tsObject:
      begin
        if m_Value.m_object<>nil then
        begin
          try
            Result:=Format('ID:%u Name:%s 对象实例:%x 对象类名:%s',[m_ID,m_Name,integer(m_Value.m_object),m_Value.m_object.ClassName]);
          except
            Result:=Format('ID:%u Name:%s 对象实例:%x 获取对象名失败',[m_ID,m_Name,integer(m_Value.m_object)]);
          end;
        end;
      end;
      tsString:Result:=Format('ID:%u Name:%s 字符串:%s',[m_ID,m_Name,m_String]);
      tsMemory:Result:=Format('ID:%u Name:%s 内存指针:%x',[m_ID,m_Name,m_Value.m_memp]);
    end;
end;

class function TStorageObj.GetMemorySize: Integer;
begin
  Result := Self.InstanceSize;
end;

procedure TStorageObj.SetValue(Value: Char);
begin
    m_Type:=tsChar;                                                           //设置字符串类型
    m_Value.m_Char:=Value;

end;

procedure TStorageObj.SetValue(Value: WideChar);
begin
    m_Type:=tsWideChar;                                                           //设置字符串类型
    m_Value.m_WideChar:=Value;

end;

procedure TStorageObj.SetValue(Value: Integer);
begin
    m_Value.m_Integer:=Value;
    m_Type:=tsInteger;                                                           //设置整形类型
end;

procedure TStorageObj.SetValue(Value: Boolean);
begin
    m_Type:=tsBoolean;                                                           //设置字符串类型
    m_Value.m_Boolean:=Value;

end;

procedure TStorageObj.SetExtended(Value: Extended);
begin
    m_Type:=tsExtended;                                                           //设置字符串类型
    m_Value.m_Extended:=Value;

end;

procedure TStorageObj.SetCurrency(Value: Currency);
begin
    m_Type:=tsCurrency;                                                           //设置字符串类型
    m_Value.m_Currency:=Value;
end;

procedure TStorageObj.SetValue(Value: Single);
begin
    m_Type:=tsSingle;                                                           //设置字符串类型
    m_Value.m_Single:=Value;
end;

procedure TStorageObj.SetDouble(Value: Double);
begin
    m_Type:=tsDouble;                                                           //设置字符串类型
    m_Value.m_Double:=Value;
end;

function TStorageObj.AsBoolean: Boolean;
begin
  Result:=m_Value.m_boolean;
end;

function TStorageObj.AsChar: Char;
begin
  Result:=m_Value.m_char;
end;

function TStorageObj.AsCurrency: Currency;
begin
  Result:=m_Value.m_currency;
end;

function TStorageObj.AsDouble: Double;
begin
  Result:=m_Value.m_Double;
end;

function TStorageObj.AsExtended: Extended;
begin
  Result:=m_Value.m_Extended;
end;

function TStorageObj.AsInt64: Int64;
begin
  Result:=m_Value.m_int64;
end;

function TStorageObj.AsInteger: Integer;
begin
  Result:=m_Value.m_integer;
end;

function TStorageObj.AsMemory: Pointer;
begin
  Result:=m_Value.m_memp;
end;

function TStorageObj.AsObject: TObject;
begin
  Result:=m_Value.m_object;
end;

function TStorageObj.AsPointer: Pointer;
begin
  Result:=m_Value.m_Pointer;
end;

function TStorageObj.AsSingle: Single;
begin
  Result:=m_Value.m_Single;
end;

function TStorageObj.AsStrBool: String;
begin
  Result:='False';
  if m_Value.m_boolean then
  begin
  Result:='True';
  end;
end;

function TStorageObj.AsString: String;
begin
  Result:=m_String;
end;

function TStorageObj.AsWideChar: WideChar;
begin
  Result:=m_Value.m_WideChar;
end;


{$ifopt R+}
  {$define RangeCheckWasOn}
  {$R-}
{$endif}
{$ifopt Q+}
  {$define OverflowCheckWasOn}
  {$Q-}
{$endif}

{ TExtBucket }
//function TExtBucket.AddKey(Key:Cardinal;sid:string): TStorageObj;
//var
//  Index:Integer;
//  isFind:Boolean;
//  PosObj:TStorageObj;
//begin
//  lock;
//  try
//    Index:=FindID(Key,isFind);                                                    //找寻目标的位置
//    if (not isFind)and(Index>=0) then                                             //没找到 正确。
//    begin
//      Result:=TStorageObj.Create(Key,tsInteger,sid);                             //创建对象
//      if (m_List.Count>0) and (Index<m_List.Count) then                          //表中有内容
//      begin
//          PosObj:=TStorageObj(m_List[Index]);                                     //获得对象
//          if PosObj<>nil then
//          begin
//            if Key>PosObj.m_ID then
//            begin
//              inc(Index);
//            end;
//            if Index>=0 then
//            begin
//              m_List.Insert(Index,Result);
//              IncOwnerCount;
//            end else
//            begin
//              Result:=nil;
//              Exit;
//            end;
//          end else
//          begin
//          end;
//      end else
//      begin
//          m_List.Add(Pointer(Result));                                            //将对象添加到尾部
//          IncOwnerCount;
//      end;
//    end else
//    begin
//      Result:=TStorageObj.Create(Key,tsInteger,sid);                             //创建对象
//      if (Index>=0)and(Index<m_List.Count) then
//      begin
//          m_List.Insert(Index,Result);
//          IncOwnerCount;
//      end else
//      begin
//        Result.Free;
//        Result:=nil;
//        //啥情况 需要输出看看
//      end;
//    end;
//  finally
//    UnLock;
//  end;
//end;


//procedure TExtBucket.AddObj(Obj: TStorageObj);
//begin
//  lock;
//  try
//     AddObjInternal(Obj);
//  finally
//    unlock;
//  end;
//end;

procedure TExtBucket.AddObjInternal(Obj: TStorageObj);
var
  Index:Integer;
  isfind:Boolean;
  Posobj:TStorageObj;
begin
//   lock;
//   try
      Index:=FindID(Obj.m_ID,isFind);                                              //找寻目标的位置
      if (not isFind)and(Index>=0) then                                            //没找到 正确。
      begin
        if (m_List.Count>0) and (Index<m_List.Count) then                          //表中有内容
        begin
          PosObj:=TStorageObj(m_List[Index]);                                      //位置处对象
          if PosObj<>nil then
          begin
            if Obj.m_ID>PosObj.m_ID then
            begin
              inc(Index);
            end;
            if Index>=0 then
            begin
              m_List.Insert(Index,Obj);
              IncOwnerCount;
            end;
          end else
          begin
              //异常
          end;
        end else
        begin
          m_List.Add(Obj);                                                        //将对象添加到尾部
          IncOwnerCount;
        end;
      end else
      begin                                                                        //基于 Key 找到了
        Posobj:=TStorageObj(m_List[Index]);                                        //获得位置处对象
        while (Posobj<>nil) and (Posobj.m_ID=Obj.m_ID) do                          //找到相同的
        begin
          if QuickCompareStrings(Posobj.Name,Obj.Name)=0 then
          begin
            Exit;                                                                  //相同对象,退出不添加
          end;
          //没找到。                                                               //Key不相同，name不同
          inc(Index);                                                              //下一个位置
          if Index<m_List.Count then
              Posobj:=TStorageObj(m_List[Index])                                    //还有有效对象
          else
              break;                                                                //结束了
        end;
          m_List.Insert(Index,Obj);                                                  //对象添加再尾部
          IncOwnerCount;
      end;
//   finally
//     unlock;
//   end;
end;

procedure TExtBucket.Clear;
var
  i:Integer;
begin
   if m_List.Count>0 then
   begin
     lock;
     try
       for I := 0 to m_List.Count - 1 do
       begin
          if m_List[i]<>nil then
            TStorageObj(m_List[i]).Free;
       end;
       m_List.Clear;
       {$IF _NeedExtHashD=1}
       OutDebugLog('实例:%x TExtBucket.Clear 执行完成',[integer(self)]);
       {$IFEND}
     finally
       unlock;
     end;
   end;
end;

procedure TExtBucket.ClearNoFree;
begin
    m_List.Clear;
end;

constructor TExtBucket.Create(owner:TExHashTable;InitCapacity:integer);
begin
   inherited Create;
   m_Time:=TimeAssessment.Create;
   m_Owner:=owner;
   m_RWSync:=TMREWSync.Create;
   m_List:=TList.Create;
   if InitCapacity > 0 then
     m_List.Capacity:=InitCapacity;
   {$IF _NeedExtHashD=1}
    OutDebugLog('TExtBucket.Create 实例:%x Create',[integer(self)]);
   {$IFEND}
end;
destructor TExtBucket.Destroy;
var
  i:Integer;
begin
    Clear;                                                                        //清理 所有的对象
    {$IF _NeedExtHashD=1}
    OutDebugLog('实例:%x TExtBucket.Clear and Free mList',[integer(self)]);
    {$IFEND}
    if m_List<>nil then FreeAndNil(m_List);
    if m_RWSync<>nil then FreeAndNil(m_RWSync);                                   //释放 锁
    if m_Time<>nil then FreeAndNil(m_Time);
    {$IF _NeedExtHashD=1}
    OutDebugLog('实例:%x TExtBucket.Destroy 结束',[integer(self)]);
    {$IFEND}
    inherited Destroy;
end;

procedure TExtBucket.DecOwnerCount;
begin
   if m_Owner<>nil then
      InterlockedDecrement(m_Owner.FElementCount);
end;

procedure TExtBucket.Delete(idx: Integer);
var
  obj:TStorageObj;
begin
  if (idx>=0)and(idx<m_List.Count) then
  begin
    lock;
    try
      Obj:=TStorageObj(m_List[idx]);
      Obj.Free;
      m_List.Delete(idx);
      DecOwnerCount;
    finally
      unlock;
    end;
  end;
end;

function TExtBucket.Delete(S: String): Boolean;
var
  Key:Cardinal;
begin
     Key:=TExHashTable.Hash(S);                                                 //计算hash
     Result:=DeleteKey(Key,S);
end;

procedure TExtBucket.DeleteInternal(idx: Integer);
var
  obj:TStorageObj;
begin
  if (idx>=0)and(idx<m_List.Count) then
  begin
      Obj:=TStorageObj(m_List[idx]);
      Obj.Free;
      m_List.Delete(idx);
      DecOwnerCount;
  end;
end;

function TExtBucket.DeleteKey(Key: Cardinal;S:String):Boolean;
var
  Index:Integer;
  ISFind:Boolean;
  Obj:TStorageObj;
begin
   result:=False;
   lock;
   try
     Index:=FindID(Key,isFind);                                                 //找到对应该对象在桶的位置
     if isFind and (Index<m_List.Count) then                                    //成功找到。并且索引在范围内
     begin
      Obj:=TStorageObj(m_List[Index]);                                          //获得对象
      while (Obj<>nil) and (Obj.m_ID=Key) do                                    //Key 值相同的情况下
      begin
        if QuickCompareStrings(Obj.Name,S)=0 then                               //Key 相同 名字相同 才是正主
        begin
           DeleteInternal(Index);                                                   //就是它，删除之
           Result:=True;
           break;
        end;
        inc(Index);                                                             //继续下一个
        if Index>=m_List.Count then break;                                      //到结束位置了。
      end;
    end;
  finally
    UnLock;
  end;
end;

procedure TExtBucket.Lock;
begin
   {$IF _NeedExtHashD=1}
      OutDebugLog('实例:%x TExtBucket.Lock Wait',[integer(self)]);
   {$IFEND}
   m_Time.StartTimer;
   m_RWSync.BeginWrite;
   m_Time.EndTimeer;
   {$IF _NeedExtHashD=1}
    if m_Time.consume>CheckTimeWait then
      begin
          OutDebugLog('实例:%x  TExtBucket.Lock 等待时间:%s',[integer(self),m_Time.AsString]);
      end;
      OutDebugLog('实例:%x TExtBucket.Lock Wait Ok',[integer(self)]);
   {$IFEND}
end;

procedure TExtBucket.RLock;
begin
   {$IF _NeedExtHashD=1}
      //OutDebugLog('实例:%x TExtBucket.RLock Wait',[integer(self)]);
   {$IFEND}
   m_Time.StartTimer;
   m_RWSync.BeginRead;
   m_Time.EndTimeer;
   {$IF _NeedExtHashD=1}
   if m_Time.consume>CheckTimeWait then
   begin
      OutDebugLog('实例:%x TExtBucket.RLock 等待时间:%s',[integer(self),m_Time.AsString]);
   end;
    //OutDebugLog('实例:%x TExtBucket.RLock Wait Ok',[integer(self)]);
   {$IFEND}
end;

procedure TExtBucket.UnLock;
begin
   m_Time.StartTimer;
   {$IF _NeedExtHashD=1}
     //OutDebugLog('实例:%x TExtBucket.UnLock Wait',[integer(self)]);
   {$IFEND}
   m_RWSync.EndWrite;
   m_Time.EndTimeer;
   if m_Time.consume>CheckTimeWait then
   begin
   {$IF _NeedExtHashD=1}
      OutDebugLog('TExtBucket.UnLock 等待时间:%s',[m_Time.AsString]);
   {$IFEND}
   end;
   {$IF _NeedExtHashD=1}
     //OutDebugLog('实例:%x TExtBucket.UnLock Wait Ok',[integer(self)]);
   {$IFEND}
end;

procedure TExtBucket.UnRLock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExtBucket.UnRLock Wait',[integer(self)]);
   {$IFEND}
   m_RWSync.EndRead;
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExtBucket.UnRLock Wait Ok',[integer(self)]);
   {$IFEND}
end;


function TExtBucket.ExGetMemorySize: Integer;
begin
  Result:=GetMemorySize+m_List.Count*TStorageObj.GetMemorySize;
end;

function TExtBucket.FindID(ID: Cardinal;var FindOk:Boolean): Integer;
var
  Obj:TStorageObj;
  nStart,nEnd :Integer;
begin
  Result:=0;
  FindOk:=False;
  if m_List.Count>0 then                                                        //如果数量为0 直接标识没找到
  begin
      nStart:=0;
      nEnd:=m_List.Count-1;
      while nstart<=nend do
      begin
         Result:= (nstart + nend) div 2;
         Obj:=TStorageObj(m_List[Result]);                                      //获得中位的数据项
         if ID <Obj.ID then
         begin
           nend:=Result-1;                                                      //index:=0 就在0位置添加
         end else if ID> Obj.ID then
         begin
           nstart:=Result+1;
         end else if ID =Obj.ID  then
         begin
           FindOK:=True;
           break;
         end else
         begin
           inc(Result);
           break;
         end;
      end;
  end else
  begin
  end;
end;

function TExtBucket.FindIndex(ID: Cardinal; var FindOk: Boolean): Integer;
begin
  rlock;
  try
    Result:=FindID(ID,FindOk);
  finally
    unrlock;
  end;
end;

procedure TExtBucket.ForEach(fn: TExObjForeachL);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          fn(SObj);
       end;
    end;
  finally
    UnRLock;
  end;
end;

procedure TExtBucket.ForEach(fn: TExObjForeach1; param: Pointer);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          fn(SObj,param);
       end;
    end;
  finally
    UnRLock;
  end;
end;

procedure TExtBucket.ForEach(fn: TExObjForeach);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          fn(SObj);
       end;
    end;
  finally
    UnRlock;
  end;
end;

procedure TExtBucket.ForEach(fn: TExObjForeachL1; param: Pointer);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          fn(SObj,param);
       end;
    end;
  finally
    UnRlock;
  end;
end;

procedure TExtBucket.ForEach(fn: TLHashForEachL1; param: Pointer);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          fn(SObj.Name,SObj.AsInteger,param);
       end;
    end;
  finally
    UnRlock;
  end;
end;

procedure TExtBucket.ForListValue(var lstItems: TList);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) then
       begin
          lstItems.Add(Pointer(SObj));
       end;
    end;
  finally
    UnRlock;
  end;
end;
procedure TExtBucket.ForListValue(var lstItems: TStringList);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) then
       begin
          lstItems.AddObject(SObj.Name,SObj);
       end;
    end;
  finally
    UnRlock;
  end;
end;

procedure TExtBucket.ForEach(fn: TLHashForEachL);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          fn(SObj.Name,SObj.AsInteger);
       end;
    end;
  finally
    UnRlock;
  end;
end;

procedure TExtBucket.ForEach(fn: TLHashForeach1; param: Pointer);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          fn(SObj.Name,SObj.AsInteger,param);
       end;
    end;
  finally
    UnRlock;
  end;
end;

function TExtBucket.ForEach(fn: TExObjForeach2; param: Pointer): Boolean;
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  Result:=True;
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          if not fn(SObj,param) then
          begin
            Result:=False;
            break;
          end;
       end;
    end;
  finally
    UnRlock;
  end;
end;

procedure TExtBucket.ForEach(fn: TLHashForeach);
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          fn(SObj.m_Name,sObj.AsInteger);
       end;
    end;
  finally
    UnRlock;
  end;
end;

function TExtBucket.GetCapacity: Integer;
begin
   Result:=m_List.Capacity;
end;

function TExtBucket.GetCount: Integer;
begin
   Result:=m_List.Count;
end;

function TExtBucket.GetObj(Key: Cardinal; sid: string): TStorageObj;
var
  Obj:TStorageObj;
  index:Cardinal;
  isFind:Boolean;
  ss:string;
begin
  result:=nil;
  RLock;
  try
    Index:=FindID(Key,isFind);                                                  //找到对应该对象在桶的位置
    //OutDebugLog('TQuickKVList.GetObj 针对:%u 找寻位置成功: 得到位置结果:%u',[Key,Integer(isFind),Index]);
    if isFind and (Index<m_List.Count) then                                     //成功找到。并且索引在范围内
    begin
      Result:=TStorageObj(m_List[Index]);                                       //获得对象
      while (Result<>nil) and (Result.m_ID=Key) do
      begin
        //OutDebugLog('TQuickKVList.GetObj 针对:%u 找寻:%d 位置成功 取出结果:%d',[Key,Index,integer(Result)]);
        ss:= Result.Name;
        //if QuickCompareStrings(Result.Name,sid)=0 then Exit;                  //确实找到
        if QuickCompareStrings(ss,sid)=0 then break;                            //确实找到
        //没找到。
        inc(Index);
        if Index<m_List.Count then
          Result:=TStorageObj(m_List[Index])
        else
          break;
      end;
      Result:=nil;
    end;
   {$IF _NeedExtHashD=1}
    OutDebugLog('实例:%x TExHashTable.GetOrAddObj 查询获得对象:%s 得到结果:%x',[integer(self),Index,Integer(Result)]);
    {$IFEND}
  finally
    UnRLock;
  end;
end;

function TExtBucket.GetOrAddObj(Key: Cardinal; sid: string): TStorageObj;
var
  OK,isFind:Boolean;
  Index:Integer;
  NeedCheckReHash:Boolean;
begin
  OK:=False;
  NeedCheckReHash:=False;
  lock;
  try
    Index:=FindID(Key,isFind);                                                  //找到对应该对象在桶的位置
    {$IF _NeedExtHashD=1}
       OutDebugLog('TExtBucket.GetOrAddObj 针对:%u:%s 定位到:%d 位置 找到标志%D',
                   [Key,Sid,Index,integer(isFind)]);
    {$IFEND}
    if isFind and (Index<m_List.Count) then                                     //成功找到。并且索引在范围内
    begin
      Result:=TStorageObj(m_List[Index]);                                       //获得对象
      while (Result<>nil) and (Result.m_ID=Key) do
      begin
        {$IF _NeedExtHashD=1}
           OutDebugLog('TExtBucket.GetOrAddObj 针对:%u:%s 找到位置:%d对象 ：%x ',
                       [Key,Sid,Index,integer(isFind)]);
        {$IFEND}
        if QuickCompareStrings(Result.Name,sid)=0 then
        begin
          {$IF _NeedExtHashD=1}
             OutDebugLog('TExtBucket.GetOrAddObj 针对:%u:%s 找到位置:%d对象 ：%x 确认名称相同',
                         [Key,Sid,Index,integer(isFind)]);
          {$IFEND}

          OK:=True;                                                             //确实找到  返回
          break;
        end;
        {$IF _NeedExtHashD=1}
        OutDebugLog('TExtBucket.GetOrAddObj 针对:%u:%s 定位到:%d 位置,存在同哈希对象:%x 名字:%s ',
                    [Key,Sid,integer(Result),Result.Name]);
        {$IFEND}
        inc(Index);                                                             //继续下一个位置检查
        if Index>=m_List.Count then  break;                                     //如果到 结束还没有找到
        Result:=TStorageObj(m_List[Index]);                                     //获得索引位置的对象
      end;
    end;
    if not OK then                                                              //没找到 需要创建一个
    begin                                                                       //没找到
      Result:=TStorageObj.Create(Key,tsInteger,sid);                            //创建对象  默认用整形
      if (Index>=0)and(Index<m_List.Count) then                                 //index 在 范围内，添加到 存储表
      begin
          m_List.Insert(Index,Result);                                          //插入到指定位置
          {$IF _NeedExtHashD=1}
          OutDebugLog('TExtBucket.GetOrAddObj 针对:%u:%s 定位到:%d 位置 添加创建对象:%x',
                      [Key,sid,Index, integer(Result)]);
          {$IFEND}
      end else
      begin
         m_List.Add(Result);
         {$IF _NeedExtHashD=1}
         OutDebugLog('TExtBucket.GetOrAddObj 针对:%u:%s 定位到:%d 位置 是尾部 添加创建对象:%x',
                      [Key,sid,Index, integer(Result)]);
         {$IFEND}
      end;
      IncOwnerCount;                                                            //上级计数增加
      NeedCheckReHash:=true;
    end;
   {$IF _NeedExtHashD=1}
    OutDebugLog('实例:%x TExHashTable.GetOrAddObj 查询Key:%u:%s 并创建对象 得到结果:%x',
                [integer(self),Key,sid,Integer(Result)]);
   {$IFEND}
  finally
    unlock;
  end;
  if (NeedCheckReHash) and(m_Owner<>nil) then  m_Owner.DoRehash(Count);         //检查 是否需要重新 hash 锁 已经恢复
end;

procedure TExtBucket.IncOwnerCount;
begin
  if m_Owner<>nil then
     InterlockedIncrement(m_Owner.FElementCount);
end;

function TExtBucket.GetIndexObj(idx: Cardinal): TStorageObj;
begin
  Result:=nil;
  rlock;
  try
    if idx<m_List.Count then Result:=TStorageObj(m_List[idx]);
  finally
    unRLock;
  end;
end;

class function TExtBucket.GetMemorySize: Integer;
begin
  Result := Self.InstanceSize;
end;

function TExtBucket.ForEach(fn: TExObjForeachL2; param: Pointer): Boolean;
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  Result:=True;
  rLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          if not fn(SObj,param) then
          begin
            Result:=False;
            break;
          end;
       end;
    end;
  finally
    unRLock;
  end;
end;

function TExtBucket.ForEach(fn: TLHashForeach2; param: Pointer): Boolean;
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  Result:=True;
  RLock;
  try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          if not fn(SObj.Name,SObj.AsInteger,param) then
          begin
            Result:=False;
            break;
          end;
       end;
    end;
  finally
    UnRLock;
  end;
end;

function TExtBucket.ForEach(fn: TLHashForEachL2; param: Pointer): boolean;
var
  I             : Integer;
  SObj          : TStorageObj;
begin
  Result:=True;
  RLock;
  Try
    for I := 0 to m_List.Count - 1 do
    begin
       SObj:=TStorageObj(m_List[i]);
       if (SObj<>nil) and assigned(fn) then
       begin
          if not fn(SObj.Name,SObj.AsInteger,param) then
          begin
            Result:=False;
            break;
          end;
       end;
    end;
  Finally
    UnRLock;
  End;
end;

procedure TExHashTable.AddObjNoLock(Obj: TStorageObj);                          //内部添加，完全无锁，操作前已经完全锁定
begin
    FBuckets[HashOfKey(Obj.m_ID)].AddObjInternal(Obj);                          //得到按照hash 获得桶对象。
end;

procedure TExHashTable.ForListValue(var lstItems:TStringList);
var
  I             : Integer;
begin
  rLock;
  try
    for I := 0 to FBucketCount - 1 do
    begin
       TExtBucket(FBuckets[i]).ForListValue(lstItems);
    end;
  finally
    unrlock;
  end;
end;

procedure TExHashTable.ForListValue(var lstItems:TQSortStringList);             //快速排序字符串表
var
  I             : Integer;
begin
  rLock;
  try
    for I := 0 to FBucketCount - 1 do
    begin
       TExtBucket(FBuckets[i]).ForListValue(TStringList(lstItems));
    end;
  finally
    UnRlock;
  end;
end;

procedure TExHashTable.Clear;
var
  I: Integer;
begin
  lock;
  try
    for I := 0 to FBucketCount - 1 do
      FBuckets[I].Clear;
    FElementCount:=0;
  finally
    unlock;
  end;
end;

//任务删除所有的 对象，因对象需要被重新使用，所以 不释放 这些对象。
//初始化桶尺寸，桶规模扩展限制点，初始化容量比例，扩容的扩张倍率
constructor TExHashTable.Create(const BucketSize:integer=16;ExtendLimit:integer=32;InitCapRate:integer=4;ExtendRateBit:Integer=1);
var
  I: Integer;
begin
  inherited Create;
  {$IFDEF DEBUG}
   m_Time:=TimeAssessment.Create;
  {$ENDIF}
  m_RWSync:=TMREWSync.Create;

  FInitCap:= InitCapRate;                                                       //初始化 容量率，为0 表示 不预先初始化
  if FInitCap<>0 then FInitCap:=ExtendLimit div InitCapRate;                    //初始化容量比例 默认是 1/4
  FExtendRateBit:=ExtendRateBit;
  if FExtendRateBit>=6 then FExtendRateBit:=6;                                  //最大扩张 32倍
  //  FAutoRehashPoint := DefaultAutoRehashPoint;                               //设置默认值
  FAutoRehashPoint:=ExtendLimit;                                                //设置 自动扩张检查点
  if (FAutoRehashPoint<=0)  or (FAutoRehashPoint>10000) then FAutoRehashPoint:=DefaultAutoRehashPoint; //设置超界 设置为
  FBucketCount := LimitBucketCount(BucketSize);
  SetLength(FBuckets, FBucketCount);
  for I := 0 to FBucketCount - 1 do
  begin
    FBuckets[I] := TExtBucket.Create(self,FInitCap);
  end;
  {$IF _NeedExtHashD=1}
  OutDebugLog('实例:%x TExHashTable.Create 完成',[integer(self)]);
  {$IFEND}
end;

destructor TExHashTable.Destroy;
var
  I: Integer;
begin
  try
    for I := 0 to FBucketCount - 1 do
      FBuckets[I].Free;
  except
   {$IF _NeedExtHashD=1}
   OutDebugLog('实例:%x TExHashTable.Destory For Free 异常',[integer(self)]);
   {$IFEND}
  end;
  setlength(FBuckets,0);
  if m_RWSync<>nil then
    begin
      FreeAndNil(m_RWSync);
    end;
  {$IFDEF DEBUG}
    if m_Time<>nil then FreeAndNil(m_Time);
  {$ENDIF}
  {$IF _NeedExtHashD=1}
   OutDebugLog('实例:%x TExHashTable.Destroy 完成',[integer(self)]);
  {$IFEND}
  inherited Destroy;
end;

procedure TExHashTable.Delete(const S: string);
var
  Key:Cardinal;
begin
  FindBucket(S,Key).DeleteKey(Key,S);
end;


procedure TExHashTable.Lock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExHashTable.Lock Wait',[integer(self)]);
   {$IFEND}
   m_Time.StartTimer;
   m_RWSync.BeginWrite;
   m_Time.EndTimeer;
   {$IFDEF DEBUG}
   if m_Time.consume>CheckTimeWait then
   begin
     {$IF _NeedExtHashD=1}
      OutDebugLog('实例:%x TExHashTable.Lock 等待时间:%s',[integer(self),m_Time.AsString]);
      {$IFEND}
   end;
   {$ENDIF}
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExHashTable.Lock WaitOK',[integer(self)]);
   {$IFEND}
end;

procedure TExHashTable.RLock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExHashTable.RLock Wait',[integer(self)]);
   {$IFEND}

   m_Time.StartTimer;
   m_RWSync.BeginRead;
   m_Time.EndTimeer;
   {$IFDEF DEBUG}
   if m_Time.consume>CheckTimeWait then
   begin
     {$IF _NeedExtHashD=1}
      OutDebugLog('实例:%x TExHashTable.RLock 等待时间:%s',[integer(self),m_Time.AsString]);
      {$IFEND}
   end;
   {$ENDIF}
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExHashTable.RLock WaitOk',[integer(self)]);
   {$IFEND}
end;

procedure TExHashTable.UnLock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExHashTable.UnLock Wait',[integer(self)]);
   {$IFEND}
   m_RWSync.EndWrite;
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExHashTable.UnLock Wait Ok',[integer(self)]);
   {$IFEND}
end;

procedure TExHashTable.UnRLock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExHashTable.UnRLock Wait',[integer(self)]);
   {$IFEND}
   m_RWSync.EndRead;
   {$IF _NeedExtHashD=1}
   //OutDebugLog('实例:%x TExHashTable.UnRLock Wait Ok',[integer(self)]);
   {$IFEND}
end;


procedure TExHashTable.DoRehash(const iCount: Integer);
begin
  if (FRehashCount >= 0) and (iCount > FAutoRehashPoint) then                   //检查每一个桶是否大于 重hash 点规模
    begin
      {$IF _NeedExtHashD=1}
       OutDebugLog('FRehashCount:%d iCount:%d FAutoRehashPoint:%d',[FRehashCount,iCount,FAutoRehashPoint]);
      {$IFEND}
      Rehash;
    end;
end;

//procedure TExHashTable.EndUpdate;
//begin
//  Dec(FUpdateCount);
//  if FUpdateCount = 0 then
//  begin
//    SetUpdateState(False);
//  end;
//end;


function TExHashTable.ExGetMemorySize: Integer;
var
  i:Integer;
begin
  Result:=0;
  for I := 0 to FBucketCount - 1 do
  begin
    Result:=Result+FBuckets[i].MemorySize;
  end;
  Result:=Result+InstanceSize;
end;

function TExHashTable.Exists(const S: string): Boolean;
var
  Obj:TStorageObj;
begin
  Obj:= GetObj(S);
  Result:=Obj<>nil;
end;

procedure TExHashTable.ForEach(fn: TLHashForeach2; param: Pointer);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     if not TExtBucket(FBuckets[i]).ForEach(fn,param) then exit;
  end;
end;

procedure TExHashTable.ForEach(fn: TLHashForeach1; param: Pointer);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     TExtBucket(FBuckets[i]).ForEach(fn,param);
  end;
end;

procedure TExHashTable.ForEach(fn: TLHashForeach);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     TExtBucket(FBuckets[i]).ForEach(fn);
  end;
end;

procedure TExHashTable.ForEach(fn: TLHashForEachL2; param: Pointer);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
    if not TExtBucket(FBuckets[i]).ForEach(fn,param) then exit;
  end;
end;

procedure TExHashTable.ForEach(fn: TExObjForeach2; param: Pointer);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
    if not TExtBucket(FBuckets[i]).ForEach(fn,param) then exit;
  end;
end;

procedure TExHashTable.ForEach(fn: TExObjForeach1; param: Pointer);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     TExtBucket(FBuckets[i]).ForEach(fn,param);
  end;
end;

procedure TExHashTable.ForEach(fn: TExObjForeach);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     TExtBucket(FBuckets[i]).ForEach(fn);
  end;
end;

procedure TExHashTable.ForEach(fn: TExObjForeachL);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     TExtBucket(FBuckets[i]).ForEach(fn);
  end;
end;

procedure TExHashTable.ForEach(fn: TExObjForeachL2; param: Pointer);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     if not TExtBucket(FBuckets[i]).ForEach(fn,param) then exit;
  end;
end;

procedure TExHashTable.ForEach(fn: TExObjForeachL1; param: Pointer);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     TExtBucket(FBuckets[i]).ForEach(fn,param);
  end;
end;

procedure TExHashTable.ForEach(fn: TLHashForEachL1; param: Pointer);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     TExtBucket(FBuckets[i]).ForEach(fn,param);
  end;
end;

procedure TExHashTable.ForEach(fn: TLHashForEachL);
var
  I             : Integer;
begin
  for I := 0 to FBucketCount - 1 do
  begin
     TExtBucket(FBuckets[i]).ForEach(fn);
  end;
end;

procedure TExHashTable.ForListValue(var lstItems: TList);
var
  I             : Integer;
begin
  rLock;
  try
    for I := 0 to FBucketCount - 1 do
    begin
       TExtBucket(FBuckets[i]).ForListValue(lstItems);
    end;
  finally
    unRLock;
  end;
end;

function TExHashTable.FindBucket(const S: string;var Key:Cardinal): TExtBucket;
begin
  Key:=Hash(S);                                                                 //计算hash
  rlock;
  try
    Result := FBuckets[HashOfKey(Key)];                                           //得到按照hash 获得桶对象。
  finally
    unrlock;
  end;
end;

function TExHashTable.GetObject(const Index: string): TObject;
var
  Obj:TStorageObj;
begin
  Result := nil;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsObject();
end;

function TExHashTable.GetPointer(const Index: string): Pointer;
var
  Obj:TStorageObj;
begin
  Result := nil;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsPointer();
end;

procedure TExHashTable.SetObject(const Index: string; Value: TObject);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;


procedure TExHashTable.SetPointer(const Index: string; Value: Pointer);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;


function TExHashTable.GetBoolean(const Index: string): Boolean;
var
  Obj:TStorageObj;
begin
  Result:= False;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsBoolean();
end;

function TExHashTable.GetChar(const Index: string): Char;
var
  Obj:TStorageObj;
begin
  Result := #0;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsChar;
end;

function TExHashTable.GetCount: Integer;
begin
  //BuildBucketCounts;
  Result := FElementCount;
end;

function TExHashTable.GetCurrency(const Index: string): Currency;
var
  Obj:TStorageObj;
begin
  Result := 0.0;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsCurrency;
end;

function TExHashTable.GetDouble(const Index: string): Double;
var
  Obj:TStorageObj;
begin
  Result := 0.0;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsDouble;
end;

function TExHashTable.GetExtended(const Index: string): Extended;
var
  Obj:TStorageObj;
begin
  Result := 0.0;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsExtended;
end;

function TExHashTable.GetInt64(const Index: string): Int64;
var
  Obj:TStorageObj;
begin
  Result := -1;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsInt64;
end;

function TExHashTable.GetInteger(const Index: string): Integer;
var
  Obj:TStorageObj;
begin
  Result := -1;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsInteger();
end;


function TExHashTable.GetMemory(const Index: string): Pointer;
var
  Obj:TStorageObj;
begin
  Result := nil;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsMemory();
end;


function TExHashTable.GetNewBucketCount(OldSize: Integer): Integer;
begin
  Result := OldSize shl FExtendRateBit;
end;

function TExHashTable.GetObj(const Index: string;NeedNew:Boolean=False): TStorageObj;
var
  Key:Cardinal;
  KVList:TExtBucket;
begin
  if NeedNew then
  begin
   {$IF _NeedExtHashD=1}
    OutDebugLog('实例:%x TExHashTable.GetObj 查询并创建对象：%s ',[integer(self),Index]);
    {$IFEND}
    Result:=FindBucket(Index,Key).GetOrAddObj(Key,Index);                       //有读锁定位桶。之后是写锁
  end else
  begin
   {$IF _NeedExtHashD=1}
    OutDebugLog('实例:%x TExHashTable.GetObj 查询获取对象：%s ',[integer(self),Index]);
    {$IFEND}
    Result:=FindBucket(Index,Key).GetObj(Key,Index);                            //有读锁的定位桶，在桶获得节点 有读锁
  end;
end;

function TExHashTable.GetSingle(const Index: string): Single;
var
  Obj:TStorageObj;
begin
  Result := 0.0;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsSingle();
end;

function TExHashTable.GetStObj(const Index: string): TStorageObj;
begin
  Result:=GetObj(Index);
end;

function TExHashTable.GetString(const Index: string): String;
var
  Obj:TStorageObj;
begin
  Result := '';
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsString();
end;

function TExHashTable.GetWideChar(const Index: string): WideChar;
var
  Obj:TStorageObj;
begin
  Result := #0;
  Obj:=GetObj(Index);
  if Obj<>nil then
       Result:=Obj.AsWideChar();
end;

class function TExHashTable.Hash(const S: string): Cardinal;
begin
    Result:=sfMurmurHash(Pointer(S),Length(S)*SizeOf(Char));
end;
function TExHashTable.HashOfKey(Key: Cardinal): Cardinal;
begin
  Result :=Key mod (FBucketCount - 1);
end;

function TExHashTable.HashOf(const S: string): Cardinal;
begin
  Result :=Hash(s) and (FBucketCount - 1);
end;

resourcestring
  //StrHashTableInfo = 'Count:%d; Buckets:%d; Max:%d; Min:%d; Spare:%d; Rehash:%d';
  StrHashTableInfo = '元素总量:%d; 桶数量:%d; 桶元素最大:%d; 桶元素最小:%d; 空桶:%d 重新hash次数:%d 实例尺寸:%d  存储对象的实例尺寸:%d';

function TExHashTable.Info: string;
var
  I, iMaxElement, iMinElement, iSpareElement, iCount: Integer;
begin
  iMaxElement := 0;
  iMinElement := MaxInt;
  iSpareElement := 0;
  iCount := 0;
  for I := 0 to FBucketCount - 1 do
  begin
    with FBuckets[I] do
    begin
      if Count = 0 then
      begin
        Inc(iSpareElement);                                                     //空桶
        iMinElement := 0;                                                       //最少 元素 为0
      end
      else
      begin
        Inc(iCount, Count);                                                     //增加 总数 加上本桶 数量
        if iMaxElement < Count then
          iMaxElement := Count;                                                 //最大元素
        if iMinElement > Count then
          iMinElement := Count;                                                 //最小元素袁术
      end;
    end;
  end;
  Result := Format(StrHashTableInfo, [iCount, FBucketCount, iMaxElement, iMinElement, iSpareElement, FRehashCount,MemorySize,ExGetMemorySize]);
end;

function TExHashTable.LimitBucketCount(I: Integer): Integer;
begin
  Result := I;
  if Result < MinBucketsCount then
  begin
    Result := MinBucketsCount;
  end
  else if Result > MaxBucketsCount then
  begin
    Result := MaxBucketsCount;
  end;
end;

function TExHashTable.GetMemorySize: Integer;
begin
 Result := Self.InstanceSize;
end;

procedure TExHashTable.Rehash;
var
  NewSize: Integer;
begin
  FRehashCount := -FRehashCount;                                                //设置为
  try
    if FBucketCount >= MaxBucketsCount then
    begin
      Exit;
    end;
    NewSize := LimitBucketCount(GetNewBucketCount(FBucketCount));
    {$IF _NeedExtHashD=1}
      OutDebugLog('实例:%x 需要重hash 当前:%d 扩展到:%d ',
               [integer(self),FBucketCount,NewSize]);
    {$IFEND}
    RehashTo(NewSize,FInitCap);
  finally
    FRehashCount := -FRehashCount;
  end;
end;

procedure TExHashTable.RehashTo(NewSize: Integer; const InitCapacity: Integer);
var
  TmpBuckets: TDynArrayBucket;
  TmpBucketSize: Integer;
  BucketObj:TExtBucket;
  Obj:TStorageObj;
  I, j: Integer;
begin
  Assert(NewSize > 0);
  lock;                                                                         //表级锁
  if NewSize = FBucketCount then
  begin
    {$IF _NeedExtHashD=1}
      //OutDebugLog('实例:%x 需要重hash 当前:%d 已经扩展到:%d 所以不需要再做',
      //           [integer(self),FBucketCount,NewSize]);
    {$IFEND}
    unlock;
    Exit;
  end;
  try
    TmpBucketSize := FBucketCount;
    TmpBuckets := Copy(FBuckets, 0, TmpBucketSize);
    FBucketCount := NewSize;
    SetLength(FBuckets, FBucketCount);
    for I := 0 to FBucketCount - 1 do
    begin
      FBuckets[I] := TExtBucket.Create(self,InitCapacity);
    end;
    //    if FUpdateCount > 0 then
    //    begin
    //      SetUpdateState(True);
    //    end;
    for I := 0 to TmpBucketSize - 1 do
    begin
      BucketObj:=TmpBuckets[I];
      if BucketObj<>nil  then
      begin
        BucketObj.lock;                                                           //锁住桶
        try
          for j := 0 to BucketObj.Count - 1 do
          begin
             Obj:=BucketObj.GetIndexObj(j);                                         //按顺序取得一个对象
             if Obj<>nil then  AddObjNoLock(Obj)                                //内部 不能加锁
             else
             begin                                                              //没有找到目标
                OutErrorLog('2193 RehashTo IndexOF %d 对象取出来是 空的',
                           [j]);
             end;
          end;
          BucketObj.ClearNoFree();                                                //清理存储的对象，但是不能释放
        finally
          BucketObj.unlock;                                                       //解锁
        end;
        try
            BucketObj.Free;                                                           //释放桶对象
        except
            on E: Exception do
            begin
              OutErrorLog('BucketObj Free Except',E);
            end;
        end;
      end else
      begin
         OutErrorLog('Rehash 第%d 桶 对象为空',[I]);
      end;
    end;
    Dec(FRehashCount);
  finally
    unlock;                                                                     //表级解锁
  end;
end;

procedure TExHashTable.SetBoolean(const Index: string; Value: Boolean);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;


procedure TExHashTable.SetCapacity(value: Integer);
begin
  RehashTo(value,FInitCap);
end;

procedure TExHashTable.SetChar(const Index: string; Value: Char);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;

procedure TExHashTable.SetCurrency(const Index: string; Value: Currency);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetCurrency(Value);
  end;
end;

procedure TExHashTable.SetDouble(const Index: string; Value: Double);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;

procedure TExHashTable.SetExtended(const Index: string; Value: Extended);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetExtended(Value);
  end;
end;

procedure TExHashTable.SetInt64(const Index: string; Value: Int64);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;


procedure TExHashTable.SetInteger(const Index: string; const Value: Integer);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
    {$IF _NeedExtHashD=1}
       //OutDebugLog('实例:%x 针对:%s 保存值:%d 成功',[integer(self),Index,Value]);
    {$IFEND}
  end;
end;


procedure TExHashTable.SetMemory(const Index: string; Value: Pointer);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;


procedure TExHashTable.SetSingle(const Index: string; Value: Single);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;

procedure TExHashTable.SetStObj(const Index: string; const Value: TStorageObj); //需要思考下。  分为修改 和 添加两个模式
var
  Key:Cardinal;
  KVList:TExtBucket;
  objindex: Integer;
  ISFind:Boolean;
begin
  lock;
  try
    KVList:=FindBucket(Index,Key);
    objindex := KVList.FindID(Key,ISFind);                                                    //
    if objindex >= 0 then
    begin
       KVList.Delete(objindex);
       KvList.AddObjInternal(Value);
    end;
  finally
    unlock;
  end;
end;

procedure TExHashTable.SetString(const Index: string; const Value: String);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                            //对象存在，修改值
      Obj.SetValue(Value);
end;

procedure TExHashTable.SetWideChar(const Index: string; Value: WideChar);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //对象存在，修改值
  begin
    Obj.SetValue(Value);
  end;
end;

function TQSortStringList.CompareStrings(const S1, S2: string): Integer;
begin
  Result:=QuickCompareStrings(S1,S2);
end;

constructor TQSortStringList.Create(const InitCapacity: Integer);
begin
  inherited Create;
  if InitCapacity > 0 then
    Capacity := InitCapacity;
  Sorted := True;
  CaseSensitive := True;
end;

function TQSortStringList.AddObject(const S: string; AObject: TObject): Integer;
begin
  Result := Count;
  if Sorted and Find(S, Result) then
    Objects[Result] := AObject
  else
    InsertItem(Result, S, AObject);
end;

//function TQSortStringList.EnsureAddObject(const S: string;
//  AObject: TObject): Integer;
//begin
//  if not Sorted then
//  begin
//    Result := Count;
//  end
//  else
//  begin
//    Find(S, Result);
//  end;
//  InsertItem(Result, S, AObject);
//end;


end.
