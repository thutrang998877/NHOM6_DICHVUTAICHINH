// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract CrowdfundingPlatform {
    struct ChienDich {
        address nguoiSangTao;
        uint mucTieu;
        uint soTienDong;
        uint thoiGianBatDau;
        uint thoiGianKetThuc;
        bool daYeuCau;
    }

    mapping(uint => ChienDich) public chienDich;
    mapping(uint => mapping(address => uint)) public dongGop;
    uint public soChienDich;

    event ChienDichDuocTao(uint chienDichId, address indexed nguoiSangTao, uint mucTieu, uint thoiGianBatDau, uint thoiGianKetThuc);
    event DongGopNhanDuoc(uint indexed chienDichId, address indexed nhaHaoTam, uint soTien);
    event ChienDichHoanTat(uint indexed chienDichId, bool thanhCong, uint soTienDaThanhToan);
    event HoanTien(uint indexed chienDichId, address indexed nhaHaoTam, uint soTien);

    modifier chiNguoiSangTaoChienDich(uint _chienDichId) {
        require(chienDich[_chienDichId].nguoiSangTao == msg.sender, "Chi nguoi sang tao moi co quyen.");
        _;
    }

    function taoChienDich(uint _mucTieu, uint _thoiGianTrongNgay) external {
        require(_mucTieu > 0, "Muc tieu phai lon hon 0.");
        require(_thoiGianTrongNgay > 0 && _thoiGianTrongNgay <= 366, "Thoi gian phai trong khoang tu 1 den 366 ngay.");

        soChienDich++;
        uint thoiGianBatDau = block.timestamp;
        uint thoiGianKetThuc = thoiGianBatDau + (_thoiGianTrongNgay * 1 days);

        chienDich[soChienDich] = ChienDich({
            nguoiSangTao: msg.sender,
            mucTieu: _mucTieu,
            soTienDong: 0,
            thoiGianBatDau: thoiGianBatDau,
            thoiGianKetThuc: thoiGianKetThuc,
            daYeuCau: false
        });

        emit ChienDichDuocTao(soChienDich, msg.sender, _mucTieu, thoiGianBatDau, thoiGianKetThuc);
    }

    function dongGopTien(uint _chienDichId) external payable {
        require(msg.value > 0, "So tien dong gop phai lon hon 0.");
        require(_chienDichId > 0 && _chienDichId <= soChienDich, "Chien dich khong ton tai.");

        ChienDich storage chienDichInstance = chienDich[_chienDichId];
        require(block.timestamp >= chienDichInstance.thoiGianBatDau, "Chien dich chua bat dau.");
        require(block.timestamp <= chienDichInstance.thoiGianKetThuc, "Chien dich da ket thuc.");

        chienDichInstance.soTienDong += msg.value;
        dongGop[_chienDichId][msg.sender] += msg.value;

        emit DongGopNhanDuoc(_chienDichId, msg.sender, msg.value);
    }

    function hoanTatChienDich(uint _chienDichId) external chiNguoiSangTaoChienDich(_chienDichId) {
        ChienDich storage chienDichInstance = chienDich[_chienDichId];
        require(block.timestamp > chienDichInstance.thoiGianKetThuc, "Chien dich chua ket thuc.");
        require(!chienDichInstance.daYeuCau, "Chien dich da duoc yeu cau hoan tat.");

        chienDichInstance.daYeuCau = true;

        if (chienDichInstance.soTienDong >= chienDichInstance.mucTieu) {
            uint soTien = chienDichInstance.soTienDong;
            chienDichInstance.soTienDong = 0;
            (bool thanhCong, ) = payable(chienDichInstance.nguoiSangTao).call{value: soTien}("");
            require(thanhCong, "Chuyen tien that bai.");
            emit ChienDichHoanTat(_chienDichId, true, soTien);
        } else {
            emit ChienDichHoanTat(_chienDichId, false, 0);
        }
    }

    function hoanTien(uint _chienDichId) external {
        ChienDich storage chienDichInstance = chienDich[_chienDichId];
        require(block.timestamp > chienDichInstance.thoiGianKetThuc, "Chien dich chua ket thuc.");
        require(chienDichInstance.soTienDong < chienDichInstance.mucTieu, "Chien dich da dat duoc muc tieu.");

        uint soTien = dongGop[_chienDichId][msg.sender];
        require(soTien > 0, "Ban khong co so du de hoan tien.");

        dongGop[_chienDichId][msg.sender] = 0;
        (bool thanhCong, ) = payable(msg.sender).call{value: soTien}("");
        require(thanhCong, "Hoan tien that bai.");

        emit HoanTien(_chienDichId, msg.sender, soTien);
    }

    function chiTietChienDich(uint _chienDichId) external view returns (
        address nguoiSangTao,
        uint mucTieu,
        uint soTienDong,
        uint thoiGianBatDau,
        uint thoiGianKetThuc,
        bool daYeuCau
    ) {
        ChienDich storage chienDichInstance = chienDich[_chienDichId];
        return (
            chienDichInstance.nguoiSangTao,
            chienDichInstance.mucTieu,
            chienDichInstance.soTienDong,
            chienDichInstance.thoiGianBatDau,
            chienDichInstance.thoiGianKetThuc,
            chienDichInstance.daYeuCau
        );
    }
}