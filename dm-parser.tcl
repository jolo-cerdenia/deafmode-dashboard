# dm-parser.tcl
# version: 0.2
#
# purpose:
# fetch deafmode signal.json
# emit operational telemetry to IRC
#
# requirements:
#   package require http
#   package require tls
#   package require json
#
# tested against:
#   Eggdrop Tcl 8.6+

package require http
package require tls
package require json

http::register https 443 ::tls::socket

namespace eval deafmode {

    variable signal_url "https://deafmo.de/dashboard/signal.json"
    variable channel "#deafmode"

    variable last_state ""
    variable debug 1

    variable update_interval 3600
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
# safe dict getter
# --------------------------------------------------

proc deafmode::dget {data args} {

    if {[catch {
        dict get $data {*}$args
    } result]} {
        return ""
    }

    return $result
}

# --------------------------------------------------
# fetch + parse signal
# --------------------------------------------------

proc deafmode::fetch_signal {} {

    variable signal_url

    debug "fetching signal data"

    if {[catch {
        set token [http::geturl $signal_url -timeout 10000]
    } err]} {

        debug "transport failure: $err"
        return ""
    }

    if {[http::status $token] ne "ok"} {

        debug "http failure: [http::status $token]"

        http::cleanup $token
        return ""
    }

    set raw_json [http::data $token]

    http::cleanup $token

    if {$raw_json eq ""} {

        debug "empty payload"
        return ""
    }

    if {[catch {
        set parsed [json::json2dict $raw_json]
    } err]} {

        debug "json parse failure: $err"
        return ""
    }

    debug "signal payload parsed"

    return $parsed
}

# --------------------------------------------------
# emit state transition + inference
# --------------------------------------------------

proc deafmode::emit_signal {parsed} {

    variable channel
    variable last_state

    set signal_dict [dget $parsed signal]

    if {$signal_dict eq ""} {
        debug "missing signal block"
        return
    }

    set current_state [dget $signal_dict state]

    if {$current_state eq ""} {
        set current_state "unknown"
    }

    set inference_list [dget $parsed inference]

    if {[llength $inference_list] > 0} {
        set primary_inference [lindex $inference_list 0]
    } else {
        set primary_inference "no inference available"
    }

    # ----------------------------------------------
    # state transition detection
    # ----------------------------------------------

    if {$last_state ne "" && $last_state ne $current_state} {

        puthelp "PRIVMSG $channel :[deafmode] state transition: $last_state -> $current_state"

        debug "state transition emitted"
    }

    set last_state $current_state

    # ----------------------------------------------
    # primary inference emission
    # ----------------------------------------------

    puthelp "PRIVMSG $channel :[deafmode] inference: $primary_inference"

    debug "inference emitted"
}

# --------------------------------------------------
# update loop
# --------------------------------------------------

proc deafmode::update_loop {} {

    variable update_interval

    debug "starting update cycle"

    if {[catch {

        set parsed [fetch_signal]

        if {$parsed eq ""} {

            debug "signal unavailable"

        } else {

            emit_signal $parsed

            debug "cycle complete"
        }

    } err]} {

        debug "fatal update error: $err"
    }

    utimer $update_interval deafmode::update_loop
}

# --------------------------------------------------
# public commands
# --------------------------------------------------

bind pub - !signal deafmode::cmd_signal
bind pub - !drift  deafmode::cmd_drift
bind pub - !state  deafmode::cmd_state

# --------------------------------------------------
# !signal
# --------------------------------------------------

proc deafmode::cmd_signal {nick host hand chan text} {

    set parsed [fetch_signal]

    if {$parsed eq ""} {

        puthelp "PRIVMSG $chan :\[deafmode\] signal unavailable"
        return
    }

    set inference_list [dget $parsed inference]

    if {[llength $inference_list] > 0} {
        set primary_inference [lindex $inference_list 0]
    } else {
        set primary_inference "no inference available"
    }

    puthelp "PRIVMSG $chan :\[deafmode\] signal: $primary_inference"
}

# --------------------------------------------------
# !drift
# --------------------------------------------------

proc deafmode::cmd_drift {nick host hand chan text} {

    set parsed [fetch_signal]

    if {$parsed eq ""} {

        puthelp "PRIVMSG $chan :\[deafmode\] drift unavailable"
        return
    }

    set drift_list [dget $parsed drift]

    if {[llength $drift_list] == 0} {

        puthelp "PRIVMSG $chan :\[deafmode\] no drift detected"
        return
    }

    set first_drift [lindex $drift_list 0]

    set drift_inference [dget $first_drift inference]

    if {$drift_inference eq ""} {
        set drift_inference "unknown drift condition"
    }

    puthelp "PRIVMSG $chan :\[deafmode\] drift: $drift_inference"
}

# --------------------------------------------------
# !state
# --------------------------------------------------

proc deafmode::cmd_state {nick host hand chan text} {

    set parsed [fetch_signal]

    if {$parsed eq ""} {

        puthelp "PRIVMSG $chan :\[deafmode\] state unavailable"
        return
    }

    set signal_dict [dget $parsed signal]

    set current_state [dget $signal_dict state]

    if {$current_state eq ""} {
        set current_state "unknown"
    }

    puthelp "PRIVMSG $chan :\[deafmode\] state: $current_state"
}

# --------------------------------------------------
# initialization
# --------------------------------------------------

deafmode::debug "deafmode signal parser loaded"

utimer 15 deafmode::update_loop
