import os
import sys
from dotenv import load_dotenv
import cloudinary
import cloudinary.uploader

# Support UTF-8 print encoding on Windows consoles
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

# Load environment variables
load_dotenv()
backend_env = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '.env')
if os.path.exists(backend_env):
    load_dotenv(backend_env)

# Fetch Cloudinary configuration
CLOUD_NAME = os.environ.get('CLOUDINARY_CLOUD_NAME', 'sys2leas')
API_KEY = os.environ.get('CLOUDINARY_API_KEY', '995613675478516')
API_SECRET = os.environ.get('CLOUDINARY_API_SECRET', 'cp7KCq5bNtyWJ3BXppLhJ8XPXas')

# Initialize Cloudinary SDK configuration
cloudinary.config(
    cloud_name=CLOUD_NAME,
    api_key=API_KEY,
    api_secret=API_SECRET,
    secure=True
)

print(f"✅ Cloudinary SDK initialized for Cloud: {CLOUD_NAME}")

def upload_image_to_cloudinary(file_source, folder="posture-ai", public_id=None):
    """
    Uploads an image (file object, bytes, or file path) directly to Cloudinary.
    Returns the secure HTTPS URL from Cloudinary.
    """
    try:
        options = {"folder": folder, "resource_type": "image"}
        if public_id:
            options["public_id"] = public_id

        target = file_source
        if hasattr(file_source, 'read'):
            raw_bytes = file_source.read()
            if hasattr(file_source, 'seek'):
                try:
                    file_source.seek(0)
                except Exception:
                    pass
            import base64
            b64_str = base64.b64encode(raw_bytes).decode('utf-8')
            target = f"data:image/png;base64,{b64_str}"

        # Execute upload using official Cloudinary SDK
        upload_result = cloudinary.uploader.upload(target, **options)
        secure_url = upload_result.get("secure_url")
        print(f"✅ Image successfully uploaded to Cloudinary: {secure_url}")
        return secure_url
    except Exception as e:
        print(f"[CLOUDINARY ERROR] Failed to upload image: {e}")
        raise e
