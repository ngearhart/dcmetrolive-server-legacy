FROM maven:3.8-openjdk-11-slim AS build

RUN mkdir /app
WORKDIR /app

COPY . .

RUN mvn clean install
# Setting for docker-compose
CMD mvn spring-boot:run

FROM openjdk:11-slim-bullseye AS final

RUN mkdir /app
WORKDIR /app
ENV TZ='America/New_York'

COPY --from=build /app/target/ /app/target

CMD java -jar target/metrorailserver-1.0-SNAPSHOT.jar
