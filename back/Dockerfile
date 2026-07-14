#================BUILD STAGE================
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY /src ./src
RUN mvn clean package -DskipTests
#================RUNTIME STAGE================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

VOLUME /data

EXPOSE 8080

CMD ["sh", "-c", "mkdir -p /data && java -jar app.jar"]