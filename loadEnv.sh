#!/bin/bash

# Load the .env file
env_file="${1:-.env}"
export $(grep -v '^#' "$env_file" | xargs)
