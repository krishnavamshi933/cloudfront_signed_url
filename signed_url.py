import boto3
from botocore.signers import CloudFrontSigner
from datetime import datetime, timedelta

def rsa_signer(message):
    with open('private_key.pem', 'rb') as key_file:
        private_key = key_file.read()
    from cryptography.hazmat.primitives import hashes
    from cryptography.hazmat.primitives.asymmetric import padding
    from cryptography.hazmat.primitives.serialization import load_pem_private_key
    private_key = load_pem_private_key(private_key, password=None)
    return private_key.sign(
        message,
        padding.PKCS1v15(),
        hashes.SHA1()
    )

key_id = 'keypair-id'
url = 'https://cloudfronturl/object'   #cloudfront url with object path
expires = int((datetime.utcnow() + timedelta(hours=1)).timestamp())

cloudfront_signer = CloudFrontSigner(key_id, rsa_signer)

signed_url = cloudfront_signer.generate_presigned_url(
    url,
    date_less_than=datetime.utcnow() + timedelta(hours=1)
)

print(signed_url)

#key pair generated commands
#openssl genrsa -out private_key.pem 2048
#openssl rsa -pubout -in private_key.pem -out public_key.pem
