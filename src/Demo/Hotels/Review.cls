Class Demo.Hotels.Review Extends %Persistent [ Not ProcedureBlock ]
{

Property Authorname As %String(MAXLEN = "");

Property DataOrigin As %String;

Property Hotelname As %String(MAXLEN = "");

Property Input As %String;

Property ResultNumber As %String;

Property ResultRow As %String;

Property Reviewdate As %String(MAXLEN = "");

Property Reviewscore As %String(MAXLEN = "");

Property Reviewtext As %String(MAXLEN = "");

Property Reviewtitle As %String(MAXLEN = "");

Property ReviewFull As %String [ Calculated, SqlComputeCode = { set {*} = {Reviewtitle} _ $c(13,10,13,10) _ {Reviewtext}}, SqlComputed ];

Property SourcePageURL As %String(MAXLEN = 500);

Property Staydetails As %String(MAXLEN = "");

Property StayType As %String [ Calculated, SqlComputeCode = { set {*} = $s($f({Staydetails},"business"):"business", $f({Staydetails},"family"):"family", $f({Staydetails},"solo"):"solo", $f({Staydetails},"couple"):"couple", $f({Staydetails},"friends"):"friends", 1:"unknown")}, SqlComputed ];

Property StayMonth As %String [ Calculated, SqlComputeCode = { set {*} = $zstrip($p({Staydetails}," ",2,3),"<>PC")}, SqlComputed ];

Property StayDate As %Date [ Calculated, SqlComputeCode = { set {*} = $zdateh($piece({StayMonth}," ",1)_" 1,"_$piece({StayMonth}," ",2),9,,,,,,,$h) }, SqlComputed ];

Property Widget As %String;

Index StayTypeIdx On StayType [ Type = bitmap ];

Index iFind On (ReviewFull) As %iFind.Index.Analytic;

Storage Default
{
<Data name="ReviewDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Authorname</Value>
</Value>
<Value name="3">
<Value>DataOrigin</Value>
</Value>
<Value name="4">
<Value>Hotelname</Value>
</Value>
<Value name="5">
<Value>Input</Value>
</Value>
<Value name="6">
<Value>ResultNumber</Value>
</Value>
<Value name="7">
<Value>ResultRow</Value>
</Value>
<Value name="8">
<Value>Reviewdate</Value>
</Value>
<Value name="9">
<Value>Reviewscore</Value>
</Value>
<Value name="10">
<Value>Reviewtext</Value>
</Value>
<Value name="11">
<Value>Reviewtitle</Value>
</Value>
<Value name="12">
<Value>SourcePageURL</Value>
</Value>
<Value name="13">
<Value>Staydetails</Value>
</Value>
<Value name="14">
<Value>Widget</Value>
</Value>
</Data>
<DataLocation>^Demo.Hotels.ReviewD</DataLocation>
<DefaultData>ReviewDefaultData</DefaultData>
<IdLocation>^Demo.Hotels.ReviewD</IdLocation>
<IndexLocation>^Demo.Hotels.ReviewI</IndexLocation>
<StreamLocation>^Demo.Hotels.ReviewS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
