# -*- coding: utf-8 -*-
"""
Created on Sun Feb 16 01:44:59 2025

@author: Fisseha
"""

from setuptools import setup, find_packages

setup(
    name="specklegen",  # Replace with your actual package name
    version="0.1.0",
    author="Fisseha A. Ferede",
    author_email="fissehaad@gmail.com",
    description="A package for generating speckle patterns and optical flow fields",
    packages=find_packages(),
    install_requires=[
        "numpy",
        "opencv-python",
        "matplotlib",
        "gstools",
    ],
    python_requires=">=3.6",
)
