# Sử dụng Eclipse Temurin JRE 17 gọn nhẹ trên Alpine Linux
FROM eclipse-temurin:17-jre-alpine

# Thiết lập thư mục làm việc trong container
WORKDIR /app

# Sao chép tệp Fat JAR từ thư mục build/libs đã đóng gói
COPY build/libs/*.jar app.jar

# Mở cổng 8080 cho ứng dụng Spring Boot
EXPOSE 8080

# Khởi chạy ứng dụng
ENTRYPOINT ["java", "-jar", "app.jar"]
