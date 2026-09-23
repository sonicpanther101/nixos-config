# 1. Convert FLAC to MP3
cd ~/driveBig/IPod
for f in *.flac; do ffmpeg -i "$f" -codec:a libmp3lame -qscale:a 2 "${f%.flac}.mp3"; done
rm *.flac

# 2. Rename MP3 files according to ID3 metadata
exiftool '-filename<${Band} - (${RecordingTime}) ${Album} - ${Track} ${Title}.%e' *.mp3

rm /run/media/adam/ADAM_S IPOD/iPod_Control/Music/F00/*
cp *.mp3 /run/media/adam/ADAM_S IPOD/iPod_Control/Music/F00 

# 3. Update iPod database
cd /run/media/adam/ADAM_S\ IPOD
python3 ./3build_db.py
sync
