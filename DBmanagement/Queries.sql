USE QuanLySoTietKiem;
GO

-- ================================================================================
-- PHẦN 1: KHUNG NHÌN (VIEWS)
-- Định nghĩa các view để đơn giản hóa việc truy xuất dữ liệu.
-- ================================================================================

-- View danh sách khách hàng (sắp xếp theo tên)
CREATE VIEW vw_DanhSachKhachHang
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY TenKH) AS STT,
    MaKH, TenKH, NgaySinh, SoGT, DiaChi, SDT
FROM KHACHHANG;
GO

-- View thông tin chi tiết 1 khách hàng + các sổ tiết kiệm đang có
CREATE OR ALTER VIEW vw_ThongTinChiTietKhachHang
AS
SELECT
    KH.MaKH, KH.TenKH, KH.NgaySinh, KH.SoGT, KH.NgayCap, KH.NoiCap, KH.HSD,
    KH.DiaChi, KH.SDT, KH.Email,
    STK.MaSo, LS.TenLoaiSo, STK.SoTienGoc, STK.NgayMoSo, STK.NgayDenHan
FROM KHACHHANG KH
LEFT JOIN CHITIETGIAODICH CT ON KH.MaKH = CT.MaKH
LEFT JOIN GIAODICH GD ON CT.MaGD = GD.MaGD
LEFT JOIN SOTIETKIEM STK ON GD.MaSo = STK.MaSo
LEFT JOIN LOAISO LS ON STK.MaLoaiSo = LS.MaLoaiSo;
GO

-- View danh sách lãi suất
CREATE VIEW vw_DanhSachLaiSuat AS
SELECT
    ROW_NUMBER() OVER (ORDER BY NgayApDung DESC) AS STT,
    ls.MaLaiSuat AS MaLS,
    ls.MaLoaiSo AS LoaiLS,
    ls.KyHan,
    ls.LaiSuatThangDau AS [LaiSuat (%)],
    ls.NgayApDung,
    CASE ls.TrangThai
        WHEN 0 THEN N'Đang áp dụng'
        WHEN 1 THEN N'Kết thúc'
        ELSE N'Không xác định'
        END AS TrangThai
FROM LAISUAT ls;
GO

-- View danh sách giao dịch
CREATE VIEW vw_DanhSachGiaoDich AS
SELECT
    ROW_NUMBER() OVER (ORDER BY gd.NgayGD DESC) AS STT,
    gd.MaGD,
    kh.TenKH,
    gd.NgayGD,
    CASE gd.LoaiGD
        WHEN 0 THEN N'Mở sổ'
        WHEN 1 THEN N'Gửi tiền'
        WHEN 2 THEN N'Rút tiền'
        WHEN 3 THEN N'Rút lãi'
        WHEN 4 THEN N'Tất toán'
        ELSE N'Không xác định'
        END AS LoaiGD,
    gd.SoTien,
    CASE gd.TrangThaiGD
        WHEN 0 THEN N'Thất bại'
        WHEN 1 THEN N'Đang xử lý'
        WHEN 2 THEN N'Thành công'
        ELSE N'Không xác định'
        END AS TrangThai
FROM GIAODICH gd
         JOIN CHITIETGIAODICH ctgd ON gd.MaGD = ctgd.MaGD
         JOIN KHACHHANG kh ON ctgd.MaKH = kh.MaKH;
GO

-- Báo cáo giao dịch theo tháng và theo từng loại
CREATE VIEW vw_BaoCaoGiaoDichTheoThang AS
SELECT
    FORMAT(G.NgayGD, 'yyyy-MM') AS Thang,
    G.LoaiGD,
    COUNT(*) AS SoLuongGD,
    SUM(G.SoTien) AS TongTienGD
FROM GIAODICH G
GROUP BY FORMAT(G.NgayGD, 'yyyy-MM'), G.LoaiGD;
GO

-- Báo cáo số sổ và tổng tiền gửi mà khách hàng sở hữu
CREATE VIEW vw_KhachHangTongQuan AS
SELECT
    KH.MaKH,
    KH.TenKH,
    COUNT(DISTINCT STK.MaSo) AS SoLuongSo,
    SUM(STK.SoTienGoc) AS TongTienGui
FROM KHACHHANG KH
JOIN CHITIETGIAODICH CT ON KH.MaKH = CT.MaKH
JOIN GIAODICH GD ON CT.MaGD = GD.MaGD
JOIN SOTIETKIEM STK ON GD.MaSo = STK.MaSo
WHERE CT.VaiTroKH = 0
GROUP BY KH.MaKH, KH.TenKH;
GO

--- VIEW: Hiển thị danh sách sổ tiết kiệm
CREATE VIEW vw_DanhSachSoTietKiem AS
SELECT
    ROW_NUMBER() OVER (ORDER BY NgayMoSo DESC) AS STT,
    MaSo, NgayMoSo, NgayDenHan, SoTienGoc, TrangThai
FROM SOTIETKIEM;
GO

--- VIEW: xem chi tiết sổ tiết kiệm
CREATE VIEW vw_ChiTietSoTietKiem AS
SELECT
    stk.MaSo,
    stk.NgayMoSo,
    stk.NgayDenHan,
    stk.SoTienGoc,
    stk.TrangThai,

    ls.MaLoaiSo,
    ls.TenLoaiSo,
    ls.DonViTien,
    CASE ls.HTGuiTien WHEN 0 THEN N'Tại quầy' ELSE N'Online' END AS HinhThucGuiTien,
    CASE ls.HTTraLai WHEN 0 THEN N'Cuối kỳ' ELSE N'Định kỳ' END AS HinhThucTraLai,
    ls.KyTraLai
FROM SOTIETKIEM stk
JOIN LOAISO ls ON stk.MaLoaiSo = ls.MaLoaiSo;
GO

--- VIEW: Hiển thị danh sách loại sổ ban đầu
CREATE VIEW Vw_LoaiSoTietKiem AS
SELECT
    MaLoaiSo,
    TenLoaiSo,
    CASE HTGuiTien
        WHEN 0 THEN N'Tại quầy'
        WHEN 1 THEN N'Online'
    END AS HinhThucGuiTien,
    CASE HTTraLai
        WHEN 0 THEN N'Cuối kỳ'
        WHEN 1 THEN N'Định kỳ'
    END AS HinhThucTraLai,
    KyTraLai,
    N'' AS MoTa
FROM LOAISO;
GO

-- ================================================================================
-- PHẦN 2: HÀM (FUNCTIONS)
-- Định nghĩa các hàm tính toán nghiệp vụ.
-- ================================================================================

-- a. Tính tổng lãi mà khách hàng nhận được sau một kỳ hạn
CREATE FUNCTION fn_TinhTienLaiCoKyHan_KhachHang(@MaKH CHAR(10))
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TongLai DECIMAL(18,2) = 0;

    SELECT @TongLai = SUM(STK.SoTienGoc * (LS.LaiSuatThangDau/ 100.00 + LS.LaiSuatThangSau * (LS.KyHan - 1)/ 100.00))
    FROM KHACHHANG KH
    JOIN CHITIETGIAODICH CT ON KH.MaKH = CT.MaKH
    JOIN GIAODICH GD ON CT.MaGD = GD.MaGD
    JOIN SOTIETKIEM STK ON GD.MaSo = STK.MaSo
    JOIN LOAISO ON STK.MaLoaiSo = LOAISO.MaLoaiSo
    JOIN LAISUAT LS ON LS.MaLoaiSo = STK.MaLoaiSo
                     AND LS.TrangThai = 0
                     AND STK.SoTienGoc >= LS.MucTien
					 AND LS.KyHan > 0
    WHERE KH.MaKH = @MaKH AND CT.VaiTroKH = 0

    RETURN ISNULL(@TongLai, 0);
END;
GO

-- b. Tính tổng lãi cho sổ không kỳ hạn mà khách hàng nhận được cho tới hiện tại
CREATE FUNCTION fn_TinhTienLaiKhongKyHan_KhachHang(@MaKH CHAR(10))
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TongLai DECIMAL(18,2) = 0;

    SELECT @TongLai = SUM(STK.SoTienGoc * (LS.LaiSuatThangDau/ 100.00 + LS.LaiSuatThangSau * (DATEDIFF(MONTH, LS.NgayApDung, GETDATE()) - 1)/ 100.00))
    FROM KHACHHANG KH
    JOIN CHITIETGIAODICH CT ON KH.MaKH = CT.MaKH
    JOIN GIAODICH GD ON CT.MaGD = GD.MaGD
    JOIN SOTIETKIEM STK ON GD.MaSo = STK.MaSo
    JOIN LOAISO ON STK.MaLoaiSo = LOAISO.MaLoaiSo
    JOIN LAISUAT LS ON LS.MaLoaiSo = STK.MaLoaiSo
                     AND LS.TrangThai = 0
                     AND STK.SoTienGoc >= LS.MucTien
					 AND LS.KyHan = 0
    WHERE KH.MaKH = @MaKH AND CT.VaiTroKH = 0

    RETURN ISNULL(@TongLai, 0);
END;
GO

-- ================================================================================
-- PHẦN 3: THỦ TỤC LƯU TRỮ (STORED PROCEDURES)
-- Định nghĩa các thủ tục thực thi nghiệp vụ CRUD và các tác vụ khác.
-- ================================================================================

-- SP thêm khách hàng – tự sinh mã KH mới
CREATE PROCEDURE ThemKhachHang
    @TenKH NVARCHAR(100),
    @NgaySinh DATE,
    @SoGT VARCHAR(20),
    @NgayCap DATE,
    @NoiCap NVARCHAR(100),
    @HSD DATE,
    @DiaChi NVARCHAR(200),
    @SDT VARCHAR(15),
    @Email VARCHAR(100)
AS
BEGIN
    DECLARE @NewMaKH CHAR(10)

    SELECT @NewMaKH = 'KH' + RIGHT('000' + CAST(ISNULL(MAX(CAST(SUBSTRING(MaKH, 3, 10) AS INT)) + 1, 1) AS VARCHAR), 3)
    FROM KHACHHANG

    INSERT INTO KHACHHANG (MaKH, TenKH, NgaySinh, SoGT, NgayCap, NoiCap, HSD, DiaChi, SDT, Email)
    VALUES (@NewMaKH, @TenKH, @NgaySinh, @SoGT, @NgayCap, @NoiCap, @HSD, @DiaChi, @SDT, @Email)

    SELECT @NewMaKH AS MaKHMoi
END;
GO

-- sp xóa KH
CREATE OR ALTER PROCEDURE XoaKhachHang
    @MaKH CHAR(10)
AS
BEGIN
    -- Kiểm tra xem khách hàng có tồn tại trong bảng CHITIETGIAODICH không
    IF EXISTS (
        SELECT 1
        FROM CHITIETGIAODICH
        WHERE MaKH = @MaKH
    )
    BEGIN
        -- Nếu có thì không cho xóa, báo lỗi
        RAISERROR(N'Không thể xóa khách hàng vì đã có giao dịch liên quan.', 16, 1)
        RETURN
    END

    -- Nếu không có giao dịch, thực hiện xóa
    DELETE FROM KHACHHANG
    WHERE MaKH = @MaKH
END;
GO

-- sp cập nhật infor KH
CREATE OR ALTER PROCEDURE CapNhatKhachHang
    @MaKH CHAR(10),
    @TenKH NVARCHAR(100),
    @NgaySinh DATE,
    @SoGT VARCHAR(20),
    @NgayCap DATE,
    @NoiCap NVARCHAR(100),
    @HSD DATE,
    @DiaChi NVARCHAR(200),
    @SDT VARCHAR(15),
    @Email VARCHAR(100)
AS
BEGIN
    -- Kiểm tra sự tồn tại
    IF NOT EXISTS (
        SELECT 1 FROM KHACHHANG WHERE MaKH = @MaKH
    )
    BEGIN
        RAISERROR(N'Không tìm thấy khách hàng cần cập nhật.', 16, 1)
        RETURN
    END

    -- Cập nhật thông tin
    UPDATE KHACHHANG
    SET
        TenKH = @TenKH,
        NgaySinh = @NgaySinh,
        SoGT = @SoGT,
        NgayCap = @NgayCap,
        NoiCap = @NoiCap,
        HSD = @HSD,
        DiaChi = @DiaChi,
        SDT = @SDT,
        Email = @Email
    WHERE MaKH = @MaKH
END;
GO

-- SP Thêm lãi suất
CREATE PROCEDURE sp_ThemLaiSuat
    @MaLaiSuat CHAR(10),
    @MaLoaiSo CHAR(10),
    @MucTien DECIMAL(18, 2),
    @KyHan INT,
    @LaiSuatThangDau FLOAT,
    @LaiSuatThangSau FLOAT,
    @NgayApDung DATE,
    @TrangThai INT
AS
BEGIN
    INSERT INTO LAISUAT (MaLaiSuat, MaLoaiSo, MucTien, KyHan, LaiSuatThangDau, LaiSuatThangSau, NgayApDung, TrangThai)
    VALUES (@MaLaiSuat, @MaLoaiSo, @MucTien, @KyHan, @LaiSuatThangDau, @LaiSuatThangSau, @NgayApDung, @TrangThai);
END;
GO

-- SP Sửa lãi suất
CREATE PROCEDURE sp_SuaLaiSuat
    @MaLaiSuat CHAR(10),
    @LaiSuatThangDau FLOAT,
    @LaiSuatThangSau FLOAT,
    @NgayApDung DATE,
    @TrangThai INT
AS
BEGIN
    UPDATE LAISUAT
    SET
        LaiSuatThangDau = @LaiSuatThangDau,
        LaiSuatThangSau = @LaiSuatThangSau,
        NgayApDung = @NgayApDung,
        TrangThai = @TrangThai
    WHERE MaLaiSuat = @MaLaiSuat;
END;
GO

-- SP Xóa lãi suất (có 2 định nghĩa trong file gốc)
CREATE PROCEDURE sp_XoaLaiSuat
    @MaLaiSuat CHAR(10),
    @XacNhan BIT -- Bắt buộc người dùng phải xác nhận rõ
AS
BEGIN
    IF @XacNhan = 1
        BEGIN
            -- Nếu sau này cần kiểm tra liên kết, bạn có thể thêm logic ở đây
            -- Gợi ý kiểm tra liên kết trước khi xóa (nâng cao)
            IF EXISTS (
                SELECT 1
                FROM SOTIETKIEM stk
                         JOIN LOAISO ls ON stk.MaLoaiSo = ls.MaLoaiSo
                         JOIN LAISUAT l ON ls.MaLoaiSo = l.MaLoaiSo
                WHERE l.MaLaiSuat = @MaLaiSuat
            )
            BEGIN
                PRINT N'Lãi suất đang được sử dụng. Không thể xóa.';
                RETURN;
            END

            DELETE FROM LAISUAT WHERE MaLaiSuat = @MaLaiSuat;

            PRINT N'Đã xóa lãi suất thành công.';
        END
    ELSE
        BEGIN
            PRINT N'Bạn chưa xác nhận thao tác xóa. Hủy thao tác.';
            -- THROW 50000, 'Xác nhận không hợp lệ. Hủy thao tác.', 1
            RETURN;
        END
END;
GO


-- SP Thêm giao dịch
CREATE PROCEDURE sp_ThemGiaoDich
    @MaGD CHAR(10),
    @MaSo CHAR(10),
    @MaKH CHAR(10),
    @LoaiGD INT,
    @SoTien DECIMAL(18, 2),
    @NgayGD DATE,
    @TrangThai INT
AS
BEGIN
    -- Thêm vào GIAODICH
    INSERT INTO GIAODICH (MaGD, MaSo, NgayGD, LoaiGD, SoTien, TrangThaiGD)
    VALUES (@MaGD, @MaSo, @NgayGD, @LoaiGD, @SoTien, @TrangThai);

    -- Thêm chi tiết giao dịch
    INSERT INTO CHITIETGIAODICH (MaKH, MaGD, VaiTroKH)
    VALUES (@MaKH, @MaGD, 0);
END;
GO

-- SP Sửa giao dịch
CREATE PROCEDURE sp_SuaGiaoDich
    @MaGD CHAR(10),
    @SoTien DECIMAL(18, 2),
    @TrangThai INT
AS
BEGIN
    UPDATE GIAODICH
    SET SoTien = @SoTien,
        TrangThaiGD = @TrangThai
    WHERE MaGD = @MaGD;
END;
GO

-- SP Xóa giao dịch
CREATE PROCEDURE sp_XoaGiaoDich
@MaGD CHAR(10)
AS
BEGIN
    DELETE FROM CHITIETGIAODICH WHERE MaGD = @MaGD;
    DELETE FROM GIAODICH WHERE MaGD = @MaGD;
END;
GO


-- SP Lọc sổ tiết kiệm theo khoảng thời gian mở sổ
CREATE PROCEDURE sp_StkLocTheoThoiGianMo @TuNgay DATE, @DenNgay Date
AS
BEGIN
	SELECT *
	FROM SOTIETKIEM
	WHERE NgayMoSo BETWEEN @TuNgay AND @DenNgay
	ORDER BY NgayMoSo;
END;
GO

-- SP Lọc sổ tiết kiệm theo khoảng thời gian đến hạn sổ
CREATE PROCEDURE sp_StkLocTheoThoiGianDenHan
	@TuNgay DATE,
	@DenNgay Date
AS
BEGIN
	SELECT *
	FROM SOTIETKIEM
	WHERE NgayDenHan BETWEEN @TuNgay AND @DenNgay
	ORDER BY NgayDenHan;
END;
GO

--- SP thêm sổ tiết kiệm
CREATE PROCEDURE sp_ThemSoTietKiem
    @MaSo CHAR(10),
    @MaLoaiSo CHAR(10),
    @NgayMoSo DATE,
    @NgayDenHan DATE,
    @SoTienGoc DECIMAL(18,2),
    @TrangThai INT
AS
BEGIN
    INSERT INTO SOTIETKIEM (MaSo, MaLoaiSo, NgayMoSo, NgayDenHan, SoTienGoc, TrangThai)
    VALUES (@MaSo, @MaLoaiSo, @NgayMoSo, @NgayDenHan, @SoTienGoc, @TrangThai);
END;
GO

--- SP Sửa sổ tiết kiệm
CREATE PROCEDURE sp_SuaSoTietKiem
    @MaSo CHAR(10),
    @MaLoaiSo CHAR(10),
    @NgayMoSo DATE,
    @NgayDenHan DATE,
    @SoTienGoc DECIMAL(18,2),
    @TrangThai INT
AS
BEGIN
    UPDATE SOTIETKIEM
    SET
        MaLoaiSo = @MaLoaiSo,
        NgayMoSo = @NgayMoSo,
        NgayDenHan = @NgayDenHan,
        SoTienGoc = @SoTienGoc,
        TrangThai = @TrangThai
    WHERE MaSo = @MaSo;
END;
GO

--- SP xóa sổ tiết kiệm
CREATE OR ALTER PROCEDURE XoaSoTietKiem
    @MaSo CHAR(10)
AS
BEGIN
    -- Kiểm tra xem sổ tiết kiệm có giao dịch nào không
    IF EXISTS (
        SELECT 1
        FROM GIAODICH
        WHERE MaSo = @MaSo
    )
    BEGIN
        -- Nếu có, không cho phép xóa
        RAISERROR(N'Không thể xóa sổ tiết kiệm vì đã có giao dịch liên quan.', 16, 1);
        RETURN;
    END

    -- Nếu không có giao dịch, thực hiện xóa sổ
    DELETE FROM SOTIETKIEM
    WHERE MaSo = @MaSo;
END;
GO

--- SP Thêm loại sổ
CREATE PROCEDURE SP_ThemLoaiSo
    @MaLoaiSo CHAR(10),
    @TenLoaiSo NVARCHAR(100),
    @DonViTien VARCHAR(10),
    @HTGuiTien INT,
    @HTTraLai INT,
    @KyTraLai NVARCHAR(50)
AS
BEGIN
    INSERT INTO LOAISO (MaLoaiSo, TenLoaiSo, DonViTien, HTGuiTien, HTTraLai, KyTraLai)
    VALUES (@MaLoaiSo, @TenLoaiSo, @DonViTien, @HTGuiTien, @HTTraLai, @KyTraLai);
END;
GO

--- SP Sửa/Cập nhật loại sổ
CREATE PROCEDURE SP_CapNhatLoaiSo
    @MaLoaiSo CHAR(10),
    @TenLoaiSo NVARCHAR(100),
    @DonViTien VARCHAR(10),
    @HTGuiTien INT,
    @HTTraLai INT,
    @KyTraLai NVARCHAR(50)
AS
BEGIN
    UPDATE LOAISO
    SET TenLoaiSo = @TenLoaiSo,
        DonViTien = @DonViTien,
        HTGuiTien = @HTGuiTien,
        HTTraLai = @HTTraLai,
        KyTraLai = @KyTraLai
    WHERE MaLoaiSo = @MaLoaiSo;
END;
GO

--- SP Xóa loại sổ
CREATE OR ALTER PROCEDURE SP_XoaLoaiSo
    @MaLoaiSo CHAR(10)
AS
BEGIN
    -- Kiểm tra có SỔ TIẾT KIỆM nào đang dùng loại sổ này không
    IF EXISTS (
        SELECT 1 FROM SOTIETKIEM WHERE MaLoaiSo = @MaLoaiSo
    )
    BEGIN
        RAISERROR(N'Không thể xóa: Đã có sổ tiết kiệm sử dụng loại sổ này.', 16, 1);
        RETURN;
    END

    -- Kiểm tra có lãi suất nào liên kết loại sổ này không
    IF EXISTS (
        SELECT 1 FROM LAISUAT WHERE MaLoaiSo = @MaLoaiSo
    )
    BEGIN
        RAISERROR(N'Không thể xóa: Đã có lãi suất liên kết với loại sổ này.', 16, 1);
        RETURN;
    END

    -- Nếu không bị ràng buộc, thực hiện xóa
    DELETE FROM LOAISO WHERE MaLoaiSo = @MaLoaiSo;
END;
GO


-- ================================================================================
-- PHẦN 4: TRIGGER
-- Định nghĩa các trigger để tự động hóa các quy tắc nghiệp vụ.
-- ================================================================================

-- Trigger cập nhật trạng thái lãi suất (có 2 định nghĩa trong file gốc)
CREATE TRIGGER trg_CapNhatTrangThaiLaiSuat
ON LAISUAT
AFTER INSERT
AS
BEGIN
    UPDATE LAISUAT
    SET TrangThai = 1 -- Kết thúc
    FROM LAISUAT LS
    JOIN inserted i ON
        LS.MaLoaiSo = i.MaLoaiSo AND
        LS.KyHan = i.KyHan AND
        LS.MucTien = i.MucTien AND
        LS.MaLaiSuat <> i.MaLaiSuat
        AND LS.TrangThai = 0 -- Đang áp dụng
END;
GO

-- Trigger cập nhật số dư sau giao dịch
CREATE TRIGGER trg_CapNhatSoDuSauGiaoDich
    ON GIAODICH
    AFTER INSERT
    AS
BEGIN
    DECLARE @LoaiGD INT, @SoTien DECIMAL(18,2), @MaSo CHAR(10), @TrangThai INT;

    SELECT @LoaiGD = LoaiGD, @SoTien = SoTien, @MaSo = MaSo
    FROM INSERTED;

    -- Nếu là rút tiền thì kiểm tra số dư
    IF @LoaiGD = 2
        BEGIN
            DECLARE @SoDuHienTai DECIMAL(18,2);

            SELECT @SoDuHienTai = SoTienGoc FROM SOTIETKIEM WHERE MaSo = @MaSo;

            IF @SoTien > @SoDuHienTai
                BEGIN
                    -- Cập nhật trạng thái thất bại
                    UPDATE GIAODICH
                    SET TrangThaiGD = 0
                    WHERE MaGD = (SELECT MaGD FROM INSERTED);
                    RETURN;
                END
        END

    -- Nếu là gửi tiền thì cộng vào số dư
    IF @LoaiGD = 1
        BEGIN
            UPDATE SOTIETKIEM
            SET SoTienGoc = SoTienGoc + @SoTien
            WHERE MaSo = @MaSo;
        END

    -- Nếu là rút tiền thì trừ khỏi số dư
    IF @LoaiGD = 2
        BEGIN
            UPDATE SOTIETKIEM
            SET SoTienGoc = SoTienGoc - @SoTien
            WHERE MaSo = @MaSo;
        END
END;
GO

-- Trigger chuyển trạng thái sổ khi đến hạn
CREATE TRIGGER trg_ChuyenTrangThaiSoTietKiem_DenHan
ON SOTIETKIEM
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE SOTIETKIEM
    SET TrangThai = 3 -- Đến hạn
    FROM SOTIETKIEM STK
    JOIN inserted i ON STK.MaSo = i.MaSo
    WHERE STK.NgayDenHan IS NOT NULL
          AND STK.NgayDenHan <= CAST(GETDATE() AS DATE)
          AND STK.TrangThai NOT IN (1, 2, 3); -- không cập nhật nếu đã tất toán, khóa, hoặc đến hạn rồi
END;
GO

-- Trigger kiểm tra số dư trước khi rút tiền
CREATE TRIGGER trg_KiemTraSoDuRutTien
ON GIAODICH
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @MaSo CHAR(10), @LoaiGD INT, @SoTien DECIMAL(18,2)

    SELECT @MaSo = MaSo, @LoaiGD = LoaiGD, @SoTien = SoTien
    FROM inserted;

    IF @LoaiGD = 2 -- 2: Rút tiền
    BEGIN
        DECLARE @SoDu DECIMAL(18,2)
        SELECT @SoDu = SoTienGoc FROM SOTIETKIEM WHERE MaSo = @MaSo;

        IF @SoTien > @SoDu
        BEGIN
            RAISERROR(N'Số tiền rút vượt quá số dư gốc!', 16, 1);
            RETURN;
        END
    END

    -- Chấp nhận thêm giao dịch nếu hợp lệ
    INSERT INTO GIAODICH(MaGD, MaSo, NgayGD, LoaiGD, SoTien, TrangThaiGD)
    SELECT MaGD, MaSo, NgayGD, LoaiGD, SoTien, TrangThaiGD FROM inserted;
END;
GO

-- Trigger cập nhật số tiền gốc khi giao dịch thành công
CREATE TRIGGER trg_CapNhatSoTienGoc_KhiGiaoDichThanhCong
ON GIAODICH
AFTER INSERT
AS
BEGIN
    UPDATE SOTIETKIEM
    SET SoTienGoc =
        CASE
            WHEN i.LoaiGD = 1 THEN SoTienGoc + i.SoTien  -- Gửi tiền
            WHEN i.LoaiGD = 2 THEN SoTienGoc - i.SoTien  -- Rút tiền
            ELSE SoTienGoc
        END
    FROM SOTIETKIEM STK
    JOIN inserted i ON STK.MaSo = i.MaSo
    WHERE i.TrangThaiGD = 2; -- Chỉ cập nhật nếu giao dịch thành công
END;
GO

-- Trigger hoàn lại tiền khi xóa giao dịch
CREATE TRIGGER trg_RollbackSoTienGoc_KhiXoaGiaoDich
ON GIAODICH
AFTER DELETE
AS
BEGIN
    UPDATE SOTIETKIEM
    SET SoTienGoc =
        CASE
            WHEN d.LoaiGD = 1 THEN SoTienGoc - d.SoTien  -- Gửi tiền: trừ lại
            WHEN d.LoaiGD = 2 THEN SoTienGoc + d.SoTien  -- Rút tiền: cộng lại
            ELSE SoTienGoc
        END
    FROM SOTIETKIEM STK
    JOIN deleted d ON STK.MaSo = d.MaSo
    WHERE d.LoaiGD IN (0, 1, 2)
      AND d.TrangThaiGD = 2; -- Chỉ rollback nếu giao dịch trước đó là thành công
END;
GO

-- Trigger xóa sổ tiết kiệm khi xóa giao dịch mở sổ
CREATE TRIGGER trg_XoaSoTietKiem_KhiXoaGiaoDichMoSo
ON GIAODICH
AFTER DELETE
AS
BEGIN
    DELETE FROM SOTIETKIEM
    WHERE MaSo IN (
        SELECT d.MaSo
        FROM deleted d
        WHERE d.LoaiGD = 0 -- Mở sổ
              AND d.TrangThaiGD = 2 -- Thành công
    );
END;
GO

/*
================================================================================
                        KỊCH BẢN PHÂN QUYỀN
                HỆ THỐNG QUẢN LÝ SỔ TIẾT KIỆM
================================================================================
*/

-- 1. TẠO LOGIN VÀ USER
-- Kết nối đến cơ sở dữ liệu master để tạo Login cho toàn Server
USE master;
GO

-- Tạo Login cho 2 người dùng
CREATE LOGIN NhanVienGiaoDich WITH PASSWORD = 'password123';
CREATE LOGIN QuanLyHeThong WITH PASSWORD = 'adminpassword';
GO

-- Chuyển đến database Quản Lý Sổ Tiết Kiệm để tạo User từ Login
USE QuanLySoTietKiem;
GO

-- Tạo User tương ứng với Login
CREATE USER NhanVienGiaoDich FOR LOGIN NhanVienGiaoDich;
CREATE USER QuanLyHeThong FOR LOGIN QuanLyHeThong;
GO

--CẤP QUYỀN THEO VAI TRÒ (ROLE-BASED PERMISSION)

--  Tạo các vai trò (Role)
CREATE ROLE GiaoDichVien;
CREATE ROLE QuanLy;
GO

--  Cấp quyền cho các vai trò
-- Vai trò GiaoDichVien
GRANT SELECT, INSERT, UPDATE ON SCHEMA::dbo TO GiaoDichVien;
GRANT EXECUTE ON OBJECT::ThemKhachHang TO GiaoDichVien;
GRANT EXECUTE ON OBJECT::CapNhatKhachHang TO GiaoDichVien;
GRANT EXECUTE ON OBJECT::sp_ThemSoTietKiem TO GiaoDichVien;
GRANT EXECUTE ON OBJECT::sp_SuaSoTietKiem TO GiaoDichVien;
GRANT EXECUTE ON OBJECT::sp_ThemGiaoDich TO GiaoDichVien;
GRANT EXECUTE ON OBJECT::sp_StkLocTheoThoiGianMo TO GiaoDichVien;
GRANT EXECUTE ON OBJECT::sp_StkLocTheoThoiGianDenHan TO GiaoDichVien;
GO

-- Vai trò QuanLy
GRANT CONTROL TO QuanLy;
GO

-- 3.3. Thêm User vào các vai trò tương ứng
EXEC sp_addrolemember 'GiaoDichVien', 'NhanVienGiaoDich';
EXEC sp_addrolemember 'QuanLy', 'QuanLyHeThong';
GO

-- Lệnh kiểm tra tài khoản đang đăng nhập là ai:
SELECT SUSER_NAME();
GO
-- Lệnh kiểm tra user trong database hiện tại là ai:
SELECT USER_NAME();
GO



-- ================================================================================
-- PHẦN 6: CÁC LỆNH TRUY VẤN, THỰC THI VÀ KIỂM TRA (QUERIES & EXECUTIONS)
-- Các lệnh dùng để kiểm tra, sử dụng các đối tượng đã tạo ở trên.
-- ================================================================================

--1. Tìm khách hàng theo mã
SELECT *
FROM KHACHHANG
WHERE MaKH = 'KH001';

--2. Tìm khách hàng theo tên
SELECT *
FROM KHACHHANG
WHERE TenKH LIKE N'Lê Thị C';

-- Xem danh sách khách hàng từ View
SELECT * FROM vw_DanhSachKhachHang;

-- Xem chi tiết khách hàng từ View
SELECT * FROM vw_ThongTinChiTietKhachHang WHERE MaKH = 'KH002';

-- Thực thi SP thêm khách hàng
EXEC ThemKhachHang
    @TenKH = N'Phạm Văn quang',
    @NgaySinh = '1993-09-30',
    @SoGT = '999885555',
    @NgayCap = '2020-01-01',
    @NoiCap = N'Cục cảnh sát',
    @HSD = '2030-01-01',
    @DiaChi = N'25 Phan Đình Phùng, đà lạt',
    @SDT = '0988121116',
    @Email = 'phamvanquang@gmail.com';

-- Thực thi SP xóa khách hàng
EXEC XoaKhachHang @MaKH = 'KH003';  -- Xóa khách hàng KH003 nếu chưa có GD

-- Thực thi SP cập nhật khách hàng
EXEC CapNhatKhachHang
    @MaKH = 'KH005',
    @TenKH = N'Phạm Văn Quang',                -- giữ nguyên
    @NgaySinh = '1999-05-16',                  -- CẬP NHẬT ngày sinh
    @SoGT = '999885555',                       -- giữ nguyên
    @NgayCap = '2020-01-01',                   -- giữ nguyên
    @NoiCap = N'Cục cảnh sát',                -- giữ nguyên
    @HSD = '2030-01-01',                       -- giữ nguyên
    @DiaChi = N'25 nguyễn trọng tấn, Đà Lạt',   -- CẬP NHẬT địa chỉ
    @SDT = '0988121116',                       -- giữ nguyên
    @Email = 'phamvanquang@gmail.com';         -- giữ nguyên

-- Tìm lãi suất
SELECT * FROM LAISUAT WHERE MaLaiSuat = 'LS001';
SELECT * FROM LAISUAT WHERE KyHan = 12;

-- Xem danh sách lãi suất từ View
SELECT * FROM vw_DanhSachLaiSuat;

-- Xem chi tiết lãi suất
SELECT * FROM LAISUAT WHERE MaLaiSuat = 'LS002';  -- ví dụ

-- Thực thi SP xóa lãi suất
EXEC sp_XoaLaiSuat @MaLaiSuat = 'LS003', @XacNhan = 1;
EXEC sp_XoaLaiSuat @MaLaiSuat = 'LS003', @XacNhan = 0;

-- Tìm giao dịch
SELECT * FROM GIAODICH gd
                  JOIN CHITIETGIAODICH ctgd ON gd.MaGD = ctgd.MaGD
                  JOIN KHACHHANG kh ON ctgd.MaKH = kh.MaKH
WHERE gd.MaGD = 'GD001';

SELECT * FROM GIAODICH gd
                  JOIN CHITIETGIAODICH ctgd ON gd.MaGD = ctgd.MaGD
                  JOIN KHACHHANG kh ON ctgd.MaKH = kh.MaKH
WHERE kh.TenKH LIKE N'%Nguyễn Văn A%';

-- Xem danh sách giao dịch từ View
SELECT * FROM vw_DanhSachGiaoDich;

-- Các truy vấn thống kê
SELECT COUNT(*) AS TongKhachHang
FROM KHACHHANG;
GO
SELECT COUNT(*) AS SoSoDangHoatDong
FROM SOTIETKIEM
WHERE TrangThai = 0;
GO
SELECT SUM(SoTienGoc) AS TongSoDu
FROM SOTIETKIEM
WHERE TrangThai = 0;
GO
SELECT AVG(LaiSuatThangDau) AS LaiSuatTrungBinh
FROM LAISUAT
WHERE TrangThai = 0;
GO

-- Thực thi SP lọc sổ tiết kiệm
EXEC sp_StkLocTheoThoiGianMo @TuNgay = '2025-01-01', @DenNgay = '2025-06-08';
GO
EXEC sp_StkLocTheoThoiGianDenHan @TuNgay = '2025-01-01', @DenNgay = '2025-07-08';
GO

-- Test các Function tính lãi
SELECT
    KH.MaKH,
    KH.TenKH,
    dbo.fn_TinhTienLaiCoKyHan_KhachHang(KH.MaKH) AS TienLaiUocTinh_CoKyHan
FROM KHACHHANG KH;
GO
SELECT
    KH.MaKH,
    KH.TenKH,
    dbo.fn_TinhTienLaiKhongKyHan_KhachHang(KH.MaKH) AS TienLaiUocTinh_KhongKyHan
FROM KHACHHANG KH;
GO

-- Truy vấn Sổ tiết kiệm & Loại sổ
SELECT *
FROM SOTIETKIEM
WHERE MaSo = 'STK001';

-- Thực thi SP thêm sổ tiết kiệm và kiểm tra
EXEC sp_ThemSoTietKiem
    @MaSo = 'STK004',
    @MaLoaiSo = 'LS02',
    @NgayMoSo = '2025-06-12',
    @NgayDenHan = '2026-06-12',
    @SoTienGoc = 15000000,
    @TrangThai = 0;
SELECT * FROM SOTIETKIEM WHERE MaSo = 'STK004';

-- Thực thi SP sửa sổ tiết kiệm và kiểm tra
EXEC sp_SuaSoTietKiem
    @MaSo = 'STK003',
    @MaLoaiSo = 'LS01',
    @NgayMoSo = '2025-06-01',
    @NgayDenHan = '2025-12-01',
    @SoTienGoc = 10000000,
    @TrangThai = 1;
SELECT * FROM SOTIETKIEM WHERE MaSo = 'STK003';

-- Thực thi SP xóa sổ tiết kiệm
EXEC XoaSoTietKiem @MaSo = 'STK001';

-- Hiển thị các loại sổ
SELECT
    MaLoaiSo,
    TenLoaiSo,
    CASE HTGuiTien
        WHEN 0 THEN N'Tại quầy'
        WHEN 1 THEN N'Online'
    END AS HinhThucGuiTien,
    CASE HTTraLai
        WHEN 0 THEN N'Cuối kỳ'
        WHEN 1 THEN N'Định kỳ'
    END AS HinhThucTraLai,
    KyTraLai,
    N'' AS MoTa -- nếu sau này có thêm mô tả thì sửa cột này
FROM LOAISO
ORDER BY KyTraLai, TenLoaiSo;

-- Tìm loại sổ theo tên
SELECT *
FROM LOAISO
WHERE TenLoaiSo LIKE N'%không kỳ hạn%';

-- Xem chi tiết loại sổ
SELECT *
FROM LOAISO
WHERE MaLoaiSo = 'LS01';

-- Thực thi SP thêm loại sổ và kiểm tra
EXEC SP_ThemLoaiSo
    @MaLoaiSo = 'LS04',
    @TenLoaiSo = N'Sổ kỳ hạn 3 tháng',
    @DonViTien = 'VND',
    @HTGuiTien = 1,         -- Online
    @HTTraLai = 0,          -- Cuối kỳ
    @KyTraLai = N'3 tháng';
SELECT * FROM LOAISO WHERE MaLoaiSo = 'LS04';

-- Thực thi SP cập nhật loại sổ và kiểm tra
EXEC SP_CapNhatLoaiSo
    @MaLoaiSo = 'LS04',
    @TenLoaiSo = N'Sổ kỳ hạn 3 tháng - cập nhật',
    @DonViTien = 'VND',
    @HTGuiTien = 0,         -- Tại quầy
    @HTTraLai = 1,          -- Định kỳ
    @KyTraLai = N'3 tháng';
SELECT * FROM LOAISO WHERE MaLoaiSo = 'LS04';

-- Thực thi SP xóa loại sổ và kiểm tra
EXEC SP_XoaLoaiSo
    @MaLoaiSo = 'LS04';
SELECT * FROM LOAISO WHERE MaLoaiSo = 'LS04';
GO