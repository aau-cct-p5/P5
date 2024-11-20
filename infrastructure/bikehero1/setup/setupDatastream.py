import os
import requests
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Get the Elasticsearch API key and host from the environment
API_KEY = os.getenv("ELASTICSEARCH_API_KEY")
ES_HOST = os.getenv("ELASTICSEARCH_HOST")

# Ensure API key and host are provided
if not API_KEY or not ES_HOST:
    raise ValueError("Missing API key or Elasticsearch host. Please check your .env file.")

# Headers for the Elasticsearch request
HEADERS = {
    "Content-Type": "application/json",
    "Authorization": f"ApiKey {API_KEY}"
}

# URL for the index template, data stream, and API key creation
INDEX_TEMPLATE_URL = f"{ES_HOST}/_index_template/bikehero_template"
DATA_STREAM_URL = f"{ES_HOST}/_data_stream/bikehero-data-stream"
API_KEY_URL = f"{ES_HOST}/_security/api_key"

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
                "user_id": {"type": "keyword"},
                "device_id": {"type": "keyword"},
                "AccelerationRMS": {"type": "float"}
            }
        }
    }
}

# Function to create the index template
def create_index_template():
    print(f"Creating index template at {INDEX_TEMPLATE_URL}...")
    response = requests.put(INDEX_TEMPLATE_URL, json=index_template_body, headers=HEADERS, verify=False)

    if response.status_code == 200:
        print("Index template created successfully!")
    else:
        print(f"Failed to create index template. Status code: {response.status_code}")
        print(response.text)

# Function to create the data stream
def create_data_stream():
    print(f"Creating data stream at {DATA_STREAM_URL}...")
    response = requests.put(DATA_STREAM_URL, headers=HEADERS, verify=False)

    if response.status_code == 200:
        print("Data stream created successfully!")
    else:
        print(f"Failed to create data stream. Status code: {response.status_code}")
        print(response.text)

# Function to create an API key with the required role descriptor
def create_api_key_with_role():
    api_key_body = {
        "name": "bikeHeroClientApiKey",
        "expiration": "1d",  # Optional expiration
        "role_descriptors": {
            "bikeHeroRole": {
                "cluster": ["monitor"],  # Cluster-level privileges (optional)
                "index": [
                    {
                        "names": ["bikehero-data-stream*"],  # Index name pattern
                        "privileges": ["write", "read", "create_index"]  # Privileges for the data stream
                    }
                ]
            }
        }
    }

    print(f"Creating API key for role 'BikeHeroClientApp' at {API_KEY_URL}...")
    response = requests.post(API_KEY_URL, json=api_key_body, headers=HEADERS, verify=False)

    if response.status_code == 200:
        api_key = response.json()["api_key"]
        print("API key created successfully!")
        print(f"bikeHeroClientApiKey: {api_key}")
    else:
        print(f"Failed to create API key. Status code: {response.status_code}")
        print("Response body: ", response.text)

# Function to show example curl request
def show_example_curl():
    example_document = {
        "@timestamp": "2023-10-01T12:00:00Z",
        "location": {"lat": 40.7128, "lon": -74.0060},
        "vibration": {"x": 0.1, "y": 0.2, "z": 0.3},
        "user_id": "user123",
        "device_id": "device456"
    }
    curl_command = f"""
    curl -X POST "{ES_HOST}/bikehero-data-stream/_doc" -H 'Content-Type: application/json' -H 'Authorization: ApiKey {API_KEY}' -d '{example_document}'
    """
    print("Example curl request to add a document to the data stream:")
    print(curl_command)

# Run the setup
if __name__ == "__main__":
    create_index_template()
    create_data_stream()
    create_api_key_with_role()
    show_example_curl()
