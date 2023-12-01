{ @author: Sylvain Maltais (support@gladir.com)
  @created: 2023
  @website(https://www.gladir.com/CODER/INTLLIB-TP)
  @abstract(Target: Turbo Pascal 7)
}

Unit INTL;

INTERFACE

{$N+}

Const
 { Ordre des dates }
 sortMDY=0;                    { MM/JJ/AA }
 sortDMY=1;                    { JJ/MM/AA }
 sortYMD=2;                    { AA/MM/JJ }
 sortMYD=3;                    { MM/AA/JJ }
 sortDYM=4;                    { JJ/AA/MM }
 sortYDM=5;                    { AA/JJ/MM }

Type
 (***** Structure d'horloge *****)
 TimeType=(AmPm,      { 12 heures avec AM/PM comme aux êtats-Unis }
  	   Military); { 24 heures comme le systSme international ou militaire }

Function  CompToStr(I:Comp):String;
Function  DateToStrDate(Year,Month,Day,DayOfWeek:Word):String;
Function  GetDateSeparator:String;
Function  GetDecimalSeparator:String;
Function  GetSortDate:Byte;
Function  GetThousandSeparator:String;
Function  GetTimeSeparator:String;
Function  GetTimeType:TimeType;
Procedure LoadCurrCountry;
Function  LongIntToStr(I:LongInt):String;
Function  LongIntToStrFullTime(Time:LongInt):String;
Function  LongIntToStrDate(Time:LongInt):String;
Function  LongIntToStrTime(Time:LongInt):String;
Function  TimeToStrTime(Hour,Min,Sec:Byte):String;

IMPLEMENTATION

Uses DOS,Strings;

Var
  { Information de pays }
 CountryInfo:Record
  Date:Word;
  Curr:Array[0..4]of Char;
  ThSep,DeSep,DtSep,TmSep:Array[0..1]of Char;
  CurrStyle,Digits:Byte;
  Time:TimeType;
  CaseUp:Pointer;
  DaSep:Array[0..1]of Char;
  FillCountry:Array[0..31]of Byte;
 End;

Function Left(S:String;L:Integer):String;Begin
 Left:=Copy(S,1,L);
End;

Function PadZeroLeft(Value:Integer;Space:Byte):String;
Var
 S:String;
Begin
 Str(Value,S);
 While Length(S)<Space do S:='0'+S;
 PadZeroLeft:=S;
End;

Function DateToStrDate(Year,Month,Day,DayOfWeek:Word):String;
Var
 Target:String;
Begin
 Case(CountryInfo.Date)of
  0:Begin
   Target:=PadZeroLeft(Month,2);
   Target:=Target+StrPas(@CountryInfo.DtSep);
   Target:=Target+PadZeroLeft(Day,2);
  End;
  1:Begin
   Target:=PadZeroLeft(Day,2);
   Target:=Target+StrPas(@CountryInfo.DtSep);
   Target:=Target+PadZeroLeft(Month,2);
  End;
  Else Begin
   Target:=PadZeroLeft(Year,4);
   Target:=Target+StrPas(@CountryInfo.DtSep);
   Target:=Target+PadZeroLeft(Month,2);
   Target:=Target+StrPas(@CountryInfo.DtSep);
   Target:=Target+PadZeroLeft(Day,2);
  End;
 End;
 If CountryInfo.Date<2Then Begin
  Target:=Target+StrPas(@CountryInfo.DtSep);
  Target:=Target+PadZeroLeft(Year,4);
 End;
 DateToStrDate:=Target
End;


Function LongIntToStrDate(Time:LongInt):String;
Var
 DT:DateTime;
Begin
 UnpackTime(Time,DT); { Bits de 31 Ö 16 de la date Çtant important!}
 LongIntToStrDate:=DateToStrDate(DT.Year,DT.Month,DT.Day,$FFFF);
End;

Function TimeToStrTime(Hour,Min,Sec:Byte):String;
Var
 S:String;
Begin
 S:=PadZeroLeft(Hour,2);
 S:=S+StrPas(@CountryInfo.TmSep);
 S:=S+PadZeroLeft(Min,2);
 S:=S+StrPas(@CountryInfo.TmSep);
 S:=S+PadZeroLeft(Sec,2);
 TimeToStrTime:=S
End;

Function LongIntToStrTime(Time:LongInt):String;
Var
 DT:DateTime;
Begin
 UnpackTime(Time,DT);
 LongIntToStrTime:=TimeToStrTime(DT.Hour,DT.Min,DT.Sec)
End;

Function LongIntToStrFullTime(Time:LongInt):String;Begin
 LongIntToStrFullTime:=LongIntToStrDate(Time)+' '+LongIntToStrTime(Time);
End;

Function CompToStr(I:Comp):String;
Var
 S:String;
 L:Byte Absolute S;
Begin
 Str(I:0:0,S);
 I:=Abs(I);
 If I>=10E10Then CompToStr:=S Else
 If I>=1000000000Then
  CompToStr:=Left(S,L-9)+CountryInfo.ThSep[0]+
        Copy(S,L-8,3)+CountryInfo.ThSep+Copy(S,L-5,3)+
        CountryInfo.ThSep[0]+Copy(S,L-2,3) Else
 If I>=1000000Then CompToStr:=Left(S,L-6)+CountryInfo.ThSep[0]+
                         Copy(S,L-5,3)+CountryInfo.ThSep[0]+
                         Copy(S,L-2,3)Else
 If I>=1000Then CompToStr:=Left(S,L-3)+CountryInfo.ThSep[0]+Copy(S,L-2,3)
           Else CompToStr:=S
End;

Function LongIntToStr(I:LongInt):String;
Var
 S:String;
 L:Byte Absolute S;
Begin
 Str(I:0,S);
 I:=Abs(I);
 If I>=1000000000Then
  LongIntToStr:=Left(S,L-9)+CountryInfo.ThSep[0]+
        Copy(S,L-8,3)+CountryInfo.ThSep+Copy(S,L-5,3)+
        CountryInfo.ThSep[0]+Copy(S,L-2,3) Else
 If I>=1000000Then LongIntToStr:=Left(S,L-6)+CountryInfo.ThSep[0]+
                         Copy(S,L-5,3)+CountryInfo.ThSep[0]+
                         Copy(S,L-2,3)Else
 If I>=1000Then LongIntToStr:=Left(S,L-3)+CountryInfo.ThSep[0]+Copy(S,L-2,3)
           Else LongIntToStr:=S
End;

Procedure LoadCurrCountry;
Var
 Regs:Registers;
Begin
 Regs.AX:=$3800;
 Regs.DS:=Seg(CountryInfo);
 Regs.DX:=Ofs(CountryInfo);
 Intr($21,Regs);
End;

Function GetDecimalSeparator:String;Begin
 GetDecimalSeparator:=CountryInfo.DeSep[0]+CountryInfo.DeSep[1];
End;

Function GetThousandSeparator:String;Begin
 GetThousandSeparator:=CountryInfo.ThSep[0]+CountryInfo.ThSep[1];
End;

Function GetDateSeparator:String;Begin
 GetDateSeparator:=CountryInfo.DtSep[0]+CountryInfo.DtSep[1];
End;

Function GetTimeSeparator:String;Begin
 GetTimeSeparator:=CountryInfo.TmSep[0]+CountryInfo.TmSep[1];
End;

Function GetSortDate:Byte;Begin
 GetSortDate:=CountryInfo.Date;
End;

Function GetTimeType:TimeType;Begin
 GetTimeType:=CountryInfo.Time;
End;

BEGIN
  { Fixe les valeurs par dÇfaut canadienne }
 CountryInfo.DeSep:=','#0;
 CountryInfo.ThSep:=' '#0;
 CountryInfo.DtSep:='-'#0;
 CountryInfo.TmSep:=':'#0;
END.