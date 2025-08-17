import json
import os
import boto3
import traceback
from PIL import Image # Assuming you use the Pillow library for image processing
import io

print("--- CONSUMER SCRIPT STARTING ---")

# Initialize AWS clients
s3 = boto3.client("s3")

# Get configuration from environment variables
THUMB_BUCKET = os.environ.get("THUMB_BUCKET")
THUMB_PREFIX = os.environ.get("THUMB_PREFIX", "thumbnails/")
THUMB_SIZE = (128, 128) # Example thumbnail size

def handler(event, context):
    """
    This is the main handler for the consumer application.
    It processes messages from SQS, which contain S3 event notifications.
    """
    try:
        print(f"DEBUG: Received event with {len(event.get('Records', []))} records.")

        if not THUMB_BUCKET:
            print("ERROR: THUMB_BUCKET environment variable is not set.")
            # In a real app, you might raise an exception here
            return {"status": "error", "message": "missing THUMB_BUCKET config"}

        for record in event.get("Records", []):
            # The message from SQS has a 'body' which is a JSON string
            message_body = json.loads(record['body'])
            
            # The S3 event notification is inside the 'Message' field
            s3_event = json.loads(message_body['Message'])

            for s3_record in s3_event.get("Records", []):
                # Extract the source bucket and key (filename)
                source_bucket = s3_record['s3']['bucket']['name']
                source_key = s3_record['s3']['object']['key']

                print(f"Processing s3://{source_bucket}/{source_key}")

                # 1. Download the image from the raw bucket
                response = s3.get_object(Bucket=source_bucket, Key=source_key)
                image_data = response['Body'].read()

                # 2. Create a thumbnail
                with Image.open(io.BytesIO(image_data)) as image:
                    image.thumbnail(THUMB_SIZE)
                    thumb_buffer = io.BytesIO()
                    image.save(thumb_buffer, format="JPEG")
                    thumb_buffer.seek(0)

                # 3. Construct the new key for the thumbnail
                filename = os.path.basename(source_key)
                thumb_key = f"{THUMB_PREFIX}{filename}"

                # 4. Upload the thumbnail to the destination bucket
                s3.upload_fileobj(
                    thumb_buffer,
                    THUMB_BUCKET, # <-- Use the destination bucket
                    thumb_key
                )
                print(f"Successfully uploaded thumbnail to s3://{THUMB_BUCKET}/{thumb_key}")

                # (Optional but recommended) After successful processing, delete the message from the SQS queue
                # receipt_handle = record['receiptHandle']
                # sqs.delete_message(QueueUrl=SQS_QUEUE_URL, ReceiptHandle=receipt_handle)

        return {"status": "ok"}

    except Exception as e:
        # Keep your robust exception handling
        print(f"FATAL: Unhandled exception in handler: {str(e)}")
        traceback.print_exc()
        return {"status": "error", "message": str(e)}
