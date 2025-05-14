import hashlib
import os
import subprocess
import logging
from pathlib import Path

# --- Configuration from environment ---
BUCKET_NAME = os.environ['BUCKET_NAME']
ENDPOINT_URL = os.environ['ENDPOINT_URL']
AWS_ACCESS_KEY_ID = os.environ['AWS_ACCESS_KEY_ID']
AWS_SECRET_ACCESS_KEY = os.environ['AWS_SECRET_ACCESS_KEY']

SYNC_DIR = Path('s3sync')
FILENAME = Path('test.file')
DOWNLOADED = Path('downloaded_test.file')
FILE_SIZE = 4096

# --- Logging ---
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

# --- Utilities ---
def run_aws_cli(command: str) -> None:
    env = os.environ.copy()
    logger.debug(f"Running command: {command}")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True, env=env)
        logger.info(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {e.stderr.strip()}")
        raise

def calculate_hash(path: Path) -> str:
    with path.open('rb') as f:
        return hashlib.sha256(f.read()).hexdigest()

def generate_file(path: Path, size: int = FILE_SIZE) -> None:
    with path.open('wb') as f:
        f.write(os.urandom(size))

def modify_first_byte(path: Path) -> None:
    with path.open('rb') as f:
        data = bytearray(f.read())
    if not data:
        raise ValueError("File is empty, cannot modify first byte.")
    data[0] = (data[0] + 1) % 256
    with path.open('wb') as f:
        f.write(data)

def restore_mtime(path: Path, original_mtime: float) -> None:
    os.utime(path, (original_mtime, original_mtime))

def sync_to_s3() -> None:
    run_aws_cli(f"aws s3 sync {SYNC_DIR} s3://{BUCKET_NAME}/ --endpoint-url {ENDPOINT_URL}")

def download_from_s3() -> None:
    run_aws_cli(f"aws s3 cp s3://{BUCKET_NAME}/{FILENAME.name} {DOWNLOADED} --endpoint-url {ENDPOINT_URL}")

# --- Main Process ---
def main() -> None:
    SYNC_DIR.mkdir(exist_ok=True)

    logger.info("Generating the original file...")
    generate_file(FILENAME)
    original_hash = calculate_hash(FILENAME)
    logger.info(f"Original SHA256 hash: {original_hash}")

    sync_path = SYNC_DIR / FILENAME.name
    FILENAME.replace(sync_path)

    sync_to_s3()

    logger.info("Modifying first byte of the file...")
    mtime_before = sync_path.stat().st_mtime
    modify_first_byte(sync_path)
    restore_mtime(sync_path, mtime_before)
    modified_hash = calculate_hash(sync_path)
    logger.info(f"Modified SHA256 hash: {modified_hash}")

    logger.info("Resyncing to S3 after modification...")
    sync_to_s3()

    logger.info("Downloading file from S3...")
    download_from_s3()
    downloaded_hash = calculate_hash(DOWNLOADED)
    logger.info(f"Downloaded file SHA256 hash: {downloaded_hash}")

    if original_hash == downloaded_hash:
        logger.warning("❌ File was not updated in the bucket — issue reproduced")
    else:
        logger.info("✅ File was updated in the bucket — no issue found")

if __name__ == "__main__":
    main()
