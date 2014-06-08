// Licence: Lesser GNU Public License 2.1 (LGPL)
#pragma rtGlobals=3		// Use modern global access method.

// The Dbws procedure is based on xylib by Marcin Wojdyr:
// https://github.com/wojdyr/xylib (https://github.com/wojdyr/xylib/blob/master/xylib/dbws.cpp)


Menu "Macros"
	submenu "Import Tool "+importloaderversion
			submenu "XRD"
				"Load DBWS	 		*.dwb *.rit	*.neu	file... b1", Dbws_load_data()
			end
	end
end

// ###################### DBWS data file ########################

static function Dbws_check(file)
	variable file
	string line
	line=read_line_trim(file) // first line
	if(strlen(line)<3*8)
		return 0
	endif
	// the first line should be in format (3F8.2, A48), but sometimes
	// the number of digits after the decimal point is 3 or 4
	if( (numtype(str2num(line[0,7]))!=0) || (numtype(str2num(line[8,15]))!=0) || (numtype(str2num(line[16,23]))!=0))
		return 0
	endif
	variable start = str2num(line[0,7])
	variable step = str2num(line[8,15])
	variable stop = str2num(line[16,23])
	if (step <0 || (start+step) > stop)
		return 0
	endif
	variable count = (stop-start)/step+1
	if((floor(count+0.5)-count) > 1e-6)
		return 0
	endif
	return 1
end

static function Dbws_load_data()
	string dfSave=""
	variable file
	string impname="DBWS"
	string filestr="*.dbw,*.rit,*.neu"
	string header = loaderstart(impname, filestr,file,dfSave)
		if (strlen(header)==0)
		return -1
	endif
	
	string s
	s=read_line_trim(file) // first line
	if(strlen(s)<3*8)
		Debugprintf2("Header to short!",0)
		close file
		return -1
	endif
	
	string name = s[24,inf]
	variable start = str2num(s[0,7])
	variable step = str2num(s[8,15])
	variable stop = str2num(s[16,23])
	Debugprintf2("Full header: "+s,1)
	//Debugprintf2("Start: "+num2str(start),0)
	//Debugprintf2("Step: "+num2str(step),0)
	//Debugprintf2("Stop: "+num2str(stop),0)
	Debugprintf2("Start: "+s[0,7]+" ; "+num2str(start),1)
	Debugprintf2("Step: "+s[8,15]+" ; "+num2str(step),1)
	Debugprintf2("Stop: "+s[16,23]+" ; "+num2str(stop),1)
	Debugprintf2("Name: "+name,1)
	
	string tmps = cleanname(name)
	Make /O/R/N=(0)  $tmps /wave=ycols
	note ycols, header
	note ycols, "Exp.name: "+name
	note ycols, "Start: "+num2str(start)
	note ycols, "Stop: "+num2str(stop)
	note ycols, "Step: "+num2str(step)
	
	SetScale/P  x,start,step,"", ycols
	// data
	variable size = 0
	variable j=0
	string sep = ","
	do
		FReadLine file, s // first line
		if(strlen(s)==0)
			break
		endif
		s=mycleanupstr(s)
		// numbers delimited by commas or spaces.
		if(strsearch(s,sep,0)!=-1)
			s= stripstr(s," ","")
		else
			if(strsearch(s,"\t",0)==-1)
				s=splitintolist(s, " ")
				sep = "_"
			else
				s=splitintolist(s, "\t")
				sep = "_"
			endif
		endif

		for(j=0;j<itemsinlist(s,sep);j+=1)
			if(numtype(str2num(StringFromList(j,s,sep))) != 0)
				Debugprintf2("Numeric value expected",0)
				close file
				return -1
			endif
			Redimension/N=(size+1) ycols
			ycols[size] = str2num(StringFromList(j,s,sep))
			size+=1
		endfor
		Fstatus file
	while(V_logEOF>V_filePOS)

	if(size != (stop-start)/step+1)
		Debugprintf2("Datacount different from expected!"+num2str(size)+ " <> " +num2str((stop-start)/step+1),0)
	endif

	loaderend(impname,1,file, dfSave)
end
// ###################### DBWS data file END ######################
