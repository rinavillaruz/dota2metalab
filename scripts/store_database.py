# stores matches in MongoDB, no duplicates
import os
import time
from pymongo import MongoClient
from src.data.open_dota_fetcher import OpenDotaFetcher

opendotafetcher =   OpenDotaFetcher()
MONGO_URI       =   os.getenv('MONGO_URI', 'mongodb://localhost:27017')
client          =   MongoClient(MONGO_URI)
db              =   client['dota2metalab']
collection      =   db['matches']

existing        =   collection.count_documents({})
if existing > 500:
    print(f"Already have {existing} matches. Skipping fetch.")
    exit(0)

all_matches     =   []
last_id         =   None

for i in range(10):
    print(f"Printing batch  {i + 1}...")
    matches         =   opendotafetcher.fetch_public_matches(less_than_match_id=last_id)
    all_matches.extend(matches)
    last_id         =   min(m['match_id'] for m in matches)
    valid_matches   =   [m for m in matches if m['duration'] != 0]

    for match in valid_matches:
        collection.update_one(
            {'match_id': match['match_id']},
            {'$set': match},
            upsert=True
        ) 
        print(f"Inserted match {match['match_id']}")
        
    time.sleep(2)

print(f"Total fetched: {len(all_matches)}")








# docker exec -it mongodb mongosh# trigger build Sun May  3 13:05:40 CEST 2026
