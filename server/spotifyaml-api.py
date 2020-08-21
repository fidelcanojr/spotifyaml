import spotipy
import boto3
import requests
import re
import json
import urllib.parse

SUPPORTED_RESOURCES = [
    "playlists"
]

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

def get_token_from_event(event):
    body = event['body']
    if body:
        token_entry = next(
            filter(
                lambda x: x.startswith("token="),
                body.split("&")
            ), None
        )
        if token_entry:
            return token_entry.replace("token=","")
    code = event['queryStringParameters']['code']
    return fetch_token(code)

def get_project_contents_form_event(event):
    body = event['body']
    if body:
        contents_entry = next(
            filter(
                lambda x: x.startswith("project_contents="),
                body.split("&")
            ), None
        )
        if contents_entry:
            contents_entry = urllib.parse.unquote(
                contents_entry.replace("project_contents=","").replace("+"," ")
            ).encode('utf-8')
            print(contents_entry)
            return json.loads(contents_entry)
    return {}

class SpotifYAMLAgent:
    def __init__(self,token, project_contents):
        self.sp = spotipy.Spotify(auth=token)
        self.user_id = self.sp.me()['id']
        self.project_contents = project_contents

    def auto_import(self):
        new_resources = {}
        user_resources = {
            "playlists": list(map(
                lambda x: x['name'],
                self.sp.user_playlists(self.user_id)['items']
            ))
        }
        for resource in SUPPORTED_RESOURCES:
            project_specific_resources = self.project_contents.get(resource,[])
            user_specific_resources = user_resources[resource]
            to_create = list(filter(
                lambda x: x not in user_specific_resources,
                map(
                    lambda y: list(y.keys())[0],
                    project_specific_resources
                )
            ))
            new_resources[resource] = to_create
        return new_resources

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
