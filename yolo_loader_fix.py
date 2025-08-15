"""
NumPy compatibility fix - This file should NOT import ultralytics!
It only sets up the environment to suppress warnings.
"""

import warnings
import os
import sys

# Suppress all NumPy-related warnings before any imports
warnings.filterwarnings('ignore', message='.*NumPy.*')
warnings.filterwarnings('ignore', message='.*numpy.*')
warnings.filterwarnings('ignore', message='.*_ARRAY_API.*')
warnings.filterwarnings('ignore', category=UserWarning)
warnings.filterwarnings('ignore', category=DeprecationWarning)

# Set environment variables to suppress warnings
os.environ['PYTHONWARNINGS'] = 'ignore'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

# Try to check numpy version without triggering errors
try:
    import numpy as np

    print(f"[yolo_loader_fix] NumPy version: {np.__version__}")

    # Add compatibility attribute if missing
    if not hasattr(np, '_ARRAY_API'):
        np._ARRAY_API = None

except ImportError:
    print("[yolo_loader_fix] NumPy not installed")
except Exception as e:
    print(f"[yolo_loader_fix] Warning: {e}")

print("[yolo_loader_fix] Compatibility module loaded (no ultralytics import)")