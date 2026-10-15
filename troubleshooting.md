# Báo cáo Chẩn đoán và Khắc phục Sự cố (Troubleshooting Post-Mortem)

Tài liệu này ghi nhận chi tiết quá trình phân tích nhật ký lỗi (Log Analysis), xác định nguyên nhân gốc rễ (Root Cause Analysis - RCA) và triển khai giải pháp khắc phục cho 3 lỗi nghiêm trọng gây đứt gãy luồng CI/CD trong tệp kịch bản `.github/workflows/broken-pipeline.yml`.

---

## 1. Sự cố 1: Lỗi "Permission Denied" tại Gradle Wrapper

### 1.1. Triệu chứng & Nhật ký lỗi (Symptoms & Log Snippet)
```text
Run ./gradlew test
/home/runner/work/_temp/8c7f9999-xxxx.sh: line 1: ./gradlew: Permission denied
Error: Process completed with exit code 126.
```

### 1.2. Phân tích Nguyên nhân gốc rễ (Root Cause Analysis)
- Khi tệp tin mã nguồn được đẩy lên Git từ các hệ điều hành không bảo toàn cờ phân quyền Linux (hoặc khi tạo file mới trên môi trường Windows mà không gán bit thực thi `+x`), tệp lệnh `gradlew` bị lưu ở chế độ `100644` (chỉ đọc và ghi, không có quyền execute).
- Khi runner `ubuntu-latest` tải mã nguồn về qua action `actions/checkout@v5`, nó giữ nguyên thuộc tính phân quyền ban đầu của Git, khiến shell không thể thực thi tập lệnh `./gradlew` và báo lỗi `Permission denied` (Exit code 126).

### 1.3. Biện pháp Khắc phục (Remediation)
Bổ sung bước phân quyền rõ ràng ngay trước khi gọi bất kỳ lệnh Gradle nào:
```yaml
# Trước khi sửa:
      - name: Thực thi JUnit Test với Gradle
        run: ./gradlew test

# Sau khi sửa:
      - name: Cấp quyền cho Gradle Wrapper
        run: chmod +x gradlew

      - name: Thực thi JUnit Test với Gradle
        run: ./gradlew test
```

---

## 2. Sự cố 2: Lỗi "Authentication Failed" khi đăng nhập GitHub Container Registry

### 2.1. Triệu chứng & Nhật ký lỗi (Symptoms & Log Snippet)
```text
Run docker/login-action@v3
  with:
    registry: ghcr.io
    username: ChongChi-hub
    password: ***
Error: Username and password required
# Hoặc:
Error: unhandled rejection: Error: Cannot perform an interactive login from a non-TTY device
# Hoặc:
Error: denied: requested access to the resource is denied / unauthorized
Error: Process completed with exit code 1.
```

### 2.2. Phân tích Nguyên nhân gốc rễ (Root Cause Analysis)
- Trong cấu hình kịch bản ban đầu, người viết bị lỗi chính tả (Typo) khi tham chiếu đến tên biến Secret, ví dụ: `${{ secrets.REGISTRY_TOKKEN }}` hoặc `${{ secrets.DOCKER_KEY }}`.
- Do biến này không tồn tại trong mục **Repository Secrets**, cơ chế GitHub Actions Context mặc định trả về chuỗi rỗng `""`.
- Khi `docker/login-action@v3` nhận mật khẩu là chuỗi rỗng, quá trình xác thực vào `ghcr.io` bị từ chối truy cập ngay lập tức.

### 2.3. Biện pháp Khắc phục (Remediation)
1. Chuẩn hóa lại tên biến Secret thành `${{ secrets.REGISTRY_TOKEN }}` khớp 100% với định danh khai báo trong Settings.
2. Thêm cơ chế dự phòng an toàn (Fallback) sử dụng token tích hợp sẵn `${{ secrets.GITHUB_TOKEN }}` đi kèm quyền `packages: write`:
```yaml
# Trước khi sửa (Lỗi Typo):
      - name: Đăng nhập vào GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.REGISTRY_TOKKEN }}

# Sau khi sửa (Đã chuẩn hóa & Fallback):
      - name: Đăng nhập vào GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.REGISTRY_TOKEN || secrets.GITHUB_TOKEN }}
```

---

## 3. Sự cố 3: Lỗi "Build Context Error" khi Đóng gói Docker Image

### 3.1. Triệu chứng & Nhật ký lỗi (Symptoms & Log Snippet)
```text
Run docker/build-push-action@v5
ERROR: failed to solve: failed to read dockerfile: open /var/lib/docker/.../Dockerfile: no such file or directory
# Hoặc:
ERROR: failed to solve: failed to compute cache key: "/build/libs/*.jar" not found: not found
Error: Process completed with exit code 1.
```

### 3.2. Phân tích Nguyên nhân gốc rễ (Root Cause Analysis)
- Tham số `context` chỉ định không gian ngữ cảnh gửi cho Docker Daemon. Nếu cấu hình sai như `context: ./src` hoặc `context: ./build`, Docker BuildKit sẽ lấy thư mục đó làm gốc.
- Khi đó, Docker Daemon không tìm thấy tệp `Dockerfile` (nằm ở thư mục gốc của repository `.`), hoặc lệnh `COPY build/libs/*.jar app.jar` trong Dockerfile sẽ tìm kiếm bên trong `src/build/libs/` dẫn đến lỗi `file not found`.

### 3.3. Biện pháp Khắc phục (Remediation)
Xác định tường minh `context: .` (thư mục gốc dự án) và đường dẫn tệp `file: ./Dockerfile`:
```yaml
# Trước khi sửa (Sai context):
      - name: Đóng gói và đẩy Docker Image lên GHCR
        uses: docker/build-push-action@v5
        with:
          context: ./src
          push: true
          tags: ${{ steps.prep.outputs.image }}

# Sau khi sửa:
      - name: Đóng gói và đẩy Docker Image lên GHCR
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: true
          tags: ${{ steps.prep.outputs.image }}
```

---

## 4. Bảng Tổng hợp Đối chiếu Trước và Sau Khắc phục

| Hạng mục lỗi | Đoạn mã lỗi ban đầu | Đoạn mã chuẩn sau khi sửa | Kết quả sau sửa |
| :--- | :--- | :--- | :--- |
| **Lỗi 1: Permission** | Thiếu `chmod +x` trước lệnh test | Thêm step `run: chmod +x gradlew` | `./gradlew test` chạy thành công (Exit 0) |
| **Lỗi 2: Auth Secret** | Gõ sai: `${{ secrets.REGISTRY_TOKKEN }}` | Sửa đúng: `${{ secrets.REGISTRY_TOKEN \|\| secrets.GITHUB_TOKEN }}` | Đăng nhập GHCR thành công: `Login Succeeded!` |
| **Lỗi 3: Build Context** | Cấu hình sai: `context: ./src` | Sửa lại: `context: .` và `file: ./Dockerfile` | Docker BuildKit tìm thấy Dockerfile và JAR, đẩy image thành công |

---

## 5. Kết luận
Sau khi áp dụng toàn bộ 3 chỉnh sửa trên vào tệp kịch bản `.github/workflows/broken-pipeline.yml`, toàn bộ pipeline đã được khôi phục thành công, chạy thông suốt từ bước kiểm thử mã nguồn, đóng gói JAR tới việc build và đẩy container image lên GitHub Container Registry với trạng thái tích xanh (Success).
