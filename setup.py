# -*- coding: utf-8 -*-
"""
Created on Sun Feb 16 01:44:59 2025

@author: Fisseha
"""

import os
from setuptools import setup, find_packages

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
README_PATH = os.path.join(BASE_DIR, "docs", "README.md")

with open(README_PATH, "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="specklegen",
    version="0.1.6",
    author="Fisseha A. Ferede",
    author_email="fissehaad[at]gmail.com",
    description="Generate sequences of random speckle patterns and defining optical flow fields.",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/Computational-Ocularscience/ElastoNet",
    packages=find_packages(),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.6",
)
