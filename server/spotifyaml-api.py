import spotipy
import boto3
import requests
import json

def fetch_token(code):
    secrets = boto3.client('secretsmanager')
    creds = json.loads(
        secrets.get_secret_value(SecretId='spotifyaml')["SecretString"]
    )
    payload = {
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": "https://thor7h42bf.execute-api.us-east-2.amazonaws.com/prod/plan",
        "client_id": creds["client_id"],
        "client_secret": creds["client_secret"]
    }
    token = requests.post(
        "https://accounts.spotify.com/api/token",
        data = payload
    ).json()['access_token']
    return token

def lambda_handler(event, context):
    if 'token' in event:
        token = event['token']
    else:
        token = fetch_token(event['queryStringParameters']['code'])
    sp = spotipy.Spotify(auth=token)
    user_id = sp.me()['id']
    playlists = sp.user_playlists(user_id)
    return {
        "statusCode" : "200",
        "body" : json.dumps(
            {
                "message": f"Run `export SPOTIFY_TOKEN={token}` to skip authentiaction on your next run!",
                "plan": playlists
            }
        )
    }
