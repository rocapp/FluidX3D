#!/bin/bash

export_dir=${1:-s}
ffmpeg -framerate 12 -pattern_type glob -i './bin/export/'${export_dir}'/image*.png' -s:v 1920x1080 -c:v libx264 -pix_fmt yuv420p ./videos/out_${export_dir}.mp4
