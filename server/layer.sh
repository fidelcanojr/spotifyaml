[ -d "package" ] || $(mkdir package && mkdir package/python)
pip3 install --target ./package/python spotipy requests >/dev/null
echo '{"message": "spotipy package successfully created"}'
