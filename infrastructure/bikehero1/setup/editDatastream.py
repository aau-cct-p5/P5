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

INDEX_TEMPLATE_URL = f"{ES_HOST}/_index_template/bikehero-template"

def update_index_template():
    update_body = {
        "index_patterns": ["bikehero-data-stream*"],
        "data_stream": {},
        "priority": 500,
        "template": {
            "mappings": {
                "properties": {
                    "AccelerationRMS": {"type": "float"}
                }
            }
        }
    }
    print(f"Updating index template at {INDEX_TEMPLATE_URL} with AccelerationRMS field...")
    response = requests.put(INDEX_TEMPLATE_URL, json=update_body, headers=HEADERS, verify=False)

    if response.status_code == 200:
        print("Index template updated successfully with AccelerationRMS field!")
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

if __name__ == "__main__":
    update_index_template()
    update_data_stream_mapping()