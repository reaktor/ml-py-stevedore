#!/bin/sh

export PYTHONPATH="/service"
export VIRTUAL_ENV=/opt/venv
export PATH="$VIRTUAL_ENV/bin:$PATH"
pytest -p no:cacheprovider
