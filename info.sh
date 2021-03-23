info_pattern="^[[:alnum:]-]*=[[:print:]]*$"

info_name(){
    echo "$1" | cut -d= -f-1
}

info_value(){
    echo "$1" | cut -d= -f2-
}

read_info(){
    grep "$info_pattern" "$1"
}

is_info(){
    grep -q "$info_pattern" "$1"
}