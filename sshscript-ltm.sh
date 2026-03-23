#!/bin/bash
# ═══════════════════════════════════════════════════════
#   SSHFREE LTM — Gestor de Servicios VPN/SSH
#   by DealerServices235 • @DealerServices235
#   Ubuntu 22/24/25
# ═══════════════════════════════════════════════════════

SCRIPT_VERSION="2.5"
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;96m'
W='\033[1;97m'
B='\033[0;34m'
P='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'
NEON='\033[1;96m'
DIM='\033[2;37m'
LINE='◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆'
LINE2='◇─────────────────────────────────────────────◇'
DIR_SCRIPTS="/etc/sshfreeltm"
DIR_SERVICES="/etc/systemd/system"
mkdir -p $DIR_SCRIPTS
if [ -f /etc/sshfreeltm/.licensed ]; then
    SAVED_KEY=$(cat /etc/sshfreeltm/.licensed)

    API_URL="https://dealerbotgenkeys.mcmilton235.workers.dev/validate"
    CHECK=$(curl -s -X POST $API_URL \
    -H "Content-Type: application/json" \
    -d "{\"key\":\"$SAVED_KEY\"}")

    VALID=$(echo $CHECK | python3 -c "import sys,json; print(json.load(sys.stdin).get('valid', False))")

    if [[ "$VALID" != "True" && "$VALID" != "true" ]]; then
        echo "Licencia invalida o expirada"
        rm -f /etc/sshfreeltm/.licensed
        exit 1
    fi
fi
# ══════════════════════════════════════════
# VERIFICACION DE LICENCIA
# ══════════════════════════════════════════
if [ ! -f /etc/sshfreeltm/.licensed ]; then
    clear
    echo -e "\033[1;96m"
    figlet -f small "LTM VPN TOOLS" 2>/dev/null || echo "LTM VPN TOOLS"
    echo -e "\033[0m"
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    echo -e "  \033[1;97m⚡ XXXXXXXXXX v2.5 by @DealerServices235\033[0m"
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    echo ""
    echo -e "  \033[1;33m🔐 Se requiere una KEY de licencia para instalar\033[0m"
    echo -e "  \033[2;37m   Obtén tu KEY con @DealerServices235\033[0m"
    echo ""
    echo -e "\033[1;96m◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆\033[0m"
    read -p "  🗝️  Ingresa tu KEY: " INPUT_KEY
    echo ""
    command -v curl > /dev/null 2>&1 || apt install -y curl > /dev/null 2>&1
    echo -e "  \033[0;36m⏳  Verificando key...\033[0m"

    VPS_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    VPS_OS=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Ubuntu")
    API_URL="https://dealerbotgenkeys.mcmilton235.workers.dev/validate"

API_URL="https://dealerbotgenkeys.mcmilton235.workers.dev/validate"

RESPONSE=$(curl -s --max-time 10 "$API_URL?key=$INPUT_KEY")

# DEBUG (puedes borrar luego)
echo "Respuesta API: $RESPONSE"

VALID=$(echo "$RESPONSE" | grep -o '"valid":true')

if [[ "$VALID" == '"valid":true' ]]; then
    mkdir -p /etc/sshfreeltm
    echo "$INPUT_KEY" > /etc/sshfreeltm/.licensed
    echo -e "  \033[0;32m✅ Key valida — Disfruta el SCRIPT DEALER\033[0m"
    sleep 2
else
    if echo "$RESPONSE" | grep -q '"expired"'; then
        MSG="⏰ Key expirada"
    elif echo "$RESPONSE" | grep -q '"used"'; then
        MSG="⚠️ Key ya usada"
    elif echo "$RESPONSE" | grep -q '"not_found"'; then
        MSG="❌ Key no existe"
    else
        MSG="❌ Error desconocido (revisa conexión o API)"
    fi

    echo -e "  \033[0;31m$MSG\033[0m"
    echo -e "  \033[2;37m   Obtén tu KEY con @DealerServices235\033[0m"
    sleep 3
    exit 1
fi



# Deshabilitar mensajes de bienvenida de Ubuntu
touch ~/.hushlogin 2>/dev/null
chmod -x /etc/update-motd.d/* 2>/dev/null
> /etc/motd 2>/dev/null

# Dar permisos a certificados letsencrypt
if [ -d /etc/letsencrypt ]; then
    chmod 755 /etc/letsencrypt/live/ /etc/letsencrypt/archive/ 2>/dev/null
    find /etc/letsencrypt -name "*.pem" -exec chmod 644 {} \; 2>/dev/null
fi

# Migrar config V2Ray si solo tiene 8080
if [ -f /usr/local/etc/v2ray/config.json ] && [ -f /etc/sshfreeltm/v2ray_domain ]; then
    python3 - << MIGEOF
import json, os
domain = open('/etc/sshfreeltm/v2ray_domain').read().strip()
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
ports = [ib['port'] for ib in config['inbounds']]
if 443 not in ports and domain:
    config['inbounds'].append({
        "port": 443,
        "protocol": "vmess",
        "settings": {"clients": []},
        "streamSettings": {
            "network": "ws",
            "security": "tls",
            "tlsSettings": {"certificates": [{"certificateFile": f"/etc/letsencrypt/live/{domain}/fullchain.pem","keyFile": f"/etc/letsencrypt/live/{domain}/privkey.pem"}]},
            "wsSettings": {"path": "/v2ray"}
        }
    })
    with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
    import subprocess
    subprocess.run(['systemctl','stop','nginx'], capture_output=True)
    subprocess.run(['systemctl','restart','v2ray'], capture_output=True)
    print("V2Ray actualizado con inbound 443 TLS")
MIGEOF
fi
# Preguntar nombre ASCII al instalar por primera vez
if [ ! -f /etc/sshfreeltm/server_name ]; then
    mkdir -p /etc/sshfreeltm
    apt install -y figlet > /dev/null 2>&1
    echo ""
    echo -e "\033[1;33mEscribe el nombre del servidor:\033[0m"
    read -p "Nombre: " INSTALL_NAME
    INSTALL_NAME=${INSTALL_NAME:-"Dealer"}
    echo "$INSTALL_NAME" > /etc/sshfreeltm/server_name
    echo "$(date +%d-%m-%Y)" > /etc/sshfreeltm/install_date
fi

# Preguntar nombre ASCII al instalar por primera vez
if [ ! -f /etc/sshfreeltm/server_name ]; then
    mkdir -p /etc/sshfreeltm
    apt install -y figlet > /dev/null 2>&1
    echo ""
    echo -e "\033[1;33mEscribe el nombre del servidor:\033[0m"
    read -p "Nombre: " INSTALL_NAME
    INSTALL_NAME=${INSTALL_NAME:-"Dealer"}
    echo "$INSTALL_NAME" > /etc/sshfreeltm/server_name
    echo "$(date +%d-%m-%Y)" > /etc/sshfreeltm/install_date
fi

# Instalar MOTD automáticamente
cat > /etc/profile.d/sshfree-motd.sh << 'MOTDSCRIPT'
#!/bin/bash
PURPLE='\033[0;35m' CYAN='\033[0;36m' GREEN='\033[0;32m'
YELLOW='\033[1;33m' WHITE='\033[1;37m' NC='\033[0m'
INSTALL_DATE=$(cat /etc/sshfreeltm/install_date 2>/dev/null || echo "N/A")
SRV_NAME=$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
CURRENT_DATE=$(date +%d-%m-%Y)
CURRENT_TIME=$(date +%H:%M:%S)
UPTIME=$(uptime -p | sed 's/up //')
RAM_FREE=$(free -h | awk '/^Mem:/{print $4}')
echo -e "${PURPLE}"
figlet -f small "$SRV_NAME" 2>/dev/null || echo "  $SRV_NAME"
echo -e "${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${YELLOW}SERVIDOR INSTALADO EL${NC}   : ${WHITE}$INSTALL_DATE${NC}"
echo -e "  ${YELLOW}FECHA/HORA ACTUAL${NC}        : ${WHITE}$CURRENT_DATE - $CURRENT_TIME${NC}"
echo -e "  ${YELLOW}NOMBRE DEL SERVIDOR${NC}      : ${WHITE}$(hostname)${NC}"
echo -e "  ${YELLOW}TIEMPO EN LINEA${NC}          : ${WHITE}$UPTIME${NC}"
echo -e "  ${YELLOW}VERSION INSTALADA${NC}        : ${WHITE}V1.0.0${NC}"
echo -e "  ${YELLOW}MEMORIA RAM LIBRE${NC}        : ${WHITE}$RAM_FREE${NC}"
echo -e "  ${YELLOW}CREADOR DEL SCRIPT${NC}       : ${PURPLE}@DealerServices235 ❴LTM❵${NC}"
echo -e "  ${GREEN}BIENVENIDO DE NUEVO!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Teclee ${YELLOW}menu${NC} para ver el MENU LTM"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
MOTDSCRIPT
chmod +x /etc/profile.d/sshfree-motd.sh
[ -f /etc/motd ] && > /etc/motd

banner() {
    clear
    SRV_NAME=$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
    echo -e "${NEON}"
    figlet -f small "$SRV_NAME" 2>/dev/null || echo "  $SRV_NAME"
    echo -e "${NC}"
    echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
    echo -e "  ${W}⚡ Gestor VPN/SSH${NC} ${DIM}by${NC} ${NEON}@DealerServices235${NC}  ${Y}❖ v${SCRIPT_VERSION}${NC}"
    echo -e "${NEON}◆━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◆${NC}"
    echo ""
}

sep() { echo -e "${NEON}${LINE}${NC}"; }
sep2() { echo -e "${DIM}${LINE2}${NC}"; }

status_service() {
    systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${NEON}◆ ON ${NC}" || echo -e "${R}◇ OFF${NC}"
}

status_port() {
    ss -${2:-t}lnp 2>/dev/null | grep -q ":${1} " && echo -e "${NEON}◆ ON ${NC}" || echo -e "${R}◇ OFF${NC}"
}

# ══════════════════════════════════════════
#   WEBSOCKET PYTHON
# ══════════════════════════════════════════

instalar_ws() {
    banner; sep
    echo -e "  ${Y}Configurar WebSocket Python${NC}"; sep; echo ""
    read -p "  Puerto WebSocket (ej: 80): " WS_PORT; WS_PORT=${WS_PORT:-80}
    read -p "  Puerto local SSH (ej: 22): " SSH_PORT; SSH_PORT=${SSH_PORT:-22}
    echo ""; sep
    echo -e "  ${W}RESPONSE (101 para WebSocket, 200 default):${NC}"
    read -p "  RESPONSE: " STATUS_RESP; STATUS_RESP=${STATUS_RESP:-200}
    echo ""; read -p "  Mini-Banner: " BANNER_MSG
    BANNER_MSG=${BANNER_MSG:-"SSHFREE LTM by DealerServices235"}
    echo ""; sep
    echo -e "  ${W}Encabezado personalizado (ENTER para default):${NC}"
    read -p "  Cabecera: " CUSTOM_HEADER
    [ -z "$CUSTOM_HEADER" ] && CUSTOM_HEADER="\r\nContent-length: 0\r\n\r\nHTTP/1.1 200 Connection Established\r\n\r\n"

    cat > $DIR_SCRIPTS/proxy_ws_${WS_PORT}.py << PYEOF
#!/usr/bin/env python3
import socket, threading, select, sys, time
LISTENING_ADDR = '0.0.0.0'
LISTENING_PORT = ${WS_PORT}
BUFLEN = 4096 * 4
TIMEOUT = 60
DEFAULT_HOST = b'127.0.0.1:${SSH_PORT}'
MSG = '${BANNER_MSG}'.encode('utf-8')
STATUS_RESP = b'${STATUS_RESP}'
FTAG = b'${CUSTOM_HEADER}'
RESPONSE = b'HTTP/1.1 ' + STATUS_RESP + b' ' + MSG + b' ' + FTAG

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False; self.host = host; self.port = port
        self.threads = []; self.threadsLock = threading.Lock(); self.logLock = threading.Lock()
    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2); self.soc.bind((self.host, int(self.port))); self.soc.listen(0)
        self.running = True
        try:
            while self.running:
                try: c, addr = self.soc.accept(); c.setblocking(1)
                except socket.timeout: continue
                conn = ConnectionHandler(c, self, addr); conn.start(); self.addConn(conn)
        finally: self.running = False; self.soc.close()
    def printLog(self, log):
        self.logLock.acquire(); print(log); self.logLock.release()
    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running: self.threads.append(conn)
        finally: self.threadsLock.release()
    def removeConn(self, conn):
        try: self.threadsLock.acquire(); self.threads.remove(conn)
        finally: self.threadsLock.release()
    def close(self):
        try:
            self.running = False; self.threadsLock.acquire()
            for c in list(self.threads): c.close()
        finally: self.threadsLock.release()

class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False; self.targetClosed = True
        self.client = socClient; self.client_buffer = b''
        self.server = server; self.log = 'Connection: ' + str(addr)
    def close(self):
        try:
            if not self.clientClosed: self.client.shutdown(socket.SHUT_RDWR); self.client.close()
        except: pass
        finally: self.clientClosed = True
        try:
            if not self.targetClosed: self.target.shutdown(socket.SHUT_RDWR); self.target.close()
        except: pass
        finally: self.targetClosed = True
    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)
            hostPort = self.findHeader(self.client_buffer, b'X-Real-Host')
            if hostPort == b'': hostPort = DEFAULT_HOST
            split = self.findHeader(self.client_buffer, b'X-Split')
            if split != b'': self.client.recv(BUFLEN)
            if hostPort != b'':
                if hostPort.startswith(b'127.0.0.1') or hostPort.startswith(b'localhost'):
                    self.method_CONNECT(hostPort)
                else: self.client.send(b'HTTP/1.1 403 Forbidden!\r\n\r\n')
            else: self.client.send(b'HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + str(e); self.server.printLog(self.log)
        finally: self.close(); self.server.removeConn(self)
    def findHeader(self, head, header):
        aux = head.find(header + b': ')
        if aux == -1: return b''
        aux = head.find(b':', aux); head = head[aux + 2:]
        aux = head.find(b'\r\n')
        if aux == -1: return b''
        return head[:aux]
    def connect_target(self, host):
        i = host.find(b':')
        if i != -1: port = int(host[i + 1:]); host = host[:i]
        else: port = ${SSH_PORT}
        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]
        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False; self.target.connect(address)
    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path.decode()
        self.connect_target(path); self.client.sendall(RESPONSE)
        self.client_buffer = b''; self.server.printLog(self.log); self.doCONNECT()
    def doCONNECT(self):
        socs = [self.client, self.target]; count = 0; error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err: error = True
            if recv:
                for in_ in recv:
                    try:
                        data = in_.recv(BUFLEN)
                        if data:
                            if in_ is self.target: self.client.send(data)
                            else:
                                while data: byte = self.target.send(data); data = data[byte:]
                            count = 0
                        else: break
                    except: error = True; break
            if count == TIMEOUT: error = True
            if error: break

if __name__ == '__main__':
    print(f"\033[0;34m{'*'*8} \033[1;32mPROXY PYTHON3 WEBSOCKET \033[0;34m{'*'*8}\n")
    print(f"\033[1;33mPUERTO:\033[1;32m {LISTENING_PORT}\n")
    server = Server(LISTENING_ADDR, LISTENING_PORT); server.start()
    while True:
        try: time.sleep(2)
        except KeyboardInterrupt: server.close(); break
PYEOF

    chmod +x $DIR_SCRIPTS/proxy_ws_${WS_PORT}.py
    cat > $DIR_SERVICES/ws-proxy-${WS_PORT}.service << EOF
[Unit]
Description=WebSocket Proxy Python Puerto ${WS_PORT}
After=network.target
[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 ${DIR_SCRIPTS}/proxy_ws_${WS_PORT}.py ${WS_PORT}
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable ws-proxy-${WS_PORT}; systemctl start ws-proxy-${WS_PORT}
    sleep 2
    systemctl is-active --quiet ws-proxy-${WS_PORT} && echo -e "\n  ${G}OK WebSocket activo en puerto ${WS_PORT}${NC}" || echo -e "\n  ${R}Error${NC}"
    read -p "  ENTER..."
}

menu_ws() {
    while true; do
        banner; sep; echo -e "  ${Y}  WEBSOCKET PYTHON${NC}"; sep; echo ""
        for f in $(ls $DIR_SERVICES/ws-proxy-*.service 2>/dev/null); do
            name=$(basename $f .service); port=$(echo $name | grep -o '[0-9]*$')
            echo -e "  Puerto ${Y}${port}${NC} $(status_service $name)"
        done
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar/Configurar"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Eliminar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) instalar_ws ;;
            2) read -p "  Puerto: " P; systemctl start ws-proxy-${P} && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) read -p "  Puerto: " P; systemctl stop ws-proxy-${P} && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) read -p "  Puerto: " P; systemctl restart ws-proxy-${P} && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Puerto (0=todos): " DEL_PORT
                if [ "$DEL_PORT" = "0" ]; then
                    for f in $DIR_SERVICES/ws-proxy-*.service; do
                        name=$(basename $f .service); systemctl stop $name; systemctl disable $name; rm -f $f
                    done; rm -f $DIR_SCRIPTS/proxy_ws_*.py
                else
                    systemctl stop ws-proxy-${DEL_PORT}; systemctl disable ws-proxy-${DEL_PORT}
                    rm -f $DIR_SERVICES/ws-proxy-${DEL_PORT}.service $DIR_SCRIPTS/proxy_ws_${DEL_PORT}.py
                fi
                systemctl daemon-reload; echo -e "  ${G}Eliminado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   BADVPN
# ══════════════════════════════════════════

menu_badvpn() {
    while true; do
        banner; sep; echo -e "  ${Y}  BADVPN UDP GATEWAY${NC}"; sep; echo ""
        echo -e "  BadVPN 7200 $(status_service badvpn-7200)"
        echo -e "  BadVPN 7300 $(status_service badvpn-7300)"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar BadVPN"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Puerto personalizado"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                if [ ! -f /usr/local/bin/badvpn-udpgw ]; then
                    echo -e "\n  ${C}Compilando BadVPN...${NC}"
                    apt install -y cmake make gcc g++ git > /dev/null 2>&1
                    cd /tmp && git clone https://github.com/ambrop72/badvpn.git > /dev/null 2>&1
                    cd badvpn && mkdir -p build && cd build
                    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 > /dev/null 2>&1
                    make install > /dev/null 2>&1
                fi
                for PORT in 7200 7300; do
                    cat > $DIR_SERVICES/badvpn-${PORT}.service << EOF
[Unit]
Description=BadVPN UDP Gateway ${PORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${PORT} --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
                    systemctl daemon-reload; systemctl enable badvpn-${PORT}; systemctl start badvpn-${PORT}
                done
                echo -e "  ${G}OK BadVPN 7200 y 7300${NC}"; sleep 2 ;;
            2) systemctl start badvpn-7200 badvpn-7300 && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop badvpn-7200 badvpn-7300 && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart badvpn-7200 badvpn-7300 && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Puerto: " BPORT
                cat > $DIR_SERVICES/badvpn-${BPORT}.service << EOF
[Unit]
Description=BadVPN UDP Gateway ${BPORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${BPORT} --max-clients 500
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload; systemctl enable badvpn-${BPORT}; systemctl start badvpn-${BPORT}
                echo -e "  ${G}OK BadVPN puerto ${BPORT}${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   UDP CUSTOM
# ══════════════════════════════════════════

menu_udp() {
    while true; do
        banner; sep; echo -e "  ${Y}  UDP CUSTOM${NC}"; sep; echo ""
        ps aux | grep -i "udp-custom\|UDP-Custom" | grep -v grep | grep -q . && echo -e "  UDP Custom ${G}[ON]${NC}" || echo -e "  UDP Custom ${R}[OFF]${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar UDP Custom"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Ver estado"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "\n  ${C}Instalando UDP Custom (Epro Dev Team)...${NC}"
                read -p "  Puerto a excluir (default 5300): " UDP_EXCL; UDP_EXCL=${UDP_EXCL:-5300}
                wget -O /tmp/install-udp "https://drive.usercontent.google.com/download?id=1S3IE25v_fyUfCLslnujFBSBMNunDHDk2&export=download&confirm=t"
                chmod +x /tmp/install-udp; bash /tmp/install-udp $UDP_EXCL
                echo -e "  ${G}OK UDP Custom instalado${NC}"; sleep 2 ;;
            2) systemctl start udp-custom 2>/dev/null || (/root/udp/udp-custom server -exclude 5300 &); echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop udp-custom 2>/dev/null; pkill -f udp-custom 2>/dev/null; echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) pkill -f udp-custom 2>/dev/null; sleep 1; systemctl start udp-custom 2>/dev/null || (/root/udp/udp-custom server -exclude 5300 &); echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5) ss -ulnp | grep udp; echo ""; read -p "  ENTER..." ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   SSL/TLS STUNNEL
# ══════════════════════════════════════════

menu_ssl() {
    while true; do
        banner; sep; echo -e "  ${Y}  SSL/TLS STUNNEL${NC}"; sep; echo ""
        echo -e "  Stunnel $(status_service stunnel4)"
        echo -e "  Puerto 443 $(status_port 443)"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar SSL/TLS Stunnel"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                apt install -y stunnel4 > /dev/null 2>&1
                read -p "  Puerto SSL (ej: 443): " SSL_PORT; SSL_PORT=${SSL_PORT:-443}
                read -p "  Puerto local SSH (ej: 22): " LOCAL_PORT; LOCAL_PORT=${LOCAL_PORT:-22}
                openssl req -new -x509 -days 3650 -nodes -out /etc/stunnel/stunnel.pem -keyout /etc/stunnel/stunnel.pem -subj "/C=US/ST=Miami/L=Miami/O=SSHFREE/CN=sshfree" 2>/dev/null
                cat > /etc/stunnel/stunnel.conf << EOF
pid = /var/run/stunnel4/stunnel.pid
cert = /etc/stunnel/stunnel.pem
socket = a:SO_REUSEADDR=1
[ssh]
accept = ${SSL_PORT}
connect = 127.0.0.1:${LOCAL_PORT}
EOF
                sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null
                systemctl enable stunnel4; systemctl start stunnel4
                echo -e "  ${G}OK SSL/TLS en puerto ${SSL_PORT}${NC}"; sleep 2 ;;
            2) systemctl start stunnel4 && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop stunnel4 && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart stunnel4 && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   V2RAY
# ══════════════════════════════════════════

menu_v2ray() {
    while true; do
        banner; sep; echo -e "  ${Y}  V2RAY VMESS${NC}"; sep; echo ""
        echo -e "  V2Ray $(status_service v2ray)"
        if [ -f /usr/local/etc/v2ray/config.json ]; then
            python3 -c "
import json
try:
    with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
    for ib in c.get('inbounds',[]):
        net=ib.get('streamSettings',{}).get('network','tcp')
        tls=ib.get('streamSettings',{}).get('security','none')
        print(f'  Puerto \033[1;33m{ib[chr(34)+chr(112)+chr(111)+chr(114)+chr(116)+chr(34)]}\033[0m | {ib[chr(34)+chr(112)+chr(114)+chr(111)+chr(116)+chr(111)+chr(99)+chr(111)+chr(108)+chr(34)]} | {net} | tls:{tls}')
except: pass
" 2>/dev/null
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar V2Ray + SSL"
        echo -e "  ${W}[2]${NC} Agregar inbound"
        echo -e "  ${W}[3]${NC} Iniciar"
        echo -e "  ${W}[4]${NC} Detener"
        echo -e "  ${W}[5]${NC} Reiniciar"
        echo -e "  ${W}[6]${NC} Crear usuario VMess"
        echo -e "  ${W}[7]${NC} Ver usuarios"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                read -p "  Dominio: " DOMAIN
                EMAIL="admin@${DOMAIN#*.}"
                echo -e "  ${C}Instalando V2Ray...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) > /dev/null 2>&1
                apt install -y nginx certbot python3-certbot-nginx > /dev/null 2>&1
                pkill -f "python3.*:80" 2>/dev/null
                systemctl stop nginx 2>/dev/null; sleep 2
                echo -e "  ${C}Obteniendo certificado SSL...${NC}"
                certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos -m $EMAIL
                # Dar permisos al certificado
                chmod 755 /etc/letsencrypt/live/ /etc/letsencrypt/archive/ 2>/dev/null
                chmod 644 /etc/letsencrypt/live/$DOMAIN/*.pem 2>/dev/null
                chmod 644 /etc/letsencrypt/archive/$DOMAIN/*.pem 2>/dev/null
                python3 - << CFGEOF
import json
config = {
    "log": {"loglevel": "warning"},
    "inbounds": [
        {
            "port": 8080,
            "protocol": "vmess",
            "settings": {"clients": []},
            "streamSettings": {"network": "ws", "wsSettings": {"path": "/v2ray"}}
        },
        {
            "port": 443,
            "protocol": "vmess",
            "settings": {"clients": []},
            "streamSettings": {
                "network": "ws",
                "security": "tls",
                "tlsSettings": {
                    "certificates": [{
                        "certificateFile": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem",
                        "keyFile": "/etc/letsencrypt/live/$DOMAIN/privkey.pem"
                    }]
                },
                "wsSettings": {"path": "/v2ray"}
            }
        }
    ],
    "outbounds": [{"protocol": "freedom"}]
}
with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
print("Config creado")
CFGEOF
                systemctl stop nginx 2>/dev/null
                systemctl enable v2ray; systemctl start v2ray
                mkdir -p /etc/sshfreeltm
                echo "$DOMAIN" > /etc/sshfreeltm/v2ray_domain
                echo -e "  ${G}OK V2Ray instalado${NC}"; sleep 2 ;;
            2)
                banner; sep
                echo -e "  ${Y}  AGREGAR INBOUND${NC}"; sep; echo ""
                read -p "  Puerto: " V2_PORT
                echo -e "  Protocolo: ${W}[1]${NC} vmess ${W}[2]${NC} vless ${W}[3]${NC} trojan"
                read -p "  Opcion: " V2_PROTO_OPT
                case $V2_PROTO_OPT in
                    1) V2_PROTO="vmess" ;;
                    2) V2_PROTO="vless" ;;
                    3) V2_PROTO="trojan" ;;
                    *) V2_PROTO="vmess" ;;
                esac
                echo -e "  Red: ${W}[1]${NC} ws ${W}[2]${NC} tcp ${W}[3]${NC} xhttp ${W}[4]${NC} grpc"
                read -p "  Opcion: " V2_NET_OPT
                case $V2_NET_OPT in
                    1) V2_NET="ws" ;;
                    2) V2_NET="tcp" ;;
                    3) V2_NET="xhttp" ;;
                    4) V2_NET="grpc" ;;
                    *) V2_NET="ws" ;;
                esac
                read -p "  Path (ej: /v2ray): " V2_PATH
                V2_PATH=${V2_PATH:-/v2ray}
                echo -e "  TLS: ${W}[1]${NC} Si ${W}[2]${NC} No"
                read -p "  Opcion: " V2_TLS_OPT
                [ "$V2_TLS_OPT" = "1" ] && V2_TLS="tls" || V2_TLS="none"
                python3 - << ADDEOF
import json, sys
port, proto, net, path, tls = int("$V2_PORT"), "$V2_PROTO", "$V2_NET", "$V2_PATH", "$V2_TLS"
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
ib = {"port": port, "protocol": proto, "settings": {"clients": []}, "streamSettings": {"network": net, "security": tls}}
if net == "ws": ib["streamSettings"]["wsSettings"] = {"path": path}
elif net == "xhttp": ib["streamSettings"]["xhttpSettings"] = {"path": path}
elif net == "grpc": ib["streamSettings"]["grpcSettings"] = {"serviceName": path.strip("/")}
config["inbounds"].append(ib)
with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
print(f"OK {proto} {net} puerto {port}")
ADDEOF
                systemctl restart v2ray
                echo -e "  ${G}OK Inbound agregado${NC}"; read -p "  ENTER..." ;;
            3) systemctl start v2ray && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            4) systemctl stop v2ray && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            5) systemctl restart v2ray && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            6)
                banner; sep
                echo -e "  ${Y}  CREAR USUARIO VMESS${NC}"; sep; echo ""
                python3 -c "
import json
with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
for i,ib in enumerate(c.get('inbounds',[])):
    net=ib.get('streamSettings',{}).get('network','tcp')
    tls=ib.get('streamSettings',{}).get('security','none')
    print(f'  [{i+1}] Puerto {ib[\"port\"]} | {ib[\"protocol\"]} | {net} | tls:{tls}')
" 2>/dev/null
                echo ""
                read -p "  Numero de inbound: " IB_NUM
                IB_IDX=$((IB_NUM - 1))
                read -p "  Nombre del perfil: " VNAME
                read -p "  Dias de validez (default 30): " V2_DAYS
                V2_DAYS=${V2_DAYS:-30}
                EXP_SHOW=$(date -d "+${V2_DAYS} days" +%d/%m/%Y)
                VDOMAIN=$(cat /etc/sshfreeltm/v2ray_domain 2>/dev/null || hostname -I | awk '{print $1}')
                python3 - << VMEOF
import json, uuid, base64, datetime
idx, name, days, domain = int("$IB_IDX"), "$VNAME", int("$V2_DAYS"), "$VDOMAIN"
with open('/usr/local/etc/v2ray/config.json') as f: config = json.load(f)
inbounds = config.get('inbounds', [])
if idx >= len(inbounds): print("Inbound no encontrado"); exit(1)
ib = inbounds[idx]
uid = str(uuid.uuid4())
exp = (datetime.datetime.now() + datetime.timedelta(days=days)).strftime("%Y-%m-%d")
exp_show = (datetime.datetime.now() + datetime.timedelta(days=days)).strftime("%d/%m/%Y")
if 'clients' not in ib['settings']: ib['settings']['clients'] = []
ib['settings']['clients'].append({"id": uid, "alterId": 0, "email": name, "expires": exp})
with open('/usr/local/etc/v2ray/config.json', 'w') as f: json.dump(config, f, indent=2)
net = ib.get('streamSettings', {}).get('network', 'tcp')
tls = ib.get('streamSettings', {}).get('security', 'none')
path = ib.get('streamSettings', {}).get('wsSettings', {}).get('path', '/v2ray') if net == 'ws' else ''
# Si el puerto es 8080 (interno nginx), usar 443 con TLS en el link
out_port = "443" if ib['port'] == 8080 else str(ib['port'])
out_tls = "tls" if ib['port'] == 8080 else (tls if tls != "none" else "")
vmess = {"v":"2","ps":name,"add":domain,"port":out_port,"id":uid,"aid":"0","net":net,"type":"none","host":domain,"path":path,"tls":out_tls}
link = "vmess://" + base64.b64encode(json.dumps(vmess).encode()).decode()
print("VMess: " + link)
print("Expira: " + exp_show + " (" + str(days) + " dias)")
print(f"[1;33mExpira:[0m {exp_show} ({days} dias)")
VMEOF
                systemctl restart v2ray; read -p "  ENTER..." ;;
            7)
                python3 -c "
import json
try:
    with open('/usr/local/etc/v2ray/config.json') as f: c=json.load(f)
    for ib in c['inbounds']:
        print(f'  Puerto {ib[\"port\"]}:')
        for u in ib['settings'].get('clients',[]):
            print(f'    - {u.get(\"email\",\"?\")} | expira: {u.get(\"expires\",\"sin expiracion\")}')
except Exception as e: print(f'Error: {e}')
"; read -p "  ENTER..." ;;
            0) break ;;
        esac
    done
}


# ══════════════════════════════════════════
#   ZIV VPN
# ══════════════════════════════════════════

menu_ziv() {
    while true; do
        banner; sep; echo -e "  ${Y}  ZIV VPN UDP${NC}"; sep; echo ""
        echo -e "  ZIV VPN $(status_service zivpn)"
        [ -f /etc/zivpn/config.json ] && PORT=$(cat /etc/zivpn/config.json | python3 -c "import json,sys; print(json.load(sys.stdin).get('listen',':5667').replace(':',''))" 2>/dev/null) && echo -e "  Puerto: ${Y}${PORT}${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar ZIV VPN V2 (Recomendado)"
        echo -e "  ${W}[2]${NC} Instalar ZIV VPN V1"
        echo -e "  ${W}[3]${NC} Iniciar"
        echo -e "  ${W}[4]${NC} Detener"
        echo -e "  ${W}[5]${NC} Reiniciar"
        echo -e "  ${W}[6]${NC} Ver configuracion"
        echo -e "  ${W}[7]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) bash <(curl -fsSL https://raw.githubusercontent.com/powermx/zivpn/main/ziv2.sh) ;;
            2) bash <(curl -fsSL https://raw.githubusercontent.com/powermx/zivpn/main/ziv1.sh) ;;
            3) systemctl start zivpn && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            4) systemctl stop zivpn && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            5) systemctl restart zivpn && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            6) cat /etc/zivpn/config.json 2>/dev/null; echo ""; read -p "  ENTER..." ;;
            7) bash <(curl -fsSL https://raw.githubusercontent.com/powermx/zivpn/main/uninstall.sh) 2>/dev/null; echo -e "  ${G}Desinstalado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   USUARIOS ZIV VPN
# ══════════════════════════════════════════

aplicar_passwords_ziv() {
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 - << PYEOF
import json, datetime
with open("/etc/zivpn/users.json") as f: users = json.load(f)
now = datetime.datetime.now()
active = [u["password"] for u in users if datetime.datetime.fromisoformat(u["expires"].split("+")[0].split(".")[0]) > now]
if not active: active = ["zi"]
with open("/etc/zivpn/config.json") as f: config = json.load(f)
# Mantener passwords existentes y agregar nuevas sin duplicar
existing = config["auth"]["config"]
merged = list(set(existing + active))
config["auth"]["config"] = merged
with open("/etc/zivpn/config.json", "w") as f: json.dump(config, f, indent=2)
PYEOF
    systemctl restart zivpn 2>/dev/null
}

crear_user_ziv() {
    banner; sep; echo -e "  ${Y}  CREAR USUARIO ZIV VPN${NC}"; sep; echo ""
    read -p "  Contraseña: " ZIV_PASS
    [ -z "$ZIV_PASS" ] && echo -e "  ${R}Contraseña requerida${NC}" && sleep 1 && return
    read -p "  Dias de validez (default 30): " ZIV_DAYS; ZIV_DAYS=${ZIV_DAYS:-30}
    EXP_DATE=$(date -d "+${ZIV_DAYS} days" -Iseconds)
    EXP_SHOW=$(date -d "+${ZIV_DAYS} days" +"%d/%m/%Y")
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 - << PYEOF
import json, datetime
with open("/etc/zivpn/users.json") as f: users = json.load(f)
users.append({"password": "$ZIV_PASS", "expires": "$EXP_DATE", "created": datetime.datetime.now().isoformat()})
with open("/etc/zivpn/users.json", "w") as f: json.dump(users, f, indent=2)
PYEOF
    aplicar_passwords_ziv
    echo ""; sep
    echo -e "  ${Y}  CREDENCIALES ZIV VPN${NC}"; sep
    echo -e "  ${W}IP:${NC}       $SERVER_IP"
    echo -e "  ${W}Puerto:${NC}   5667"
    echo -e "  ${W}Pass:${NC}     $ZIV_PASS"
    echo -e "  ${W}Expira:${NC}   $EXP_SHOW ($ZIV_DAYS dias)"
    echo ""; sep; read -p "  ENTER..."
}

listar_users_ziv() {
    banner; sep; echo -e "  ${Y}  USUARIOS ZIV VPN${NC}"; sep; echo ""
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 - << PYEOF
import json, datetime
with open("/etc/zivpn/users.json") as f: users = json.load(f)
if not users: print("  Sin usuarios")
else:
    now = datetime.datetime.now()
    for u in users:
        exp = datetime.datetime.fromisoformat(u["expires"])
        estado = "\033[0;32m[ACTIVO]\033[0m" if exp > now else "\033[0;31m[EXPIRADO]\033[0m"
        print(f"  Pass: {u['password']:<20} Expira: {exp.strftime('%d/%m/%Y')}  {estado}")
PYEOF
    echo ""; read -p "  ENTER..."
}

eliminar_user_ziv() {
    banner; sep; echo -e "  ${R}  ELIMINAR USUARIO ZIV VPN${NC}"; sep; echo ""
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 -c "
import json
with open('/etc/zivpn/users.json') as f: u=json.load(f)
[print(f'  - {x[\"password\"]}') for x in u] if u else print('  Sin usuarios')
"
    echo ""; read -p "  Contraseña a eliminar: " DEL_PASS
    python3 - << PYEOF
import json
with open("/etc/zivpn/users.json") as f: users = json.load(f)
users = [u for u in users if u["password"] != "$DEL_PASS"]
with open("/etc/zivpn/users.json", "w") as f: json.dump(users, f, indent=2)
PYEOF
    aplicar_passwords_ziv; echo -e "  ${G}Eliminado${NC}"; sleep 1
}

limpiar_expirados_ziv() {
    [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
    python3 - << PYEOF
import json, datetime
with open("/etc/zivpn/users.json") as f: users = json.load(f)
now = datetime.datetime.now()
activos = [u for u in users if datetime.datetime.fromisoformat(u["expires"]) > now]
exp = len(users) - len(activos)
with open("/etc/zivpn/users.json", "w") as f: json.dump(activos, f, indent=2)
print(f"  {exp} expirados eliminados" if exp > 0 else "  Sin expirados")
PYEOF
}

menu_users_ziv() {
    while true; do
        banner; sep; echo -e "  ${Y}  USUARIOS ZIV VPN${NC}"; sep; echo ""
        [ ! -f /etc/zivpn/users.json ] && echo "[]" > /etc/zivpn/users.json
        TOTAL=$(python3 -c "import json; print(len(json.load(open('/etc/zivpn/users.json'))))" 2>/dev/null || echo 0)
        echo -e "  Total usuarios: ${G}${TOTAL}${NC}"
        echo -e "  ZIV VPN: $(status_service zivpn)"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Crear usuario"
        echo -e "  ${W}[2]${NC} Listar usuarios"
        echo -e "  ${W}[3]${NC} Eliminar usuario"
        echo -e "  ${W}[4]${NC} Limpiar expirados"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) crear_user_ziv ;;
            2) listar_users_ziv ;;
            3) eliminar_user_ziv ;;
            4) limpiar_expirados_ziv; aplicar_passwords_ziv; echo -e "  ${G}Limpiado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

# ══════════════════════════════════════════
#   USUARIOS SSH
# ══════════════════════════════════════════

listar_usuarios() {
    banner; sep; echo -e "  ${Y}  USUARIOS SSH ACTIVOS${NC}"; sep; echo ""
    printf "  %-20s %-15s %s\n" "Usuario" "Expira" "Estado"
    sep
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do
        EXP=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        if [ "$EXP" = "never" ] || [ -z "$EXP" ]; then
            printf "  ${Y}%-20s${NC} %-15s\n" "$user" "Sin expirar"
        else
            EXP_TS=$(date -d "$EXP" +%s 2>/dev/null || echo 0)
            NOW_TS=$(date +%s)
            if [ $EXP_TS -lt $NOW_TS ]; then
                printf "  ${R}%-20s${NC} %-15s ${R}[EXPIRADO]${NC}\n" "$user" "$EXP"
            else
                printf "  ${G}%-20s${NC} %-15s\n" "$user" "$EXP"
            fi
        fi
    done
    echo ""; sep; read -p "  ENTER..."
}

crear_usuario() {
    banner; sep; echo -e "  ${Y}  CREAR USUARIO SSH${NC}"; sep; echo ""
    read -p "  Nombre de usuario: " USR_NAME
    [ -z "$USR_NAME" ] && echo -e "  ${R}Nombre requerido${NC}" && sleep 1 && return
    read -p "  Contraseña (ENTER para generar): " USR_PASS
    [ -z "$USR_PASS" ] && USR_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1) && echo -e "  ${G}Generada: ${W}${USR_PASS}${NC}"
    read -p "  Dias de validez (default 30): " USR_DAYS; USR_DAYS=${USR_DAYS:-30}
    EXP_DATE=$(date -d "+${USR_DAYS} days" +%Y-%m-%d)
    EXP_SHOW=$(date -d "+${USR_DAYS} days" +%d/%m/%Y)
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    echo ""; echo -e "  ${C}Creando usuario...${NC}"
    if id "$USR_NAME" &>/dev/null; then
        usermod -e $EXP_DATE $USR_NAME; echo "$USR_NAME:$USR_PASS" | chpasswd
    else
        useradd -M -s /bin/false -e $EXP_DATE $USR_NAME
        echo "$USR_NAME:$USR_PASS" | chpasswd
        chage -E $EXP_DATE -M 99999 $USR_NAME; usermod -f 0 $USR_NAME
    fi
    echo ""; sep; echo -e "  ${Y}  CREDENCIALES${NC}"; sep
    echo -e "  ${W}Usuario:${NC}  $USR_NAME"
    echo -e "  ${W}Password:${NC} $USR_PASS"
    echo -e "  ${W}IP:${NC}       $SERVER_IP"
    echo -e "  ${W}Expira:${NC}   $EXP_SHOW ($USR_DAYS dias)"
    echo ""; sep; echo -e "  ${Y}  CONEXIONES DISPONIBLES${NC}"; sep; echo ""
    echo -e "  ${C}SSH Directo:${NC}"; echo -e "  ${W}$SERVER_IP:22@$USR_NAME:$USR_PASS${NC}"; echo ""
    ss -tlnp | grep -q ":80 " && echo -e "  ${C}WS Puerto 80:${NC}" && echo -e "  ${W}$SERVER_IP:80@$USR_NAME:$USR_PASS${NC}" && echo ""
    systemctl is-active --quiet stunnel4 2>/dev/null && echo -e "  ${C}SSL/TLS 443:${NC}" && echo -e "  ${W}$SERVER_IP:443@$USR_NAME:$USR_PASS${NC}" && echo ""
    ps aux | grep -i "udp-custom\|UDP-Custom" | grep -v grep | grep -q . && echo -e "  ${C}UDP Custom:${NC}" && echo -e "  ${W}$SERVER_IP:1-65535@$USR_NAME:$USR_PASS${NC}" && echo ""
    (systemctl is-active --quiet badvpn-7200 2>/dev/null || systemctl is-active --quiet badvpn-7300 2>/dev/null) && echo -e "  ${C}BadVPN:${NC}" && systemctl is-active --quiet badvpn-7200 && echo -e "  ${W}Puerto 7200 activo${NC}" && systemctl is-active --quiet badvpn-7300 && echo -e "  ${W}Puerto 7300 activo${NC}" && echo ""
    sep; read -p "  ENTER..."
}

eliminar_usuario() {
    banner; sep; echo -e "  ${R}  ELIMINAR USUARIO SSH${NC}"; sep; echo ""
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do printf "  ${Y}%-20s${NC}\n" "$user"; done
    echo ""; read -p "  Usuario a eliminar: " DEL_USR
    if id "$DEL_USR" &>/dev/null; then
        pkill -u "$DEL_USR" 2>/dev/null; userdel -f "$DEL_USR" 2>/dev/null
        echo -e "  ${G}OK Usuario $DEL_USR eliminado${NC}"
    else echo -e "  ${R}Usuario no encontrado${NC}"; fi
    sleep 2
}

renovar_usuario() {
    banner; sep; echo -e "  ${Y}  RENOVAR USUARIO SSH${NC}"; sep; echo ""
    awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | while read user; do
        EXP=$(chage -l $user 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        printf "  ${Y}%-20s${NC} %s\n" "$user" "$EXP"
    done
    echo ""; read -p "  Usuario a renovar: " REN_USR
    id "$REN_USR" &>/dev/null || { echo -e "  ${R}No encontrado${NC}"; sleep 1; return; }
    read -p "  Dias a agregar (default 30): " REN_DAYS; REN_DAYS=${REN_DAYS:-30}
    EXP_DATE=$(date -d "+${REN_DAYS} days" +%Y-%m-%d)
    EXP_SHOW=$(date -d "+${REN_DAYS} days" +%d/%m/%Y)
    usermod -e $EXP_DATE $REN_USR; chage -E $EXP_DATE $REN_USR
    echo -e "  ${G}OK $REN_USR renovado hasta $EXP_SHOW${NC}"; sleep 2
}

menu_usuarios() {
    while true; do
        banner; sep; echo -e "  ${Y}  GESTIÓN DE USUARIOS SSH${NC}"; sep; echo ""
        TOTAL=$(awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd | wc -l)
        echo -e "  Total usuarios: ${G}${TOTAL}${NC}"; echo ""; sep
        echo -e "  ${W}[1]${NC} Crear usuario"
        echo -e "  ${W}[2]${NC} Listar usuarios"
        echo -e "  ${W}[3]${NC} Eliminar usuario"
        echo -e "  ${W}[4]${NC} Renovar usuario"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1) crear_usuario ;;
            2) listar_usuarios ;;
            3) eliminar_usuario ;;
            4) renovar_usuario ;;
            0) break ;;
        esac
    done
}


instalar_motd() {
    banner; sep
    echo -e "  ${Y}  CONFIGURAR MOTD DEL SERVIDOR${NC}"; sep; echo ""
    read -p "  Nombre del servidor: " SRV_NAME
    [ -z "$SRV_NAME" ] && SRV_NAME="SSHFREE LTM"
    
    # Instalar figlet para ASCII art
    apt install -y figlet > /dev/null 2>&1
    
    INSTALL_DATE=$(date +%d-%m-%Y)
    VERSION="V1.0.0"
    
    # Generar ASCII del nombre
    ASCII_NAME=$(figlet -f slant "$SRV_NAME" 2>/dev/null || echo "$SRV_NAME")
    
    # Guardar fecha de instalación
    echo "$INSTALL_DATE" > /etc/sshfreeltm/install_date
    echo "$SRV_NAME" > /etc/sshfreeltm/server_name
    
    # Crear script MOTD dinámico
    cat > /etc/profile.d/sshfree-motd.sh << MOTDEOF
#!/bin/bash
PURPLE='[0;35m'
CYAN='[0;36m'
GREEN='[0;32m'
YELLOW='[1;33m'
WHITE='[1;37m'
NC='[0m'

INSTALL_DATE=\$(cat /etc/sshfreeltm/install_date 2>/dev/null || echo "N/A")
SRV_NAME=\$(cat /etc/sshfreeltm/server_name 2>/dev/null || echo "SSHFREE LTM")
CURRENT_DATE=\$(date +%d-%m-%Y)
CURRENT_TIME=\$(date +%H:%M:%S)
UPTIME=\$(uptime -p | sed 's/up //')
RAM_FREE=\$(free -h | awk '/^Mem:/{print \$4}')
HOSTNAME=\$(hostname)

echo -e "\${PURPLE}"
figlet -f slant "\$SRV_NAME" 2>/dev/null || echo "\$SRV_NAME"
echo -e "\${NC}"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo -e "  \${YELLOW}SERVIDOR INSTALADO EL\${NC}   : \${WHITE}\$INSTALL_DATE\${NC}"
echo -e "  \${YELLOW}FECHA/HORA ACTUAL\${NC}        : \${WHITE}\$CURRENT_DATE - \$CURRENT_TIME\${NC}"
echo -e "  \${YELLOW}NOMBRE DEL SERVIDOR\${NC}      : \${WHITE}\$HOSTNAME\${NC}"
echo -e "  \${YELLOW}TIEMPO EN LINEA\${NC}          : \${WHITE}\$UPTIME\${NC}"
echo -e "  \${YELLOW}VERSION INSTALADA\${NC}        : \${WHITE}V1.0.0\${NC}"
echo -e "  \${YELLOW}MEMORIA RAM LIBRE\${NC}        : \${WHITE}\$RAM_FREE\${NC}"
echo -e "  \${YELLOW}CREADOR DEL SCRIPT\${NC}       : \${PURPLE}@DealerServices235 ❴LTM❵\${NC}"
echo -e "  \${GREEN}BIENVENIDO DE NUEVO!\${NC}"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo -e "  Teclee \${YELLOW}menu\${NC} para ver el MENU LTM"
echo -e "\${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${NC}"
echo ""
MOTDEOF

    chmod +x /etc/profile.d/sshfree-motd.sh
    
    # Deshabilitar MOTD por defecto de Ubuntu
    [ -f /etc/motd ] && > /etc/motd
    
    echo -e "
  ${G}OK MOTD configurado para ${SRV_NAME}${NC}"
    echo -e "  ${Y}Se mostrara al conectarte por SSH${NC}"
    sleep 2
}

# ══════════════════════════════════════════
#   MENÚ PRINCIPAL
# ══════════════════════════════════════════

desinstalar_script() {
    banner; sep
    echo -e "  ${R}  DESINSTALAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${Y}Esto eliminará:${NC}"
    echo -e "  - Comando menu"
    echo -e "  - MOTD del servidor"
    echo -e "  - Archivos de configuracion"
    echo -e "  - Servicios instalados (WS, BadVPN, etc)"
    echo ""
    read -p "  Confirmar (si/no): " CONFIRM
    [ "$CONFIRM" != "si" ] && echo -e "  ${Y}Cancelado${NC}" && sleep 1 && return

    echo -e "\n  ${C}Desinstalando...${NC}"
    # Detener y eliminar servicios
    for svc in ws-proxy-* badvpn-* udp-custom stunnel4 v2ray zivpn hysteria-server; do
        systemctl stop $svc 2>/dev/null
        systemctl disable $svc 2>/dev/null
        rm -f /etc/systemd/system/$svc.service
    done
    systemctl daemon-reload

    # Eliminar archivos
    rm -f /usr/local/bin/menu
    rm -f /etc/profile.d/sshfree-motd.sh
    rm -rf /etc/sshfreeltm
    rm -rf $DIR_SCRIPTS

    echo -e "  ${G}Script desinstalado correctamente${NC}"
    sleep 2
    exit 0
}
actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/Dealer-Dev/Script-ssh-udp-v2ray/main/sshscript-ltm.sh"
    chmod +x /usr/local/bin/menu
    echo -e "  ${G}OK Script actualizado${NC}"
    echo -e "  ${Y}Reinicia el menu para aplicar cambios${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/Dealer-Dev/Script-ssh-udp-v2ray/main/sshscript-ltm.sh"
    chmod +x /usr/local/bin/menu
    echo -e "  ${G}OK Script actualizado${NC}"
    echo -e "  ${Y}Reinicia el menu para aplicar cambios${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_antiddos() {
    while true; do
        banner; sep
        echo -e "  ${Y}  ANTI-DDOS${NC}"; sep; echo ""
        # Ver estado
        DDOS_ST=$(iptables -L INPUT -n 2>/dev/null | grep -c "limit\|REJECT\|DROP")
        if [[ "${DDOS_ST:-0}" -gt 3 ]]; then
            echo -e "  Estado: ${G}[ACTIVO]${NC}"
        else
            echo -e "  Estado: ${R}[INACTIVO]${NC}"
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Activar Anti-DDoS Agresivo"
        echo -e "  ${W}[2]${NC} Desactivar Anti-DDoS"
        echo -e "  ${W}[3]${NC} Ver reglas activas"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Aplicando Anti-DDoS agresivo...${NC}"
                apt install -y iptables-persistent fail2ban > /dev/null 2>&1

                # Limpiar reglas previas
                iptables -F
                iptables -X
                iptables -Z

                # Política por defecto
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT

                # Permitir loopback
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

                # Permitir puertos activos
                for PORT in $(ss -tlnp | awk '/LISTEN/{print $4}' | grep -o '[0-9]*$' | sort -u); do
                    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
                done
                for PORT in $(ss -ulnp | awk '/UNCONN/{print $4}' | grep -o '[0-9]*$' | sort -u); do
                    iptables -A INPUT -p udp --dport $PORT -j ACCEPT
                done

                # Anti SYN Flood
                iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP

                # Anti UDP Flood
                iptables -A INPUT -p udp -m limit --limit 50/s --limit-burst 100 -j ACCEPT
                iptables -A INPUT -p udp -j DROP

                # Anti ICMP Flood (ping)
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 2/s --limit-burst 4 -j ACCEPT
                iptables -A INPUT -p icmp -j DROP

                # Bloquear escaneo de puertos
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP

                # Limitar conexiones por IP
                iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 5 -j REJECT
                iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 -j REJECT

                # Anti brute force SSH
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP

                # Bloquear IPs privadas falsas
                iptables -A INPUT -s 10.0.0.0/8 ! -i lo -j DROP
                iptables -A INPUT -s 172.16.0.0/12 ! -i lo -j DROP
                iptables -A INPUT -s 192.168.0.0/16 ! -i lo -j DROP

                # Guardar reglas
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules

                # Configurar fail2ban
                cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 86400

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF
                systemctl enable fail2ban
                systemctl restart fail2ban 2>/dev/null

                echo -e "  ${G}✓ SYN Flood bloqueado${NC}"
                echo -e "  ${G}✓ UDP Flood bloqueado${NC}"
                echo -e "  ${G}✓ ICMP Flood bloqueado${NC}"
                echo -e "  ${G}✓ Port scanning bloqueado${NC}"
                echo -e "  ${G}✓ Brute Force SSH bloqueado${NC}"
                echo -e "  ${G}✓ Conexiones limitadas por IP${NC}"
                echo -e "  ${G}✓ Fail2ban activo${NC}"
                echo ""
                echo -e "  ${G}OK Anti-DDoS agresivo activado${NC}"
                read -p "  ENTER..." ;;
            2)
                iptables -F
                iptables -X
                iptables -P INPUT ACCEPT
                iptables -P FORWARD ACCEPT
                iptables -P OUTPUT ACCEPT
                systemctl stop fail2ban 2>/dev/null
                echo -e "  ${Y}Anti-DDoS desactivado${NC}"; sleep 2 ;;
            3)
                echo ""
                iptables -L INPUT -n --line-numbers | head -30
                echo ""
                read -p "  ENTER..." ;;
            0) break ;;
        esac
    done
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/Dealer-Dev/Script-ssh-udp-v2ray/main/sshscript-ltm.sh"
    chmod +x /usr/local/bin/menu
    echo -e "  ${G}OK Script actualizado${NC}"
    echo -e "  ${Y}Reinicia el menu para aplicar cambios${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_antiddos() {
    while true; do
        banner; sep
        echo -e "  ${Y}  ANTI-DDOS${NC}"; sep; echo ""
        # Ver estado
        DDOS_ST=$(iptables -L INPUT -n 2>/dev/null | grep -c "limit\|REJECT\|DROP")
        if [[ "${DDOS_ST:-0}" -gt 3 ]]; then
            echo -e "  Estado: ${G}[ACTIVO]${NC}"
        else
            echo -e "  Estado: ${R}[INACTIVO]${NC}"
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Activar Anti-DDoS Agresivo"
        echo -e "  ${W}[2]${NC} Desactivar Anti-DDoS"
        echo -e "  ${W}[3]${NC} Ver reglas activas"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Aplicando Anti-DDoS agresivo...${NC}"
                apt install -y iptables-persistent fail2ban > /dev/null 2>&1

                # Limpiar reglas previas
                iptables -F
                iptables -X
                iptables -Z

                # Política por defecto
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT

                # Permitir loopback
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

                # Permitir puertos activos
                for PORT in $(ss -tlnp | awk '/LISTEN/{print $4}' | grep -o '[0-9]*$' | sort -u); do
                    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
                done
                for PORT in $(ss -ulnp | awk '/UNCONN/{print $4}' | grep -o '[0-9]*$' | sort -u); do
                    iptables -A INPUT -p udp --dport $PORT -j ACCEPT
                done

                # Anti SYN Flood
                iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP

                # Anti UDP Flood
                iptables -A INPUT -p udp -m limit --limit 50/s --limit-burst 100 -j ACCEPT
                iptables -A INPUT -p udp -j DROP

                # Anti ICMP Flood (ping)
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 2/s --limit-burst 4 -j ACCEPT
                iptables -A INPUT -p icmp -j DROP

                # Bloquear escaneo de puertos
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP

                # Limitar conexiones por IP
                iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 5 -j REJECT
                iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 -j REJECT

                # Anti brute force SSH
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP

                # Bloquear IPs privadas falsas
                iptables -A INPUT -s 10.0.0.0/8 ! -i lo -j DROP
                iptables -A INPUT -s 172.16.0.0/12 ! -i lo -j DROP
                iptables -A INPUT -s 192.168.0.0/16 ! -i lo -j DROP

                # Guardar reglas
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules

                # Configurar fail2ban
                cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 86400

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF
                systemctl enable fail2ban
                systemctl restart fail2ban 2>/dev/null

                echo -e "  ${G}✓ SYN Flood bloqueado${NC}"
                echo -e "  ${G}✓ UDP Flood bloqueado${NC}"
                echo -e "  ${G}✓ ICMP Flood bloqueado${NC}"
                echo -e "  ${G}✓ Port scanning bloqueado${NC}"
                echo -e "  ${G}✓ Brute Force SSH bloqueado${NC}"
                echo -e "  ${G}✓ Conexiones limitadas por IP${NC}"
                echo -e "  ${G}✓ Fail2ban activo${NC}"
                echo ""
                echo -e "  ${G}OK Anti-DDoS agresivo activado${NC}"
                read -p "  ENTER..." ;;
            2)
                iptables -F
                iptables -X
                iptables -P INPUT ACCEPT
                iptables -P FORWARD ACCEPT
                iptables -P OUTPUT ACCEPT
                systemctl stop fail2ban 2>/dev/null
                echo -e "  ${Y}Anti-DDoS desactivado${NC}"; sleep 2 ;;
            3)
                echo ""
                iptables -L INPUT -n --line-numbers | head -30
                echo ""
                read -p "  ENTER..." ;;
            0) break ;;
        esac
    done
}

menu_speed_udp() {
    banner; sep
    echo -e "  ${Y}  MEJORAR VELOCIDAD UDP${NC}"; sep; echo ""
    echo -e "  ${C}Aplicando optimizaciones...${NC}"
    echo ""

    # BBR
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf 2>/dev/null
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

    # Buffers UDP
    echo "net.core.rmem_max=134217728" >> /etc/sysctl.conf
    echo "net.core.wmem_max=134217728" >> /etc/sysctl.conf
    echo "net.core.rmem_default=25165824" >> /etc/sysctl.conf
    echo "net.core.wmem_default=25165824" >> /etc/sysctl.conf
    echo "net.core.netdev_max_backlog=65536" >> /etc/sysctl.conf
    echo "net.ipv4.udp_rmem_min=8192" >> /etc/sysctl.conf
    echo "net.ipv4.udp_wmem_min=8192" >> /etc/sysctl.conf

    # Aplicar cambios
    sysctl -p > /dev/null 2>&1

    # Verificar BBR
    BBR=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -o bbr)
    if [ "$BBR" = "bbr" ]; then
        echo -e "  ${G}✓ BBR activado${NC}"
    else
        echo -e "  ${Y}✓ Buffers optimizados (BBR no disponible en este kernel)${NC}"
    fi
    echo -e "  ${G}✓ Buffers UDP maximizados${NC}"
    echo -e "  ${G}✓ Network backlog optimizado${NC}"
    echo ""
    sep
    echo -e "  ${G}OK Optimizacion aplicada${NC}"
    read -p "  ENTER..."
}

menu_slowdns() {
    SLOWDNS_DIR="/etc/slowdns"
    SERVER_SERVICE="server-sldns"
    CLIENT_SERVICE="client-sldns"
    PUBKEY_FILE="$SLOWDNS_DIR/server.pub"
    while true; do
        banner; sep
        echo -e "  ${Y}  SLOWDNS${NC}"; sep; echo ""
        SDNS_ST=$(systemctl is-active $SERVER_SERVICE 2>/dev/null)
        [ "$SDNS_ST" = "active" ] && echo -e "  Estado: ${G}[ACTIVO]${NC}" || echo -e "  Estado: ${R}[INACTIVO]${NC}"
        [ -f "$PUBKEY_FILE" ] && echo -e "  PubKey: ${W}$(cat $PUBKEY_FILE)${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar SlowDNS"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Ver Public Key"
        echo -e "  ${W}[5]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Instalando dependencias...${NC}"
                apt install -y git screen iptables net-tools curl wget dos2unix gnutls-bin netfilter-persistent
                mkdir -p $SLOWDNS_DIR
                chmod 700 $SLOWDNS_DIR
                read -p "  Dominio NS: " SDNS_DOMAIN
                read -p "  Puerto SSH local (default 22): " SDNS_PORT
                SDNS_PORT=${SDNS_PORT:-22}
                echo -e "  ${C}Descargando binarios...${NC}"
                wget -q -O $SLOWDNS_DIR/sldns-server "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-server"
                wget -q -O $SLOWDNS_DIR/sldns-client "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-client"
                wget -q -O $SLOWDNS_DIR/server.key "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.key"
                wget -q -O $SLOWDNS_DIR/server.pub "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.pub"
                chmod +x $SLOWDNS_DIR/*
                iptables -I INPUT -p udp --dport 5300 -j ACCEPT
                iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
                netfilter-persistent save 2>/dev/null
                cat > /etc/systemd/system/$CLIENT_SERVICE.service << EOF
[Unit]
Description=Client SlowDNS
After=network.target
[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/sldns-client -udp 8.8.8.8:53 --pubkey-file $PUBKEY_FILE $SDNS_DOMAIN 127.0.0.1:$SDNS_PORT
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
                cat > /etc/systemd/system/$SERVER_SERVICE.service << EOF
[Unit]
Description=Server SlowDNS
After=network.target
[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/sldns-server -udp :5300 -privkey-file $SLOWDNS_DIR/server.key $SDNS_DOMAIN 127.0.0.1:$SDNS_PORT
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable $CLIENT_SERVICE $SERVER_SERVICE
                systemctl start $CLIENT_SERVICE $SERVER_SERVICE
                echo -e "  ${G}OK SlowDNS instalado${NC}"
                echo -e "  PubKey: $(cat $PUBKEY_FILE 2>/dev/null)"
                read -p "  ENTER..." ;;
            2) systemctl start $CLIENT_SERVICE $SERVER_SERVICE && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop $CLIENT_SERVICE $SERVER_SERVICE && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) cat $PUBKEY_FILE 2>/dev/null || echo -e "  ${R}No encontrada${NC}"; echo ""; read -p "  ENTER..." ;;
            5)
                systemctl stop $CLIENT_SERVICE $SERVER_SERVICE 2>/dev/null
                systemctl disable $CLIENT_SERVICE $SERVER_SERVICE 2>/dev/null
                rm -rf $SLOWDNS_DIR
                rm -f /etc/systemd/system/$CLIENT_SERVICE.service /etc/systemd/system/$SERVER_SERVICE.service
                systemctl daemon-reload
                echo -e "  ${G}SlowDNS desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_dropbear() {
    while true; do
        banner; sep
        echo -e "  ${Y}  DROPBEAR SSH${NC}"; sep; echo ""
        DB_ST=$(systemctl is-active dropbear 2>/dev/null)
        [ "$DB_ST" = "active" ] && echo -e "  Estado: ${G}[ACTIVO]${NC}" || echo -e "  Estado: ${R}[INACTIVO]${NC}"
        DB_PORT=$(cat /etc/sshfreeltm/dropbear_port 2>/dev/null || echo "444")
        echo -e "  Puerto: ${W}${DB_PORT}${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar Dropbear"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Cambiar puerto"
        echo -e "  ${W}[6]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Instalando Dropbear...${NC}"
                apt install -y dropbear
                read -p "  Puerto Dropbear (default 444): " DB_PORT
                DB_PORT=${DB_PORT:-444}
                mkdir -p /etc/sshfreeltm
                echo "$DB_PORT" > /etc/sshfreeltm/dropbear_port
                # Configurar
                sed -i "s/NO_START=1/NO_START=0/" /etc/default/dropbear 2>/dev/null
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$DB_PORT/" /etc/default/dropbear 2>/dev/null
                grep -q "DROPBEAR_PORT" /etc/default/dropbear || echo "DROPBEAR_PORT=$DB_PORT" >> /etc/default/dropbear
                # Crear servicio
                cat > /etc/systemd/system/dropbear.service << EOF
[Unit]
Description=Dropbear SSH Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/sbin/dropbear -F -p $DB_PORT
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                # Generar llaves Dropbear
                mkdir -p /etc/dropbear
                [ ! -f /etc/dropbear/dropbear_dss_host_key ] && dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_rsa_host_key ] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key > /dev/null 2>&1
                # Agregar /bin/false a shells permitidos
                grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
                systemctl enable dropbear
                systemctl start dropbear
                iptables -I INPUT -p tcp --dport $DB_PORT -j ACCEPT 2>/dev/null
                echo -e "  ${G}OK Dropbear instalado en puerto ${DB_PORT}${NC}"; sleep 2 ;;
            2) systemctl start dropbear && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop dropbear && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart dropbear && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Nuevo puerto: " NEW_PORT
                echo "$NEW_PORT" > /etc/sshfreeltm/dropbear_port
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$NEW_PORT/" /etc/default/dropbear 2>/dev/null
                sed -i "s/-p [0-9]*/-p $NEW_PORT/" /etc/systemd/system/dropbear.service 2>/dev/null
                systemctl daemon-reload
                systemctl restart dropbear
                echo -e "  ${G}Puerto cambiado a ${NEW_PORT}${NC}"; sleep 2 ;;
            6)
                systemctl stop dropbear; systemctl disable dropbear
                apt remove -y dropbear > /dev/null 2>&1
                rm -f /etc/systemd/system/dropbear.service
                systemctl daemon-reload
                echo -e "  ${G}Dropbear desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_banner_ssh() {
    while true; do
        banner; sep
        echo -e "  ${Y}  BANNER SSH${NC}"; sep; echo ""
        echo -e "  Banner actual:"
        echo ""
        cat /etc/ssh/sshd_config | grep -i "^Banner" || echo "  Sin banner configurado"
        [ -f /etc/ssh/banner ] && cat /etc/ssh/banner || echo ""
        echo ""; sep
        echo -e "  ${W}[1]${NC} Crear/Editar banner"
        echo -e "  ${W}[2]${NC} Quitar banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                banner; sep
                echo -e "  ${Y}Escribe el banner SSH${NC}"
                echo -e "  ${C}(Texto que aparece al conectar por SSH)${NC}"; sep; echo ""
                echo -e "  Ejemplo:"
                echo -e "  ╔══════════════════════════════════╗"
                echo -e "  ║   SERVIDOR PRIVADO - SSHFREE LTM ║"
                echo -e "  ╚══════════════════════════════════╝"
                echo ""; sep
                read -p "  Texto del banner: " BANNER_TXT
                echo "$BANNER_TXT" > /etc/ssh/banner
                # Configurar sshd para mostrar banner
                grep -q "^Banner" /etc/ssh/sshd_config && sed -i "s|^Banner.*|Banner /etc/ssh/banner|" /etc/ssh/sshd_config || echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
                systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
                echo -e "  ${G}OK Banner SSH configurado${NC}"; sleep 2 ;;
            2)
                sed -i '/^Banner/d' /etc/ssh/sshd_config
                rm -f /etc/ssh/banner
                systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
                echo -e "  ${G}OK Banner eliminado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

menu_herramientas() {
    while true; do
        banner; sep
        echo -e "  ${Y}  HERRAMIENTAS Y PROTOCOLOS${NC}"; sep; echo ""
        printf " ${C}∘${NC} WebSocket  %-13b ${C}∘${NC} BadVPN 7200 %b\n" "$(status_port 80)" "$(status_service badvpn-7200)"
        printf " ${C}∘${NC} UDP Custom %-12b ${C}∘${NC} BadVPN 7300 %b\n" "$(ps aux | grep -i UDP-Custom | grep -v grep | grep -q . && echo -e "${G}[ON]${NC}" || echo -e "${R}[OFF]${NC}")" "$(status_service badvpn-7300)"
        printf " ${C}∘${NC} SSL/TLS    %-12b ${C}∘${NC} V2Ray       %b\n" "$(status_service stunnel4)" "$(status_service v2ray)"
        printf " ${C}∘${NC} ZIV VPN   %-12b ${C}∘${NC} SlowDNS %b\n" "$(status_service zivpn)" "$(status_service server-sldns)"
        printf " ${C}∘${NC} Dropbear  %b\n" "$(status_service dropbear)"
        echo ""; sep
        printf " ${W}[1]${NC} %-22s ${W}[2]${NC} %s\n" "WebSocket Python" "BadVPN UDP"
        printf " ${W}[3]${NC} %-22s ${W}[4]${NC} %s\n" "UDP Custom" "SSL/TLS Stunnel"
        printf " ${W}[5]${NC} %-22s ${W}[6]${NC} %s\n" "V2Ray VMess" "ZIV VPN"
        printf " ${W}[7]${NC} %-22s ${W}[8]${NC} %s\n" "Banner SSH" "Mejorar Velocidad UDP"
        printf " ${W}[9]${NC} %-22s ${W}[10]${NC} %s\n" "Anti-DDoS" "SlowDNS"
        printf " ${W}[11]${NC} Dropbear SSH\n"
        sep
        printf " ${W}[0]${NC} Volver\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1) menu_ws ;;
            2) menu_badvpn ;;
            3) menu_udp ;;
            4) menu_ssl ;;
            5) menu_v2ray ;;
            6) menu_ziv ;;
            7) menu_banner_ssh ;;
            8) menu_speed_udp ;;
            9) menu_antiddos ;;
            10) menu_slowdns ;;
            11) menu_dropbear ;;
            9) menu_antiddos ;;
            10) menu_slowdns ;;
            11) menu_dropbear ;;
            0) break ;;
            *) echo -e "  ${R}Opcion invalida${NC}"; sleep 1 ;;
        esac
    done
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/Dealer-Dev/Script-ssh-udp-v2ray/main/sshscript-ltm.sh"
    chmod +x /usr/local/bin/menu
    echo -e "  ${G}OK Script actualizado${NC}"
    echo -e "  ${Y}Reinicia el menu para aplicar cambios${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/Dealer-Dev/Script-ssh-udp-v2ray/main/sshscript-ltm.sh"
    chmod +x /usr/local/bin/menu
    echo -e "  ${G}OK Script actualizado${NC}"
    echo -e "  ${Y}Reinicia el menu para aplicar cambios${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_antiddos() {
    while true; do
        banner; sep
        echo -e "  ${Y}  ANTI-DDOS${NC}"; sep; echo ""
        # Ver estado
        DDOS_ST=$(iptables -L INPUT -n 2>/dev/null | grep -c "limit\|REJECT\|DROP")
        if [[ "${DDOS_ST:-0}" -gt 3 ]]; then
            echo -e "  Estado: ${G}[ACTIVO]${NC}"
        else
            echo -e "  Estado: ${R}[INACTIVO]${NC}"
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Activar Anti-DDoS Agresivo"
        echo -e "  ${W}[2]${NC} Desactivar Anti-DDoS"
        echo -e "  ${W}[3]${NC} Ver reglas activas"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Aplicando Anti-DDoS agresivo...${NC}"
                apt install -y iptables-persistent fail2ban > /dev/null 2>&1

                # Limpiar reglas previas
                iptables -F
                iptables -X
                iptables -Z

                # Política por defecto
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT

                # Permitir loopback
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

                # Permitir puertos activos
                for PORT in $(ss -tlnp | awk '/LISTEN/{print $4}' | grep -o '[0-9]*$' | sort -u); do
                    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
                done
                for PORT in $(ss -ulnp | awk '/UNCONN/{print $4}' | grep -o '[0-9]*$' | sort -u); do
                    iptables -A INPUT -p udp --dport $PORT -j ACCEPT
                done

                # Anti SYN Flood
                iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP

                # Anti UDP Flood
                iptables -A INPUT -p udp -m limit --limit 50/s --limit-burst 100 -j ACCEPT
                iptables -A INPUT -p udp -j DROP

                # Anti ICMP Flood (ping)
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 2/s --limit-burst 4 -j ACCEPT
                iptables -A INPUT -p icmp -j DROP

                # Bloquear escaneo de puertos
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP

                # Limitar conexiones por IP
                iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 5 -j REJECT
                iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 -j REJECT

                # Anti brute force SSH
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP

                # Bloquear IPs privadas falsas
                iptables -A INPUT -s 10.0.0.0/8 ! -i lo -j DROP
                iptables -A INPUT -s 172.16.0.0/12 ! -i lo -j DROP
                iptables -A INPUT -s 192.168.0.0/16 ! -i lo -j DROP

                # Guardar reglas
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules

                # Configurar fail2ban
                cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 86400

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF
                systemctl enable fail2ban
                systemctl restart fail2ban 2>/dev/null

                echo -e "  ${G}✓ SYN Flood bloqueado${NC}"
                echo -e "  ${G}✓ UDP Flood bloqueado${NC}"
                echo -e "  ${G}✓ ICMP Flood bloqueado${NC}"
                echo -e "  ${G}✓ Port scanning bloqueado${NC}"
                echo -e "  ${G}✓ Brute Force SSH bloqueado${NC}"
                echo -e "  ${G}✓ Conexiones limitadas por IP${NC}"
                echo -e "  ${G}✓ Fail2ban activo${NC}"
                echo ""
                echo -e "  ${G}OK Anti-DDoS agresivo activado${NC}"
                read -p "  ENTER..." ;;
            2)
                iptables -F
                iptables -X
                iptables -P INPUT ACCEPT
                iptables -P FORWARD ACCEPT
                iptables -P OUTPUT ACCEPT
                systemctl stop fail2ban 2>/dev/null
                echo -e "  ${Y}Anti-DDoS desactivado${NC}"; sleep 2 ;;
            3)
                echo ""
                iptables -L INPUT -n --line-numbers | head -30
                echo ""
                read -p "  ENTER..." ;;
            0) break ;;
        esac
    done
}

actualizar_script() {
    banner; sep
    echo -e "  ${Y}  ACTUALIZAR SCRIPT${NC}"; sep; echo ""
    echo -e "  ${C}Descargando ultima version...${NC}"
    wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/Dealer-Dev/Script-ssh-udp-v2ray/main/sshscript-ltm.sh"
    chmod +x /usr/local/bin/menu
    echo -e "  ${G}OK Script actualizado${NC}"
    echo -e "  ${Y}Reinicia el menu para aplicar cambios${NC}"
    sleep 2
    exec /usr/local/bin/menu
}

menu_antiddos() {
    while true; do
        banner; sep
        echo -e "  ${Y}  ANTI-DDOS${NC}"; sep; echo ""
        # Ver estado
        DDOS_ACTIVE=$(iptables -L INPUT -n 2>/dev/null | grep -q "limit" && echo 1 || echo 0)
        if [ "$DDOS_ACTIVE" = "1" ]; then
            echo -e "  Estado: ${G}[ACTIVO]${NC}"
        else
            echo -e "  Estado: ${R}[INACTIVO]${NC}"
        fi
        echo ""; sep
        echo -e "  ${W}[1]${NC} Activar Anti-DDoS Agresivo"
        echo -e "  ${W}[2]${NC} Desactivar Anti-DDoS"
        echo -e "  ${W}[3]${NC} Ver reglas activas"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Aplicando Anti-DDoS agresivo...${NC}"
                apt install -y iptables-persistent fail2ban > /dev/null 2>&1

                # Limpiar reglas previas
                iptables -F
                iptables -X
                iptables -Z

                # Política por defecto
                iptables -P INPUT ACCEPT
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT

                # Permitir loopback
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

                # Permitir puertos activos
                for PORT in $(ss -tlnp | awk '/LISTEN/{print $4}' | grep -o '[0-9]*$' | sort -u); do
                    iptables -A INPUT -p tcp --dport $PORT -j ACCEPT
                done
                for PORT in $(ss -ulnp | awk '/UNCONN/{print $4}' | grep -o '[0-9]*$' | sort -u); do
                    iptables -A INPUT -p udp --dport $PORT -j ACCEPT
                done

                # Anti SYN Flood
                iptables -A INPUT -p tcp --syn -m limit --limit 10/s --limit-burst 20 -j ACCEPT
                iptables -A INPUT -p tcp --syn -j DROP

                # Anti UDP Flood
                iptables -A INPUT -p udp -m limit --limit 50/s --limit-burst 100 -j ACCEPT
                iptables -A INPUT -p udp -j DROP

                # Anti ICMP Flood (ping)
                iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 2/s --limit-burst 4 -j ACCEPT
                iptables -A INPUT -p icmp -j DROP

                # Bloquear escaneo de puertos
                iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
                iptables -A INPUT -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP

                # Limitar conexiones por IP
                iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 5 -j REJECT
                iptables -A INPUT -p tcp -m connlimit --connlimit-above 50 -j REJECT

                # Anti brute force SSH
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
                iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 5 -j DROP

                # Bloquear IPs privadas falsas
                iptables -A INPUT -s 10.0.0.0/8 ! -i lo -j DROP
                iptables -A INPUT -s 172.16.0.0/12 ! -i lo -j DROP
                iptables -A INPUT -s 192.168.0.0/16 ! -i lo -j DROP

                # Guardar reglas
                iptables-save > /etc/iptables/rules.v4 2>/dev/null || iptables-save > /etc/iptables.rules

                # Configurar fail2ban
                cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
maxretry = 3
bantime = 86400

[http-get-dos]
enabled = true
port = http,https
filter = http-get-dos
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
EOF
                systemctl enable fail2ban
                systemctl restart fail2ban 2>/dev/null

                echo -e "  ${G}✓ SYN Flood bloqueado${NC}"
                echo -e "  ${G}✓ UDP Flood bloqueado${NC}"
                echo -e "  ${G}✓ ICMP Flood bloqueado${NC}"
                echo -e "  ${G}✓ Port scanning bloqueado${NC}"
                echo -e "  ${G}✓ Brute Force SSH bloqueado${NC}"
                echo -e "  ${G}✓ Conexiones limitadas por IP${NC}"
                echo -e "  ${G}✓ Fail2ban activo${NC}"
                echo ""
                echo -e "  ${G}OK Anti-DDoS agresivo activado${NC}"
                read -p "  ENTER..." ;;
            2)
                iptables -F
                iptables -X
                iptables -P INPUT ACCEPT
                iptables -P FORWARD ACCEPT
                iptables -P OUTPUT ACCEPT
                systemctl stop fail2ban 2>/dev/null
                echo -e "  ${Y}Anti-DDoS desactivado${NC}"; sleep 2 ;;
            3)
                echo ""
                iptables -L INPUT -n --line-numbers | head -30
                echo ""
                read -p "  ENTER..." ;;
            0) break ;;
        esac
    done
}

menu_speed_udp() {
    banner; sep
    echo -e "  ${Y}  MEJORAR VELOCIDAD UDP${NC}"; sep; echo ""
    echo -e "  ${C}Aplicando optimizaciones...${NC}"
    echo ""

    # BBR
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf 2>/dev/null
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf

    # Buffers UDP
    echo "net.core.rmem_max=134217728" >> /etc/sysctl.conf
    echo "net.core.wmem_max=134217728" >> /etc/sysctl.conf
    echo "net.core.rmem_default=25165824" >> /etc/sysctl.conf
    echo "net.core.wmem_default=25165824" >> /etc/sysctl.conf
    echo "net.core.netdev_max_backlog=65536" >> /etc/sysctl.conf
    echo "net.ipv4.udp_rmem_min=8192" >> /etc/sysctl.conf
    echo "net.ipv4.udp_wmem_min=8192" >> /etc/sysctl.conf

    # Aplicar cambios
    sysctl -p > /dev/null 2>&1

    # Verificar BBR
    BBR=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | grep -o bbr)
    if [ "$BBR" = "bbr" ]; then
        echo -e "  ${G}✓ BBR activado${NC}"
    else
        echo -e "  ${Y}✓ Buffers optimizados (BBR no disponible en este kernel)${NC}"
    fi
    echo -e "  ${G}✓ Buffers UDP maximizados${NC}"
    echo -e "  ${G}✓ Network backlog optimizado${NC}"
    echo ""
    sep
    echo -e "  ${G}OK Optimizacion aplicada${NC}"
    read -p "  ENTER..."
}

menu_slowdns() {
    SLOWDNS_DIR="/etc/slowdns"
    SERVER_SERVICE="server-sldns"
    CLIENT_SERVICE="client-sldns"
    PUBKEY_FILE="$SLOWDNS_DIR/server.pub"
    while true; do
        banner; sep
        echo -e "  ${Y}  SLOWDNS${NC}"; sep; echo ""
        SDNS_ST=$(systemctl is-active $SERVER_SERVICE 2>/dev/null)
        [ "$SDNS_ST" = "active" ] && echo -e "  Estado: ${G}[ACTIVO]${NC}" || echo -e "  Estado: ${R}[INACTIVO]${NC}"
        [ -f "$PUBKEY_FILE" ] && echo -e "  PubKey: ${W}$(cat $PUBKEY_FILE)${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar SlowDNS"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Ver Public Key"
        echo -e "  ${W}[5]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Instalando dependencias...${NC}"
                apt install -y git screen iptables net-tools curl wget dos2unix gnutls-bin netfilter-persistent
                mkdir -p $SLOWDNS_DIR
                chmod 700 $SLOWDNS_DIR
                read -p "  Dominio NS: " SDNS_DOMAIN
                read -p "  Puerto SSH local (default 22): " SDNS_PORT
                SDNS_PORT=${SDNS_PORT:-22}
                echo -e "  ${C}Descargando binarios...${NC}"
                wget -q -O $SLOWDNS_DIR/sldns-server "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-server"
                wget -q -O $SLOWDNS_DIR/sldns-client "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/sldns-client"
                wget -q -O $SLOWDNS_DIR/server.key "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.key"
                wget -q -O $SLOWDNS_DIR/server.pub "https://raw.githubusercontent.com/fisabiliyusri/SLDNS/main/slowdns/server.pub"
                chmod +x $SLOWDNS_DIR/*
                iptables -I INPUT -p udp --dport 5300 -j ACCEPT
                iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
                netfilter-persistent save 2>/dev/null
                cat > /etc/systemd/system/$CLIENT_SERVICE.service << EOF
[Unit]
Description=Client SlowDNS
After=network.target
[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/sldns-client -udp 8.8.8.8:53 --pubkey-file $PUBKEY_FILE $SDNS_DOMAIN 127.0.0.1:$SDNS_PORT
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
                cat > /etc/systemd/system/$SERVER_SERVICE.service << EOF
[Unit]
Description=Server SlowDNS
After=network.target
[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/sldns-server -udp :5300 -privkey-file $SLOWDNS_DIR/server.key $SDNS_DOMAIN 127.0.0.1:$SDNS_PORT
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable $CLIENT_SERVICE $SERVER_SERVICE
                systemctl start $CLIENT_SERVICE $SERVER_SERVICE
                echo -e "  ${G}OK SlowDNS instalado${NC}"
                echo -e "  PubKey: $(cat $PUBKEY_FILE 2>/dev/null)"
                read -p "  ENTER..." ;;
            2) systemctl start $CLIENT_SERVICE $SERVER_SERVICE && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop $CLIENT_SERVICE $SERVER_SERVICE && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) cat $PUBKEY_FILE 2>/dev/null || echo -e "  ${R}No encontrada${NC}"; echo ""; read -p "  ENTER..." ;;
            5)
                systemctl stop $CLIENT_SERVICE $SERVER_SERVICE 2>/dev/null
                systemctl disable $CLIENT_SERVICE $SERVER_SERVICE 2>/dev/null
                rm -rf $SLOWDNS_DIR
                rm -f /etc/systemd/system/$CLIENT_SERVICE.service /etc/systemd/system/$SERVER_SERVICE.service
                systemctl daemon-reload
                echo -e "  ${G}SlowDNS desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_dropbear() {
    while true; do
        banner; sep
        echo -e "  ${Y}  DROPBEAR SSH${NC}"; sep; echo ""
        DB_ST=$(systemctl is-active dropbear 2>/dev/null)
        [ "$DB_ST" = "active" ] && echo -e "  Estado: ${G}[ACTIVO]${NC}" || echo -e "  Estado: ${R}[INACTIVO]${NC}"
        DB_PORT=$(cat /etc/sshfreeltm/dropbear_port 2>/dev/null || echo "444")
        echo -e "  Puerto: ${W}${DB_PORT}${NC}"
        echo ""; sep
        echo -e "  ${W}[1]${NC} Instalar Dropbear"
        echo -e "  ${W}[2]${NC} Iniciar"
        echo -e "  ${W}[3]${NC} Detener"
        echo -e "  ${W}[4]${NC} Reiniciar"
        echo -e "  ${W}[5]${NC} Cambiar puerto"
        echo -e "  ${W}[6]${NC} Desinstalar"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                echo -e "
  ${C}Instalando Dropbear...${NC}"
                apt install -y dropbear
                read -p "  Puerto Dropbear (default 444): " DB_PORT
                DB_PORT=${DB_PORT:-444}
                mkdir -p /etc/sshfreeltm
                echo "$DB_PORT" > /etc/sshfreeltm/dropbear_port
                # Configurar
                sed -i "s/NO_START=1/NO_START=0/" /etc/default/dropbear 2>/dev/null
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$DB_PORT/" /etc/default/dropbear 2>/dev/null
                grep -q "DROPBEAR_PORT" /etc/default/dropbear || echo "DROPBEAR_PORT=$DB_PORT" >> /etc/default/dropbear
                # Crear servicio
                cat > /etc/systemd/system/dropbear.service << EOF
[Unit]
Description=Dropbear SSH Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/sbin/dropbear -F -p $DB_PORT
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                # Generar llaves Dropbear
                mkdir -p /etc/dropbear
                [ ! -f /etc/dropbear/dropbear_dss_host_key ] && dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_rsa_host_key ] && dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key > /dev/null 2>&1
                [ ! -f /etc/dropbear/dropbear_ecdsa_host_key ] && dropbearkey -t ecdsa -f /etc/dropbear/dropbear_ecdsa_host_key > /dev/null 2>&1
                # Agregar /bin/false a shells permitidos
                grep -q "/bin/false" /etc/shells || echo "/bin/false" >> /etc/shells
                systemctl enable dropbear
                systemctl start dropbear
                iptables -I INPUT -p tcp --dport $DB_PORT -j ACCEPT 2>/dev/null
                echo -e "  ${G}OK Dropbear instalado en puerto ${DB_PORT}${NC}"; sleep 2 ;;
            2) systemctl start dropbear && echo -e "  ${G}Iniciado${NC}"; sleep 1 ;;
            3) systemctl stop dropbear && echo -e "  ${Y}Detenido${NC}"; sleep 1 ;;
            4) systemctl restart dropbear && echo -e "  ${G}Reiniciado${NC}"; sleep 1 ;;
            5)
                read -p "  Nuevo puerto: " NEW_PORT
                echo "$NEW_PORT" > /etc/sshfreeltm/dropbear_port
                sed -i "s/DROPBEAR_PORT=.*/DROPBEAR_PORT=$NEW_PORT/" /etc/default/dropbear 2>/dev/null
                sed -i "s/-p [0-9]*/-p $NEW_PORT/" /etc/systemd/system/dropbear.service 2>/dev/null
                systemctl daemon-reload
                systemctl restart dropbear
                echo -e "  ${G}Puerto cambiado a ${NEW_PORT}${NC}"; sleep 2 ;;
            6)
                systemctl stop dropbear; systemctl disable dropbear
                apt remove -y dropbear > /dev/null 2>&1
                rm -f /etc/systemd/system/dropbear.service
                systemctl daemon-reload
                echo -e "  ${G}Dropbear desinstalado${NC}"; sleep 2 ;;
            0) break ;;
        esac
    done
}

menu_banner_ssh() {
    while true; do
        banner; sep
        echo -e "  ${Y}  BANNER SSH${NC}"; sep; echo ""
        echo -e "  Banner actual:"
        echo ""
        cat /etc/ssh/sshd_config | grep -i "^Banner" || echo "  Sin banner configurado"
        [ -f /etc/ssh/banner ] && cat /etc/ssh/banner || echo ""
        echo ""; sep
        echo -e "  ${W}[1]${NC} Crear/Editar banner"
        echo -e "  ${W}[2]${NC} Quitar banner"
        echo -e "  ${W}[0]${NC} Volver"; sep
        read -p "  Opcion: " OPT
        case $OPT in
            1)
                banner; sep
                echo -e "  ${Y}Escribe el banner SSH${NC}"
                echo -e "  ${C}(Texto que aparece al conectar por SSH)${NC}"; sep; echo ""
                echo -e "  Ejemplo:"
                echo -e "  ╔══════════════════════════════════╗"
                echo -e "  ║   SERVIDOR PRIVADO - SSHFREE LTM ║"
                echo -e "  ╚══════════════════════════════════╝"
                echo ""; sep
                read -p "  Texto del banner: " BANNER_TXT
                echo "$BANNER_TXT" > /etc/ssh/banner
                # Configurar sshd para mostrar banner
                grep -q "^Banner" /etc/ssh/sshd_config && sed -i "s|^Banner.*|Banner /etc/ssh/banner|" /etc/ssh/sshd_config || echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
                systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
                echo -e "  ${G}OK Banner SSH configurado${NC}"; sleep 2 ;;
            2)
                sed -i '/^Banner/d' /etc/ssh/sshd_config
                rm -f /etc/ssh/banner
                systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
                echo -e "  ${G}OK Banner eliminado${NC}"; sleep 1 ;;
            0) break ;;
        esac
    done
}

menu_herramientas() {
    while true; do
        banner; sep
        echo -e "  ${Y}  HERRAMIENTAS Y PROTOCOLOS${NC}"; sep; echo ""
        printf " ${C}∘${NC} WebSocket  %-13b ${C}∘${NC} BadVPN 7200 %b\n" "$(status_port 80)" "$(status_service badvpn-7200)"
        printf " ${C}∘${NC} UDP Custom %-12b ${C}∘${NC} BadVPN 7300 %b\n" "$(ps aux | grep -i UDP-Custom | grep -v grep | grep -q . && echo -e "${G}[ON]${NC}" || echo -e "${R}[OFF]${NC}")" "$(status_service badvpn-7300)"
        printf " ${C}∘${NC} SSL/TLS    %-12b ${C}∘${NC} V2Ray       %b\n" "$(status_service stunnel4)" "$(status_service v2ray)"
        printf " ${C}∘${NC} ZIV VPN   %-12b ${C}∘${NC} SlowDNS %b\n" "$(status_service zivpn)" "$(status_service server-sldns)"
        printf " ${C}∘${NC} Dropbear  %b\n" "$(status_service dropbear)"
        echo ""; sep
        printf " ${W}[1]${NC} %-22s ${W}[2]${NC} %s\n" "WebSocket Python" "BadVPN UDP"
        printf " ${W}[3]${NC} %-22s ${W}[4]${NC} %s\n" "UDP Custom" "SSL/TLS Stunnel"
        printf " ${W}[5]${NC} %-22s ${W}[6]${NC} %s\n" "V2Ray VMess" "ZIV VPN"
        printf " ${W}[7]${NC} %-22s ${W}[8]${NC} %s\n" "Banner SSH" "Mejorar Velocidad UDP"
        printf " ${W}[9]${NC} %-22s ${W}[10]${NC} %s\n" "Anti-DDoS" "SlowDNS"
        printf " ${W}[11]${NC} Dropbear SSH\n"
        sep
        printf " ${W}[0]${NC} Volver\n"; sep; echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1) menu_ws ;;
            2) menu_badvpn ;;
            3) menu_udp ;;
            4) menu_ssl ;;
            5) menu_v2ray ;;
            6) menu_ziv ;;
            7) menu_banner_ssh ;;
            8) menu_speed_udp ;;
            9) menu_antiddos ;;
            10) menu_slowdns ;;
            11) menu_dropbear ;;
            9) menu_antiddos ;;
            10) menu_slowdns ;;
            11) menu_dropbear ;;
            0) break ;;
            *) echo -e "  ${R}Opcion invalida${NC}"; sleep 1 ;;
        esac
    done
}

menu_principal() {
    while true; do
        banner
        SRV_IP=$(hostname -I | awk '{print $1}')
        SRV_OS=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Ubuntu")
        SRV_CPU=$(nproc)
        SRV_DATE=$(date +%d/%m/%Y-%H:%M)
        SRV_RAM=$(free -h | awk '/^Mem:/{print $4}')
        SRV_UPTIME=$(uptime -p | sed 's/up //')
        WS_ST=$(status_port 80)
        BD1_ST=$(status_service badvpn-7200)
        BD2_ST=$(status_service badvpn-7300)
        UDP_ST=$(ps aux | grep -i "udp-custom\|UDP-Custom" | grep -v grep | grep -q . && echo -e "${G}[ON]${NC}" || echo -e "${R}[OFF]${NC}")
        SSL_ST=$(status_service stunnel4)
        V2_ST=$(status_service v2ray)
        ZIV_ST=$(status_service zivpn)
        sep
        printf " ${NEON}◈${NC} ${DIM}SO:${NC}  ${W}%-20s${NC} ${NEON}◈${NC} ${DIM}IP:${NC}  ${NEON}%s${NC}\n" "$SRV_OS" "$SRV_IP"
        printf " ${NEON}◈${NC} ${DIM}CPU:${NC} ${W}%-19s${NC} ${NEON}◈${NC} ${DIM}Fecha:${NC} ${Y}%s${NC}\n" "$SRV_CPU cores" "$SRV_DATE"
        printf " ${NEON}◈${NC} ${DIM}RAM:${NC} ${W}%-19s${NC} ${NEON}◈${NC} ${DIM}Uptime:${NC} ${W}%s${NC}\n" "$SRV_RAM" "$SRV_UPTIME"
        sep
        printf " ${NEON}◈${NC} ${W}WebSocket ${NC} %-13b ${NEON}◈${NC} ${W}BadVPN 7200${NC} %b\n" "$WS_ST" "$BD1_ST"
        printf " ${NEON}◈${NC} ${W}UDP Custom${NC} %-12b ${NEON}◈${NC} ${W}BadVPN 7300${NC} %b\n" "$UDP_ST" "$BD2_ST"
        printf " ${NEON}◈${NC} ${W}SSL/TLS   ${NC} %-12b ${NEON}◈${NC} ${W}V2Ray      ${NC} %b\n" "$SSL_ST" "$V2_ST"
        printf " ${NEON}◈${NC} ${W}ZIV VPN   ${NC} %b\n" "$ZIV_ST"
        sep
        printf " \033[1;97m❬1❭ ⚡  Usuarios SSH         ❬2❭ 📡 Usuarios VMess\033[0m\n"
        printf " \033[1;97m❬3❭ 🔐 Usuarios ZIV VPN     ❬4❭ 🛠  Herramientas\033[0m\n"
        sep
        echo -e " ${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        printf " ${NEON}❖ Version: ${Y}v%s ${NEON}❖${NC}\n" "$SCRIPT_VERSION"
        sep
        printf " ${Y}❬9❭ 🖥️  %-18s${NC} ${R}❬10❭ 🗑️  %s${NC}\n" "Configurar MOTD" "Desinstalar"
        printf " ${Y}❬11❭ 🔄 Actualizar Script${NC}\n"
        sep
        printf " ${R}❬0❭ ✖  Salir${NC}\n"
        sep
        echo ""
        read -p " Opcion: " OPT
        case $OPT in
            1) menu_usuarios ;;
            2) menu_v2ray ;;
            3) menu_users_ziv ;;
            4) menu_herramientas ;;
            9) instalar_motd ;;
            10) desinstalar_script ;;
            11) actualizar_script ;;
            11) actualizar_script ;;
            0) echo -e "\n  ${G}Hasta luego! — DealerServices235${NC}\n"; exit 0 ;;
            *) echo -e "  ${R}Opcion invalida${NC}"; sleep 1 ;;
        esac
    done
}

[ "$EUID" -ne 0 ] && echo -e "${R}Ejecuta como root${NC}" && exit 1
menu_principal

# Auto-instalar comando menu
wget -q -O /usr/local/bin/menu "https://raw.githubusercontent.com/Dealer-Dev/Script-ssh-udp-v2ray/main/sshscript-ltm.sh"
chmod +x /usr/local/bin/menu
echo -e "\033[0;32mComando menu instalado\033[0m"
