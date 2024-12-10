from elasticsearch import Elasticsearch
from dotenv import load_dotenv
import os
import csv

# Get API key from .env file
load_dotenv()
api_key=os.getenv("ELASTIC_API_KEY")
host="https://elastic.mcmogens.dk"

index_name=".ds-bikehero-data-stream-2024.11.22-000001"

def fetch_data(host, api_key, index_name, scroll='2m', batch_size=1000):
    query = {
    "query": {
        "match_all": {}
        }
    }
    elastic=Elasticsearch(
        hosts=[host],
        api_key=api_key
    )
    data = []
    response = elastic.search(index=index_name, body=query, scroll=scroll, size=batch_size)
    scroll_id = response.get('_scroll_id')
    hits = response['hits']['hits']

    data.extend([hit['_source'] for hit in hits])
    print(f"Fetched {len(hits)} documents in the first batch...")
    while hits:
        response = elastic.scroll(scroll_id=scroll_id, scroll=scroll)
        scroll_id=response.get('_scroll_id')
        hits = response['hits']['hits']
        if not hits: 
            break
        data.extend([hit['_source'] for hit in hits])
        print(f"Fetched {len(hits)} more documents, total: {len(data)}")
    
    elastic.clear_scroll(scroll_id=scroll_id)
    print(f"Finished fetchin {len(data)} documents.")

    return data

def prepare_for_csv(data):
    new_data = []
    for record in data:
        new_record = record.copy()
        if 'location' in new_record and isinstance(new_record['location'], dict):
            loc = new_record.pop('location')
            new_record['location_lat'] = loc.get('lat', '')
            new_record['location_lon'] = loc.get('lon', '')
        if 'accelerometer' in new_record and isinstance(new_record['accelerometer'], dict):
            accel = new_record.pop('accelerometer')
            new_record['accelerometer_x'] = accel.get('x', '')
            new_record['accelerometer_y'] = accel.get('y', '')
            new_record['accelerometer_z'] = accel.get('z', '')
        if 'gyroscope' in new_record and isinstance(new_record['gyroscope'], dict):
            gyro = new_record.pop('gyroscope')
            new_record['gyroscope_x'] = gyro.get('x', '')
            new_record['gyroscope_y'] = gyro.get('y', '')
            new_record['gyroscope_z'] = gyro.get('z', '')
        new_data.append(new_record)
    return new_data

def save_to_csv(data, file_name):
    if not data:
        print("No data to write to CSV.")
        return
    
    headers = data[0].keys()

    with open(file_name, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=headers)
        writer.writeheader()
        writer.writerows(data)

    print(f"Data successfully written to {file_name}")


data = fetch_data(host, api_key, index_name)
data = prepare_for_csv(data)
save_to_csv(data, "./training_data.csv")