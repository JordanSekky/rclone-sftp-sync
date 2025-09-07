FROM rclone/rclone

RUN apk add --no-cache bash

COPY rclone_sync.sh /app/

WORKDIR /app

RUN chmod +x /app/rclone_sync.sh

ENTRYPOINT ["/app/rclone_sync.sh"]
