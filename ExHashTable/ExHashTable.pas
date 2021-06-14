
unit ExHashTable;
//================================================================================
//* ������ƣ�������������
//* ��Ԫ���ƣ������� Hash ��Ԫ
//* ��Ԫ���ߣ������Ľ��� CnVcl ��hashtable
//* ��    ע�����浥Ԫ ֧�� ���ֻ����������� �洢�Ķ����ܹ����Զ��ͷţ��ڴ�ָ�� Ҳ�����ͷ�
//* ��    ע�����浥Ԫ ֧�� ���ֻ����������� ��׼ָ�� Pointer �ͷ���ʹ��������
//* ��    ע������ϣ �ܹ��Զ���չ��Ҫ�Ŀռ��� ��������
//* ��    ע���ͱ�׼��Map ��ͬ���ڣ�Ͱһ�� ʹ�������������������������λ����ʹ�ö�������
//* ��    ע����� ��ӵĶ��� �ǵ�ǰ�д洢�ģ���ô����ֵ���ǡ����� �ڴ�ָ�� �ֱ���Free FreeMem
//* ��    ע���ϵ�ֵ ���ͷš�����Ǳ�׼ָ�룬��Ҫʹ���� ���ͷţ�����ӡ�
//* ��    ע��
//================================================================================
interface

{$DEFINE SUPPORT_INLINE}
uses
  SysUtils, Classes,Windows,uCalcTime{$IFDEF DEBUG},Dlog{$ENDIF};

const
  DefaultAutoRehashPoint = $100;                                                //ÿһ��Ͱ������  ��ʼ��ģ����Ϊ Ͱ���޵�
  DefaultDivNum          = 4;                                                   //Ĭ�� ��ʼ�� Ͱ���� Ϊ1/4
  //ExtendSizeMul        = 1;                                                 //ÿ����չ��������չΪ��ǰ��2��  Ҳ���� * 2
  CheckTimeWait          =2000000;                                              //2ms
  KeyNotFind    = $FFFFFFFF;
  _NeedExtHashD           = 1;

var
  MaxBucketsCount: Integer = $1000000;                                          //Ͱ����ģ  16M
  MinBucketsCount: Integer = $10;                                               //Ͱ��С��ģ 16

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
  TExObjForeach1 = procedure(Obj:TStorageObj; param: Pointer) of object;        //������ ִ�в��� ��ֹͣ
  TExObjForeach2 = function(Obj:TStorageObj;param: Pointer): Boolean of object; //������ ��ֹͣ

  TExObjForeachL = procedure(Obj:TStorageObj);
  TExObjForeachL1 = procedure(Obj:TStorageObj; param: Pointer);
  TExObjForeachL2 = function(Obj:TStorageObj;param: Pointer): Boolean;          //������ ��ֹͣ

  TLHashForeach = procedure(key: string; value: Integer) of object;
  TLHashForeach1 = procedure(key: string; value: Integer; param: Pointer) of object;
  TLHashForeach2 = function(key: string; value: Integer; param: Pointer): Boolean of object; //������ ��ֹͣ

  TLHashForeachL = procedure(key: string; value: Integer);
  TLHashForEachL1 = procedure(key: string; value: Integer; param: Pointer);
  TLHashForEachL2 = function(key: string; value: Integer; param: Pointer): Boolean; //������ ��ֹͣ

  TStorageObjType = (tsBoolean,tsInteger,tsChar,tsWideChar,tsInt64,tsSingle,tsDouble,tsExtended,tsCurrency,tsPointer,tsObject,tsString,tsMemory);

  //�洢���� Ŀ���� �ṩ��ͬ�������͵� ��д����  ������Ҫ��ʶ  ID �����ֵ�hash ֵ
  TStorageObj  = class                                                          //�洢����
    private
      m_ID   : Cardinal;                                                        //��ʶ��Hash
      m_Name  : String;                                                         //�ַ�����ʶ��
      m_Type : TStorageObjType;                                                 //��������
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
      end;                                                                      //�洢�ռ䣬��Ÿ���ֵ
      m_String :string;                                                         //����ַ���
    public
      constructor Create(id: Cardinal; bt: TStorageObjType=tsInteger;name:String='');  //���� ����Key
      destructor Destroy; override;
      class function GetMemorySize():Integer;                                          //�ڴ�ߴ�
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

      procedure SetValue(Value:String);overload;                                //�ַ�����
      procedure SetValue(Value:Int64);overload;                                 //����Int64
      procedure SetValue(Value:Integer);overload;                               //����
      procedure SetValue(Value:Boolean);overload;                               //����
      procedure SetValue(Value:Char);overload;                                  //�ַ�
      procedure SetValue(Value:WideChar);overload;                              //���ַ�
      procedure SetValue(Value:Single);overload;                                //������
      procedure SetDouble(Value:Double);                                        //˫����
      procedure SetExtended(Value:Extended);                                    //��չ
      procedure SetCurrency(Value:Currency);                                    //����
      procedure SetValue(Value:TObject);overload;                               //���� �Զ��ͷ�
      procedure SetValue(Value:Pointer);overload;                               //ָ�� �� ʹ���� �����ͷ�
      procedure SetMemory(Value:Pointer);                                       //�ڴ�ָ��

      property ID: Cardinal read m_ID;                                          //Hash
      property Name: String read m_Name;                                        //����
      property ObjType: TStorageObjType read m_Type;                            //����

      //property MemorySize: Integer read GetMemorySize;                        //�ڴ�ߴ�
   end;
  //Ͱ����ʵ�� һ����������� ���ɵĴ洢����Ͱ��
  //�¼���Ķ������Key ���ڣ���ô�Ƚ����֣������ͬ������ڸö������
  //���� �ַ��� hash ֵ��ͬ��������ײ�ˡ�Ͱ���Դ洢 ��ײ��������ͬ���ַ���
  //hash ֵ��ͬ�������ӵĶ��� ���� ǰ�档
  TExtBucket = class(TPersistent)                                               //Ͱ����
    private
      m_List:  TList;                                                           //
      m_RWSync: TMREWSync;                                                      //
      m_Owner:  TExHashTable;                                                   //������
      {$IFDEF DEBUG}
      m_Time:TimeAssessment;
      {$ENDIF}
      procedure  IncOwnerCount;
      procedure  DecOwnerCount;

      function  GetCount:Integer;
      function GetCapacity():Integer;
      procedure AddObjInternal(Obj:TStorageObj);                                //����������
      procedure DeleteInternal(idx:Integer);                                    //���ڵĲ������汾
      procedure ClearNoFree();
      function ExGetMemorySize:Integer;                                         //
      procedure Lock; virtual;
      procedure UnLock; virtual;                                                //����
      procedure RLock; virtual;
      procedure UnRLock; virtual;                                               //����
      function FindID(ID: Cardinal;var FindOk:Boolean): Integer;                //�ڴ治���� ������
    protected
    public
      constructor Create(owner:TExHashTable;InitCapacity:integer);              //���� ��Ҫ�и��������� ���Կ�
      destructor Destroy; override;                                             //�ͷ�
      class function GetMemorySize():Integer;                                   //�ڴ�ߴ�
      procedure Clear;
      procedure Delete(idx:Integer);overload;                                   //ɾ�� idx λ�ô��Ķ���
      function  Delete(S:String):Boolean;overload;                              //����� �����汾
      function  DeleteKey(Key: Cardinal;S:String):Boolean;                      //����� �����汾

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

      //function AddKey(Key:Cardinal;sid:string):TStorageObj;                   //���һ�� Key Sid
      //procedure AddObj(Obj:TStorageObj);                                      //��Ӷ��� ���ڲ�
      function GetObj(Key:Cardinal;sid:string):TStorageObj;                     //����ö��󣬲����ھͷ��ؿ�
      function GetOrAddObj(Key: Cardinal; sid: string):TStorageObj;             //������ ���,��������ھ���Ӷ���

      function GetIndexObj(idx: Cardinal):TStorageObj;

      function FindIndex(ID: Cardinal;var FindOk:Boolean): Integer;

      property Count: Integer read GetCount;
      property Capacity: Integer read GetCapacity;
      property MemorySize: Integer read ExGetMemorySize;                        //�ڴ�ߴ�
    end;

  TDynArrayBucket = array of TExtBucket;
  //����չ�Ĺ�ϣ�������  ʹ�ÿ��ٵ� ��ϣ�㷨��MurmurHash
  //Ͱ�ܹ��Զ���չ  �洢�ĵ�Ԫ ʹ�� ����� TStorageObj �ܹ� �洢 ���ֻ�����������
  //ʹ�� TMREWSync ����������� ������ ������ס ���󣬿��Բ��������� д�� ����ס���ж�
  //��� ֻҪ���� ����hash �ڱ���� ��ʵ����߳̿���ͬʱ������
  //�� Ͱ�ļ���������ǲ��룬ԭ���� ÿһ��Ͱ�� Ҳ�ǲ�����
  //�� ��һ��Ͱ��Ҫд�룬��ʱ��Ҫ�ȵ�ǰ���еĶ�����д�����⿪��
  TExHashTable = class
  private
    FBuckets: TDynArrayBucket;                                                  //Ͱ����
    FBucketCount: Integer;                                                      //Ͱ����
    FElementCount: Integer;                                                     //�ܹ���Ԫ������
    FAutoRehashPoint: Integer;                                                  //Ͱ������ ��������ֵ������ ����Hash
    FInitCap        : integer;                                                  //Ĭ�� ��ʼ�� Ͱ���� Ϊ1/4
    FExtendRateBit  : integer;                                                  //ÿ����չ��������չΪ��ǰ��2��  Ҳ���� * 2
    m_RWSync: TMREWSync;                                                        //���߳���
    {$IFDEF DEBUG}
      m_Time:TimeAssessment;
    {$ENDIF}

    procedure DoRehash(const iCount: Integer); {$IFDEF SUPPORT_INLINE} inline; {$ENDIF}
    procedure Rehash;
    procedure SetCapacity(value:Integer);

    function GetObj(const Index: string;NeedNew:Boolean=False):TStorageObj;     //���һ������NeedNew ΪTrue ��ô �����ڶ��󣬻ᴴ��
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
    procedure UnLock; virtual;                                                  //����
    procedure RLock; virtual;
    procedure UnRLock; virtual;                                                 //����
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
    //��ʼ��Ĭ��ֵ  Ͱ 16�� ��С����չ�������� 32��Ͱ��ģ����32 ��չ�� //��ʼ����������Ϊ 1/4���� 0 ��ʾ ��ʼ������Ϊ0 //���� �� �� 1 Ҳ���� 2�� 2��ʾ 4����
    constructor Create(const BucketSize:integer=16;ExtendLimit:integer=32;InitCapRate:integer=4;ExtendRateBit:Integer=1);
    destructor Destroy; override;
    function GetMemorySize: Integer;                                            //�ڴ�ߴ�
    class function Hash(const S: string): Cardinal;                             //����Hash 32λ��ֵ

    procedure Clear; virtual;
    procedure Delete(const S: string);
    function Exists(const S: string): Boolean;                                  //����Ƿ���� S �Ĵ洢����
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

    property SO[const Index: string]: TStorageObj read GetStObj write SetStObj; default;  //��ô洢����
    property O[const Index: string]: TObject read GetObject write SetObject;              //�洢�� ȡ�� �ⲿ����
    property P[const Index: string]: Pointer read GetPointer write SetPointer;            //���� ��ȡ�� ָ��
    property S[const Index: string]: string read GetString write SetString;               //�ַ���
    property M[const Index: string]: Pointer read GetMemory write SetMemory;              //�ڴ�ָ��  ���Զ��ͷ�
    property B[const Index: string]: boolean read GetBoolean write SetBoolean;            //����
    property I[const Index: string]: Integer read GetInteger write SetInteger;
    property IE[const Index: string]: Int64 read GetInt64 write SetInt64;

    property CC[const Index: string]: Char read GetChar write SetChar;
    property CW[const Index: string]: WideChar read GetWideChar write SetWideChar;
    //
    property FS[const Index: string]: Single read GetSingle write SetSingle;
    property FD[const Index: string]: Double read GetDouble write SetDouble;
    property FE[const Index: string]: Extended read GetExtended write SetExtended;
    property FC[const Index: string]: Currency read GetCurrency write SetCurrency;
    property MemorySize: Integer read ExGetMemorySize;                          //�ڴ�ߴ�

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
        if LStr1Char1 <> LStr2Char1 then  // �Ƚ����ֽڣ�����Ҫ�ĳ� Unicode �±Ƚ����ַ���
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
            LCompInd := - LLength1 * SizeOf(Char); // ��ǰ�ң����ݸ��Ե��ַ����ȱȽ�

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
    m_Type:=tsString;                                                           //�����ַ�������
    m_String:=Value;
end;

procedure TStorageObj.SetValue(Value: TObject);
begin
 m_Value.m_object:=Value;
 m_Type:=tsObject;                                                              //�����ַ�������
end;

procedure TStorageObj.SetMemory(Value: Pointer);
begin
 m_Value.m_memp:=Value;
 m_Type:=tsMemory;
end;

procedure TStorageObj.SetValue(Value: Pointer);
begin
 m_Value.m_Pointer:=Value;
 m_Type:=tsPointer;                                                             //�����ַ�������
end;

constructor TStorageObj.Create(id: Cardinal; bt: TStorageObjType=tsInteger;name:String='');
begin
  inherited Create;
  m_ID:=id;                                                                     //��ʶ��
  m_type :=bt;                                                                  //��������
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
      tsBoolean:Result:=Format('ID:%u Name:%s ����:%s',[m_ID,m_Name,AsStrBool]);
      tsInteger:Result:=Format('ID:%u Name:%s ����:%d',[m_ID,m_Name,m_Value.m_integer]);
      tsChar:Result:=Format('ID:%u Name:%s �ַ�#:%d',[m_ID,m_Name,m_Value.m_char]);
      tsWideChar:Result:=Format('ID:%u Name:%s ���ַ�#:%d',[m_ID,m_Name,integer(m_Value.m_WideChar)]);
      tsInt64:Result:=Format('ID:%u Name:%s 64λ����:%d',[m_ID,m_Name,m_Value.m_int64]);
      tsSingle:Result:=Format('ID:%u Name:%s ������#:%f',[m_ID,m_Name,m_Value.m_Single]);
      tsDouble:Result:=Format('ID:%u Name:%s ˫�����ַ�#:%f',[m_ID,m_Name,m_Value.m_Double]);
      tsExtended:Result:=Format('ID:%u Name:%s ��չ����#:%f',[m_ID,m_Name,m_Value.m_Extended]);
      tsCurrency:Result:=Format('ID:%u Name:%s ���ھ���#:%f',[m_ID,m_Name,m_Value.m_Currency]);
      tsPointer:Result:=Format('ID:%u Name:%s ָ��:%x',[m_ID,m_Name,m_Value.m_Pointer]);
      tsObject:
      begin
        if m_Value.m_object<>nil then
        begin
          try
            Result:=Format('ID:%u Name:%s ����ʵ��:%x ��������:%s',[m_ID,m_Name,integer(m_Value.m_object),m_Value.m_object.ClassName]);
          except
            Result:=Format('ID:%u Name:%s ����ʵ��:%x ��ȡ������ʧ��',[m_ID,m_Name,integer(m_Value.m_object)]);
          end;
        end;
      end;
      tsString:Result:=Format('ID:%u Name:%s �ַ���:%s',[m_ID,m_Name,m_String]);
      tsMemory:Result:=Format('ID:%u Name:%s �ڴ�ָ��:%x',[m_ID,m_Name,m_Value.m_memp]);
    end;
end;

class function TStorageObj.GetMemorySize: Integer;
begin
  Result := Self.InstanceSize;
end;

procedure TStorageObj.SetValue(Value: Char);
begin
    m_Type:=tsChar;                                                           //�����ַ�������
    m_Value.m_Char:=Value;

end;

procedure TStorageObj.SetValue(Value: WideChar);
begin
    m_Type:=tsWideChar;                                                           //�����ַ�������
    m_Value.m_WideChar:=Value;

end;

procedure TStorageObj.SetValue(Value: Integer);
begin
    m_Value.m_Integer:=Value;
    m_Type:=tsInteger;                                                           //������������
end;

procedure TStorageObj.SetValue(Value: Boolean);
begin
    m_Type:=tsBoolean;                                                           //�����ַ�������
    m_Value.m_Boolean:=Value;

end;

procedure TStorageObj.SetExtended(Value: Extended);
begin
    m_Type:=tsExtended;                                                           //�����ַ�������
    m_Value.m_Extended:=Value;

end;

procedure TStorageObj.SetCurrency(Value: Currency);
begin
    m_Type:=tsCurrency;                                                           //�����ַ�������
    m_Value.m_Currency:=Value;
end;

procedure TStorageObj.SetValue(Value: Single);
begin
    m_Type:=tsSingle;                                                           //�����ַ�������
    m_Value.m_Single:=Value;
end;

procedure TStorageObj.SetDouble(Value: Double);
begin
    m_Type:=tsDouble;                                                           //�����ַ�������
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
//    Index:=FindID(Key,isFind);                                                    //��ѰĿ���λ��
//    if (not isFind)and(Index>=0) then                                             //û�ҵ� ��ȷ��
//    begin
//      Result:=TStorageObj.Create(Key,tsInteger,sid);                             //��������
//      if (m_List.Count>0) and (Index<m_List.Count) then                          //����������
//      begin
//          PosObj:=TStorageObj(m_List[Index]);                                     //��ö���
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
//          m_List.Add(Pointer(Result));                                            //��������ӵ�β��
//          IncOwnerCount;
//      end;
//    end else
//    begin
//      Result:=TStorageObj.Create(Key,tsInteger,sid);                             //��������
//      if (Index>=0)and(Index<m_List.Count) then
//      begin
//          m_List.Insert(Index,Result);
//          IncOwnerCount;
//      end else
//      begin
//        Result.Free;
//        Result:=nil;
//        //ɶ��� ��Ҫ�������
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
      Index:=FindID(Obj.m_ID,isFind);                                              //��ѰĿ���λ��
      if (not isFind)and(Index>=0) then                                            //û�ҵ� ��ȷ��
      begin
        if (m_List.Count>0) and (Index<m_List.Count) then                          //����������
        begin
          PosObj:=TStorageObj(m_List[Index]);                                      //λ�ô�����
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
              //�쳣
          end;
        end else
        begin
          m_List.Add(Obj);                                                        //��������ӵ�β��
          IncOwnerCount;
        end;
      end else
      begin                                                                        //���� Key �ҵ���
        Posobj:=TStorageObj(m_List[Index]);                                        //���λ�ô�����
        while (Posobj<>nil) and (Posobj.m_ID=Obj.m_ID) do                          //�ҵ���ͬ��
        begin
          if QuickCompareStrings(Posobj.Name,Obj.Name)=0 then
          begin
            Exit;                                                                  //��ͬ����,�˳������
          end;
          //û�ҵ���                                                               //Key����ͬ��name��ͬ
          inc(Index);                                                              //��һ��λ��
          if Index<m_List.Count then
              Posobj:=TStorageObj(m_List[Index])                                    //������Ч����
          else
              break;                                                                //������
        end;
          m_List.Insert(Index,Obj);                                                  //���������β��
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
       OutDebugLog('ʵ��:%x TExtBucket.Clear ִ�����',[integer(self)]);
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
    OutDebugLog('TExtBucket.Create ʵ��:%x Create',[integer(self)]);
   {$IFEND}
end;
destructor TExtBucket.Destroy;
var
  i:Integer;
begin
    Clear;                                                                        //���� ���еĶ���
    {$IF _NeedExtHashD=1}
    OutDebugLog('ʵ��:%x TExtBucket.Clear and Free mList',[integer(self)]);
    {$IFEND}
    if m_List<>nil then FreeAndNil(m_List);
    if m_RWSync<>nil then FreeAndNil(m_RWSync);                                   //�ͷ� ��
    if m_Time<>nil then FreeAndNil(m_Time);
    {$IF _NeedExtHashD=1}
    OutDebugLog('ʵ��:%x TExtBucket.Destroy ����',[integer(self)]);
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
     Key:=TExHashTable.Hash(S);                                                 //����hash
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
     Index:=FindID(Key,isFind);                                                 //�ҵ���Ӧ�ö�����Ͱ��λ��
     if isFind and (Index<m_List.Count) then                                    //�ɹ��ҵ������������ڷ�Χ��
     begin
      Obj:=TStorageObj(m_List[Index]);                                          //��ö���
      while (Obj<>nil) and (Obj.m_ID=Key) do                                    //Key ֵ��ͬ�������
      begin
        if QuickCompareStrings(Obj.Name,S)=0 then                               //Key ��ͬ ������ͬ ��������
        begin
           DeleteInternal(Index);                                                   //��������ɾ��֮
           Result:=True;
           break;
        end;
        inc(Index);                                                             //������һ��
        if Index>=m_List.Count then break;                                      //������λ���ˡ�
      end;
    end;
  finally
    UnLock;
  end;
end;

procedure TExtBucket.Lock;
begin
   {$IF _NeedExtHashD=1}
      OutDebugLog('ʵ��:%x TExtBucket.Lock Wait',[integer(self)]);
   {$IFEND}
   m_Time.StartTimer;
   m_RWSync.BeginWrite;
   m_Time.EndTimeer;
   {$IF _NeedExtHashD=1}
    if m_Time.consume>CheckTimeWait then
      begin
          OutDebugLog('ʵ��:%x  TExtBucket.Lock �ȴ�ʱ��:%s',[integer(self),m_Time.AsString]);
      end;
      OutDebugLog('ʵ��:%x TExtBucket.Lock Wait Ok',[integer(self)]);
   {$IFEND}
end;

procedure TExtBucket.RLock;
begin
   {$IF _NeedExtHashD=1}
      //OutDebugLog('ʵ��:%x TExtBucket.RLock Wait',[integer(self)]);
   {$IFEND}
   m_Time.StartTimer;
   m_RWSync.BeginRead;
   m_Time.EndTimeer;
   {$IF _NeedExtHashD=1}
   if m_Time.consume>CheckTimeWait then
   begin
      OutDebugLog('ʵ��:%x TExtBucket.RLock �ȴ�ʱ��:%s',[integer(self),m_Time.AsString]);
   end;
    //OutDebugLog('ʵ��:%x TExtBucket.RLock Wait Ok',[integer(self)]);
   {$IFEND}
end;

procedure TExtBucket.UnLock;
begin
   m_Time.StartTimer;
   {$IF _NeedExtHashD=1}
     //OutDebugLog('ʵ��:%x TExtBucket.UnLock Wait',[integer(self)]);
   {$IFEND}
   m_RWSync.EndWrite;
   m_Time.EndTimeer;
   if m_Time.consume>CheckTimeWait then
   begin
   {$IF _NeedExtHashD=1}
      OutDebugLog('TExtBucket.UnLock �ȴ�ʱ��:%s',[m_Time.AsString]);
   {$IFEND}
   end;
   {$IF _NeedExtHashD=1}
     //OutDebugLog('ʵ��:%x TExtBucket.UnLock Wait Ok',[integer(self)]);
   {$IFEND}
end;

procedure TExtBucket.UnRLock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExtBucket.UnRLock Wait',[integer(self)]);
   {$IFEND}
   m_RWSync.EndRead;
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExtBucket.UnRLock Wait Ok',[integer(self)]);
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
  if m_List.Count>0 then                                                        //�������Ϊ0 ֱ�ӱ�ʶû�ҵ�
  begin
      nStart:=0;
      nEnd:=m_List.Count-1;
      while nstart<=nend do
      begin
         Result:= (nstart + nend) div 2;
         Obj:=TStorageObj(m_List[Result]);                                      //�����λ��������
         if ID <Obj.ID then
         begin
           nend:=Result-1;                                                      //index:=0 ����0λ�����
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
    Index:=FindID(Key,isFind);                                                  //�ҵ���Ӧ�ö�����Ͱ��λ��
    //OutDebugLog('TQuickKVList.GetObj ���:%u ��Ѱλ�óɹ�: �õ�λ�ý��:%u',[Key,Integer(isFind),Index]);
    if isFind and (Index<m_List.Count) then                                     //�ɹ��ҵ������������ڷ�Χ��
    begin
      Result:=TStorageObj(m_List[Index]);                                       //��ö���
      while (Result<>nil) and (Result.m_ID=Key) do
      begin
        //OutDebugLog('TQuickKVList.GetObj ���:%u ��Ѱ:%d λ�óɹ� ȡ�����:%d',[Key,Index,integer(Result)]);
        ss:= Result.Name;
        //if QuickCompareStrings(Result.Name,sid)=0 then Exit;                  //ȷʵ�ҵ�
        if QuickCompareStrings(ss,sid)=0 then break;                            //ȷʵ�ҵ�
        //û�ҵ���
        inc(Index);
        if Index<m_List.Count then
          Result:=TStorageObj(m_List[Index])
        else
          break;
      end;
      Result:=nil;
    end;
   {$IF _NeedExtHashD=1}
    OutDebugLog('ʵ��:%x TExHashTable.GetOrAddObj ��ѯ��ö���:%s �õ����:%x',[integer(self),Index,Integer(Result)]);
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
    Index:=FindID(Key,isFind);                                                  //�ҵ���Ӧ�ö�����Ͱ��λ��
    {$IF _NeedExtHashD=1}
       OutDebugLog('TExtBucket.GetOrAddObj ���:%u:%s ��λ��:%d λ�� �ҵ���־%D',
                   [Key,Sid,Index,integer(isFind)]);
    {$IFEND}
    if isFind and (Index<m_List.Count) then                                     //�ɹ��ҵ������������ڷ�Χ��
    begin
      Result:=TStorageObj(m_List[Index]);                                       //��ö���
      while (Result<>nil) and (Result.m_ID=Key) do
      begin
        {$IF _NeedExtHashD=1}
           OutDebugLog('TExtBucket.GetOrAddObj ���:%u:%s �ҵ�λ��:%d���� ��%x ',
                       [Key,Sid,Index,integer(isFind)]);
        {$IFEND}
        if QuickCompareStrings(Result.Name,sid)=0 then
        begin
          {$IF _NeedExtHashD=1}
             OutDebugLog('TExtBucket.GetOrAddObj ���:%u:%s �ҵ�λ��:%d���� ��%x ȷ��������ͬ',
                         [Key,Sid,Index,integer(isFind)]);
          {$IFEND}

          OK:=True;                                                             //ȷʵ�ҵ�  ����
          break;
        end;
        {$IF _NeedExtHashD=1}
        OutDebugLog('TExtBucket.GetOrAddObj ���:%u:%s ��λ��:%d λ��,����ͬ��ϣ����:%x ����:%s ',
                    [Key,Sid,integer(Result),Result.Name]);
        {$IFEND}
        inc(Index);                                                             //������һ��λ�ü��
        if Index>=m_List.Count then  break;                                     //����� ������û���ҵ�
        Result:=TStorageObj(m_List[Index]);                                     //�������λ�õĶ���
      end;
    end;
    if not OK then                                                              //û�ҵ� ��Ҫ����һ��
    begin                                                                       //û�ҵ�
      Result:=TStorageObj.Create(Key,tsInteger,sid);                            //��������  Ĭ��������
      if (Index>=0)and(Index<m_List.Count) then                                 //index �� ��Χ�ڣ���ӵ� �洢��
      begin
          m_List.Insert(Index,Result);                                          //���뵽ָ��λ��
          {$IF _NeedExtHashD=1}
          OutDebugLog('TExtBucket.GetOrAddObj ���:%u:%s ��λ��:%d λ�� ��Ӵ�������:%x',
                      [Key,sid,Index, integer(Result)]);
          {$IFEND}
      end else
      begin
         m_List.Add(Result);
         {$IF _NeedExtHashD=1}
         OutDebugLog('TExtBucket.GetOrAddObj ���:%u:%s ��λ��:%d λ�� ��β�� ��Ӵ�������:%x',
                      [Key,sid,Index, integer(Result)]);
         {$IFEND}
      end;
      IncOwnerCount;                                                            //�ϼ���������
      NeedCheckReHash:=true;
    end;
   {$IF _NeedExtHashD=1}
    OutDebugLog('ʵ��:%x TExHashTable.GetOrAddObj ��ѯKey:%u:%s ���������� �õ����:%x',
                [integer(self),Key,sid,Integer(Result)]);
   {$IFEND}
  finally
    unlock;
  end;
  if (NeedCheckReHash) and(m_Owner<>nil) then  m_Owner.DoRehash(Count);         //��� �Ƿ���Ҫ���� hash �� �Ѿ��ָ�
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

procedure TExHashTable.AddObjNoLock(Obj: TStorageObj);                          //�ڲ���ӣ���ȫ����������ǰ�Ѿ���ȫ����
begin
    FBuckets[HashOfKey(Obj.m_ID)].AddObjInternal(Obj);                          //�õ�����hash ���Ͱ����
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

procedure TExHashTable.ForListValue(var lstItems:TQSortStringList);             //���������ַ�����
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

//����ɾ�����е� �����������Ҫ������ʹ�ã����� ���ͷ� ��Щ����
//��ʼ��Ͱ�ߴ磬Ͱ��ģ��չ���Ƶ㣬��ʼ���������������ݵ����ű���
constructor TExHashTable.Create(const BucketSize:integer=16;ExtendLimit:integer=32;InitCapRate:integer=4;ExtendRateBit:Integer=1);
var
  I: Integer;
begin
  inherited Create;
  {$IFDEF DEBUG}
   m_Time:=TimeAssessment.Create;
  {$ENDIF}
  m_RWSync:=TMREWSync.Create;

  FInitCap:= InitCapRate;                                                       //��ʼ�� �����ʣ�Ϊ0 ��ʾ ��Ԥ�ȳ�ʼ��
  if FInitCap<>0 then FInitCap:=ExtendLimit div InitCapRate;                    //��ʼ���������� Ĭ���� 1/4
  FExtendRateBit:=ExtendRateBit;
  if FExtendRateBit>=6 then FExtendRateBit:=6;                                  //������� 32��
  //  FAutoRehashPoint := DefaultAutoRehashPoint;                               //����Ĭ��ֵ
  FAutoRehashPoint:=ExtendLimit;                                                //���� �Զ����ż���
  if (FAutoRehashPoint<=0)  or (FAutoRehashPoint>10000) then FAutoRehashPoint:=DefaultAutoRehashPoint; //���ó��� ����Ϊ
  FBucketCount := LimitBucketCount(BucketSize);
  SetLength(FBuckets, FBucketCount);
  for I := 0 to FBucketCount - 1 do
  begin
    FBuckets[I] := TExtBucket.Create(self,FInitCap);
  end;
  {$IF _NeedExtHashD=1}
  OutDebugLog('ʵ��:%x TExHashTable.Create ���',[integer(self)]);
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
   OutDebugLog('ʵ��:%x TExHashTable.Destory For Free �쳣',[integer(self)]);
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
   OutDebugLog('ʵ��:%x TExHashTable.Destroy ���',[integer(self)]);
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
   //OutDebugLog('ʵ��:%x TExHashTable.Lock Wait',[integer(self)]);
   {$IFEND}
   m_Time.StartTimer;
   m_RWSync.BeginWrite;
   m_Time.EndTimeer;
   {$IFDEF DEBUG}
   if m_Time.consume>CheckTimeWait then
   begin
     {$IF _NeedExtHashD=1}
      OutDebugLog('ʵ��:%x TExHashTable.Lock �ȴ�ʱ��:%s',[integer(self),m_Time.AsString]);
      {$IFEND}
   end;
   {$ENDIF}
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExHashTable.Lock WaitOK',[integer(self)]);
   {$IFEND}
end;

procedure TExHashTable.RLock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExHashTable.RLock Wait',[integer(self)]);
   {$IFEND}

   m_Time.StartTimer;
   m_RWSync.BeginRead;
   m_Time.EndTimeer;
   {$IFDEF DEBUG}
   if m_Time.consume>CheckTimeWait then
   begin
     {$IF _NeedExtHashD=1}
      OutDebugLog('ʵ��:%x TExHashTable.RLock �ȴ�ʱ��:%s',[integer(self),m_Time.AsString]);
      {$IFEND}
   end;
   {$ENDIF}
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExHashTable.RLock WaitOk',[integer(self)]);
   {$IFEND}
end;

procedure TExHashTable.UnLock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExHashTable.UnLock Wait',[integer(self)]);
   {$IFEND}
   m_RWSync.EndWrite;
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExHashTable.UnLock Wait Ok',[integer(self)]);
   {$IFEND}
end;

procedure TExHashTable.UnRLock;
begin
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExHashTable.UnRLock Wait',[integer(self)]);
   {$IFEND}
   m_RWSync.EndRead;
   {$IF _NeedExtHashD=1}
   //OutDebugLog('ʵ��:%x TExHashTable.UnRLock Wait Ok',[integer(self)]);
   {$IFEND}
end;


procedure TExHashTable.DoRehash(const iCount: Integer);
begin
  if (FRehashCount >= 0) and (iCount > FAutoRehashPoint) then                   //���ÿһ��Ͱ�Ƿ���� ��hash ���ģ
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
  Key:=Hash(S);                                                                 //����hash
  rlock;
  try
    Result := FBuckets[HashOfKey(Key)];                                           //�õ�����hash ���Ͱ����
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
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetValue(Value);
  end;
end;


procedure TExHashTable.SetPointer(const Index: string; Value: Pointer);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
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
    OutDebugLog('ʵ��:%x TExHashTable.GetObj ��ѯ����������%s ',[integer(self),Index]);
    {$IFEND}
    Result:=FindBucket(Index,Key).GetOrAddObj(Key,Index);                       //�ж�����λͰ��֮����д��
  end else
  begin
   {$IF _NeedExtHashD=1}
    OutDebugLog('ʵ��:%x TExHashTable.GetObj ��ѯ��ȡ����%s ',[integer(self),Index]);
    {$IFEND}
    Result:=FindBucket(Index,Key).GetObj(Key,Index);                            //�ж����Ķ�λͰ����Ͱ��ýڵ� �ж���
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
  StrHashTableInfo = 'Ԫ������:%d; Ͱ����:%d; ͰԪ�����:%d; ͰԪ����С:%d; ��Ͱ:%d ����hash����:%d ʵ���ߴ�:%d  �洢�����ʵ���ߴ�:%d';

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
        Inc(iSpareElement);                                                     //��Ͱ
        iMinElement := 0;                                                       //���� Ԫ�� Ϊ0
      end
      else
      begin
        Inc(iCount, Count);                                                     //���� ���� ���ϱ�Ͱ ����
        if iMaxElement < Count then
          iMaxElement := Count;                                                 //���Ԫ��
        if iMinElement > Count then
          iMinElement := Count;                                                 //��СԪ��Ԭ��
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
  FRehashCount := -FRehashCount;                                                //����Ϊ
  try
    if FBucketCount >= MaxBucketsCount then
    begin
      Exit;
    end;
    NewSize := LimitBucketCount(GetNewBucketCount(FBucketCount));
    {$IF _NeedExtHashD=1}
      OutDebugLog('ʵ��:%x ��Ҫ��hash ��ǰ:%d ��չ��:%d ',
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
  lock;                                                                         //����
  if NewSize = FBucketCount then
  begin
    {$IF _NeedExtHashD=1}
      //OutDebugLog('ʵ��:%x ��Ҫ��hash ��ǰ:%d �Ѿ���չ��:%d ���Բ���Ҫ����',
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
        BucketObj.lock;                                                           //��סͰ
        try
          for j := 0 to BucketObj.Count - 1 do
          begin
             Obj:=BucketObj.GetIndexObj(j);                                         //��˳��ȡ��һ������
             if Obj<>nil then  AddObjNoLock(Obj)                                //�ڲ� ���ܼ���
             else
             begin                                                              //û���ҵ�Ŀ��
                OutErrorLog('2193 RehashTo IndexOF %d ����ȡ������ �յ�',
                           [j]);
             end;
          end;
          BucketObj.ClearNoFree();                                                //����洢�Ķ��󣬵��ǲ����ͷ�
        finally
          BucketObj.unlock;                                                       //����
        end;
        try
            BucketObj.Free;                                                           //�ͷ�Ͱ����
        except
            on E: Exception do
            begin
              OutErrorLog('BucketObj Free Except',E);
            end;
        end;
      end else
      begin
         OutErrorLog('Rehash ��%d Ͱ ����Ϊ��',[I]);
      end;
    end;
    Dec(FRehashCount);
  finally
    unlock;                                                                     //������
  end;
end;

procedure TExHashTable.SetBoolean(const Index: string; Value: Boolean);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
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
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetValue(Value);
  end;
end;

procedure TExHashTable.SetCurrency(const Index: string; Value: Currency);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetCurrency(Value);
  end;
end;

procedure TExHashTable.SetDouble(const Index: string; Value: Double);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetValue(Value);
  end;
end;

procedure TExHashTable.SetExtended(const Index: string; Value: Extended);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetExtended(Value);
  end;
end;

procedure TExHashTable.SetInt64(const Index: string; Value: Int64);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetValue(Value);
  end;
end;


procedure TExHashTable.SetInteger(const Index: string; const Value: Integer);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetValue(Value);
    {$IF _NeedExtHashD=1}
       //OutDebugLog('ʵ��:%x ���:%s ����ֵ:%d �ɹ�',[integer(self),Index,Value]);
    {$IFEND}
  end;
end;


procedure TExHashTable.SetMemory(const Index: string; Value: Pointer);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetValue(Value);
  end;
end;


procedure TExHashTable.SetSingle(const Index: string; Value: Single);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
  begin
    Obj.SetValue(Value);
  end;
end;

procedure TExHashTable.SetStObj(const Index: string; const Value: TStorageObj); //��Ҫ˼���¡�  ��Ϊ�޸� �� �������ģʽ
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
  if Obj<>nil then                                                            //������ڣ��޸�ֵ
      Obj.SetValue(Value);
end;

procedure TExHashTable.SetWideChar(const Index: string; Value: WideChar);
var
  Obj:TStorageObj;
begin
  Obj:=GetObj(Index,True);
  if Obj<>nil then                                                              //������ڣ��޸�ֵ
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
