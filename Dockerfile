FROM python:3.8-slim

WORKDIR /app

COPY ./build/web .
CMD python -m http.server 8000 