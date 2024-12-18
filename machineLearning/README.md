# BikeHero Machine Learning Module

Prerequisites:
- Docker Desktop
- Python
- Pip
- .env file in trainingFetcher folder with API key for Elastic (read privileges)
- .env file in updater folder with API key for Elastic (write privileges)

Write us an email for api keys

## How to run on local machine

1. **Fetch data from Elastic**
   ``` cd ./trainingFetcher
   docker-compose up --build
   ```
Note: May take several minutes to run.

2. **Run surface detection engine**
    ``` rm ../surfaceDetectionEngine/data/training_data.csv
    cp data/training_data.csv ../surfaceDetectionEngine/data/training_data.csv
    cd ../surfaceDetectionEngine
    $env:MODE="train"
    docker-compose up --build
    $env:MODE="predict"
    docker-compose up --build
    ```
Note: Each docker container may take several minutes to run. They must be run seperately and in order.


3. **Send prediction data to Elastic**
    ``` rm ../updater/data/predictions/predictions.csv
    cp data/predictions.csv ../updater/data/predictions/predictions.csv
    cd ../updater
    docker-compose up --build
    ```
 Note: May take several minutes to run.
