"""Phone Limit Tester module.

This module simulates multiple phones sending batches of fake documents to Elasticsearch.
"""

import asyncio
import aiohttp
import json
import random
from datetime import datetime, timezone

# Configuration Parameters
ELASTICSEARCH_URL = 'https://elastic.mcmogens.dk/testinglimits/_bulk?pretty'
API_KEY = 'dEZ0a3o1TUJKeGlHZ2pkMzBsRUY6MVhBMm5UV1RSSnltRWxmRWxmUTJfcmFkdw=='
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

async def send_batch(session, bulk_payload, phone_id, batch_number):
    """
    Sends a single batch of documents to Elasticsearch.
    """
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'ApiKey {API_KEY}'
    }
    try:
        async with session.post(ELASTICSEARCH_URL, headers=headers, data=bulk_payload) as response:
            status = response.status
            response_text = await response.text()
            if status == 200:
                print(f"Phone {phone_id}: Batch {batch_number} sent successfully. Status {response_text.status if hasattr(response_text, 'status') else status}")
            else:
                print(f"Phone {phone_id}: Batch {batch_number} failed. Status: {status}, Response: {response_text.status}")
    except Exception as e:
        print(f"Phone {phone_id}: Batch {batch_number} encountered an exception: {e}")

async def simulate_phone(phone_id, session):
    """
    Simulates a single phone sending batches of documents.
    """
    for batch_number in range(1, BATCHES_PER_PHONE + 1):
        # Generate fake documents
        documents = [generate_fake_document() for _ in range(BATCH_SIZE)]
        bulk_payload = prepare_bulk_payload(documents)
        # Send the batch
        await send_batch(session, bulk_payload, phone_id, batch_number)

async def main():
    connector = aiohttp.TCPConnector(limit=1000)
    timeout = aiohttp.ClientTimeout(total=600)
    async with aiohttp.ClientSession(connector=connector, timeout=timeout) as session:
        tasks = []
        for phone_id in range(1, NUMBER_OF_PHONES + 1):
            task = asyncio.create_task(simulate_phone(phone_id, session))
            tasks.append(task)
        await asyncio.gather(*tasks)

if __name__ == '__main__':
    asyncio.run(main())
