from setuptools import setup, find_packages

setup(
    name="youtube-phrase-scanner",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        "boto3>=1.28.0",
        "pytubefix>=3.0.0",
        "torch>=2.0.0",
        "torchaudio>=2.0.0",
        "ffmpeg-python>=0.2.0",
        "requests>=2.31.0",
        "numpy>=1.24.0",
        "Pillow>=10.0.0",
        "scikit-learn>=1.3.0",
        "pydub>=0.25.1",
        "soundfile>=0.12.1",
    ],
    # whisperx is installed separately with git+https://github.com/m-bain/whisperx.git
    python_requires=">=3.7",
)
