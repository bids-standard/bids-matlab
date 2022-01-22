#!/bin/bash

sphinx-build -M latexpdf source build

cp build/latex/bids-matlab.pdf bids-matlab.pdf
