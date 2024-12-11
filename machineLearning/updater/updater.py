# updater.py
import os
import csv
from dotenv import load_dotenv
from elasticsearch import Elasticsearch, helpers

# Load environment variables
load_dotenv()
api_key = os.getenv("ELASTIC_API_KEY")
host = "https://elastic.mcmogens.dk"
index_name = ".ds-bikehero-data-stream-2024.11.22-000001"
predictions_dir = "./data/predictions"

# Connect to Elasticsearch
elastic = Elasticsearch(
    hosts=[host],
    api_key=api_key
)

def bulk_update_documents(elastic, index_name, docs, batch_size=1000):
    # docs is a list of dicts, each containing '_id' and some predicted_* fields.
    actions = []
    for doc in docs:
        if '_id' not in doc:
            continue
        # Collect all predicted_* fields
        predicted_fields = {k: v for k, v in doc.items() if k.startswith('predicted_') and v.strip() != ''}
        if not predicted_fields:
            # If no predicted fields or they are empty, skip
            continue
        action = {
            "_op_type": "update",
            "_index": index_name,
            "_id": doc['_id'],
            "doc": predicted_fields
        }
        actions.append(action)
        if len(actions) == batch_size:
            helpers.bulk(elastic, actions)
            actions = []
    # Final flush
    if actions:
        helpers.bulk(elastic, actions)

def process_predictions_file(file_path):
    docs = []
    with open(file_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Extract all fields including _id and any predicted_*
            # We assume _id exists; if not, we skip.
            if '_id' not in row:
                continue
            doc = {'_id': row['_id']}
            # Include all predicted_* fields
            for key, val in row.items():
                if key.startswith('predicted_'):
                    doc[key] = val
            docs.append(doc)
    return docs

def main():
    if not os.path.exists(predictions_dir):
        print(f"Predictions directory {predictions_dir} not found.")
        return
    
    files = [f for f in os.listdir(predictions_dir) if f.endswith(".csv")]
    if not files:
        print("No prediction CSV files found in /data/predictions.")
        return

    total_updated = 0
    for file_name in files:
        file_path = os.path.join(predictions_dir, file_name)
        print(f"Processing {file_path}...")
        docs = process_predictions_file(file_path)
        if docs:
            # Update all documents with any predicted_* fields found
            bulk_update_documents(elastic, index_name, docs)
            total_updated += len(docs)
            print(f"Updated {len(docs)} documents from {file_name}.")
        else:
            print(f"No valid documents to update from {file_name}.")

    print(f"Finished updating. Total documents updated: {total_updated}")

if __name__ == "__main__":
    main()
