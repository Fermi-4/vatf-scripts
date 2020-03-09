import argparse
import time
import os
import boto3
import botocore

with open('/mnt/gtautoftp/ml_models/aws.info') as file:
    for line in file:
        fields = line.strip().split('=')
        if fields[0] == 'ROLE_NAME':
            ROLE_NAME=fields[1]

BUCKET_NAME="sagemaker-ti-test"
DEFAULT_SHAPE='{"input": [4,224,224,3]}'
DEFAULT_FRAMEWORK="TENSORFLOW"

def get_output_file(filename, target):
    return filename.replace('.tgz','').replace('.tar.gz','') + "-" + target + ".tgz"

parser = argparse.ArgumentParser(description='Generate an S3 signed URL')
parser.add_argument('-b', '--bucket', help='bucket name', default=BUCKET_NAME)
parser.add_argument('-f', '--filename', help='local filename')
parser.add_argument('-r', '--region', help='AWS region', default="us-east-2")
parser.add_argument('-s', '--shape', help='shape, Tensorflow e.g. {"input": [4,224,224,3]}', default=DEFAULT_SHAPE)
parser.add_argument('-t', '--target', help='target device, e.g. sitara_am57x')
parser.add_argument('-n', '--name', help='compilation job name')
parser.add_argument('-a', '--role', help='sagemaker role', default=ROLE_NAME)
parser.add_argument('-w', '--framework', help='framework', default=DEFAULT_FRAMEWORK)
args = parser.parse_args()

base_filename = os.path.basename(args.filename)

s3 = boto3.client('s3', region_name=args.region)
s3r = boto3.resource('s3')

# Noop if bucket already exists
try:
    s3r.create_bucket(Bucket=args.bucket)
except Exception:
    # Already exists, move on
    pass

# Upload file if required
test_bucket = s3r.Bucket(args.bucket)
if not [os.key for os in test_bucket.objects.filter(Prefix=base_filename)]:
    s3.upload_file(args.filename, args.bucket, base_filename)

# Compile model
sagemaker = boto3.client('sagemaker', region_name=args.region)

output_file = get_output_file(base_filename, args.target)

sagemaker.create_compilation_job(CompilationJobName=args.name,
    RoleArn=args.role,
    InputConfig={
        'S3Uri': "s3://{}/{}".format(args.bucket, base_filename),
        'DataInputConfig': args.shape,
        'Framework': args.framework,
    },
    OutputConfig={
        'S3OutputLocation': "s3://" + args.bucket,
        'TargetDevice': args.target
    },
    StoppingCondition={
        'MaxRuntimeInSeconds': 900
    })

start_time = time.time()
print(sagemaker.describe_compilation_job(CompilationJobName=args.name))

while(sagemaker.describe_compilation_job(CompilationJobName=args.name)["CompilationJobStatus"]
        in ["STARTING", "INPROGRESS"]):
    if time.time() - start_time > 1000:
        raise RuntimeError("CompilationJob failed to complete on time")
    time.sleep(10)

print(sagemaker.describe_compilation_job(CompilationJobName=args.name))

# Download compile model
s3.download_file(args.bucket, output_file, output_file)
