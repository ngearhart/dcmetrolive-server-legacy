FROM maven:3.8-openjdk-11-slim

RUN mkdir /app
WORKDIR /app
ENV TZ='America/New_York'

COPY . .

RUN mvn clean install 

CMD mvn spring-boot:run
