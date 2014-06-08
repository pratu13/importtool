// Licence: Lesser GNU Public License 2.1 (LGPL)
#pragma rtGlobals=3		// Use modern global access method.

// The Sietronics Sieray CPI procedure is based on xylib by Marcin Wojdyr:
// https://github.com/wojdyr/xylib (https://github.com/wojdyr/xylib/blob/master/xylib/cpi.cpp)


Menu "Macros"
	submenu "Import Tool "+importloaderversion
			submenu "XRD"
				"Load Sietronics Sieray 			*.cpi	file... b1",  Cpi_load_data()
			end
	end
end

// ###################### Sietronics Sieray CPI ########################
// Sietronics Sieray CPI format
// format example:

// SIETRONICS XRD SCAN
// 10.00
// 155.00
// 0.010
// Cu
// 1.54056
// 1-1-1900
// 0.600
// HH117 CaO:Nb2O5 neutron batch .0
// SCANDATA
// 8992
// 9077
// 9017
// 9018
// 9129
// 9057
// ...
// 

static function Cpi_check(file)
	variable file
	string line
	line = read_line_trim(file)
	if(cmpstr(line,"SIETRONICS XRD SCAN")==0)
		return 1
	endif
	return 0
end


function Cpi_load_data()
	string dfSave=""
	variable file
	string impname="Sietronics Sieray CPI"
	string filestr="*.cpi"
	string header = loaderstart(impname, filestr,file,dfSave)
		if (strlen(header)==0)
		return -1
	endif

	string s
	read_line_trim(file) // first line
	variable xmin = read_line_int(file)
	variable xmax = read_line_int(file)
	variable xstep = read_line_int(file)
	string anode = read_line_trim(file)
	string wavelength = read_line_trim(file)
	string dates = read_line_trim(file)
	string misc = read_line_trim(file)
	string expname = read_line_trim(file)
	string tmps = cleanname(expname)
	variable ncount = (xmax-xmin)/xstep+1
	Make /O/R/N=(ncount)  $tmps /wave=ycols
	Debugprintf2("Start: "+num2str(xmin),1)
	Debugprintf2("Stop: "+num2str(xmax),1)
	Debugprintf2("Step: "+num2str(xstep),1)
	Debugprintf2("#Counts: "+num2str(ncount),1)
	
	SetScale/P  x,xmin,xstep,"", ycols
	note ycols, header
	Note ycols, "Expname: " +expname
	Note ycols, "Misc: " + misc
	Note ycols, "Date: " + dates
	Note ycols, "Anode: " + anode
	Note ycols, "Wavelength: " + wavelength
	
	// ignore the rest of the header
	do
		s=read_line_trim(file)
		if(cmpstr(s, "SCANDATA") == 0)
			//print s
			break
		endif
		Fstatus file
	while(V_logEOF>V_filePOS)
	
	// data
	variable i = 0
	do
		FReadLine file, s
		if(strlen(s) == 0)
			break
		endif
		s=mycleanupstr(s)
		ycols[i] = str2num(s)	
		i+=1	
		fstatus file
	while(V_logEOF>V_filePOS)
	
	if(i != ncount)
		Debugprintf2("Datacount different from expected!"+num2str(i)+ " <> " +num2str(ncount),0)
	endif
	loaderend(impname,1,file, dfSave)
end


// ###################### Sietronics Sieray CPI END ######################
