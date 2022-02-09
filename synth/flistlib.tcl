# Flat flist from Hier flist
proc flisth2f {ifpath} {
    set ifname [string trim [file tail $ifpath]]

    set flsub "flisth2f.sub"
    
    exec envsubst <$ifpath >$flsub

    set fd [open $flsub "r"]
    set frdata [read $fd]
    close $fd

    set ofilelist {}

    set rdata [split $frdata "\n"]
    foreach  rline $rdata {
        if {[string first "\-f" $rline] != -1} {
            #puts -nonewline "include filelist: "
            #puts $rline
            set incldata [split $rline " "]
            #puts [lindex $incldata 1]
            set incfilepath [lindex $incldata 1]
            set incfilelist [flisth2f $incfilepath]
            #puts $incfilelist
            set ofilelist [concat $ofilelist $incfilelist]
        } else {
            lappend ofilelist $rline
        }
    }

    file delete $flsub
    
    return $ofilelist
}

proc flistflat {ifpath} {

    set ifname [string trim [file tail $ifpath]]
    
    append ofname $ifname ".flat"
    
    set ofilelist [flisth2f $ifpath]
    
    set fd [open $ofname "w"]
    
    foreach  wline $ofilelist {
        puts $fd $wline
    }
    close $fd
}

proc getfilelist {fname} {
    
    set fd [open $fname "r"]
    set frdata [read $fd]
    close $fd
    
    set filelist {}
    
    set rdata [split $frdata "\n"]
    foreach  rline $rdata {
        if {[string first "#" $rline] != -1} {
            #puts -nonewline "exclude: "
            #puts $rline
        } elseif {[string first "//" $rline] != -1} {
            #puts -nonewline "exclude: "
            #puts $rline
        } elseif {[string equal [string trim $rline] ""] == 1} {
            #puts -nonewline "exclude1: "
            #puts [string trim $rline]
        } else {
            #puts -nonewline "file: "
            #puts $rline
            lappend filelist $rline
        }
    }
    
    return $filelist
}


#set fpath "../build/flist"
#set ifname [string trim [file tail $fpath]]
#append ofname $ifname ".flat"

# Create a flat flist file
#set ofilelist [flistflat $fpath]
# Read a flat flist into tcl list
#set filelist [getfilelist $ofname]


