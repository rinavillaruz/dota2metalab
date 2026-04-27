# fetches from OpenDota API with pagination
import requests
import time

class OpenDotaFetcher:
    BASE_URL = "https://api.opendota.com/api"

    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Dota2MetaLab/1.0'
        })
    
    def fetch_public_matches(self, limit=1000, less_than_match_id=None):
        url = f"{self.BASE_URL}/publicMatches"
        
        if less_than_match_id:
            url = f"{url}?less_than_match_id={less_than_match_id}"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            matches = response.json()
            return matches[:limit]
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                time.sleep(60)
                return self.fetch_public_matches(limit=limit, less_than_match_id=less_than_match_id)
            elif e.response.status_code == 404:
                return None
            raise

    def fetch_match_details(self, match_id):
        url = f"{self.BASE_URL}/matches/{match_id}"

        try:
            response = self.session.get(url)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                time.sleep(60)
                return self.fetch_match_details(match_id)
            elif e.response.status_code == 404:
                return None
            raise
            