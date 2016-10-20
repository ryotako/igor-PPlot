#pragma ModuleName=PPlot

/////////////////////////////////////////////////////////////////////////////////
// Menu /////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
strconstant PPlot_Menu="PPlot"

Menu StringFromList(0,PPlot_Menu)
	RemoveListItem(0,PPlot_Menu)
	"Summary Plot",/Q,PPlot#MenuCommandSummaryPlot()
	"\M0Summary Plot (Rec)",/Q,PPlot#MenuCommandSummaryPlot(recursive=1)
	Submenu "Gradation"
		"*COLORTABLEPOP*(Rainbow)",/Q,PPlot#MenuCommandGradation()
	End
	"\M0Gradation (Rainbow)",/Q,PPlot#Gradate("","Rainbow")
	"Auto Format",/Q,PPlot#Format("")
	"Auto Legand",/Q,PPlot#LegandFromFolderName("")
   "Reverse Legend Order",/Q,PPlot#ReverseLegendOrder("","")
	"Reverse Trace Order",/Q,PPlot#ReverseTraceOrder("")
End

static Function MenuCommandSummaryPlot([recursive])
	Variable recursive
	String wlist=""
	DFREF here = GetDataFolderDFR()
	Variable i,N=CountObjects(":",4)
	for(i=0;i<N;i+=1)
		SetDataFolder $":"+PossiblyQuoteName(GetIndexedObjName(":",4,i))
		wlist=AddListItem(wList,WaveList("*",";","TEXT:0,DIMS:1"))
		SetDataFolder here
	endfor
	wlist=Unique(wlist)
	String wNameX,wNameY
	Prompt wNameX,"X Wave:",popup,wlist
	Prompt wNameY,"Y Wave:",popup,wlist
	DoPrompt/HELP="" "SummaryPlot",wNameY,wNameX
	if(V_Flag)
		return NaN
	endif
	String graph=""
	if(recursive)
		graph=SummaryPlotRecursive("",wNameX,wNameY)	
	else
		graph=SummaryPlot("",wNameX,wNameY)
	endif
	if(strlen(graph))
		Format(graph)
		Gradate(graph,"Rainbow")
		LegandFromFolderName(graph,root=GetDataFolder(1))
	endif
End
Function/S Unique(list)
	String list
	String buf=""
	do
		String item = StringFromList(0,list)
		buf+=item+";"
		list=RemoveFromList(item,list)
	while(ItemsInList(list))
	return RemoveFromList("",buf)
End

static Function MenuCommandGradation()
	GetLastUserMenuInfo
	PPlot#Gradate("",S_Value)
End

/////////////////////////////////////////////////////////////////////////////////
// Functions ////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
Function/S GraphName(s)
	String s
	if(strlen(s))
		String gs=WinList(s,";","WIN:1")
		return StringFromList(WhichListItem(s,gs),gs)
	else
		return WinName(0,1,1)
	endif
End

static Function/S Format(graph)
	String graph
	graph = GraphName(graph)
	if(strlen(graph))
		ModifyGraph/W=$graph tick=2     // inside ticks
		ModifyGraph/W=$graph mirror=1   // mirror axis 
		ModifyGraph/W=$graph standoff=0 // no statndoff
		ModifyGraph/W=$graph lsize=1.5  // line width
		ModifyGraph/W=$graph gFont="Arial",gfSize=16
		return graph
	endif
	return ""
End

static Function/S SummaryPlot(root,wNameX,wNameY)
	String root,wNameX,wNameY
	root = RemoveEnding(root,":")+":"
	if(DataFolderExists(root))
		Display as GetDataFolder(1)+" "+wNameY+SelectString(strlen(wNameX),""," vs "+wNameX)
		SummaryPlot_(root,wNameX,wNameY)
		return S_Name
	endif
	return ""
End

static Function SummaryPlot_(root,wNameX,wNameY)
	String root,wNameX,wNameY
		DFREF here = GetDataFolderDFR()
		SetDataFolder $root
		DFREF there = GetDataFolderDFR()		
		Variable i,N=CountObjects(root,4)
		for(i=0;i<N;i+=1)
			SetDataFolder $":"+PossiblyQuoteName(GetIndexedObjName(":",4,i))
			WAVE wX=$PossiblyQuoteName(wNameX)
			WAVE wY=$PossiblyQuoteName(wNameY)
			if(WaveExists(wY) && WaveExists(wX))
				AppendToGraph wY vs wX
			elseif(WaveExists(wY))
				AppendToGraph wY
			endif
			SetDataFolder there
		endfor
		SetDataFolder here
End

static Function/S SummaryPlotRecursive(root,wNameX,wNameY)
	String root,wNameX,wNameY
	root = RemoveEnding(root,":")+":"
	if(GrepString(root,"^:"))
		root=RemoveEnding(GetDataFolder(1),":")+root
	endif
	if(DataFolderExists(root))
		Display as GetDataFolder(1)+" "+wNameY+SelectString(strlen(wNameX),""," vs "+wNameX)
		SummaryPlotRecursive_(root,wNameX,wNameY)
		return S_Name
	endif
	return ""
End

static Function/S SummaryPlotRecursive_(root,wNameX,wNameY)
	String root,wNameX,wNameY
	SummaryPlot_(root,wNameX,wNameY)
	Variable i,N=CountObjects(root,4)
	for(i=0;i<N;i+=1)
		String sub=root+PossiblyQuoteName(GetIndexedObjName(root,4,i))+":"
		SummaryPlotRecursive_(sub,wNameX,wNameY)
	endfor	
End

static Function/S Gradate(graph,cTabName)
	String graph,cTabName
	graph = GraphName(graph)
	WAVE colors = ColorTable(cTabName)
	if(strlen(graph))
		if(DimSize(colors,0))
			String traces=TraceNameList(graph,";",2^0+2^2) // without invisible plots
			Variable i,N=ItemsInList(traces)
			for(i=0;i<N;i+=1)
				Variable j=(DimSize(colors,0)/(N-1))*i
				ModifyGraph/W=$graph rgb($StringFromList(i,traces))=(colors[j][0],colors[j][1],colors[j][2])
			endfor
		endif
		return graph
	endif
	return ""
End
static Function/WAVE ColorTable(cTabName)
	String cTabName
	if(WhichListItem(cTabName,CTabList())>=0)
		DFREF here=GetDataFolderDFR()
		SetDataFolder NewFreeDataFolder()
		ColorTab2Wave $cTabName
		Duplicate/FREE M_colors w
		SetDataFolder here
	else
		Make/FREE/N=(0,0) w
	endif
	return w
End

static Function/S LegandFromFolderName(graph [root])
	String graph,root
	graph = GraphName(graph)
	if(strlen(graph))
		String buf=""
		String traces=TraceNameList(graph,";",2^0)
		Variable i,N=ItemsInList(traces)
		for(i=0;i<N;i+=1)
			WAVE w=WaveRefIndexed(graph,i,1)
			String df=GetWavesDataFolder(w,1)
			if(ParamIsDefault(root) || cmpstr(df[0,strlen(root)-1],root))
				df=GetWavesDataFolder(w,0)
			else
				df=RemoveEnding(df[strlen(root),inf],":")
			endif
			SplitString/E="^'?(.*)'?$" df,df
			sprintf buf,"%s\\s(%s) %s\r",buf,StringFromList(i,traces),df
		endfor
		Legend/A=RC/B=1/F=0/H=30/J RemoveEnding(buf,"\r")
		return graph	
	endif
	return ""
End

static Function/S ReverseTraceOrder(graph)
	String graph
	graph = GraphName(graph)
	if(strlen(graph))	
		String traces=TraceNameList(graph,";",2^0)
		Variable i,N=ItemsInList(traces)
		for(i=0;i<N-1;i+=1)
			ReorderTraces $StringFromList(i,traces),{$StringFromList(N-1,traces)}
		endfor
		return graph
	endif
	return ""
End

static Function/S ReverseLegendOrder(graph,textName)
	String graph,textName
	graph = GraphName(graph)
	if(strlen(graph))
		if(strlen(textName)==0)
			textName=StringFromList(0,AnnotationList(graph))
		endif
		String oldText=ReplaceString("\\r",StringByKey("TEXT",AnnotationInfo(graph,textName)),"\r")
		if(strlen(oldText))
			String newText=""
			Variable i,N=ItemsInList(oldText,"\r")
			for(i=0;i<N;i+=1)
				newText+=StringFromList(N-1-i,oldText,"\r")+"\r"
			endfor
			newText=RemoveEnding(newText,"\r")			
		endif
		Legend/C/N=$textName/W=$graph ReplaceString("\\\\",newText,"\\")
		return graph
	endif
	return ""
End