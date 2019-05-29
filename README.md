# Proyecto Final - Hybrid Auto-Scaling

> Esto proyecto ha sido diseñado por Javier Porrón, estudiante de 2 ASIR en el IES Arcipreste de Hita. 

***"Hibryd Auto-Scaling"*** es un conjunto de utilidades las cuales permiten escalar un servidor fiscio/virtualizado a AWS y balancear la carga entre el servidor y la instancia AWS.

## Requerimientos para la instalacion y configuracionde Hybrid Auto-Scaling.
- [Bind9 DNS Server](https://www.isc.org/downloads/bind/) &mdash; Este proyecto utiliza Bind9 para la resolucion de nombres.
- [Nagios](https://www.nagios.org/) &mdash; Se requiere del uso de nagios para la monitorizacion de los servidores los cuales se quieren escalar.
- [Nagios-plugins](https://www.nagios.org/downloads/nagios-plugins/) &mdash; Plugins para la monitorizacion de los servidores.
- [Nagios NRPE server](https://packages.debian.org/stretch/nagios-nrpe-server) &mdash; NRPE permite ejecutar plugins de forma remota.
- [Apache HTTP Server](https://httpd.apache.org/) &mdash; Servidor HTTP para la gestion de nagios.
- [Haproxy](http://www.haproxy.org/) &mdash; Permite balancear la carga entre las instancias y servidores.
- [AWS](https://aws.amazon.com/es/) &mdash; Será necesaria una cuenta en AWS, así como AWS-CLI para la gestion por consola.

## Configuracion de Hybrid Auto-Scaling

**ATENCION! La configuracion de ejemplo descrita acontinuación corresponde a un servicio web. Si se desea puede modificarse para cualquier otro tipo de servicio.**

Equipos utilizados para la realizacion del projecto:

| Equipo  | Nombre de referencia | Configuracion de RED  | Servicios instalados |
| --------- | ------------  |   ------------  |------------  |
|  Raspberry pi| agent       |  192.168.1.10/24 | Apache HTTP Server, Nagios, nagios-nrpe-server, AWS-CLI, nagios-plugins |
| Maquina Virtual | dns     | 192.168.1.5/24 | Bind9 DNS Server|
| Maquina virtual | web1    | 192.168.1.50/24 | Apache HTTP Server |

## INDICE
1. [Nagios](#n)
2. [Nagios NRPE Server](#nrpe)
3. [Haproxy](#h)
4. [AWS](#a)
5. [Archivo main.cfg](#m)
6. [Scripts](#s)
7. [Claves Publicas y Privadas](#c)
8. [Scripts de Provisionamiento](#p)
9. [Configuracion DNS](#d)

### <a name="n"></a> Nagios

1. [Configurar archivo *nagios.cfg*](#n1)
2. [Configuracion de comandos de nagios](#n2)
3. [Generar archivo de configuración para definir hosts y servicios.](#n3)

<a name="n1"></a> Dentro del archivo de configuracion de nagios (  *nagios.cfg* ), debemos tener los siguientes parametros: 
~~
check_external_commnads=1
~~

<a name="n2"></a> Por otro lado, en el archivo *commands.cfg* definimos lo siguiente:
- ***check_remote_load*** &mdash; Permite monitorizar la carga del procesador en un servidor remoto. Para ello utiliza el ***NRPE Plugin***.
~~
define command{
        command_name check_remote_load
        command_line \$USER1\$/check_nrpe -H '$HOSTADDRESS$' -c check_load
}
~~
- ***nagios-cpu-handler*** &mdash; Ejecuta el script ***nagios-cpu-handler.sh***, el cual realiza una determinada acción cuando el servidor esta en un estado en concreto.
~~
define command{
        command_name nagios-cpu-handler
        command_line /Auto-Scaling/nagios-cpu-handler.sh '$HOSTNAME$' '$HOSTADDRESS$' '$SERVICESTATE$' '$SERVICESTATETYPE$$
}
~~

<a name="n3"></a> A continuacion, creamos un archivo de configuración dentro del directorio */etc/nagios3/conf.d/*. Por ejemplo, *gobierno.cfg* y le añadimos lo siguiente:
- Hay que definir un grupo de host los cuales seran los que escalaremos.
~~
define hostgroup{
        hostgroup_name          nodes
        alias                   Nodos Dinamicos
        members                 web1
}
~~
- Los servicios que queramos tener monitorizando los servidores.
- Definimos el servicio *Load* el cual ejecutara como *event_handler* el comando *nagios-cpu-handler* y como *check_command* definimos el comando *check_remote_load*:
~~
define service {
        hostgroup_name                 nodes
        service_description            Load
        event_handler                  nagios-cpu-handler
        check_command                  check_remote_load
        use                            generic-service
        notification_interval          0
}
~~
- Hay que definir tambien el host que queremos escalar. Como ejemplo, dicho host tiene la direccion 192.168.1.50.
~~
define host{
        use                     generic-host            ; Name of host template to use
        host_name               web1
        alias                   web1
        address                 192.168.1.50
}
~~

Debemos asegurarnos que el servicio este iniciado:
~~
systemctl start nagios3
~~
### <a name="nrpe"></a> Nagios NRPE Server
Es necesario editar el fichero de configuracion de este servicio para permitir a unos host contactar con el demonio NRPE. Por ello añadimos al fichero */etc/nagios/nrpe.cfg* lo siguiente:q:
~~
allowed_hosts=127.0.0.1,192.168.1.0/24
~~
Por ultimo, asegurarnos que el servicio este iniciado:
~~
systemctl start nagios-nrpe-server
~~

### <a name="h"></a> Haproxy
El fichero de configuración de Haproxy */etc/haproxy/haproxy.cfg* debe estar configurado para balancear la carga entre los nuevos servidores que vayan añadiendose. Configuracion de ejemplo:
~~
global
        daemon
        maxconn 1024
        log /dev/log    local0
        log /dev/log    local1  notice
        chroot  /var/lib/haproxy
        user haproxy
        group   haproxy

defaults
        log     global
        mode    http
        timeout connect 5000ms
        timeout client  50000ms
        timeout server  50000ms

listen  balanceador
        bind    www.gobierno.vota:80
        mode http
        stats enable
        stats auth      admin:admin
        balance roundrobin
        server web1            192.168.1.50:80
~~

### <a name="a"></a> AWS
AWS-CLI debe estar configurado en el equipo. https://docs.aws.amazon.com/es_es/cli/latest/userguide/cli-chap-install.html

Será necesario generar unas claves, las cuales tambien utilizaremos para la gestion de los servidores. Más información en: https://docs.aws.amazon.com/es_es/AWSEC2/latest/UserGuide/ec2-key-pairs.html

### <a name="m"></a> Archivo main.cfg
El fichero */Auto-Scaling/scripts/main.cfg* contiene las variables que hay que configurar necesarias para el funcionamiento de la utilidad. A continuación se explica la utilidad de cada una: 

| Variable  | Descripcion   |
| --------- | ------------  |         
|*HOST=("web1")*| Nombre de hosts. Formato: *HOSTS=("web1" "web2" "web3").* El nombre puede ser el que se desee. Esta variable se utiliza para generar el nombre para la plantilla, y para referirse a la instancia|    
|*SCRIPT1="/Auto-Scaling/provision/provision.sh"*   |SCRIPTS de provisionamiento. SCRIPT1 corresponde con la posicion del primer host ("web1"). Si se han añadido mas hosts en el parametro anterior, los scripts de aprovisionamiento para los dieferentes hosts se indicarian asi: SCRIPT2 corresponderia con la posicion del segundo ("web2"), SCRIPT3 corresponderia con la posicion del tercero ("web3")... etc. Pueden crearse tantos SCRIPTS como hosts se indiquen en el parametro anterior|
| *NAGIOS="/etc/nagios3/conf.d/gobierno.cfg"* | Ruta del fichero de configuracion de Nagios.|
| *KEY="/Auto-Scaling/keys/MyREDHAT.pem"* |Ruta donde se almacena la clave privada que se usara para conectar entre servidores |
| *PKEY="/Auto-Scaling/keys/MyREDHAY.pub"* |Ruta donde se almacena la calve publica que se usara para conectar entre servidores|
| *DNS="192.168.1.5"* |Direccion IP del servidor DNS |
| *ZONE_PATH="/var/named/gobierno.vota.zone"* |Ruta del fichero de configuracion de la zona DNS |

Al iniciarse el script, se generarán nuevas variables en el archivo:

| Variable  | Descripcion   |
| --------- | ------------  | 
| *TEMPLATE_[$HOST]_[$num]_AWS="/Auto-Scaling/templates/[$HOST]_[$num]_AWS.json"* | Esta variable contiene la ruta de la plantilla que se ha generado al iniciarse el script. La variable *$HOST* corresponde a uno de los valores de la variable definida anteriormente (HOST). La variable *$num* corresponde a un numero generado para numerar las instancias, en el caso de que ya exista una instancia para dicho host.|
| *IP_[$HOST]_[$num]_AWS="X.X.X.X"* | Contiene la direccion IP pública de la instancia generada. La variable *$HOST* corresponde a uno de los valores de la variable definida anteriormente (HOST). La variable *$num* corresponde a un numero generado para numerar las instancias, en el caso de que ya exista una instancia para dicho host. |

### <a name="s"></a> SCRIPTS
| SCRIPT | EXPLICACION|
| --------- | ------------  | 
| *auto-scaling.sh*| Inicia el proceso de escalado. Se encarga de ejecutar todo el proceso. Este script es ejecutado por el comando definido en nagios: *nagios-cpu-handler* |
| *gen_temp.sh*| Genera la plantilla para las instancias apartir de la plantilla *cloud.json*. ***cloud.json*** es una plantilla básica la cual despliega una instancia t2.micro, con sistema operativo Red Hat. Si se deasea, se puede sustituir esta plantilla basica por cualquier otra de AWS, pero deberá llamarse ***cloud.json*** y estar en la ruta */Auto-Scaling/tempaltes/* |
| *letsgocloud.sh* | Este script despliega la instancia en AWS, utiliza como parametro la plantilla correspondiente y el script de porvisionamiento correspondiente. |
| *update_nagios.sh* | Se encarga de actualizar el servicio nagios añadiendo la instancia creada a su configuracion. Tambien genera la variable correspondiente a la IP en el fichero main.cfg|
| *update_haproxy.sh* | Actualiza e incia el servicio haproxy para balancear la carga entre el servidor definido en su configuración y las instancias creadas |
 | *update_dns.sh* | Añade un nuevo registro DNS que corresponde con las instancias nuevas creadas, ademas de actualizar el registro "www" y sea "agent" el asociado a dicho registro. (Si no se desea actualizar el servicio DNS deberá ser comentado en el script *auto-scaling.sh*) |

### <a name="c"></a> CLAVES PUBLICAS Y PRIVADAS
 Será necesaria copiar las claves publicas en los archivos */root/.ssh/authorized_keys* de los servidores DNS y AGENT, así como permitir el login con clave.

### <a name="p"></a> Scripts de provisionamiento
Estos scripts deben ser generados propiamente. En el caso de ejemplo, dicho script instala el servicio Apache HTTP Server en la instancia creada automaticamente y la configura con un backup de una pagina web generado manualmente el cual se almacena en */Auto-Scaling/backup.tgz*.

### <a name="d"></a> Configuración DNS
PROXIMAMENTE

