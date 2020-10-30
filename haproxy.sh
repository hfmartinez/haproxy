
#archivo de aprovisionamiento HaProxy
echo "[Task 1] Update system"
apt-get update

echo "[Task 2] Add servers to /etc/hosts file "
echo '192.168.80.20 haproxyserver  haproxy' | tee -a /etc/hosts
echo '192.168.80.21 webserver1  web1' | tee -a /etc/hosts
echo '192.168.80.22 webserver2  web2' | tee -a /etc/hosts


echo "[Task 3] Install LXD cluster"
snap install lxd
gpasswd -a vagrant lxd
cat <<EOF | lxd init --preseed
config:
  core.https_address: 192.168.80.20:8443
  core.trust_password: haproxysecret
networks:
- config:
    bridge.mode: fan
    fan.underlay_subnet: 192.168.80.0/24
  description: ""
  name: lxdfan0
  type: ""
  project: default
storage_pools:
- config: {}
  description: ""
  name: local
  driver: dir
profiles:
- config: {}
  description: ""
  devices:
    eth0:
      name: eth0
      network: lxdfan0
      type: nic
    root:
      path: /
      pool: local
      type: disk
  name: default
cluster:
  server_name: haproxyserver
  enabled: true
  member_config: []
  cluster_address: ""
  cluster_certificate: ""
  server_address: ""
  cluster_password: ""
EOF

echo "[Task 4] Generating Certificate"
sed ':a;N;$!ba;s/\n/\n\n/g' /var/snap/lxd/common/lxd/server.crt > /vagrant/cert.txt



echo "[Task 5] Launch Haproxy container"
lxc launch ubuntu:18.04 haproxy --target haproxyserver < /dev/null
sleep 5

echo "[Task 6] Update system and installation into haproxy container"
lxc exec haproxy -- apt-get update
lxc exec haproxy -- apt-get install haproxy -y

echo "[Task 7] Haproxy setup"
cat <<EOF > /home/vagrant/haproxy.cfg
global
    log /dev/log local0
    log localhost local1 notice
    user haproxy
    group haproxy
    maxconn 2000
    daemon

defaults
    log global
    mode http
    option httplog
    option dontlognull
    retries 3
    timeout connect 5000
    timeout client 50000
    timeout server 50000

frontend http-in
    bind *:80
    acl carga fe_sess_rate ge 100
    acl falla nbsrv(webservers) eq 0
    use_backend respaldo if carga
    use_backend respaldo if falla
    default_backend webservers

backend webservers
    balance roundrobin
    stats enable
    stats auth admin:admin
    stats uri /stats
    option httpchk
    option forwardfor
    option http-server-close
    errorfile 503 /etc/haproxy/errors/503.http
    server web1 webserver1:80 check
    server web2 webserver2:80 check

backend respaldo
    errorfile 503 /etc/haproxy/errors/503.http
    balance roundrobin
    stats enable
    stats auth admin:admin
    stats uri /stats
    option httpchk
    option forwardfor
    option http-server-close
    server web3 webserver3:80 check
    server web4 webserver4:80 check
    server web5 webserver5:80 check
    server web6 webserver6:80 check

EOF

lxc file push /home/vagrant/haproxy.cfg haproxy/etc/haproxy/haproxy.cfg

echo "[Task 8] Init Haproxy"
lxc exec haproxy -- service haproxy restart

echo "[Task 9] Port Forwarding"
lxc config device add haproxy haproxyport proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80

echo "[Task 10] Change error page"
cat <<EOF > /home/vagrant/503.http
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html><body><h1>Lo sentimos servicio no disponible</h1>
Microproyecto 1 - Computacion en la nube.
</body></html>
EOF

lxc file push /home/vagrant/503.http haproxy/etc/haproxy/errors/503.http

echo "Haproxy server Ok!"