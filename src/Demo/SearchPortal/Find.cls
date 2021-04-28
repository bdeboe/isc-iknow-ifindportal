Include %IFInclude

Class Demo.SearchPortal.Find Extends %SQL.AbstractFind
{

ClassMethod Find(pQID As %Integer) As %SQL.AbstractFind [ SqlName = Find, SqlProc ]
{
	set f = ..%New()
	set f.qid = pQID
	quit f
}

Property qid As %Integer;

Method ContainsItem(pItem As %String) As %Boolean
{
	$$$IFBITOFFPOS(pItem,tChunk,tPos)
	quit $bit(^CacheTemp.IF.SearchPortal.Query(i%qid,"b",tChunk),tPos)
}

Method GetChunk(pChunk As %Integer) As %Binary
{
	quit $g(^CacheTemp.IF.SearchPortal.Query(i%qid,"b",pChunk))
}

Method NextChunk(ByRef pChunk As %Integer = "") As %Binary
{
	set pChunk = $order(^CacheTemp.IF.SearchPortal.Query(i%qid,"b",pChunk),1,tBits)
	quit $g(tBits)
}

Method PreviousChunk(ByRef pChunk As %Integer = "") As %Binary
{
	set pChunk = $order(^CacheTemp.IF.SearchPortal.Query(i%qid,"b",pChunk),-1,tBits)
	quit $g(tBits)
}

}
