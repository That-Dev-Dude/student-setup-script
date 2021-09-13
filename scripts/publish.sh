#!/bin/sh

aws s3 cp src/setup.sh $S3_BUCKET

# /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"