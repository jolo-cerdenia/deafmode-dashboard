# dm-parser.tcl
# version: 0.1
#
# purpose:
# fetch deafmode signal.json
# emit operational inferences to IRC
#
# requirements:
# package require http
# package require json
#
# tested conceptually for Eggdrop Tcl 8.6+

package require http
package require json

namespace eval deafmode {
    variable signal_url "https://deafmo.de/dashboard/signal.json"
    variable channel "#deafmode"

    variable last_state ""
    variable debug 1
}

# --------------------------------------------------
# debug logger
# --------------------------------------------------

proc deafmode::debug {msg} {
    variable debug

    if {$debug} {
        putlog "\[deafmode\] $msg"
    }
}

# --------------------------------------------------
# fetch signal.json
# --------------------------------------------------

proc deafmode::fetch_signal {} {
    variable signal_url

    debug "fetching signal data"

    set token [http::geturl $signal_url -timeout 10000]

    if {[http::status $token] ne "ok"} {
        debug "http fetch failed"
        http::cleanup $token
        return ""
    }

    set data [http::data $token]

    http::cleanup $token

    return $data
}

# --------------------------------------------------
# parse json safely
# --------------------------------------------------

proc deafmode::parse_signal {raw_json} {

    if {$raw_json eq ""} {
        return ""
    }

    if {[catch {
        set parsed [json::json2dict $raw_json]
    } err]} {
        debug "json parse failure: $err"
        return ""
    }

    return $parsed
}

# --------------------------------------------------
# emit formatted signal line
# --------------------------------------------------

proc deafmode::emit_signal {parsed} {
    variable channel
    variable last_state

    set signal_dict [dict get $parsed signal]

    set current_state [dict get $signal_dict state]

    set inference_list [dict get $parsed inference]

    set primary_inference [lindex $inference_list 0]

    # ----------------------------------------------
    # state transition detection
    # ----------------------------------------------

    if {$last_state ne "" && $last_state ne $current_state} {

        puthelp "PRIVMSG $channel :$begin:math:display$state$end:math:display$ $last_state → $current_state"

        debug "state transition emitted"
    }

    set last_state $current_state

    # ----------------------------------------------
    # primary inference emission
    # ----------------------------------------------

    puthelp "PRIVMSG $channel :$begin:math:display$inference$end:math:display$ $primary_inference"

    debug "inference emitted"
}

# --------------------------------------------------
# hourly update loop
# --------------------------------------------------

proc deafmode::update_loop {} {

    debug "starting update cycle"

    set raw_json [fetch_signal]

    if {$raw_json eq ""} {
        debug "empty signal payload"

        utimer 3600 deafmode::update_loop
        return
    }

    set parsed [parse_signal $raw_json]

    if {$parsed eq ""} {
        debug "parsed signal invalid"

        utimer 3600 deafmode::update_loop
        return
    }

    emit_signal $parsed

    debug "cycle complete"

    # ----------------------------------------------
    # hourly cadence
    # ----------------------------------------------

    utimer 3600 deafmode::update_loop
}

# --------------------------------------------------
# manual commands
# --------------------------------------------------

bind pub - !signal deafmode::cmd_signal
bind pub - !drift deafmode::cmd_drift
bind pub - !state deafmode::cmd_state

# ----------------------------------------------
# !signal
# ----------------------------------------------

proc deafmode::cmd_signal {nick host hand chan text} {

    set raw_json [fetch_signal]

    set parsed [parse_signal $raw_json]

    if {$parsed eq ""} {
        puthelp "PRIVMSG $chan :[signal] unavailable"
        return
    }

    set inference_list [dict get $parsed inference]

    set primary_inference [lindex $inference_list 0]

    puthelp "PRIVMSG $chan :$begin:math:display$signal$end:math:display$ $primary_inference"
}

# ----------------------------------------------
# !drift
# ----------------------------------------------

proc deafmode::cmd_drift {nick host hand chan text} {

    set raw_json [fetch_signal]

    set parsed [parse_signal $raw_json]

    if {$parsed eq ""} {
        puthelp "PRIVMSG $chan :[drift] unavailable"
        return
    }

    set drift_list [dict get $parsed drift]

    set first_drift [lindex $drift_list 0]

    set drift_inference [dict get $first_drift inference]

    puthelp "PRIVMSG $chan :$begin:math:display$drift$end:math:display$ $drift_inference"
}

# ----------------------------------------------
# !state
# ----------------------------------------------

proc deafmode::cmd_state {nick host hand chan text} {

    set raw_json [fetch_signal]

    set parsed [parse_signal $raw_json]

    if {$parsed eq ""} {
        puthelp "PRIVMSG $chan :[state] unavailable"
        return
    }

    set signal_dict [dict get $parsed signal]

    set current_state [dict get $signal_dict state]

    puthelp "PRIVMSG $chan :$begin:math:display$state$end:math:display$ $current_state"
}

# --------------------------------------------------
# initialization
# --------------------------------------------------

deafmode::debug "deafmode signal parser loaded"

utimer 15 deafmode::update_loop
