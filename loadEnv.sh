#!/bin/bash

# Load the .env file
export $(grep -v '^#' .env | xargs)
