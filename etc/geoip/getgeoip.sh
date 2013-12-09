#!/bin/bash
# getgeoip.sh: Downloads the MaxMind Lite Cityv6 database

wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz
gunzip GeoLiteCityv6.dat.gz