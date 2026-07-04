USE QuanLySoTietKiem;
GO
--khách hàng
INSERT INTO KHACHHANG (MaKH, TenKH, NgaySinh, SoGT, NgayCap, NoiCap, HSD, DiaChi, SDT, Email)
VALUES
('KH001', N'Nguyễn Văn A', '1990-05-10', '123456789', '2010-06-15', N'Công an TP.HCM', '2030-06-15', N'1 Lê Lợi, Q1, TP.HCM', '0911123456', 'nguyenvana@gmail.com'),
('KH002', N'Trần Thị B', '1985-12-01', '987654321', '2011-01-20', N'Công an Hà Nội', '2031-01-20', N'75 Lý Thường Kiệt, Hoàn Kiếm, Hà Nội', '0909988776', 'tranthib@yahoo.com'),
('KH003', N'Lê Thị C', '1983-03-04', '100000003', '2021-03-24', N'Cục cảnh sát', '2031-03-24', N'Số 15 Nguyễn Văn Linh, TP.HCM', '0930787881', 'ltc@gmail.com');

--loại sổ
INSERT INTO LOAISO (MaLoaiSo, TenLoaiSo, DonViTien, HTGuiTien, HTTraLai, KyTraLai)
VALUES
('LS01', N'Sổ kỳ hạn 6 tháng', 'VND', 0, 0, N'6 tháng'),
('LS02', N'Sổ kỳ hạn 12 tháng', 'VND', 1, 1, N'1 tháng'),
('LS03', N'Sổ không kỳ hạn', 'VND', 1, 1, N'Hàng ngày');

--lãi suất
INSERT INTO LAISUAT (MaLaiSuat, MaLoaiSo, MucTien, KyHan, LaiSuatThangDau, LaiSuatThangSau, NgayApDung, TrangThai)
VALUES
('LS001', 'LS01', 1000000, 6, 5.2, 5.2, '2024-01-01', 0),
('LS002', 'LS02', 5000000, 12, 6.5, 6.7, '2024-03-01', 1),
('LS003', 'LS03', 0, 0, 0.5, 0.5, '2024-06-01', 0);

--sổ tiết kiệm
INSERT INTO SOTIETKIEM (MaSo, MaLoaiSo, NgayMoSo, NgayDenHan, SoTienGoc, TrangThai)
VALUES
('STK001', 'LS01', '2025-01-01', '2025-07-01', 20000000, 0),
('STK002', 'LS02', '2024-05-01', '2025-05-01', 100000000, 1),
('STK003', 'LS03', '2025-06-01', NULL, 5000000, 0);

--giao dịch
INSERT INTO GIAODICH (MaGD, MaSo, NgayGD, LoaiGD, SoTien, TrangThaiGD)
VALUES
('GD001', 'STK001', '2025-01-01', 0, 20000000, 2), -- Mở sổ
('GD002', 'STK002', '2024-05-01', 0, 100000000, 2), -- Mở sổ
('GD003', 'STK003', '2025-06-01', 1, 5000000, 1), -- Gửi tiền, đang xử lý
('GD004', 'STK002', '2025-05-01', 4, 106500000, 2); -- Tất toán

--chi tiết giao dịch
INSERT INTO CHITIETGIAODICH (MaKH, MaGD, VaiTroKH)
VALUES
('KH001', 'GD001', 0),
('KH002', 'GD002', 0),
('KH001', 'GD003', 0),
('KH002', 'GD004', 1); -- GD004 do người được ủy quyền KH002 thực hiện
