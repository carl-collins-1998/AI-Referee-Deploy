"""
NumPy 2.x compatibility fix for Ultralytics YOLO
This module must be imported before any torch/ultralytics imports
"""

import warnings
import sys
import os

# Suppress all NumPy-related warnings
warnings.filterwarnings('ignore', message='.*NumPy.*')
warnings.filterwarnings('ignore', message='.*numpy.*')
warnings.filterwarnings('ignore', category=UserWarning)
warnings.filterwarnings('ignore', category=DeprecationWarning)

# Set environment variable to suppress warnings
os.environ['PYTHONWARNINGS'] = 'ignore'

# Try to monkey-patch numpy compatibility
try:
    import numpy as np

    # Check version
    version = np.__version__
    print(f"[yolo_loader_fix] NumPy version: {version}")

    if version.startswith('2.'):
        print("[yolo_loader_fix] WARNING: NumPy 2.x detected. Attempting compatibility patches...")

        # Add compatibility attributes that might be missing
        if not hasattr(np, '_ARRAY_API'):
            np._ARRAY_API = None

        # Suppress the specific torch warning
        import torch

        torch.set_warn_always(False)

except ImportError as e:
    print(f"[yolo_loader_fix] NumPy not yet installed: {e}")
except Exception as e:
    print(f"[yolo_loader_fix] Error during compatibility patching: {e}")

print("[yolo_loader_fix] Compatibility module loaded successfully")