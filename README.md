# Báo cáo Thực hành DevOps - Session 12: Bài 5

## Chẩn đoán và khắc phục 3 sự cố đứt gãy Pipeline CI/CD thực tế

### 1. Giới thiệu tổng quan
Bài thực hành mô phỏng và giải quyết các tình huống lỗi thực tế (Incident Troubleshooting) thường gặp nhất trong các hệ thống CI/CD doanh nghiệp. Thông qua việc phân tích nhật ký log chi tiết từ runner GitHub Actions, sinh viên tiến hành định vị và sửa chữa 3 lỗi nghiêm trọng trong tệp kịch bản `.github/workflows/broken-pipeline.yml`:
1. **Lỗi 1 (Permission Denied):** Gradle Wrapper thiếu cờ thực thi `+x`.
2. **Lỗi 2 (Authentication Failed):** Lỗi chính tả trong tên biến bí mật (`secrets.REGISTRY_TOKEN`).
3. **Lỗi 3 (Build Context Error):** Xác định sai ngữ cảnh build context và đường dẫn `Dockerfile`.

### 2. Cấu trúc thư mục bài nộp
```text
SS12_HW05_DaoTrongTri_PTIT062/
├── .github/
│   └── workflows/
│       └── broken-pipeline.yml# Kịch bản CI/CD đã được sửa lỗi hoàn chỉnh
├── gradle/
│   └── wrapper/
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── src/
│   ├── main/
│   │   ├── java/com/ptit/devops_ss12/Application.java
│   │   └── resources/application.properties
│   └── test/
│       └── java/com/ptit/devops_ss12/ApplicationTests.java
├── .gitignore
├── build.gradle
├── Dockerfile                 # Đóng gói ứng dụng chạy trên Temurin 17 JRE Alpine
├── gradlew
├── gradlew.bat
├── settings.gradle
├── troubleshooting.md         # Báo cáo phân tích RCA và so sánh đối chiếu trước/sau sửa
├── README.md                  # Hướng dẫn tổng quan bài tập
└── REPORT.md                  # Báo cáo kỹ thuật chi tiết kèm minh chứng tích xanh
```

Chi tiết tài liệu chẩn đoán xem tại [troubleshooting.md](troubleshooting.md) và báo cáo kỹ thuật tại [REPORT.md](REPORT.md).
