#!/bin/bash

TITLE=$1
NAME=_posts/$(date --rfc-3339 date)-${TITLE}.markdown
touch ${NAME}

echo "---" >> ${NAME}
echo "layout: post" >> ${NAME}
echo "title: ${TITLE}" >> ${NAME}
DATE=$(date --rfc-3339 seconds | sed -e 's/\+/ \+/')
echo "date: ${DATE}" >> ${NAME}
echo "categories: none" >> ${NAME}
echo "---" >> ${NAME}
echo "" >> ${NAME}
