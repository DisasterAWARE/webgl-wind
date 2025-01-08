#!/bin/bash

# "printf '%(%Y%m%d)T' -1" to generate GFS_DATE
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
  GFS_DATE=$(date -u '+%Y%m%d')
  GFS_TIME=$(( ($(date -u '+%H') - 4) / 6 * 6))  # takes NOAA about 4 hours to generate a forecast
else
  GFS_DATE=$(date --utc '+%Y%m%d')
  GFS_TIME=$(( ($(date --utc '+%H') - 4) / 6 * 6))  # takes NOAA about 4 hours to generate a forecast
fi
GFS_TIME=$(printf %02d $GFS_TIME) # 00, 06, 12, 18, UTC hours when NOAA releases a new forecast
RES="0p50" # 0p25, 0p50 or 1p00
Hi_RES="0p25"
BBOX="leftlon=0&rightlon=360&toplat=90&bottomlat=-90"
WIND_LEVEL="lev_10_m_above_ground=on"
TEMP_LEVEL="lev_2_m_above_ground=on"
FORECASTS=("f000" "f006" "f012" "f018" "f024" "f030" "f036")

GFS_DATE="20241211";
GFS_TIME="18";

echo "$GFS_DATE - $GFS_TIME"

# LEVEL="lev_20_m_above_ground=on"
# LEVEL="lev_500_mb=on"
# GFS_URL="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_${RES}.pl?file=gfs.t${GFS_TIME}z.pgrb2.${RES}.f000&${LEVEL}&${BBOX}&dir=%2Fgfs.${GFS_DATE}${GFS_TIME}"
# GFS_URL="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_${RES}.pl?dir=%2Fgfs.${GFS_DATE}%2F${GFS_TIME}%2Fatmos&file=gfs.t${GFS_TIME}z.pgrb2.${RES}.anl&${LEVEL}&subregion=&toplat=90&leftlon=0&rightlon=360&bottomlat=-90"
GFS_URL="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_${RES}.pl?dir=%2Fgfs.${GFS_DATE}%2F${GFS_TIME}%2Fatmos&toplat=90&leftlon=0&rightlon=360&bottomlat=-90"
GFS_HI_RES_URL="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_${Hi_RES}.pl?dir=%2Fgfs.${GFS_DATE}%2F${GFS_TIME}%2Fatmos&toplat=90&leftlon=0&rightlon=360&bottomlat=-90"
#https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p50.pl?dir=%2Fgfs.20241205%2F00%2Fatmos&file=gfs.t00z.pgrb2full.0p50.f000&var_VGRD=on&lev_10_m_above_ground=on&toplat=90&leftlon=0&rightlon=360&bottomlat=-90
#https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p50.pl?dir=%2Fgfs.20241205%2F00%2Fatmos&file=gfs.t00z.pgrb2full.0p50.f000&var_UGRD=on&lev_10_m_above_ground=on&toplat=90&leftlon=0&rightlon=360&bottomlat=-90
#https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p50.pl?dir=%2Fgfs.20241206%2F00%2Fatmos&file=gfs.t00z.pgrb2full.0p50.f000&var_TCDC=on&lev_entire_atmosphere=on&toplat=90&leftlon=0&rightlon=360&bottomlat=-90
#https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p50.pl?dir=%2Fgfs.20241205%2F18%2Fatmos&file=gfs.t18z.pgrb2full.0p50.f000&var_TCDC=on&lev_entire_atmosphere=on&toplat=90&leftlon=0&rightlon=360&bottomlat=-90
# gfs.t18z.pgrb2.1p00.anl
# gfs.t18z.pgrb2.1p00.f003

for FORECAST in "${FORECASTS[@]}"
do

  FILENAME="gfs.t${GFS_TIME}z.pgrb2full.${RES}.${FORECAST}"
  HI_RES_FILENAME="gfs.t${GFS_TIME}z.pgrb2full.${Hi_RES}.${FORECAST}"

  echo "Downloading GFS_URL: ${GFS_URL}&file=${FILENAME}&${WIND_LEVEL}&var_UGRD=on"
  curl -s "${GFS_URL}&file=${FILENAME}&${WIND_LEVEL}&var_UGRD=on" -o utmp.grib

  echo "Downloading GFS_URL: ${GFS_URL}&file=${FILENAME}&${WIND_LEVEL}&var_VGRD=on"
  curl -s "${GFS_URL}&file=${FILENAME}&file=${FILENAME}&${WIND_LEVEL}&var_VGRD=on" -o vtmp.grib

  echo "Downloading GFS_URL: ${GFS_URL}&file=${FILENAME}&${TEMP_LEVEL}&var_TMP=on"
  curl -s "${GFS_URL}&file=${FILENAME}&file=${FILENAME}&${TEMP_LEVEL}&var_TMP=on" -o ktmp.grib

  echo "Downloading GFS_URL: ${GFS_HI_RES_URL}&file=${HI_RES_FILENAME}&var_TCDC=on&lev_entire_atmosphere=on"
  curl -s "${GFS_URL}&file=${FILENAME}&var_TCDC=on&lev_entire_atmosphere=on" -o ctmp.grib

  echo "Downloading GFS_URL: ${GFS_URL}&file=${FILENAME}&var_SNOD=on&lev_surface=on"
  curl -s "${GFS_URL}&file=${FILENAME}&file=${FILENAME}&var_SNOD=on&lev_surface=on" -o stmp.grib

  grib_set -r -s packingType=grid_simple utmp.grib utmp_processed.grib
  grib_set -r -s packingType=grid_simple vtmp.grib vtmp_processed.grib
  grib_set -r -s packingType=grid_simple ktmp.grib ktmp_processed.grib
  grib_set -r -s packingType=grid_simple ctmp.grib ctmp_processed.grib
  grib_set -r -s packingType=grid_simple stmp.grib stmp_processed.grib

  u_json=$(grib_dump -j utmp_processed.grib)
  v_json=$(grib_dump -j vtmp_processed.grib)
  k_json=$(grib_dump -j ktmp_processed.grib)
  c_json=$(grib_dump -j ctmp_processed.grib)
  s_json=$(grib_dump -j stmp_processed.grib)

  echo "$u_json" > debug_u.json
  echo "$v_json" > debug_v.json
  echo "$c_json" > debug_c.json
  echo "$s_json" > debug_s.json

  # Create wind JSON file
  printf "{\"u\":$u_json,\"v\":$v_json}" > wind/tmp.json

  # Create temperature JSON file
  printf "{\"u\":$u_json,\"v\":$v_json,\"k\":$k_json}" > temperature/tmp.json

  echo "{\"u\":$u_json" > cloud/tmp.json
  echo ",\"v\":$v_json" >> cloud/tmp.json
  echo ",\"c\":$c_json}" >> cloud/tmp.json
  echo "{\"s\":$s_json}" > snow-depth/tmp.json

  rm utmp.grib vtmp.grib utmp_processed.grib vtmp_processed.grib ktmp.grib ktmp_processed.grib ctmp.grib ctmp_processed.grib

  DIR=`dirname $0`
  node ${DIR}/wind-prepare.js ${GFS_DATE}${GFS_TIME}"${FORECAST}"
  node ${DIR}/temperature-prepare.js ${GFS_DATE}${GFS_TIME}"${FORECAST}"
  node ${DIR}/cloud-prepare.js ${GFS_DATE}${GFS_TIME}"${FORECAST}"
  node ${DIR}/snow-depth-prepare.js ${GFS_DATE}${GFS_TIME}"${FORECAST}"

  HOURS=${FORECAST#f}

  # Add forecast hours to date
  #  ADJUSTED_DATE=$(date -d "$(cat "temperature/${GFS_DATE}${GFS_TIME}${FORECAST}.json" | jq -r .date )+${FORECAST#f} hours" '+%FT%H:00Z')
  if [[ "$OSTYPE" == "darwin"* ]]; then
    NEW_DATE=$(date -u -j -f "%Y%m%d%H" "${GFS_DATE}${GFS_TIME}" "+%Y-%m-%dT%H:00:00Z")
    ADJUSTED_DATE=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" -v+"${HOURS}"H "$NEW_DATE" '+%Y-%m-%dT%H:00:00Z')
#    echo "Adjusted Date: " + "$ADJUSTED_DATE"
  else
    ADJUSTED_DATE=$(date -d "$(cat "temperature/${GFS_DATE}${GFS_TIME}${FORECAST}.json" | jq -r .date )+${HOURS} hours" '+%FT%H:00Z')
  fi

  cat "temperature/"${GFS_DATE}${GFS_TIME}${FORECAST}.json | jq ".date = \"$ADJUSTED_DATE\"" > temperature/tmp2.json
  mv temperature/tmp2.json temperature/${GFS_DATE}${GFS_TIME}${FORECAST}.json
  rm -f temperature/tmp.json temperature/tmp2.json

  cat "wind/"${GFS_DATE}${GFS_TIME}${FORECAST}.json | jq ".date = \"$ADJUSTED_DATE\"" > wind/tmp2.json
  mv wind/tmp2.json wind/${GFS_DATE}${GFS_TIME}${FORECAST}.json
  rm -f wind/tmp.json wind/tmp2.json

  cat "cloud/"${GFS_DATE}${GFS_TIME}${FORECAST}.json | jq ".date = \"$ADJUSTED_DATE\"" > cloud/tmp2.json
  mv cloud/tmp2.json cloud/${GFS_DATE}${GFS_TIME}${FORECAST}.json
  rm -f cloud/tmp.json cloud/tmp2.json

  cat "snow-depth/"${GFS_DATE}${GFS_TIME}${FORECAST}.json | jq ".date = \"$ADJUSTED_DATE\"" > snow-depth/tmp2.json
  mv snow-depth/tmp2.json snow-depth/${GFS_DATE}${GFS_TIME}${FORECAST}.json
  rm -f snow-depth/tmp.json snow-depth/tmp2.json

done

node temperature-manifest-builder.js temperature/${GFS_DATE}${GFS_TIME}*.json
node wind-manifest-builder.js wind/${GFS_DATE}${GFS_TIME}*.json
node cloud-manifest-builder.js cloud/${GFS_DATE}${GFS_TIME}*.json
node snow-depth-manifest-builder.js snow-depth/${GFS_DATE}${GFS_TIME}*.json
