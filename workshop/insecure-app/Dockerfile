# Start from Ubuntu
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl wget jq procps

# Create /app directory and set as working directory
RUN mkdir /app
WORKDIR /app

# Add application and requirements.txt
ADD ./app.py /app/
ADD ./tutorial.db /app/
ADD ./requirements.txt /app/ 

# Install Python packages from requirements.txt
RUN python3 -m pip install --no-cache-dir -r requirements.txt --break-system-packages

# Create an uploads directory
RUN mkdir /uploads

# Install Flask in a weird way
RUN python3 -m pip install Flask

CMD ["python3", "/app/app.py"]
