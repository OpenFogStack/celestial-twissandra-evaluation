```sh
HOST2=35.246.136.86
HOST3=34.107.32.189
HOST4=34.141.84.181
HOST5=35.246.160.180
COORDINATOR=35.198.73.246

scp -i ../celestial/gcloud.pem tp@"$HOST2":/celestial/vmlinux5 .

scp -ri ../celestial/gcloud.pem vmlinux5 tp@"$HOST2":/celestial/vmlinux5
scp -ri ../celestial/gcloud.pem vmlinux5 tp@"$HOST3":/celestial/vmlinux5
scp -ri ../celestial/gcloud.pem vmlinux5 tp@"$HOST4":/celestial/vmlinux5
scp -ri ../celestial/gcloud.pem vmlinux5 tp@"$HOST5":/celestial/vmlinux5

scp -ri ../celestial/gcloud.pem client/client.img tp@"$HOST2":.
scp -ri ../celestial/gcloud.pem client/client.img tp@"$HOST3":.
scp -ri ../celestial/gcloud.pem client/client.img tp@"$HOST4":.
scp -ri ../celestial/gcloud.pem client/client.img tp@"$HOST5":.

scp -ri ../celestial/gcloud.pem combinedsat/combinedsat.img tp@"$HOST2":.
scp -ri ../celestial/gcloud.pem combinedsat/combinedsat.img tp@"$HOST3":.
scp -ri ../celestial/gcloud.pem combinedsat/combinedsat.img tp@"$HOST4":.
scp -ri ../celestial/gcloud.pem combinedsat/combinedsat.img tp@"$HOST5":.

scp -ri ../celestial/gcloud.pem server/server.img tp@"$HOST2":.
scp -ri ../celestial/gcloud.pem server/server.img tp@"$HOST3":.
scp -ri ../celestial/gcloud.pem server/server.img tp@"$HOST4":.
scp -ri ../celestial/gcloud.pem server/server.img tp@"$HOST5":.

scp -ri ../celestial/gcloud.pem cassandra/cassandra.img tp@"$HOST2":.
scp -ri ../celestial/gcloud.pem cassandra/cassandra.img tp@"$HOST3":.
scp -ri ../celestial/gcloud.pem cassandra/cassandra.img tp@"$HOST4":.
scp -ri ../celestial/gcloud.pem cassandra/cassandra.img tp@"$HOST5":.

scp -ri ../celestial/gcloud.pem combined/combined.img tp@"$HOST2":.
scp -ri ../celestial/gcloud.pem combined/combined.img tp@"$HOST3":.
scp -ri ../celestial/gcloud.pem combined/combined.img tp@"$HOST4":.
scp -ri ../celestial/gcloud.pem combined/combined.img tp@"$HOST5":.

scp -ri ../celestial/gcloud.pem client/clientping.img tp@"$HOST2":.
scp -ri ../celestial/gcloud.pem client/clientping.img tp@"$HOST3":.
scp -ri ../celestial/gcloud.pem client/clientping.img tp@"$HOST4":.
scp -ri ../celestial/gcloud.pem client/clientping.img tp@"$HOST5":.

scp -ri ../celestial/gcloud.pem client/clientapi.img tp@"$HOST2":.
scp -ri ../celestial/gcloud.pem client/clientapi.img tp@"$HOST3":.
scp -ri ../celestial/gcloud.pem client/clientapi.img tp@"$HOST4":.
scp -ri ../celestial/gcloud.pem client/clientapi.img tp@"$HOST5":.

scp -ri gcloud.pem proto tp@"$HOST2":.
scp -ri gcloud.pem proto tp@"$HOST3":.
scp -ri gcloud.pem proto tp@"$HOST4":.
scp -ri gcloud.pem proto tp@"$HOST5":.

scp -ri gcloud.pem proto tp@"$COORDINATOR":.

go build -o celestial.bin .

scp -ri ../celestial/gcloud.pem tp@"$HOST2":./results/ ./results-"$HOST2"
scp -ri ../celestial/gcloud.pem tp@"$HOST3":./results/ ./results-"$HOST3"
scp -ri ../celestial/gcloud.pem tp@"$HOST4":./results/ ./results-"$HOST4"
scp -ri ../celestial/gcloud.pem tp@"$HOST5":./results/ ./results-"$HOST5"
```

```sh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/YnLg+PB6lviYzwUEJgLvQKcTWvIxvY2GwJbtuM+W4RADS7pcs83vCvYtGt9RQa5UGDEkkq78tPZtQQBfzal8+vzdJ1S3fPYA7k6ZKsdFouB+IqtU6P/Uy7rhNG6ItUygxg6/skKfWpUGWpsgN1ALCzXR0/qUIQ4Mwfu/2iL2idITNCfVJt/C6KTlRYribwqzoXGL+Ji8N1P+2ZiMW3rxVoKNQYhYgwrJhcxMjSTjgZLkiQHkkTsc02aVeg3dxtkJEi0s/eWEUEq/UVmx7roiQi/dC8bTjRkL8oIw98fiarMufbz5czJJk+91aHOEXss8xBuMkJdrKRAe++oSxw0Oqt2W52hWILdmABkrpz35lkvwgfBLOSXLI7zYAKAs7VK7un2cnSBCHNaofJorN3TQ9zgH9SXdHa5R2p1NVGeQaswkg84G5wGOjSZ8qYQn4LGs98yI5u53KSdq7JbyLJr1Ld3jTIM4LwDiVQ99lG3ZYZRTN8eZ0eijJ78Z3huPcnYDHv6BkHKwg60q9YspIzW8gGKSbgrdz4g2AIRIfSXaOAkPToxLnP/f/WuX+Zp6/yqMIiueqXGe2ySmV40NV302yl7sJgEQwtlw21EOVjqUHA7jRKI54BJj8dZYG7gB5gUgD7JNQJT5iHZowmcAvjnwVW0OFdG9tNkb40Y69hW97w== tobias@Tobiass-Air.fritz.box" > .ssh/authorized_keys
```
