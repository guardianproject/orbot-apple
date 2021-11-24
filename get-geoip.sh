#!/bin/sh

#  get-geoip.sh
#  Orbot
#
#  Created by Benjamin Erhart on 04.02.19.
#  Copyright © 2019 - 2021 Guardian Project. All rights reserved.

# Only downloads new geoip files, if they are missing or older than a day.

if [ ! -f ./TorVPN/geoip ] || [ ! -f ./TorVPN/geoip6 ] || test `find . -name geoip -mtime +1`
then
    curl -Lo ./TorVPN/geoip https://gitweb.torproject.org/tor.git/plain/src/config/geoip?h=tor-0.4.6.8
    curl -Lo ./TorVPN/geoip6 https://gitweb.torproject.org/tor.git/plain/src/config/geoip6?h=tor-0.4.6.8
fi
