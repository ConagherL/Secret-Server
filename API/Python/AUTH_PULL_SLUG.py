import requests
import json

def getOToken(site, user, password):
    authApi = site + '/oauth2/token'
    authHeaders = {'content-type': 'application/x-www-form-urlencoded'}
    body = {
        'grant_type': 'password',
        'username': user,
        'password': password
    }
    resp = requests.post(authApi, data=body, headers=authHeaders)
    
    if resp.status_code not in (200, 304):
        raise Exception("Error retrieving OAuth token. %s %s" % (resp.status_code, resp.text))  
    
    resp_json = json.loads(resp.text)
    token = resp_json["access_token"]
    
    return token

def getSecretField(site, token, secretId, fieldSlug):
    endpoint = f"{site}/api/v1/secrets/{secretId}/fields/{fieldSlug}"
    headers = {
        "Authorization": "Bearer " + token,
        "Content-Type": "application/json"
    }
    response = requests.get(endpoint, headers=headers)
    
    if response.status_code == 200:
        return json.loads(response.text)
    else:
        raise Exception(f"Error retrieving secret field. {response.status_code} {response.text}")

# Example usage:
site = "https://XXXXXXX.secretservercloud.com"  # Your Secret Server site
user = "your_username"
password = "your_password"
secretId = 1234  # Replace with your actual secret ID
fieldSlug = "password"  # Replace with the slug for the field you're interested in

token = getOToken(site, user, password)
secretField = getSecretField(site, token, secretId, fieldSlug)

print(secretField)
