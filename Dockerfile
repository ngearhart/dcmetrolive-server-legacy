FROM maven:3.8-openjdk-11-slim AS build

RUN mkdir /app
WORKDIR /app

COPY . .

RUN mvn clean install 

FROM openjdk:11-slim-bullseye

RUN mkdir /app
WORKDIR /app
ENV TZ='America/New_York'

COPY --from=build /app/target/ /app/target

CMD java -jar target/metrorailserver-1.0-SNAPSHOT.jar
