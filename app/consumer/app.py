import os
import time
import json
import boto3
from io import BytesIO
from PIL import Image

print("--- CONSUMER APP STARTING ---")

# Initialize AWS clients
sqs = boto3.client("sqs")
s3 = boto3.client("s3")

# Get configuration from environment variables
QUEUE_URL = os.environ["SQS_QUEUE_URL"]
THUMB_BUCKET = os.environ["THUMB_BUCKET"]
THUMB_PREFIX = os.environ.get("THUMB_PREFIX", "thumbnails/")

def resize_image(data):
    """Resizes image data to a thumbnail, converting to RGB if necessary."""
    try:
        image = Image.open(BytesIO(data))
        
        # --- FIX #1: Convert RGBA images (like PNGs) to RGB before saving as JPEG ---
        if image.mode == 'RGBA':
            image = image.convert('RGB')
            
        image.thumbnail((300, 300))
        out = BytesIO()
        image.save(out, format="JPEG")
        out.seek(0)
        print("Image resized successfully.")
        return out.read()
    except Exception as e:
        print(f"ERROR: Failed to resize image. {e}")
        raise

def process_message(msg):
    """Processes a single SQS message."""
    print("DEBUG: Processing message...")
    body = json.loads(msg["Body"])
    
    # If message is from SNS, the actual payload is in the "Message" field
    payload_str = body.get("Message", json.dumps(body))
    payload = json.loads(payload_str)

    # --- FIX #2: Safely check if this is a valid S3 event with a 'Records' key ---
    if 'Records' not in payload:
        print(f"WARNING: Skipping message, not a valid S3 event: {payload}")
        return

    for s3_record in payload.get('Records', []):
        source_bucket = s3_record['s3']['bucket']['name']
        source_key = s3_record['s3']['object']['key']

        print(f"Source: s3://{source_bucket}/{source_key}")

        if source_key.startswith(THUMB_PREFIX):
            print("Skipping thumbnail, already processed.")
            continue

        resp = s3.get_object(Bucket=source_bucket, Key=source_key)
        data = resp["Body"].read()
        
        thumb_data = resize_image(data)
        
        thumb_key = THUMB_PREFIX + os.path.basename(source_key)
        
        s3.put_object(
            Bucket=THUMB_BUCKET,
            Key=thumb_key,
            Body=thumb_data,
            ContentType="image/jpeg"
        )
        print(f"SUCCESS: Wrote thumbnail to s3://{THUMB_BUCKET}/{thumb_key}")

def worker_loop():
    """Main loop to poll SQS for messages."""
    print("Starting worker loop, polling SQS...")
    while True:
        try:
            resp = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=20
            )
            msgs = resp.get("Messages", [])
            if not msgs:
                print("No messages in queue. Waiting...")
                continue

            for m in msgs:
                try:
                    process_message(m)
                    sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=m["ReceiptHandle"])
                    print("Message deleted from queue.")
                except Exception as e:
                    print(f"ERROR processing message: {e}")
        except Exception as e:
            print(f"ERROR in worker loop: {e}")
        
        time.sleep(1)

if __name__ == "__main__":
    worker_loop()
