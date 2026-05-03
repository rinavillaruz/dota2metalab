#  Flask API serving predictions from the trained model
import os
import joblib
import numpy as np
from tensorflow import keras
from pymongo import MongoClient
from flask import Flask, request, jsonify

MONGO_URI   =   os.getenv('MONGO_URI', 'mongodb://localhost:27017')
MODEL_DIR   =   os.getenv('MODEL_DIR', 'models')
MODEL_PATH  =   f"{MODEL_DIR}/dota2_model.h5"
SCALER_PATH =   f"{MODEL_DIR}/scaler.pkl"

app         =   Flask(__name__)

# Load model and scaler
try:
    model       =   keras.models.load_model(MODEL_PATH)
    scaler      =   joblib.load(SCALER_PATH)
except Exception as e:
    print(f"Model not loaded: {e}")
    model  = None
    scaler = None

# MongoDB connection
client      =   MongoClient(MONGO_URI)
db          =   client['dota2metalab']
collection  =   db['matches']

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'model_loaded': model is not None
    })

@app.route('/stats')
def stats():
    total = collection.count_documents({})
    radiant_wins = collection.count_documents({'radiant_win': True})
    return jsonify({
        'total_matches': total,
        'radiant_wins': radiant_wins,
        'dire_wins': total - radiant_wins
    })

@app.route('/predict', methods=['POST'])
def predict():
    if model is None:
        return jsonify({'error': 'Model not loaded yet. Run trainer first.'}), 503
    
    data        =   request.json
    features    =   np.array([
        data['radiant_team'] + data['dire_team'] + [data['duration']]
    ])

    features_scaled =   scaler.transform(features)
    prediction      =   model.predict(features_scaled, verbose=0)[0][0]

    return jsonify({
        'radiant_win_probability': float(prediction),
        'predicted_winner': 'Radiant' if prediction > 0.5 else 'Dire'
    })

# test change

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=True)
# trigger
# trigger build Sun May  3 12:26:38 CEST 2026
# trigger build Sun May  3 13:05:35 CEST 2026
