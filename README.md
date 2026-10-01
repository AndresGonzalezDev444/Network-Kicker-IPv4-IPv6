# ⚡ Network Kicker — Dual Stack

<p align="center">

**Herramienta de laboratorio para análisis y pruebas de seguridad de redes IPv4/IPv6**

<br>

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge\&logo=gnu-bash\&logoColor=white)
![Kali Linux](https://img.shields.io/badge/Kali%20Linux-557C94?style=for-the-badge\&logo=kalilinux\&logoColor=white)
![IPv4](https://img.shields.io/badge/IPv4-ARP-blue?style=for-the-badge)
![IPv6](https://img.shields.io/badge/IPv6-NDP-purple?style=for-the-badge)
![Nmap](https://img.shields.io/badge/Nmap-network%20scanner-red?style=for-the-badge)
![Linux](https://img.shields.io/badge/Linux-supported-black?style=for-the-badge\&logo=linux)

</p>

---

## 🧠 ¿Qué es Network Kicker?

**Network Kicker** es una herramienta desarrollada en Bash para realizar **pruebas controladas de seguridad y resiliencia de redes locales**, trabajando simultáneamente sobre los protocolos **IPv4 e IPv6**.

El proyecto automatiza diferentes tareas que normalmente tendrían que realizarse manualmente:

* 🔎 Detección automática de la interfaz de red.
* 🌐 Identificación del gateway.
* 🖥️ Descubrimiento de dispositivos dentro de la red.
* 📡 Obtención de información de los dispositivos detectados.
* ⚔️ Simulación de ataques ARP sobre IPv4.
* 🧬 Pruebas de manipulación NDP sobre IPv6.
* 📢 Generación de Router Advertisements durante la prueba.
* 📊 Monitorización del estado de los procesos.
* 🔄 Reinicio automático de determinados procesos si finalizan inesperadamente.
* 🧹 Restauración de parámetros de red al detener la herramienta.

El script está diseñado principalmente para **laboratorios de ciberseguridad, redes propias, máquinas virtuales y entornos donde exista autorización explícita**.

> ⚠️ **IMPORTANTE:** Esta herramienta puede interrumpir la conectividad de otros dispositivos de una red. Utilízala únicamente en redes propias o en entornos donde tengas autorización para realizar pruebas de seguridad.

---

# 🎯 Objetivo del proyecto

El objetivo principal de Network Kicker es estudiar, desde un punto de vista práctico, cómo diferentes mecanismos de una red local pueden verse afectados mediante técnicas de manipulación de tráfico y descubrimiento de vecinos.

El proyecto permite experimentar con dos familias de protocolos:

```text
                    NETWORK KICKER
                         │
              ┌──────────┴──────────┐
              │                     │
           IPv4                   IPv6
              │                     │
        ARP Spoofing           NDP Poisoning
              │                     │
              └──────────┬──────────┘
                         │
                  Network Testing
                         │
                 ┌───────┴───────┐
                 │               │
             Discovery        Monitoring
```

---

# 🛠️ Tecnologías utilizadas

| Tecnología                | Uso                                           |
| ------------------------- | --------------------------------------------- |
| 🐚 **Bash**               | Lenguaje principal del proyecto               |
| 🐉 **Kali Linux**         | Entorno recomendado para pruebas de seguridad |
| 🔎 **Nmap**               | Descubrimiento de dispositivos                |
| 🕸️ **dsniff / arpspoof** | Pruebas relacionadas con ARP                  |
| 🌐 **arping**             | Operaciones y restauración ARP                |
| 🧬 **thc-ipv6**           | Herramientas relacionadas con pruebas IPv6    |
| 🔥 **iptables**           | Control del tráfico IPv4                      |
| 🔥 **ip6tables**          | Control del tráfico IPv6                      |
| 🐧 **Linux networking**   | Detección y configuración de interfaces       |
| 📡 **ARP / NDP**          | Protocolos involucrados en las pruebas        |

---

# ⚔️ Técnicas involucradas

## 🌐 IPv4 — ARP Spoofing

La herramienta utiliza `arpspoof` para realizar una prueba bidireccional de manipulación de las asociaciones ARP entre el objetivo y el gateway.

Conceptualmente:

```text
             ┌──────────────┐
             │   Gateway    │
             └──────┬───────┘
                    │
                 ARP ↕
                    │
             ┌──────┴───────┐
             │Network Kicker│
             └──────┬───────┘
                    │
                 ARP ↕
                    │
             ┌──────┴───────┐
             │    Target    │
             └──────────────┘
```

La herramienta establece procesos separados para las dos direcciones de comunicación.

---

## 🧬 IPv6 — NDP

IPv6 no utiliza ARP.

En su lugar utiliza **Neighbor Discovery Protocol (NDP)**, basado en ICMPv6.

Network Kicker incorpora herramientas de `thc-ipv6` para realizar pruebas relacionadas con:

* Neighbor Discovery.
* Neighbor Advertisement.
* Router Advertisements.
* Manipulación de información de vecinos IPv6.

Esto permite estudiar diferencias entre los mecanismos de descubrimiento de vecinos de IPv4 e IPv6.

---

# 🔍 Descubrimiento de dispositivos

Antes de comenzar una prueba, la herramienta intenta detectar automáticamente:

```text
┌─────────────────────────────────────┐
│          NETWORK DISCOVERY          │
├─────────────────────────────────────┤
│ Interface       → eth0 / wlan0      │
│ Gateway         → 192.168.1.1       │
│ Local IPv4      → 192.168.1.X       │
│ Local IPv6      → IPv6 global       │
│ Network         → 192.168.1.0/24    │
└─────────────────────────────────────┘
```

Posteriormente utiliza **Nmap** para descubrir los dispositivos disponibles en el segmento de red.

El usuario puede seleccionar un objetivo mediante:

* 🔢 Número asignado en la lista.
* 🌐 Dirección IP.

---

# 💻 Compatibilidad

### 🐉 Kali Linux — recomendado

El proyecto está pensado principalmente para **Kali Linux**, debido a que muchas de las herramientas utilizadas forman parte del ecosistema de seguridad de esta distribución.

También puede funcionar en otras distribuciones Debian/Ubuntu compatibles con los paquetes requeridos.

### 🖥️ Máquina virtual

Es posible utilizarlo dentro de:

* VirtualBox
* VMware
* Hardware físico

### ⚠️ VirtualBox

Si se utiliza una máquina virtual para realizar pruebas sobre otros dispositivos de la LAN, la conectividad de red de la VM debe configurarse correctamente.

El proyecto contempla específicamente el escenario de **Adaptador Puente (Bridged)** y advierte que el modo NAT no permite realizar determinadas pruebas contra otros dispositivos de la red local.

---

# 📦 Requisitos

Necesitas:

* 🐧 Linux
* 🐚 Bash
* 👑 Permisos `root`
* 🔎 Nmap
* 🕸️ dsniff
* 📡 arping
* 🧬 thc-ipv6
* 🔥 iptables
* 🔥 ip6tables

El propio script verifica algunas dependencias y puede intentar instalarlas mediante `apt`.

Entre las herramientas comprobadas se encuentran `arpspoof`, `nmap`, `arping` y `thc-ipv6`.

---

# 🚀 Instalación

Clona el repositorio:

```bash
git clone https://github.com/AndresGonzalezDev444/NETWORK-KICKER.git
```

Entra al directorio:

```bash
cd NETWORK-KICKER
```

Concede permisos de ejecución:

```bash
chmod +x andresdev_kick.sh
```

---

# ▶️ Ejecución

La herramienta requiere privilegios elevados porque necesita acceder a interfaces de red, tablas de firewall y parámetros del kernel.

Ejecuta:

```bash
sudo ./andresdev_kick.sh
```

Al iniciar, el programa comprobará los permisos:

```text
[!] Ejecuta con sudo.
```

si no se ejecuta con privilegios suficientes.

---

# 🔎 Flujo de ejecución

El funcionamiento general es:

```text
             ┌─────────────────────┐
             │       START         │
             └──────────┬──────────┘
                        ↓
             ┌─────────────────────┐
             │ Root verification   │
             └──────────┬──────────┘
                        ↓
             ┌─────────────────────┐
             │ Dependencies check  │
             └──────────┬──────────┘
                        ↓
             ┌─────────────────────┐
             │ Network detection   │
             └──────────┬──────────┘
                        ↓
             ┌─────────────────────┐
             │ Device discovery    │
             └──────────┬──────────┘
                        ↓
             ┌─────────────────────┐
             │ Target selection    │
             └──────────┬──────────┘
                        ↓
             ┌─────────────────────┐
             │ IPv4 / IPv6 tests   │
             └──────────┬──────────┘
                        ↓
             ┌─────────────────────┐
             │ Live monitoring     │
             └──────────┬──────────┘
                        ↓
                    Ctrl + C
                        ↓
             ┌─────────────────────┐
             │ Network restoration │
             └─────────────────────┘
```

---

# 🖥️ Información mostrada

Durante la ejecución, la herramienta muestra información como:

```text
┌──────────────────────────────────────────────────┐
│  Red IPv4  : 192.168.1.0/24                      │
│  Interfaz  : eth0                                 │
│  Router    : 192.168.1.1                          │
│  Mi IPv4   : 192.168.1.100                        │
│  Mi IPv6   : xxxx:xxxx::xxxx                     │
└──────────────────────────────────────────────────┘
```

Posteriormente muestra los dispositivos encontrados mediante el escaneo.

También identifica, cuando es posible:

* IP del objetivo.
* Dirección MAC.
* Dirección IPv6 global.
* Interfaz utilizada.

---

# 📊 Monitorización

Una vez iniciada la prueba, Network Kicker mantiene un pequeño monitor en vivo.

Puede mostrar estados como:

```text
●ARP4   ●NDP6   ●RA6 | 125s | 192.168.1.105
```

Donde:

| Indicador | Significado                            |
| --------- | -------------------------------------- |
| 🟢 `ARP4` | Proceso ARP IPv4 activo                |
| 🟢 `NDP6` | Proceso NDP IPv6 activo                |
| 🟢 `RA6`  | Proceso de Router Advertisement activo |
| ⏱️ Tiempo | Tiempo transcurrido                    |
| 🎯 IP     | Objetivo seleccionado                  |

El script también comprueba periódicamente si determinados procesos siguen activos y puede reiniciarlos durante la ejecución.

---

# 🧹 Restauración de la red

Una característica importante del proyecto es su función de limpieza.

Al presionar:

```text
CTRL + C
```

se ejecuta una rutina de restauración.

Esta rutina intenta:

* Detener los procesos utilizados.
* Restaurar el estado original de `ip_forward`.
* Restaurar configuraciones IPv6.
* Eliminar reglas temporales de `iptables`.
* Eliminar reglas temporales de `ip6tables`.
* Restaurar asociaciones ARP mediante `arping`.

## El script registra el estado original antes de comenzar y utiliza esa información durante la limpieza.

# 🧪 Casos de uso

## 🔬 1. Laboratorio de ciberseguridad

Utilizar el proyecto en una red aislada para comprender:

* ARP spoofing.
* NDP.
* IPv4 vs IPv6.
* ICMPv6.
* Tablas ARP.
* Tablas de vecinos IPv6.
* Firewall de Linux.

---

## 🛡️ 2. Pruebas de resiliencia

Permite estudiar cómo se comportan dispositivos ante determinadas manipulaciones de la infraestructura de red.

Puede utilizarse para posteriormente analizar mecanismos de defensa y detección.

---

## 🎓 3. Educación

Puede servir como proyecto práctico para estudiar:

```text
Redes
  ↓
IPv4
  ↓
ARP
  ↓
IPv6
  ↓
NDP
  ↓
ICMPv6
  ↓
Firewall
  ↓
Ciberseguridad
```

---

## 🧪 4. Laboratorios con máquinas virtuales

Una configuración típica podría ser:

```text
             ┌─────────────────┐
             │   Router/LAN    │
             └────────┬────────┘
                      │
              ┌───────┴───────┐
              │                │
        ┌─────┴─────┐    ┌─────┴─────┐
        │ Kali Linux│    │ Test Host │
        │  Network  │    │           │
        │  Kicker   │    │  Target   │
        └───────────┘    └───────────┘
```

> Se recomienda utilizar una red de laboratorio aislada cuando se estén realizando pruebas de seguridad.

---

# ⚠️ Consideraciones de seguridad

Este proyecto **no debe utilizarse contra redes o dispositivos sin autorización**.

Las técnicas utilizadas pueden producir:

* Pérdida temporal de conectividad.
* Alteraciones de la comunicación local.
* Cambios en tablas de vecinos.
* Interrupciones de servicios.
* Comportamiento inesperado en dispositivos IPv4/IPv6.

### ✅ Entornos apropiados

* Laboratorio personal.
* Red propia.
* Máquinas virtuales.
* CTFs autorizados.
* Entornos académicos.
* Pentesting con autorización.

### ❌ Entornos no apropiados

* Redes públicas.
* Redes de terceros.
* Wi-Fi de otras personas.
* Infraestructura empresarial sin autorización.
* Dispositivos que no estén dentro del alcance autorizado.

---

# 📁 Estructura del proyecto

Una estructura recomendada para el repositorio:

```text
NETWORK-KICKER/
│
├── 📜 andresdev_kick.sh
├── 📄 README.md
├── 📄 LICENSE
└── 📁 docs/
    └── 📄 laboratory.md
```

---

# 🧩 Arquitectura funcional

```text
                   Network Kicker
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
   Discovery          IPv4             IPv6
        │                │                │
      Nmap           ARP              NDP
        │           Spoofing         Poisoning
        │                │                │
        └────────────────┼────────────────┘
                         ▼
                    Monitoring
                         │
                         ▼
                    Restoration
```

---

# 📚 Conceptos estudiados

Este proyecto permite profundizar en conceptos como:

* ARP — Address Resolution Protocol
* NDP — Neighbor Discovery Protocol
* IPv4
* IPv6
* ICMPv6
* MAC Address
* Gateway
* Network Interface
* Routing
* `iptables`
* `ip6tables`
* Linux networking
* Network discovery
* Network security
* Virtual networking
* ARP spoofing
* Neighbor Discovery manipulation

---

# 🧑‍💻 Autor

## Andres Gonzalez Dev

**Robinson Andrés González Quintero**

💻 Desarrollo de software · Sistemas · Ciberseguridad

🌐 **Página web:**
https://andresgonzalezdev.me

🐙 **GitHub:**
https://github.com/AndresGonzalezDev444

---

<p align="center">

### ⚡ AndresGonzalezDev

**Building • Learning • Breaking • Securing**

🐧 💻 🔐 🌐

</p>

---

## ⚖️ Disclaimer

Este proyecto fue desarrollado con fines **educativos, académicos y de investigación en ciberseguridad**.

El autor no se responsabiliza por el uso indebido de la herramienta ni por daños ocasionados mediante su utilización fuera de entornos autorizados.

**El usuario es responsable de garantizar que posee autorización para realizar cualquier prueba sobre la red o dispositivo seleccionado.**

---
