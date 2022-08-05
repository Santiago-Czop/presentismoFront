FROM python:3.8-slim

WORKDIR /app

COPY ./release/web .
CMD python -m http.server $PORT