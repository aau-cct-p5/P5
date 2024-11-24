import requests
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

API_KEY = os.getenv("ELASTICSEARCH_API_KEY")
ES_HOST = os.getenv("ELASTICSEARCH_HOST")

# Ensure API key and host are provided
if not API_KEY or not ES_HOST:
    raise ValueError("Missing API key or Elasticsearch host. Please check your .env file.")

HEADERS = {
    "Content-Type": "application/json",
    "Authorization": f"ApiKey {API_KEY}"
}

INDEX_TEMPLATE_URL = f"{ES_HOST}/_index_template/bikehero_template"
DATA_STREAM_URL = f"{ES_HOST}/_data_stream/bikehero-data-stream"

def update_index_template():
    # Define the index template
    index_template_body = {
        "index_patterns": ["bikehero-data-stream*"],
        "data_stream": {},
        "template": {
            "settings": {
                "number_of_shards": 1,
                "number_of_replicas": 1
            },
            "mappings": {
                "properties": {
                    "@timestamp": {"type": "date"},
                    "location": {"type": "geo_point"},
                    "vibration": {
                        "properties": {
                            "x": {"type": "float"},
                            "y": {"type": "float"},
                            "z": {"type": "float"}
                        }
                    },
                    "rmsAcceleration": {"type": "float"}
                }
            }
        }
    }
    print(f"Updating index template at {INDEX_TEMPLATE_URL}...")
    response = requests.put(INDEX_TEMPLATE_URL, json=index_template_body, headers=HEADERS, verify=False)

    if response.status_code == 200:
        print("Index template updated successfully with full template body and different priority!")
    else:
        print(f"Failed to update index template. Status code: {response.status_code}")
        print(response.text)

def update_data_stream_mapping():
    data_stream_url = f"{ES_HOST}/bikehero-data-stream/_mapping"
    update_body = {
        "properties": {
            "AccelerationRMS": {"type": "float"}
        }
    }
    print(f"Updating data stream mapping at {data_stream_url} with AccelerationRMS field...")
    response = requests.put(data_stream_url, json=update_body, headers=HEADERS, verify=False)

    if response.status_code == 200:
        print("Data stream mapping updated successfully with AccelerationRMS field!")
    else:
        print(f"Failed to update data stream mapping. Status code: {response.status_code}")
        print(response.text)

def delete_data_stream():
    print(f"Deleting data stream at {DATA_STREAM_URL}...")
    response = requests.delete(DATA_STREAM_URL, headers=HEADERS, verify=False)
    if response.status_code == 200 or response.status_code == 404:
        print("Data stream deleted successfully or does not exist.")
    else:
        print(f"Failed to delete data stream. Status code: {response.status_code}")
        print(response.text)

def create_data_stream():
    print(f"Creating data stream at {DATA_STREAM_URL}...")
    response = requests.put(DATA_STREAM_URL, headers=HEADERS, verify=False)
    if response.status_code == 200:
        print("Data stream created successfully!")
    else:
        print(f"Failed to create data stream. Status code: {response.status_code}")
        print(response.text)

if __name__ == "__main__":
    delete_data_stream()
    update_index_template()
    create_data_stream()
    update_data_stream_mapping()