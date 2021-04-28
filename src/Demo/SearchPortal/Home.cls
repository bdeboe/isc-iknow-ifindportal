Include %IFInclude

Class Demo.SearchPortal.Home Extends %ZEN.Component.page
{

Parameter IFPTABLE = "Demo_Hotels.Review";

Parameter IFPINDEX;

Parameter IFPFILTERFIELDS;

Parameter IFPORDERFIELD;

Parameter IFPTITLEFIELD;

Parameter IFPORIGINALTEXTFIELD;

Parameter IFPENTITYCLICK [ Constraint = "drill,reset" ] = "reset";

Parameter CSSINCLUDES = "bootstrap-3-3-5/dist/css/bootstrap.min.css";

Parameter JSINCLUDES = "jquery-2.0.3.min.js,bootstrap-3-3-5/dist/js/bootstrap.min.js";

Property tableName As %ZEN.Datatype.string(MAXLEN = 256, ZENURL = "t") [ InitialExpression = {..#IFPTABLE} ];

Property className As %ZEN.Datatype.string [ Private ];

Property mappingPrefix As %ZEN.Datatype.string [ Private ];

Property hasPrivateStorage As %ZEN.Datatype.boolean [ Private ];

Property indexName As %ZEN.Datatype.string(MAXLEN = 256, ZENURL = "i") [ InitialExpression = {..#IFPINDEX} ];

Property metadataColumns As %ZEN.Datatype.string(MAXLEN = 2000, ZENURL = "mf") [ InitialExpression = {..#IFPFILTERFIELDS} ];

Property orderField As %ZEN.Datatype.string(MAXLEN = 256, ZENURL = "of") [ InitialExpression = {..#IFPORDERFIELD} ];

Property titleField As %ZEN.Datatype.string(MAXLEN = 256, ZENURL = "tf") [ InitialExpression = {..#IFPTITLEFIELD} ];

Property originalTextField As %ZEN.Datatype.string(MAXLEN = 256, ZENURL = "otf") [ InitialExpression = {..#IFPORIGINALTEXTFIELD} ];

Property metadataParsed As %ZEN.Datatype.string(MAXLEN = 2000) [ Private ];

Property metadata1Index As %ZEN.Datatype.string(MAXLEN = 256) [ Private ];

Property searchString As %ZEN.Datatype.string(MAXLEN = 256, ZENURL = "q");

Property searchMode As %ZEN.Datatype.string(MAXLEN = 256, ZENURL = "m") [ InitialExpression = {$$$IFSEARCHNORMAL} ];

Property searchMD1 As %ZEN.Datatype.string(MAXLEN = 256, ZENURL = "j");

Property qid As %ZEN.Datatype.integer(ZENURL = "qid");

Property criteria As %ZEN.Datatype.string(MAXLEN = "", ZENURL = "c");

XData Style
{
<style type="text/css">
body {
	padding: 20px;
}

.searchMatch, .searchMatchNeg {
	font-weight: bold;
	background-color: Gold;
}

.textFragment {
	color: #555;
	font-style: italic;
}

.publishingDate {
	color: #5cb85c;
}
</style>
}

XData Contents [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<page title="iFind Search Portal" width="100%">
<hgroup cellVAlign="top" width="100%">
<vgroup width="70%">
<hgroup>
<assistedText id="txtSearch" controlWidth="350px" controlClass="form-control"
controlType="custom"  isSuggestedDataComplete="true" triggerChars="" hideGhost="true" 
	onUpdateDataClient="zenPage.inputTermClient(base)"
  	onchange="zenPage.search(zenThis.getValue(),zen('selMD1').getValue());return;" 
 	onkeyup="zenPage.onTermKeyUp();return;" />
 <spacer width="15" />
 <select id="selMD1" controlClass="form-control" controlStyle="width:100px;"
 sql="SELECT DISTINCT %EXACT($$$MD1) FROM $$$TABLE"
 onchange="zenPage.search(zen('txtSearch').getValue(),zenThis.getValue());" />
 <spacer width="15" />
<button id="btnSearch" caption="Search!" controlClass="btn btn-primary"
onclick="zenPage.search(zen('txtSearch').getValue(),zen('selMD1').getValue());" />
</hgroup>
<spacer height="15" />
<html id="htmlResults" OnDrawContent="DrawResults" />
</vgroup>
<spacer width="15" />
<vgroup width="30%">
<!--titleBox title="Filter facet" /-->
<html id="htmlFilterFacet" OnDrawContent="DrawFacet" seed="$$$MD1" />
<spacer height="15" />

<!--titleBox title="Dominant terms" /-->
<html id="htmlDominantTerms" OnDrawContent="DrawDominantTerms" />
<spacer height="15" />

<!--titleBox title="Similar terms" /-->
<html id="htmlSimilarTerms" OnDrawContent="DrawSimilarTerms" />
<spacer height="15" />

<!--titleBox title="Related terms" /-->
<html id="htmlRelatedTerms" OnDrawContent="DrawRelatedTerms" />
</vgroup>
</hgroup>

<!--html id="htmlResultDoc" OnDrawContent="DrawDocument" /-->
<html>
<div id="docModal" class="modal fade" role="dialog">
<div class="modal-dialog">
<div class="modal-content">
<div class="modal-header">
<span class="glyphicon glyphicon-remove close" data-dismiss="modal"> </span>
<h4 id="docModalTitle" class="modal-title"></h4>
</div>
<div id="docModalText" class="modal-body">
</div>
<div class="modal-footer" style="text-align: left;">
<p>Similar records:</p>
<ul id="docModalSimilar">
</ul>
</div>
</div>
</div>
</div>
</html>
</page>
}

ClientMethod selectDocument(id, launchModal) [ Language = javascript ]
{
	//if (!launchModal) { $('#docModal').modal('hide'); }
	/*var html = zen('htmlResultDoc');
	var sc = html.setProperty('seed', id);
	sc = html.refreshContents(true);
	if (launchModal) { $('#docModal').modal('show'); }*/
	
	var json = zenPage.GetDocumentDetails(id);
	console.log(json);
	$('#docModalTitle').text(json.Title);
	$('#docModalText').html(json.Text);
	var sim = $('#docModalSimilar').empty();
	for (var i = 1; i <= json.SimilarCount; i++) {
		$('<li />').append($('<a onclick="zenPage.selectDocument(\''+json['Similar'+i+'ID']+'\');" />').text(json['Similar'+i+'Text'])).appendTo(sim);
	}
	if (launchModal) { $('#docModal').modal('show'); }
}

ClientMethod search(string, md1) [ Language = javascript ]
{
	// first ensure we have our saved results
	sc = zenPage.DoSearch(string, md1);
	zenPage.refreshAll();
}

ClientMethod refine(criteria) [ Language = javascript ]
{
	var sc = zenPage.RefineSearch(criteria);
	zenPage.refreshAll();
}

ClientMethod refreshAll() [ Language = javascript ]
{
	// asynchronously refresh relevant panels
	zen('htmlResults').refreshContents();
	zen('htmlFilterFacet').refreshContents();
	zen('htmlDominantTerms').refreshContents();
	zen('htmlSimilarTerms').refreshContents();
	zen('htmlRelatedTerms').refreshContents();
}

Method RefineSearch(pNewCriteria As %String) As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set ..criteria = ..criteria _$s(..criteria="":"",1:",")_pNewCriteria
		
		set tType = $piece(pNewCriteria,":",1)
		if tType="prop" {
			set tSQL = "SELECT ID FROM "_..tableName_" WHERE "_$piece(pNewCriteria,":",2)_" = '"_$piece(pNewCriteria,":",3)_"' AND %ID %FIND Demo_SearchPortal.Find("_..qid_")"
			set tResult = ##class(%SQL.Statement).%ExecDirect(,tSQL)
			while tResult.%Next() {
				set tID = tResult.%GetData(1)
				$$$IFBITOFFPOS(tID,tChunk,tPos)
				set $bit(tBits(tChunk),tPos)=1
			}
			// compress bitmaps
			set tMaxChunk=$order(tBits(""),-1)
			for tChunk = 1:1:tMaxChunk {
				set tBits(tChunk) = $bitlogic(tBits(tChunk))
			}
		} else {
			set tFinder = $classmethod(..className, ..indexName_"Embedded")
			if (tType = "entity") {
				do tFinder.PrepareFind("{"_$piece(pNewCriteria,":",2)_"}", ..searchMode)
			} elseif (tType = "word") {
				do tFinder.PrepareFind($piece(pNewCriteria,":",2), ..searchMode)
			}
			merge tOldBits = ^CacheTemp.IF.SearchPortal.Query(..qid,"b")
			set tChunk=""
			for {
				set tBits = tFinder.NextChunk(.tChunk)
				quit:tChunk=""
				set tBits(tChunk)=$bitlogic(tBits & tOldBits(tChunk))
			}
		}
		
		set tNewQID = $i(^CacheTemp.IF.SearchPortal.Query)
		merge ^CacheTemp.IF.SearchPortal.Query(tNewQID,"b") = tBits
		set ^CacheTemp.IF.SearchPortal.Query(tNewQID, "parent") = ..qid
		set ..qid = tNewQID
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DoSearch(pSearch As %String, pMD1 As %String = "") As %Status [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		if (..searchString'=pSearch) && ..qid {
			job ..ClearHistory(..qid)
		}
		
		set ..criteria = "", ..searchString = pSearch, ..searchMD1 = pMD1
		
		set tSearchMode = ..searchMode
		set tFinder = $classmethod(..className, ..indexName_"Embedded")
		do tFinder.PrepareFind(pSearch, tSearchMode)
		
		// fetch bitmap for MD1 field
		if ..metadata1Index'="" {
			merge tMD1Bits = @..metadata1Index@(" "_$$$UPPER(pMD1))
		} else {
			set tResult = ##class(%SQL.Statement).%ExecDirect(,"SELECT %ID FROM "_..tableName_" WHERE "_$piece(..metadataParsed,",",1)_" = '"_pMD1_"'")
			while tResult.%Next() {
				$$$IFBITOFFPOS(tResult.%GetData(1),tChunk,tPos)
				set $bit(tMD1Bits(tChunk),tPos)=1
			}
		}
		
		set tQID = $i(^CacheTemp.IF.SearchPortal.Query)
		
		set tChunk=""
		for {
			set tBits = tFinder.NextChunk(.tChunk)
			quit:tChunk=""
			
			set:pMD1'="" tBits = $bitlogic(tBits & tMD1Bits(tChunk))
			
			set ^CacheTemp.IF.SearchPortal.Query(tQID,"b",tChunk)=tBits
		}
		set ..qid = tQID
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method DrawResults(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		
		set tSearchString = ..searchString
		set tSearchMode = ..searchMode
		set tHighlightTags = "<font class=""searchMatch"">,<font class=""searchMatchNeg"">"
		set tLimit = 5
		
		write !,"<p>Searching for <i>",tSearchString,"</i>"
		write:..searchMD1'="" " in '",..searchMD1,"'"
		if ..criteria'="" {
			write " filtered by ",..criteria
		}
		write " <span class=""hidden"">"_..qid_"</span></p>"
		
		set tSQL = "SELECT ID, "
		#define QuoteIfReserved(%w) $s($system.SQL.IsReservedWord(%w):$$$QUOTE(%w), 1:%w)
		if ..metadataParsed'="" {
			for i = 1:1:$l(..metadataParsed," ") {
				set tField = $piece(..metadataParsed,",",i)
				set tSQL = tSQL _ $$$QuoteIfReserved(tField) _ " , "
			}
		}
		set:tSQL'[..orderField tSQL = tSQL_$$$QuoteIfReserved(..orderField)_" , "
		set:tSQL'[..titleField tSQL = tSQL_$$$QuoteIfReserved(..titleField)_" , "
		set tSQL = tSQL _..tableName_"_"_..indexName_"Highlight(ID, '"_tSearchString_"', '"_tSearchMode_"', '"_tHighlightTags_"', "_tLimit_") Text, "
		set tSQL = tSQL _..tableName_"_"_..indexName_"Rank(ID, '"_tSearchString_"', '"_tSearchMode_"') Rank "
		set tSQL = tSQL_"FROM "_..tableName_" WHERE %ID %FIND Demo_SearchPortal.Find("_..qid_") ORDER BY "_$$$QuoteIfReserved(..orderField)_" DESC, Rank DESC"
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute()
		
		write !,"<table class=""table table-hover"">"
		
		while tResult.%Next() {
			write !,"<tr style=""cursor:pointer;"" onclick=""zenPage.selectDocument(",tResult.%Get("ID"),", true);"">"
			write !,"<td><a href=""#"" onclick""zenPage.selectDocument(",tResult.%Get("ID"),", true);"">",tResult.%Get("ID"),"</a></td>"
			write !,"<td>"
			
			set tTitle = tResult.%Get(..titleField)
			set:tTitle="" tTitle = "<i>untitled</i>"
			write !,"<p>", /*tResult.%Get("Year")," - ",tResult.%Get("Issue")," - ","<b>", */ tTitle,"</b>"
			// rather arbitrary score tresholds for now
			set tRank = tResult.%Get("Rank")
			write !,"<span style=""width:20px;"">&nbsp</span>"
			write:tRank>0 "<span class=""glyphicon glyphicon-star"" aria-hidden=""true""></span>"
			write:tRank>0.0001 "<span class=""glyphicon glyphicon-star"" aria-hidden=""true""></span>"
			write:tRank>0.0005 "<span class=""glyphicon glyphicon-star"" aria-hidden=""true""></span>"
			write:tRank>0.001 "<span class=""glyphicon glyphicon-star"" aria-hidden=""true""></span>"
			write:tRank>0.01 "<span class=""glyphicon glyphicon-star"" aria-hidden=""true""></span>"
			
			set tDate = tResult.%Get(..orderField)
			write !,"<br/><span class=""textFragment"">",tResult.%Get("Text"),"</span> - <span class=""publishingDate"">",tDate,"</span></p>"
		
			write !,"</td>"
			write !,"</tr>"
		}
		write !,"</table>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

Method InputTerm(pBase As %String) As %String [ ZenMethod ]
{
	set tFindPrefix = $s(..hasPrivateStorage:..mappingPrefix, 1:"%iFind.")
	set tResult = ##class(%SQL.Statement).%ExecDirect(,"SELECT TOP 12 Entity FROM "_tFindPrefix_"FindEntities('"_pBase_"*', '"_..searchMode_"')") // WHERE EntityId IN (SELECT EntityId FROM poc_cIndexDocument.cIndexDocument_IdxIFind_EntSpreadRec)")
	set tResultString = ""
	while tResult.%Next() {
		set tResultString = tResultString_","_tResult.%GetData(1)
	}
	quit tResultString
}

ClientMethod inputTermClient(text) [ Language = javascript ]
{
	// quit if input string is too short
	if ((text == null) || (text.length < 2))
		return '';
		
	return zenPage.InputTerm(text);
}

ClientMethod onTermKeyUp() [ Language = javascript ]
{
	if (zenEvent && ((zenEvent.keyCode==13) || (zenEvent.which==13))) {
		zenPage.search(zen('txtSearch').getValue());
	}
	return true;
}

Method DrawFacet(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tSQL = "SELECT %EXACT("_pSeed_"), COUNT(*) FROM "_..tableName_" WHERE %ID %FIND Demo_SearchPortal.Find("_..qid_") GROUP BY %EXACT("_pSeed_")"
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute()
		
		write !,"<div class=""panel panel-primary"">"
		write !,"<div class=""panel-heading""><b>Filter by "_pSeed_"</b></div>"
		write !,"<table class=""table table-hover"">"
		//write !,"<tr><th>"_pSeed_"</th><th>Count</th></tr>"
		
		while tResult.%Next() {
			write !,"<tr>"
			write !,"<td><a href=""javascript:zenPage.refine('prop:",pSeed,":",tResult.%GetData(1),"');"">",tResult.%GetData(1),"</a></td>"
			write !,"<td>",tResult.%GetData(2),"</td>"
			write !,"</tr>"
		}
		write !,"</table>"
		write !,"</div>"
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

Method DrawDominantTerms(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		// take TOP 30 as the limit on StrippedEntityId=EntityId may halve (or worse) the list
		set tSQL = "SELECT TOP 30 EntId, SUM(conceptValue) Dom FROM "_..mappingPrefix_"Dom WHERE RecId %FIND Demo_SearchPortal.Find("_..qid_") GROUP BY EntId ORDER BY 2 DESC"
		set tSQL = "SELECT TOP 12 EntId->Value, Dom FROM ("_tSQL_") WHERE EntId->EntityId = EntId->StrippedEntityId"

		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute()
		
		write !,"<div class=""panel panel-primary"">"
		write !,"<div class=""panel-heading""><b>Dominant concepts</b></div>"
		write !,"<table class=""table table-hover"">"
		//write !,"<tr><th>Entity</th><th>Score</th></tr>"
		
		while tResult.%Next() {
			write !,"<tr>"
			write !,"<td>",..DrawEntityLink(tResult.%GetData(1)),"</td>"
			write !,"<td>",tResult.%GetData(2),"</td>"
			write !,"</tr>"
		}
		write !,"</table>"
		write !,"</div>"
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

ClassMethod DrawEntityLink(pEntity As %String) As %String
{
	if ..#IFPENTITYCLICK="drill" {
		quit "<a href=""javascript:zenPage.refine('entity:"_$zconvert(pEntity,"O","JS")_"');"">"_pEntity_"</a>"
	} else {
		quit "<a href=""javascript:zen('txtSearch').setValue('"_$zconvert(pEntity,"O","JS")_"'); zenPage.search('"_$zconvert(pEntity,"O","JS")_"');"">"_pEntity_"</a>"
	}
}

Method DrawSimilarTerms(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tFindPrefix = $s(..hasPrivateStorage:..mappingPrefix, 1:"%iFind.")
		set tSQL = "SELECT TOP 12 e.Entity, COUNT(s.RecId) Spread FROM "_tFindPrefix_"FindEntities(?, ?) e JOIN "_..mappingPrefix_"EntSpreadRec s ON e.EntityId = s.EntityId WHERE RecId %FIND Demo_SearchPortal.Find("_..qid_") GROUP BY Entity ORDER BY Spread DESC"
 
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute(..searchString, ..searchMode)
		
		write !,"<div class=""panel panel-primary"">"
		write !,"<div class=""panel-heading""><b>Similar concepts</b></div>"
		write !,"<table class=""table table-hover"">"
		//write !,"<tr><th>Entity</th><th>Score</th></tr>"
		
		while tResult.%Next() {
			write !,"<tr>"
			write !,"<td>",..DrawEntityLink(tResult.%GetData(1)),"</td>"
			write !,"<td>",tResult.%GetData(2),"</td>"
			write !,"</tr>"
		}
		write !,"</table>"
		write !,"</div>"
		
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

Method DrawRelatedTerms(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		set tFindPrefix = $s(..hasPrivateStorage:..mappingPrefix, 1:"%iFind.")
		set tSQL = "SELECT TOP 30 TargetId, SUM(Value) Prox FROM "_..mappingPrefix_"Prox WHERE RecId %FIND Demo_SearchPortal.Find(?) AND OriginId IN (SELECT EntityId FROM "_tFindPrefix_"FindEntities(?,?)) GROUP BY TargetId ORDER BY Prox DESC"
		set tSQL = "SELECT TOP 12 TargetId->Value, Prox FROM ("_tSQL_") WHERE TargetId->EntityId = TargetId->StrippedEntityId"
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare(tSQL)
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute(..qid, ..searchString, ..searchMode)
		
		write !,"<div class=""panel panel-primary"">"
		write !,"<div class=""panel-heading""><b>Related concepts</b></div>"
		write !,"<table class=""table table-hover"">"
		//write !,"<tr><th>Entity</th><th>Score</th></tr>"
		
		while tResult.%Next() {
			write !,"<tr>"
			write !,"<td>",..DrawEntityLink(tResult.%GetData(1)),"</td>"
			write !,"<td>",tResult.%GetData(2),"</td>"
			write !,"</tr>"
		}
		write !,"</table>"
		write !,"</div>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

Method %OnAfterCreatePage() As %Status
{
	set tSC = ..InitializeTable()
	quit:$$$ISERR(tSC) tSC
	
	if (..searchString'="") {
		set ..%GetComponentById("txtSearch").value = ..searchString
		do ..DoSearch(..searchString, ..searchMD1)
	}
	quit $$$OK
}

Method InitializeTable() As %Status
{
	set tSC = $$$OK
	try {
		// first find table
		if '$system.SQL.TableExists(..tableName, .tMetadata) {
			set tSC = $$$ERROR($$$TableDoesNotExist, ..tableName)
			quit
		}
		set ..className = $lg(tMetadata,3)
		set tClassDef = ##class(%Dictionary.CompiledClass).%OpenId(..className)
		
		// then find and validate index
		if (..indexName'="") {
			set tIndexDef = ##class(%Dictionary.CompiledIndex).%OpenId(..className_"||"_..indexName)
			if '$isobject(tIndexDef) {
				set tSC = $$$ERROR($$$GeneralError, "No index '"_..indexName_"' on table '"_..tableName_"'")
				quit
			} elseif (tIndexDef.TypeClass="") || '$classmethod(tIndexDef.TypeClass,"%IsA","%iFind.Index.Analytic") {
				set tSC = $$$ERROR($$$GeneralError, "Index '"_..indexName_"' on table '"_..tableName_"' is not an analytic one")
				quit
			}
		} else {
			set tIndexDef = ""
			for i = 1:1:tClassDef.Indices.Count() {
				set tIndexType = tClassDef.Indices.GetAt(i).TypeClass
				continue:tIndexType=""
				continue:'$classmethod(tIndexType,"%IsA","%iFind.Index.Analytic")
				set tIndexDef = tClassDef.Indices.GetAt(i), ..indexName = tIndexDef.Name
				quit
			}
		}
		if '$isobject(tIndexDef) {
			set tSC = $$$ERROR($$$GeneralError, "No Analytic iFind index on table '"_..tableName_"'")
			quit
		}
		if ('tIndexDef.Parameters.GetAt("IFINDMAPPINGS")) && ('tIndexDef.Parameters.GetAt("IFINDADVANCED")) {
			set tSC = $$$ERROR($$$GeneralError, "iFind index should have mappings enabled (IFINDMAPPINGS=1)")
			quit
		}
		set tPrefix = tIndexDef.Parameters.GetAt("IFINDADVANCEDSQLPREFIX")
		if (tPrefix = "") {
			set ..mappingPrefix = $tr(..tableName,".","_")_"."_$piece(..tableName,".",*)_"_"_..indexName_"_"
		} else {
			set ..mappingPrefix = $tr(..tableName,".","_")_"."_tPrefix
		}
		set ..hasPrivateStorage = (tIndexDef.Parameters.GetAt("IFINDSHAREDDATALOCATION")'="")&&(tIndexDef.Parameters.GetAt("IFINDSHAREDDATALOCATION")'="NAMESPACE")
		
		// parse columns explicitly supplied through mf URL param
		set tMDCount = $l(..metadataColumns,","), tMetadata=0
		for i = 1:1:tMDCount {
			set tColName = $zstrip($piece(..metadataColumns,",",i),"<>W")
			continue:tColName=""
			set tMetadata($i(tMetadata)) = tColName
			set tMetadataI(tColName) = tMetadata
		}
		
		// append all fields with simple bitmap index
		for i = 1:1:tClassDef.Indices.Count() {
			set tIndexDef = tClassDef.Indices.GetAt(i)
			continue:(tIndexDef.Type'="bitmap")&&(tIndexDef.Type'="bitslice")
			continue:tIndexDef.Extent
			
			set tIndexProps = tIndexDef.Properties
			continue:tIndexProps["," // skip complex ones
			set tIndexProps = $piece(tIndexProps,"(",1) // list indices
			
			if '$d(tMetadataI(tIndexProps)) {
				set tMetadata($i(tMetadata)) = tIndexProps
				set tMetadataI(tIndexProps) = tMetadata
			}
			
			// track index location to cheat in DoSearch()
			if (tMetadata=1)||(tIndexProps=$g(tMetadata(1))) {
				continue:tClassDef.Storages.Count()>1
				#dim tStorageDef as %Dictionary.CompiledStorage = tClassDef.Storages.GetAt(1)
				continue:tStorageDef.Type'="%Library.CacheStorage"
				for j=1:1:tStorageDef.Indices.Count() {
					continue:tStorageDef.Indices.GetAt(j).Name'=tIndexDef.Name
					set ..metadata1Index = tStorageDef.Indices.GetAt(j).Location
					quit
				}
				continue:..metadata1Index'=""
				set ..metadata1Index = $s($e(tStorageDef.IndexLocation,*)=")":$e(tStorageDef.IndexLocation,1,*-1)_",", 1:tStorageDef.IndexLocation_"(")_$$$QUOTE(tIndexDef.Name)_")"
			}
		}
		
		// now fetch corresponding SqlFieldNames
		for i = 1:1:tMetadata {
			set tColDef = ##class(%Dictionary.CompiledProperty).%OpenId(..className_"||"_tMetadata(i))
			set:tColDef.SqlFieldName'="" tMetadata(i) = tColDef.SqlFieldName
			set ..metadataParsed = ..metadataParsed_$s(i=1:"",1:",")_tMetadata(i)
		}
		
		// retrieve title and order fields
		for i = 1:1:tClassDef.Properties.Count() {
			set tColDef = tClassDef.Properties.GetAt(i)
			if ((..titleField="") && ($$$UPPER(tColDef.Name)["TITLE")) || ($$$UPPER(tColDef.Name)="TITLE") {
				set ..titleField = tColDef.Name
			}
			if ((..orderField="") && (($$$UPPER(tColDef.Name)["DATE") || ($$$UPPER(tColDef.Type)["DATE"))) {
				set ..orderField = tColDef.Name
			}
		}
		set:..titleField="" ..titleField = "ID"
		set:..orderField="" ..orderField = "ID"
		
		// now update all code referring to the table and/or index name
		set tSelType = ..%GetComponentById("selMD1")
		if (tMetadata) {
			set tSelType.sql = $replace(tSelType.sql,"$$$TABLE",..tableName)
			set tSelType.sql = $replace(tSelType.sql,"$$$MD1",tMetadata(1))
			set tSelType.title = $tr(tMetadata(1),"_"," ")
		} else {
			set tSelType.hidden = 1
		}
		
		if (tMetadata) {
			set ..%GetComponentById("htmlFilterFacet").seed = tMetadata(1)
		} else {
			set ..%GetComponentById("htmlFilterFacet").hidden = 1
		}
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit tSC
}

Method ErrorHandler(pSC As %Status) As %Status
{
	if $$$ISERR(pSC) {
		set tMessage = $zconvert($system.Status.GetErrorText(pSC),"O","JS")
		&js<console.log('ERROR: #(tMessage)#')>
	}
	quit pSC
}

Method DrawDocument(pSeed As %String) As %Status
{
	set tSC = $$$OK
	try {
		quit:'pSeed
		
		set tHighlightTags = "<a class=""searchMatch"" name=""firsthit"">,<a class=""searchMatchNeg"" name=""firsthit"">"
		set tObj = $classmethod(..className, "%OpenId", pSeed)
		set tTitle = $s(..titleField="ID":$method(tObj,"%Id"), 1:$property(tObj, ..titleField))
		
		if (..originalTextField'="") {
			set tLongString = $property(tObj, ..originalTextField)
		
			// now isolate <body> contents
			set tLongString = $e(tLongString,$find(tLongString,">",$find(tLongString,"<body")),*)
			set tLongString = $e(tLongString,1,$find(tLongString,"</body")-7)
			
			// decode &xxxx; and translate some pesky chars
			set tLongString = $translate(tLongString,$c(160)," ")
			set tLongString = $zcvt(tLongString,"I","HTML")
			
			// ensure strings are separated from tags
			set tLongString = $replace(tLongString,"<"," <")
			set tLongString = $replace(tLongString,">","> ")
			
			set tLongString = ##class(%iFind.Utils).Highlight(tLongString, ..searchString, ..searchMode, tHighlightTags)
			
		} else {
			set tLongString = $classmethod(..className, ..indexName_"Highlight", pSeed, ..searchString, ..searchMode, tHighlightTags)
		}
		
		write !,"<div id=""docModal"" class=""modal fade"" role=""dialog"">"
		write !,"  <div class=""modal-dialog"">"
		write !,"    <div class=""modal-content"">"
		write !,"      <div class=""modal-header"">"
		write !,"        <button type=""button"" class=""close"" data-dismiss=""modal"">&times;</button>"
		write !,"        <h4 class=""modal-title"">"_tTitle_"</h4>"
		write !,"      </div>"
		write !,"      <div class=""modal-body"">"
		write $replace(tLongString," </a>","</a>")
		write !,"      </div>"
		write !,"      <div class=""modal-footer"" style=""text-align: left;"">"
		write !,"		<p>Similar records:</p>"
		write !,"        <ul>"
		
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare("SELECT TOP 5 RecordID FROM Demo_SearchPortal.FindSimilar(?,?,?)")
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute(..tableName, ..indexName, pSeed)
		while tResult.%Next() {
			set tOtherRecordID = tResult.%GetData(1)
			set tOtherRecord = $classmethod(..className, "%OpenId", tOtherRecordID)
			if (..titleField'="ID") {
				set tString = $property(tOtherRecord, ..titleField)
			} elseif (..originalTextField'="") {
				set tString = $e($property(tOtherRecord,..originalTextField), 1, 40)_"..."
			} else {
				set tString = $e($classmethod(..className, ..indexName_"Highlight", tOtherRecordID, ..searchString, ..searchMode, tHighlightTags), 1, 40)_"..."
			}
			write !,"       <li><a href=""#"" onclick=""zenPage.selectDocument('"_tOtherRecordID_"', false);"">"_tString_"</a></li>"
		}
		
		write !,"       </ul>"
		write !,"      </div>"
		write !,"    </div>"
		write !,"  </div>"
		write !,"</div>"
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	quit ..ErrorHandler(tSC)
}

Method GetDocumentDetails(pID As %String) As %ZEN.proxyObject [ ZenMethod ]
{
	set tSC = $$$OK
	try {
		set tProxy = ##class(%ZEN.proxyObject).%New()
		quit:'pID
		
		set tHighlightTags = "<a class=""searchMatch"" name=""firsthit"">,<a class=""searchMatchNeg"" name=""firsthit"">"
		set tObj = $classmethod(..className, "%OpenId", pID)
		set tProxy.Title = $s(..titleField="ID":$method(tObj,"%Id"), 1:$property(tObj, ..titleField))
		
		if (..originalTextField'="") {
			set tLongString = $property(tObj, ..originalTextField)
		
			// now isolate <body> contents
			set tLongString = $e(tLongString,$find(tLongString,">",$find(tLongString,"<body")),*)
			set tLongString = $e(tLongString,1,$find(tLongString,"</body")-7)
			
			// decode &xxxx; and translate some pesky chars
			set tLongString = $translate(tLongString,$c(160)," ")
			set tLongString = $zcvt(tLongString,"I","HTML")
			
			// ensure strings are separated from tags
			set tLongString = $replace(tLongString,"<"," <")
			set tLongString = $replace(tLongString,">","> ")
			
			set tLongString = ##class(%iFind.Utils).Highlight(tLongString, ..searchString, ..searchMode, tHighlightTags)
			
		} else {
			set tLongString = $classmethod(..className, ..indexName_"Highlight", pID, ..searchString, ..searchMode, tHighlightTags)
		}
		set tProxy.Text = $replace(tLongString," </a>","</a>")
		
		//set tProxy.Similar = ##class(%ListOfObjects).%New()
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare("SELECT TOP 5 RecordID FROM Demo_SearchPortal.FindSimilar(?,?,?)")
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute(..tableName, ..indexName, pID), tCount=0
		while tResult.%Next() {
			set tOtherRecordID = tResult.%GetData(1)
			set tOtherRecord = $classmethod(..className, "%OpenId", tOtherRecordID)
			if (..titleField'="ID") {
				set tString = $property(tOtherRecord, ..titleField)
			} elseif (..originalTextField'="") {
				set tString = $e($property(tOtherRecord,..originalTextField), 1, 40)_"..."
			} else {
				set tString = $e($classmethod(..className, ..indexName_"Highlight", tOtherRecordID, ..searchString, ..searchMode, tHighlightTags), 1, 40)_"..."
			}
			set tString = $method(tOtherRecord,"%Id")_": "_tString
			/*set tProxy2 = ##class(%ZEN.proxyObject).%New()
			set tProxy2.ID = tOtherRecordID
			set tProxy2.Title = tString
			do tProxy.Similar.Insert(tProxy2)*/
			// ridiculous alternative as ZenMethods don't allow returning nested JSON:
			set $property(tProxy, "Similar"_$i(tCount)_"ID") = tOtherRecordID
			set $property(tProxy, "Similar"_tCount_"Text") = tString
		}
		set tProxy.SimilarCount = tCount
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	do ..ErrorHandler(tSC)
	quit tProxy
}

ClassMethod ClearHistory(pQID As %Integer) As %Status
{
	set tParent = $g(^CacheTemp.IF.SearchPortal.Query(pQID,"parent"))
	kill ^CacheTemp.IF.SearchPortal.Query(pQID)
	quit $s(tParent:..ClearHistory(tParent), 1:$$$OK)
}

}
