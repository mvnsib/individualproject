#Python Environment
FROM python:3.10

#Copies the app directory
COPY . /app
WORKDIR /app

#Copies the requirement.txt file
COPY requirements.txt ./requirements.txt
#Install the dependencies in order to run the container
RUN pip install --upgrade -r requirements.txt

#Executes python when the container is initiated
ENTRYPOINT [ "python" ]
#When docker container starts
CMD ["app.py"]