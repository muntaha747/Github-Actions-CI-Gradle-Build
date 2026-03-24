# -------- Stage 1: Build --------
FROM gradle:8.7-jdk17 AS builder

WORKDIR /app

# Copy source code
COPY . .

# Build the application
RUN gradle clean build

# -------- Stage 2: Run --------
FROM eclipse-temurin:21-jdk

WORKDIR /app

# Copy built jar from builder stage
COPY --from=builder /app/app/build/libs/*.jar app.jar

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

