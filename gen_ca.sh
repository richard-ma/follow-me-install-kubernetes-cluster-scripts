#!/bin/sh

confDir=./conf
binDir=./bin
keysDir=./keys

wget -c -O $binDir/cfssl_linux-amd64 https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget -c -O $binDir/cfssljson_linux-amd64 https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget -c -O $binDir/cfssl-certinfo_linux-amd64 https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

chmod +x $binDir/cfssl_linux-amd64 $binDir/cfssljson_linux-amd64 $binDir/cfssl-certinfo_linux-amd64

$binDir/cfssl_linux-amd64 gencert -initca $keysDir/ca-csr.json | $binDir/cfssljson_linux-amd64 -bare ca
mv ./ca.csr ./ca-key.pem ./ca.pem $keysDir

cat > kubernetes-csr.json << EOF
{
  "CN": "kubernetes",
  "hosts": [
EOF
for host in `cat $confDir/host.list`; do
    echo "    $host" >> kubernetes-csr.json
done
cat >> kubernetes-csr.json << EOF
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
mv ./kubernetes-csr.json $keysDir/
$binDir/cfssl_linux-amd64 gencert -ca=$keysDir/ca.pem -ca-key=$keysDir/ca-key.pem -config=$keysDir/ca-config.json -profile=kubernetes $keysDir/kubernetes-csr.json | $binDir/cfssljson_linux-amd64 -bare kubernetes
mv ./kubernetes.csr ./kubernetes-key.pem ./kubernetes.pem $keysDir

$binDir/cfssl_linux-amd64 gencert -ca=$keysDir/ca.pem -ca-key=$keysDir/ca-key.pem -config=$keysDir/ca-config.json -profile=kubernetes $keysDir/admin-csr.json | $binDir/cfssljson_linux-amd64 -bare admin
mv ./admin.csr ./admin-key.pem ./admin.pem $keysDir

$binDir/cfssl_linux-amd64 gencert -ca=$keysDir/ca.pem -ca-key=$keysDir/ca-key.pem -config=$keysDir/ca-config.json -profile=kubernetes $keysDir/kube-proxy-csr.json | $binDir/cfssljson_linux-amd64 -bare kube-proxy
mv ./kube-proxy.csr ./kube-proxy-key.pem ./kube-proxy.pem $keysDir

# 将$keysDir中的pem文件分发到所有机器的/etc/kubernetes/ssl
