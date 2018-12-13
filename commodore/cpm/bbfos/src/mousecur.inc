{
SG Tools Pro (C) 1992 Steve Goldsmith

The Mouse Cursor module allows you to control a cursor with 1351 and
compatible mouses in port 2.
}

{global mouse vars}

var

  mseXOld, mseXFeel, mseXOverflow, mseYOld, mseYFeel, mseYOverflow : byte;
  mseXCur, mseYCur, mseXCurMin, mseXCurMax,mseYCurMin, mseYCurMax : integer;

procedure InitMouseCur (XCur, YCur, XCurMin,YCurMin,XCurMax,YCurMax : integer;
                        XFeel,YFeel,XOverflow,YOverflow : byte);

begin
  mseXCur := XCur;
  mseYCur := YCur;
  mseXCurMin := XCurMin;
  mseYCurMin := YCurMin;
  mseXCurMax := XCurMax;
  mseYCurMax := YCurMax;
  mseXFeel := XFeel;
  mseYFeel := YFeel;
  mseXOverFlow := XOverflow;
  mseYOverflow := YOverflow;
  mseX := 0;
  mseY := 0;
  mseXOld := 0;
  mseYOld := 0
end;

procedure UpdateMouseCurX;

var

  XDiff : byte;

begin
  XDiff := abs (mseXOld-mseX); {calc abs diff between old and new pos}
  if XDiff >= mseXFeel then      {see if diff > feel}
  begin
    if XDiff < mseXOverflow then {see if diff overflowed}
    begin
      if (mseXCur < mseXCurMax) and {which direction are we going?}
      (mseX > mseXOld) then
        mseXCur := mseXCur+1
      else
        if (mseXCur > mseXCurMin) and
        (mseX < mseXOld) then
          mseXCur := mseXCur-1
    end;
    mseXOld := mseX  {old mouse pos = new pos}
  end
end;

procedure UpdateMouseCurY;

var

  YDiff : byte;

begin
  YDiff := abs (mseYOld-mseY); {calc abs diff between old and new pos}
  if YDiff >= mseYFeel then      {see if diff > feel}
  begin
    if YDiff < mseYOverflow then {see if diff overflowed}
    begin
      if (mseYCur < mseYCurMax) and {which direction are we going?}
      (mseY < mseYOld) then
        mseYCur := mseYCur+1
      else
        if (mseYCur > mseYCurMin) and
        (mseY > mseYOld) then
          mseYCur := mseYCur-1
    end;
    mseYOld := mseY  {old mouse pos = new pos}
  end
end;
