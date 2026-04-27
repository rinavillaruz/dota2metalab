# trains a neural network, saves model and scaler
import os
import numpy as np
import joblib
from tensorflow import keras
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from pymongo import MongoClient

MODEL_DIR   =   os.getenv('MODEL_DIR', 'models')
MODEL_PATH  =   f"{MODEL_DIR}/dota2_model.h5"
# check if model already exists and is recent
if os.path.exists(MODEL_PATH):
    print("Model already exists. Skipping training.")
    exit(0)

MONGO_URI   =   os.getenv('MONGO_URI', 'mongodb://localhost:27017')

client      =   MongoClient(MONGO_URI)
db          =   client['dota2metalab']
collection  =   db['matches']

# Data Collection / Data Loading
matches     =   list(collection.find({}))
X           =   []
y           =   []

for match in matches:
    # Feature Engineering / Data Preparation
    features    =   match['radiant_team'] + match['dire_team'] + [match['duration']]
    label       =   int(match['radiant_win'])
    X.append(features)
    y.append(label)

if len(X) == 0:
    print("No matches found in database. Run fetcher first.")
    exit(1)
    
print(f"Total matches {len(X)}")
print(f"Sample features {X[0]}")
print(f"Sample label {y[0]}")

# Convert to numpy arrays - part of Data Preparation
X = np.array(X)
y = np.array(y)

# Train/Test Split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Feature Scaling / Preprocessing
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test) 

# Model Architecture
model = keras.Sequential([
    keras.layers.Dense(64, activation='relu', input_shape=(11,)),
    keras.layers.Dense(32, activation='relu'),
    keras.layers.Dense(1, activation='sigmoid')
])

model.compile(
    optimizer='adam',
    loss='binary_crossentropy',
    metrics=['accuracy']
)

# Train
model.fit(X_train, y_train, epochs=10, batch_size=32, validation_data=(X_test, y_test))

# Save
model.save(f'{MODEL_DIR}/dota2_model.h5')
joblib.dump(scaler, f'{MODEL_DIR}/scaler.pkl')
print("Model saved!")