#!/bin/bash

# "printf '%(%Y%m%d)T' -1" to generate GFS_DATE
set -e

GFS_DATE=$(date --utc '+%Y%m%d')
GFS_TIME=$(( $(date --utc '+%H') / 6 * 6)) # 00, 06, 12, 18, UTC hours when NOAA releases a new forecast
RES="1p00" # 0p25, 0p50 or 1p00
BBOX="leftlon=0&rightlon=360&toplat=90&bottomlat=-90"
LEVEL="lev_1000_mb=on"
FORECASTS=("f000" "f006" "f012" "f018" "f024" "f030" "f036")

echo "$GFS_DATE - $GFS_TIME"

# LEVEL="lev_20_m_above_ground=on"
# LEVEL="lev_500_mb=on"
# GFS_URL="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_${RES}.pl?file=gfs.t${GFS_TIME}z.pgrb2.${RES}.f000&${LEVEL}&${BBOX}&dir=%2Fgfs.${GFS_DATE}${GFS_TIME}"
# GFS_URL="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_${RES}.pl?dir=%2Fgfs.${GFS_DATE}%2F${GFS_TIME}%2Fatmos&file=gfs.t${GFS_TIME}z.pgrb2.${RES}.anl&${LEVEL}&subregion=&toplat=90&leftlon=0&rightlon=360&bottomlat=-90"
GFS_URL="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_${RES}.pl?dir=%2Fgfs.${GFS_DATE}%2F${GFS_TIME}%2Fatmos&${LEVEL}&subregion=&toplat=90&leftlon=0&rightlon=360&bottomlat=-90"

# gfs.t18z.pgrb2.1p00.anl
# gfs.t18z.pgrb2.1p00.f003

for FORECAST in "${FORECASTS[@]}"
do

  FILENAME="gfs.t${GFS_TIME}z.pgrb2.${RES}.${FORECAST}"
  echo "Downloading GFS_URL: ${GFS_URL}&var_UGRD=on"
  curl "${GFS_URL}&file=${FILENAME}&var_UGRD=on" -o utmp.grib
  echo "Downloading GFS_URL: ${GFS_URL}&var_VGRD=on"
  curl "${GFS_URL}&file=${FILENAME}&var_VGRD=on" -o vtmp.grib

  grib_set -r -s packingType=grid_simple utmp.grib utmp_processed.grib
  grib_set -r -s packingType=grid_simple vtmp.grib vtmp_processed.grib

  printf "{\"u\":`grib_dump -j utmp_processed.grib`,\"v\":`grib_dump -j vtmp_processed.grib`}" > tmp.json

  rm utmp.grib vtmp.grib utmp_processed.grib vtmp_processed.grib

  DIR=`dirname $0`
  node ${DIR}/prepare.js ${GFS_DATE}${GFS_TIME}"${FORECAST}"

  rm tmp.json

done

