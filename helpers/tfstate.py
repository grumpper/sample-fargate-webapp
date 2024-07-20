import os
import boto3
import botocore


def create_s3_bucket_if_not_exists(bucket_name, region):
    s3 = boto3.client('s3', region_name=region)

    try:
        s3.head_bucket(Bucket=bucket_name)
        print(f"Bucket {bucket_name} already exists.")
    except botocore.exceptions.ClientError as e:
        error_code = int(e.response['Error']['Code'])
        if error_code == 404:
            print(f"Bucket {bucket_name} does not exist. Creating...")
            s3.create_bucket(
                Bucket=bucket_name,
                CreateBucketConfiguration={'LocationConstraint': region}
            )
            s3.put_bucket_versioning(
                Bucket=bucket_name,
                VersioningConfiguration={'Status': 'Enabled'}
            )
            s3.put_bucket_encryption(
                Bucket=bucket_name,
                ServerSideEncryptionConfiguration={
                    'Rules': [
                        {
                            'ApplyServerSideEncryptionByDefault': {
                                'SSEAlgorithm': 'AES256'
                            }
                        }
                    ]
                }
            )
            print(f"Bucket {bucket_name} created.")
        else:
            raise


if __name__ == "__main__":
    bucket_name = os.getenv("TF_STATE_BUCKET_NAME")
    region = os.getenv("TF_STATE_BUCKET_REGION")

    if bucket_name and region:
        create_s3_bucket_if_not_exists(bucket_name, region)
    else:
        print("Environment variables TF_STATE_BUCKET_NAME and TF_STATE_BUCKET_REGION must be set.")
