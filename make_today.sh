#!/bin/bash

TITLE=$1
NAME=_posts/$(date --rfc-3339 date)_${TITLE}.md
touch ${NAME}

echo "---" >> ${NAME}
echo "layout: post" >> ${NAME}
echo "title: ${TITLE}" >> ${NAME}
DATE=$(date --rfc-3339 seconds)
echo "date: ${DATE}" >> ${NAME}
echo "categories: none" >> ${NAME}
echo "---" >> ${NAME}
echo "" >> ${NAME}
