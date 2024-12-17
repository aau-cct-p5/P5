"""Phone Limit Tester module.

This module simulates multiple phones sending batches of fake documents to Elasticsearch.
"""

import concurrent.futures
import requests
import json
import random
import time
from datetime import datetime, timezone

# Configuration Parameters
ELASTICSEARCH_URL = 'https://elastic.mcmogens.dk/testinglimits/_bulk?pretty'
API_KEY = 'MUF6TzFKTUJKeGlHZ2pkM1RfeUo6bHlVUl8xZnlSREs2REotbVZ4ZzA0Zw=='
NUMBER_OF_PHONES = 100
BATCH_SIZE = 1000
BATCHES_PER_PHONE = 50


def generate_fake_document():
    """Generates a single fake document matching the specified structure."""
    return {
        '@timestamp': datetime.now(timezone.utc).isoformat(),
        'location': {
            'lat': round(random.uniform(-90, 90), 6),
            'lon': round(random.uniform(-180, 180), 6),
        },
        'accelerometer': f"x={round(random.uniform(-10, 10), 3)}, y={round(random.uniform(-10, 10), 3)}, z={round(random.uniform(-10, 10), 3)}",
        'gyroscope': f"x={round(random.uniform(-500, 500), 3)}, y={round(random.uniform(-500, 500), 3)}, z={round(random.uniform(-500, 500), 3)}",
        'rmsAcceleration': round(random.uniform(0, 15), 3),
        'surfaceType': random.choice(['asphalt', 'gravel', 'dirt', 'sand', 'concrete']),
    }

def prepare_bulk_payload(documents):
    """
    Prepares the bulk API payload.
    Each document is preceded by a create action for a data stream.
    """
    actions = []
    for doc in documents:
        action = {"create": {}}
        actions.append(json.dumps(action))
        actions.append(json.dumps(doc))
    bulk_payload = '\n'.join(actions) + '\n'
    return bulk_payload

def send_batch(bulk_payload, phone_id, batch_number):
    """
    Sends a single batch of documents to Elasticsearch.
    """
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'ApiKey {API_KEY}'
    }
    try:
        start_time = time.time()
        response = requests.post(ELASTICSEARCH_URL, headers=headers, data=bulk_payload)
        end_time = time.time()
        elapsed_time = end_time - start_time
        status = response.status_code
        response_text = response.text
        if status == 200:
            print(f"Phone {phone_id}: Batch {batch_number} sent successfully in {elapsed_time:.2f} seconds. Status {response.status_code}")
        else:
            print(f"Phone {phone_id}: Batch {batch_number} failed in {elapsed_time:.2f} seconds. Status: {status}, Response: {response_text}")
    except Exception as e:
        end_time = time.time()
        elapsed_time = end_time - start_time
        print(f"Phone {phone_id}: Batch {batch_number} encountered an exception after {elapsed_time:.2f} seconds: {e}")

def simulate_phone(phone_id):
    """
    Simulates a single phone sending batches of documents.
    """
    for batch_number in range(1, BATCHES_PER_PHONE + 1):
        # Generate fake documents
        documents = [generate_fake_document() for _ in range(BATCH_SIZE)]
        bulk_payload = prepare_bulk_payload(documents)
        # Send the batch
        send_batch(bulk_payload, phone_id, batch_number)

def main():
    start_time = time.time()
    with concurrent.futures.ThreadPoolExecutor(max_workers=NUMBER_OF_PHONES) as executor:
        futures = [
            executor.submit(simulate_phone, phone_id) 
            for phone_id in range(1, NUMBER_OF_PHONES + 1)
        ]
        concurrent.futures.wait(futures)
    end_time = time.time()
    elapsed_time = end_time - start_time
    print(f"Total execution time: {elapsed_time:.2f} seconds")

if __name__ == '__main__':
    main()
