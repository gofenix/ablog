#!/bin/sh

hugo && cd public && git add -A && git commit -m "add a article" && git push && cd .. && sh backup.sh