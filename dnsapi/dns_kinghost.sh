#!/usr/bin/env sh

#KINGHOST_username="xxxx@sss.com"
#KINGHOST_Password="sdfsdfsdfljlbjkljlkjsdfoiwje"

KING_Api="https://api.kinghost.net/acme"

# Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
# Used to add txt record
dns_kinghost_add() {
    fulldomain=$1
    txtvalue=$2

    KINGHOST_username="${KINGHOST_username:-$(_readaccountconf_mutable KINGHOST_username)}"
    KINGHOST_Password="${KINGHOST_Password:-$(_readaccountconf_mutable KINGHOST_Password)}"
    if [ -z "$KINGHOST_username" ] || [ -z "$KINGHOST_Password" ]; then
        KINGHOST_username=""
        KINGHOST_Password=""
        _err "You don't specify KingHost api password and email yet."
        _err "Please create you key and try again."
        return 1
    fi
    
    #save the credentials to the account conf file.
    _saveaccountconf_mutable KINGHOST_username  "$KINGHOST_username"
    _saveaccountconf_mutable KINGHOST_Password  "$KINGHOST_Password"

    _debug "Getting txt records"
    _kinghost_rest GET "dns" "name=$fulldomain&content=$txtvalue"

    #This API call returns "status":"ok" if dns record does not exists
    #We are creating a new txt record here, so we expect the "ok" status
    if ! printf "%s" "$response" | grep '"status":"ok"' >/dev/null; then
        _err "Error"
        _err "$response"
        return 1
    fi

    _kinghost_rest POST "dns" "name=$fulldomain&content=$txtvalue"
    if ! printf "%s" "$response" | grep '"status":"ok"' >/dev/null; then
        _err "Error"
        _err "$response"
        return 1
    fi

    return 0;
}

# Usage: fulldomain txtvalue
# Used to remove the txt record after validation
dns_kinghost_rm() {
    fulldomain=$1
    txtvalue=$2

    KINGHOST_Password="${KINGHOST_Password:-$(_readaccountconf_mutable KINGHOST_Password)}"
    KINGHOST_username="${KINGHOST_username:-$(_readaccountconf_mutable KINGHOST_username)}"
        if [ -z "$KINGHOST_Password" ] || [ -z "$KINGHOST_username" ]; then
        KINGHOST_Password=""
        KINGHOST_username=""
        _err "You don't specify KingHost api key and email yet."
        _err "Please create you key and try again."
        return 1
    fi

    _debug "Getting txt records"
    _kinghost_rest GET "dns" "name=$fulldomain&content=$txtvalue"

    #This API call returns "status":"ok" if dns record does not exists
    #We are removing a txt record here, so the record must exists
    if printf "%s" "$response" | grep '"status":"ok"' >/dev/null; then
        _err "Error"
        _err "$response"
        return 1
    fi

    _kinghost_rest DELETE "dns" "name=$fulldomain&content=$txtvalue"
    if ! printf "%s" "$response" | grep '"status":"ok"' >/dev/null; then
        _err "Error"
        _err "$response"
        return 1
    fi

    return 0;
}


####################  Private functions below ##################################
_kinghost_rest() {
  method=$1
  uri="$2"
  data="$3"
  _debug "$uri"

  export _H1="X-Auth-Email: $KINGHOST_username"
  export _H2="X-Auth-Key: $KINGHOST_Password"

  if [ "$method" != "GET" ]; then
    _debug data "$data"
    response="$(_post "$data" "$KING_Api/$uri.json" "" "$method")"
  else
    response="$(_get "$KING_Api/$uri.json?$data")"
  fi

  if [ "$?" != "0" ]; then
    _err "error $uri"
    return 1
  fi
  _debug2 response "$response"
  return 0
}
