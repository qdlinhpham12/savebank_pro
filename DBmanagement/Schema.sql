-- Tạo database
CREATE DATABASE QuanLySoTietKiem;
GO

USE QuanLySoTietKiem;
GO

--------------------------------------------------
-- BẢNG 1: KHACHHANG (Thông tin khách hàng)
--------------------------------------------------
CREATE TABLE KHACHHANG (
    MaKH CHAR(10) PRIMARY KEY,
    TenKH NVARCHAR(100) NOT NULL,
    NgaySinh DATE,
    SoGT VARCHAR(20) UNIQUE NOT NULL,
    NgayCap DATE,
    NoiCap NVARCHAR(100),
    HSD DATE, CHECK (HSD >= NgayCap),
    DiaChi NVARCHAR(200),
    SDT VARCHAR(15) UNIQUE CHECK (LEN(SDT) BETWEEN 9 AND 15),
    Email VARCHAR(100) UNIQUE CHECK (Email LIKE '_%@_%._%')
);
GO

--------------------------------------------------
-- BẢNG 2: LOAISO (Các loại hình sổ tiết kiệm)
--------------------------------------------------
CREATE TABLE LOAISO (
    MaLoaiSo CHAR(10) PRIMARY KEY,
    TenLoaiSo NVARCHAR(100) NOT NULL,
    DonViTien VARCHAR(10) NOT NULL,
    HTGuiTien INT CHECK (HTGuiTien IN (0, 1)), -- 0: Tại quầy, 1: Online
    HTTraLai INT CHECK (HTTraLai IN (0, 1)), -- 0: Cuối kỳ, 1: Định kỳ
    KyTraLai NVARCHAR(50)
);
GO

------------------------------------------------------
-- BẢNG 3: LAISUAT (Bảng lãi suất theo từng loại sổ)
------------------------------------------------------
CREATE TABLE LAISUAT (
    MaLaiSuat CHAR(10) PRIMARY KEY,
	MaLoaiSo CHAR(10) NOT NULL,
    MucTien DECIMAL(18, 2) NOT NULL CHECK (MucTien >= 0),
    KyHan INT NOT NULL, ----####---- Tính theo tháng (0 là không kỳ hạn)
    LaiSuatThangDau FLOAT CHECK (LaiSuatThangDau >= 0),
    LaiSuatThangSau FLOAT CHECK (LaiSuatThangSau >= 0),
    NgayApDung DATE NOT NULL,
	TrangThai INT NOT NULL,

	FOREIGN KEY (MaLoaiSo) REFERENCES LOAISO(MaLoaiSo) 
);

---------------------------------------------------
-- BẢNG 4: SOTIETKIEM (Thông tin các sổ tiết kiệm)
---------------------------------------------------
CREATE TABLE SOTIETKIEM (
    MaSo CHAR(10) PRIMARY KEY,
    MaLoaiSo CHAR(10) NOT NULL,
    NgayMoSo DATE NOT NULL DEFAULT GETDATE(),
    NgayDenHan DATE, CHECK (NgayDenHan >= NgayMoSo),
    SoTienGoc DECIMAL(18, 2) NOT NULL CHECK (SoTienGoc >= 0),
    TrangThai INT NOT NULL,
	
	FOREIGN KEY (MaLoaiSo) REFERENCES LOAISO(MaLoaiSo)
);
GO

--------------------------------------------------
-- BẢNG 5: GIAODICH (Lịch sử giao dịch của mỗi sổ)
-------------------------------------------------- 
CREATE TABLE GIAODICH (
    MaGD CHAR(10) PRIMARY KEY,
    MaSo CHAR(10) NOT NULL,
    NgayGD DATE NOT NULL DEFAULT GETDATE(),
    LoaiGD INT NOT NULL,
    SoTien DECIMAL(18, 2) NOT NULL CHECK (SoTien >= 0),
    TrangThaiGD INT NOT NULL,
	
	FOREIGN KEY (MaSo) REFERENCES SOTIETKIEM(MaSo)
);
GO

--------------------------------------------------------------
-- BẢNG 6: CHITIETGIAODICH (Chi tiết các giao dịch đã diễn ra)
--------------------------------------------------------------
CREATe TABLE CHITIETGIAODICH (
	MaKH CHAR(10) NOT NULL,
	MaGD CHAR(10) NOT NULL,
	VaiTroKH INT NOT NULL,
	
	PRIMARY KEY (MaKH, MaGD),
	FOREIGN KEY (MaKH) REFERENCES KHACHHANG(MaKH),
	FOREIGN KEY (MaGD) REFERENCES GIAODICH(MaGD)
);
GO