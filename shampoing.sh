#!/bin/sh
# Shampoing : from your shazam app to mp3 files
#
# There is no guaranty the script is working for you or don't damage
# your system. Use at own Risk!
#
# License: BSD
# http://www.freebsd.org/copyright/freebsd-license.html

if [ ! -f /tmp/library.db ]
then
    read -p "Android (rooted) IP adress for an ssh connexion: " ip
    scp root@${ip}:/data/data/com.shazam.android/databases/library.db  /tmp/
fi

echo "SELECT artist.name, track.title  FROM artist, artist_track, track  WHERE artist_track.artist_id=artist.id AND artist_track.track_id=track._id;" | sqlite3 /tmp/library.db | sed -e 's#|# #g' > /tmp/tracks

sql="SELECT artist.name, track.title  FROM artist, artist_track, track  WHERE artist_track.artist_id=artist.id AND artist_track.track_id=track._id;"
echo $sql| sqlite3 /tmp/library.db | sed -e 's#|# #g' > /tmp/tracks

while read t
do         
  echo $t ;
  yt_title=$(curl -s --data-urlencode "search_query=$t" http://www.youtube.com/results |grep yt-lockup-content | head -1 | sed s/^.*title..// | sed s/\".*// );
  echo "Youtube title found : $yt_title";
  sim_score=$(python score.py  "$t" "$yt_title") ;

  yt_id=$(curl -s --data-urlencode "search_query=$t" http://www.youtube.com/results |grep yt-lockup-content | head -1 | sed s/^.*watch...//  | sed s/\".*//) ;
  youtube-dl  $yt_id ;
  ffmpeg -i $yt_id.flv -vn -ar 44100 -ac 2 -ab 128k -f mp3 "$t"_"$sim_score".mp3 </dev/null; 
done < /tmp/tracks
