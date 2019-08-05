#!/bin/bash

# ####################################################################
# # OctoShUI.sh [ --no-clear ]
# #
# # This script provides a Text UI for Octoprint
# # It depends on the octoprint_statfs plugin
# #     https://github.com/sbts/OctoPrint_StatFS.git
# #
# # The UI is "status only" at the moment
# #   ie: you can't control anything
# #
# # The UI is designed to run on a standard Pi 7" touchscreen
# #     @ 100 Columns by 30 Lines
# # Other display sizes are possible, but the two Output functions
# #   - ReDraw
# #   - GetData
# # would need to be carefully adjusted
# #
# ####################################################################


Script="$0"
MaxLoops=10

Dir='/tmp/octoprint_statFS'

mkdir -p "$Dir"

Args="$@"

[[ $Args =~ '--no-clear' ]] && : || clear;

read -rst10 Home < <( tput cup 0 0 )
read -rst10 clrEOL < <( tput el )
read -rst10 clrEOD < <( tput ed )

export COLUMNS
export LINES
read -rst5 COLUMNS < <( tput cols )
read -rst5 LINES < <( tput lines )

getValue() { # $1=Filename    $2=Line    $3=Column    $V = result
    declare -g V='----'
    [[ -r "${1:-/dev/null}" ]] && read -rst5 V < "$F";
    V="${V/None/----}"
    tput cup ${2:-0} ${3:-0};
}

progressBar='####################################################################################################....................................................................................................'
temperatureGuage='####################################################################################################....................................................................................................'


printCompletionBar() { # $1 = Line   $2 = Column   $3 = Percent Complete
    (( P = 100 - ($3 /2) ))
    tput cup $1 $2;
    printf "%s" "${progressBar:$P:50}"
    tput cup $1 $(( $2 + 22 ));
    printf " %s%% " "${3}";
}

trunc_V() {
    V="${V%.*}" # truncate to integer
}
convert_V_to_hhmmss() {
    trunc_V
    (( H = V / 3600 ))
    (( M = (V / 60) - (H * 60) ))
    (( S = V - (V/60*60) ))
    H="0$H"
    M="0$M"
    S="0$S"
    V="${H: -2}:${M: -2}:${S: -2}"
}

# 0x6a j ┘
# 0x6b k ┐
# 0x6c l ┌
# 0x6d m └
# 0x6e n ┼
# 0x71 q ─
# 0x74 t ├
# 0x75 u ┤
# 0x76 v ┴
# 0x77 w ┬
# 0x78 x │

# ┌─┬┐
# ├─┼┤
# │ ││
# └─┴┘

# ┌───────────────────────┐
# │ Last Updated          │
# │       System      °C  │
# └───────────────────────┘
#

ReDraw() {
    echo -n "$Home"
    cat <<-EOF
	┌─                     ┌──────────────────────────────────────────────────┐                       ─┐
	│                      │                                                  │                        │
	│                      ├──────────────────────────────────────────────────┤                        │
	│          ┌─          │                                                  │          ─┐            │
	│          └───────────┴──────────────────────────────────────────────────┴───────────┘            │
	│                                                                                                  │
	│ ┌─ Filename ────────────────────────────────────────────────────────┐  ┌─ Estimated Print Time ┐ │
	│ │                                                                   │  │              hh:mm:ss │ │
	│ └───────────────────────────────────────────────────────────────────┘  └───────────────────────┘ │
	│                                                                                                  │
	│ ┌─ Bed Temperature ─────┐ ┌─ Chamber Temperature ─┐                    ┌───────────────────────┐ │
	│ │ Current      Target   │ │ Current      Target   │                    │ Last Updated          │ │
	│ │       °C           °C │ │       °C           °C │                    │       System      °C  │ │
	│ └───────────────────────┘ └───────────────────────┘                    └───────────────────────┘ │
	│                                                                        ┌─ Z Position ──────────┐ │
	│ ┌─ Tool 0  Temperature ─┐ ┌─ Tool 1  Temperature ─┐                    │                       │ │
	│ │ Current      Target   │ │ Current      Target   │                    └───────────────────────┘ │
	│ │       °C           °C │ │       °C           °C │                                              │
	│ └───────────────────────┘ └───────────────────────┘                                              │
	│                                                                                                  │
	│ ┌─ Tool 0 ─────────────────────────────────────────────────────────────────────────────────────┐ │
	│ │                                                                                              │ │
	│ └──────────────────────────────────────────────────────────────────────────────────────────────┘ │
	│                                                                                                  │
	│ ┌─ Tool 1 ─────────────────────────────────────────────────────────────────────────────────────┐ │
	│ │                                                                                              │ │
	│ └──────────────────────────────────────────────────────────────────────────────────────────────┘ │
	│                                                                                                  │
	EOF
echo -n └──────────────────────────────────────────────────────────────────────────────────────────────────┘
#    echo -n "${clrEOD}"
}

printTemperatureBar() { # $1 = Line   $2 = Column   $3 = Current Temp    $4 = Target Temp    $5 = Tool Number
    Tc="${3/----/0}"
    Tt="${4/----/0}"
    FS=94 # Full Scale character count
    (( X= ((Tt+99)/100)*100 ))
    (( X <=0 )) && (( X = 100 ))
    (( T = Tt*FS/X ))
    (( P = Tc*FS/X ))
    (( P_ = 100 - P ))    # Invert P to be an offset for the Gauge window
    tput cup $1 $2;
        printf "%s" "${temperatureGuage:$P_:94}"
    tput cup $(( $1 -1 )) $2; printf "─ Tool $5 ─────────────────────────────────────────────────────────────────────────────────────";
    tput cup $(( $1 +1 )) $2; printf "──────────────────────────────────────────────────────────────────────────────────────";
    tput cup $(( $1 -1 )) $(( T +3 ));  printf "┬";
    (( T < 8 )) && { tput cup $(( $1 -1 )) $(( $2 +2 )); printf "Tool $5 "; }
    tput cup $(( $1 )) $(( T +3 ));     printf "<";
    tput cup $(( $1 +1 )) $(( T +3 ));  printf "┴";
#    tput cup $1 $(( $2 + 45 ));         printf " %s °C " "${Tc}";
    (( P-= 5 )); (( P < $2 )) && P="$2"
    tput cup $1 $(( P ));               printf " %s °C #" "${Tc}";
    tput cup $(( $1 +1 )) $(( FS -5 )); printf " %s °C " "$X";
}


GetData() {
    D="$Dir"
    read -rst5 Date < <( date '+%Y-%m-%d %H:%M:%S' ); tput cup 0 7; printf "%s" "${Date%% *}"; tput cup 0 83; printf "%s" "${Date##* }"
    F="${D}/last_updated"            ; getValue "$F" 11 88; convert_V_to_hhmmss; printf "%s" "${V:-???}"
    F="/sys/class/thermal/thermal_zone0/temp"; getValue "$F" 12 88; printf "%s.%s" "${V%???}" "${V:2:1}"

    D="$Dir/current_data"
    F="${D}/state/text"              ; getValue "$F" 1 40; printf ">> %s <<" "$V"
    F="${D}/progress/completion"     ; getValue "$F" 3 58; trunc_V; printCompletionBar 3 24 "$V"; 
    F="${D}/progress/printTime"      ; getValue "$F" 3 13; convert_V_to_hhmmss; printf " %s " "$V"
    F="${D}/progress/printTimeLeft"  ; getValue "$F" 3 75; convert_V_to_hhmmss; printf " %s " "$V"
    F="${D}/job/file/name"           ; getValue "$F" 7 4; printf "%s" "$V"
    F="${D}/job/estimatedPrintTime"  ; getValue "$F" 7 77; convert_V_to_hhmmss; printf "%s" "$V"
    F="${D}/currentZ"                ; getValue "$F" 15 75; printf "%14s mm" "$V"

    D="$Dir/./current_temperatures"
    F="${D}/bed/actual"              ; getValue "$F" 12 5; printf "%s" "$V"
    F="${D}/bed/target"              ; getValue "$F" 12 19; printf "%s" "$V"
#    F="${D}/bed/offset"              ; getValue "$F" 12 33; printf "%s" "$V"
    F="${D}/chamber/actual"          ; getValue "$F" 12 31; printf "%s" "$V"
    F="${D}/chamber/target"          ; getValue "$F" 12 44; printf "%s" "$V"
#    F="${D}/chamber/offset"          ; getValue "$F" 12 33; printf "%s" "$V"
    F="${D}/tool0/actual"            ; getValue "$F" 17 5; printf "%s" "$V"; trunc_V; TemperatureCurrent="$V"
    F="${D}/tool0/target"            ; getValue "$F" 17 19; printf "%s" "$V"; trunc_V; TemperatureTarget="$V"
    printTemperatureBar 21 3 "$TemperatureCurrent" "$TemperatureTarget" 0
#    F="${D}/tool0/offset"            ; getValue "$F" 17 33; printf "%s" "$V"
    F="${D}/tool1/actual"            ; getValue "$F" 17 31; printf "%s" "$V"; trunc_V; TemperatureCurrent="$V"
    F="${D}/tool1/target"            ; getValue "$F" 17 44; printf "%s" "$V"; trunc_V; TemperatureTarget="$V"
    printTemperatureBar 25 3 "$TemperatureCurrent" "$TemperatureTarget" 1
#    F="${D}/tool1/offset"            ; getValue "$F" 17 33; printf "%s" "$V"
    tput cup $LINES $COLUMNS
}

#clear;

ReDraw
(( Lc = MaxLoops ))
GetData
while ! read -rst1 -n1 K; do
    (( Lc-- <=0 )) && break
    GetData
done

#exec "$Script" --no-clear

exit

