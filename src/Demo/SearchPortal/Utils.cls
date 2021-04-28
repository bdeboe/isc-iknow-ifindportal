Class Demo.SearchPortal.Utils
{

Query FindSimilar(pTableName As %String, pIndexName As %String, pRecordID As %CacheString) As %Query(ROWSPEC = "RecordId:%CacheString,Score:%Numeric,Count:%Integer") [ SqlName = FindSimilar, SqlProc ]
{
}

ClassMethod FindSimilarExecute(ByRef qHandle As %Binary, pTableName As %String, pIndexName As %String, pRecordID As %CacheString) As %Status [ Internal ]
{
	set tSC = $$$OK
	try {
random	set tRID = $random(99999)
		set x = $i(^||%IF.FindSimilar(tRID))
		goto:x>1 random  // retry if we weren't the first one
		
		set qHandle = $lb(tRID, 0)
		kill ^||%IF.FindSimilar(tRID)
		
		kill ^||%IF.TempAgg, ^||%IF.TempSorted
		
		if '$system.SQL.TableExists(pTableName,.tMetadata) {
			set tSC = $$$ERROR($$$TableDoesNotExist, pTableName)
			quit
		}
		set tClassName = $lg(tMetadata,3)
		set tIndexDef = ##class(%Dictionary.CompiledIndex).%OpenId(tClassName_"||"_pIndexName)
		if '$isobject(tIndexDef) {
			set tSC = $$$ERROR($$$GeneralError, "No index '"_pIndexName_"' found in table '"_pTableName_"'")
			quit
		}
		if (tIndexDef.TypeClass="") || '$classmethod(tIndexDef.TypeClass,"%IsA","%iFind.Index.Analytic") {
			set tSC = $$$ERROR($$$GeneralError, "Index '"_pIndexName_"' in table '"_pTableName_"' is not an iFind Analytic index")
			quit
		}
		if 'tIndexDef.Parameters.GetAt("IFINDMAPPINGS") {
			set tSC = $$$ERROR($$$GeneralError, "Index '"_pIndexName_"' in table '"_pTableName_"' does not have its IFINDMAPPINGS parameter enabled")
			quit
		}
		
		set tPrefix = tIndexDef.Parameters.GetAt("IFINDADVANCEDSQLPREFIX")
		set:tPrefix="" tPrefix = $p(pTableName,".",*)_"_"_pIndexName_"_"
		set tPackage = $tr(pTableName,".","_")_"."_tPrefix
		
		
		// step 1: fetch entities best representing this record based on dominance
		set tStatement = ##class(%SQL.Statement).%New()
		set tSC = tStatement.%Prepare("SELECT COUNT(*) FROM "_tPackage_"Dom WHERE RecId = ? AND conceptValue > 0")
		quit:$$$ISERR(tSC)
		set tResult = tStatement.%Execute(pRecordID)
		set tConceptCount = tResult.%GetData(1)
		set tWindowSize = $s(tConceptCount>250:50, tConceptCount>150:tConceptCount*0.2, tConceptCount>100:tConceptCount*0.3, tConceptCount>50:0.4, tConceptCount>25:0.7, 1:20)
		
		set tSC = tStatement.%Prepare("SELECT TOP ? EntId, conceptValue FROM "_tPackage_"Dom WHERE RecId = ? AND conceptValue > 0 ORDER BY conceptValue DESC")
		quit:$$$ISERR(tSC)
		
		set tResult = tStatement.%Execute(tWindowSize, pRecordID), tEntList=""
		while tResult.%Next() {
			set tEntityId = tResult.%Get("EntId")
			set tEntList = tEntList_$s(tEntList="":"",1:",")_tEntityId
			set tSourceWeights(tEntityId) = tResult.%Get("conceptValue")
		}
		
		// step 2: fetch records containing any of these and sort by match count
		set tSC = tStatement.%Prepare("SELECT RecId FROM "_tPackage_"Ent WHERE EntityId = ? AND RecId != ?")
		quit:$$$ISERR(tSC)
		
		set tEntityId = ""
		for {
			set tEntityId = $order(tSourceWeights(tEntityId))
			quit:tEntityId=""
			
			set tResult = tStatement.%Execute(tEntityId, pRecordID)
			while tResult.%Next() {
				set tRecId = tResult.%Get("RecId")
				set ^||%IF.TempAgg(tRecId) = $g(^||%IF.TempAgg(tRecId))+1
				set ^||%IF.TempAgg(tRecId, tEntityId) = ""
			}
		}
		
		// TODO: if the max number of results is known, we could do optimizations
		// based on what we know thus far. Let's keep it simple for now.
		set tSC = tStatement.%Prepare("SELECT EntId, conceptValue FROM "_tPackage_"Dom WHERE RecId = ? AND EntId IN ("_tEntList_")")
		quit:$$$ISERR(tSC)
		set tRecId = "", x = $sortbegin(^||%IF.TempSorted)
		for {
			set tRecId = $order(^||%IF.TempAgg(tRecId),1,tCount)
			quit:tRecId=""
			
			set tResult = tStatement.%Execute(tRecId), tScore=0
			while tResult.%Next() {
				set tScore = tScore + (tResult.%Get("conceptValue") * tSourceWeights(tResult.%Get("EntId")))
			}
			
			set ^||%IF.TempSorted(-tScore,tRecId)=$lb(tCount)
		}
		set x = $sortend(^||%IF.TempSorted)
		kill ^||%IF.TempSorted(0)
		
		set tScore = ""
		for {
			set tScore = $order(^||%IF.TempSorted(tScore))
			quit:tScore=""
			
			set tRecId = ""
			for {
				set tRecId = $order(^||%IF.TempSorted(tScore,tRecId),1,tData)
				quit:tRecId=""
				
				set ^||%IF.FindSimilar(tRID) = 1+$g(^||%IF.FindSimilar(tRID))
				set ^||%IF.FindSimilar(tRID,^||%IF.FindSimilar(tRID)) = $lb(tRecId, -tScore)_tData
			}
		}

	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	kill ^||%IF.TempAgg, ^||%IF.TempSorted
	quit tSC
}

ClassMethod FindSimilarClose(ByRef qHandle As %Binary) As %Status [ Internal, PlaceAfter = FindWordsExecute ]
{
	kill ^||%IF.FindSimilar(+$lg(qHandle,1))
	quit $$$OK
}

ClassMethod FindSimilarFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ Internal, PlaceAfter = FindWordsExecute ]
{
	set tRID = +$lg(qHandle,1), tPrevious=$lg(qHandle,2)
	set tNext = $order(^||%IF.FindSimilar(tRID, tPrevious),1,tData)
	if tNext="" {
		set AtEnd=1, qHandle=$lb(tRID), Row=""
	} else {
		set AtEnd=0, $li(qHandle,2)=tNext
		set Row = tData
	}
	quit $$$OK
}

}
