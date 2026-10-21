# HTTPS for the API

The API serves HTTPS when `SSL_CERT_FILE` and `SSL_KEY_FILE` are set in `API/.env`.
The certificate is signed by the professor's certificate authority (CA).

## 1. Generate the private key and the signing request (CSR)

Run this on the server, inside `API/`:

```sh
mkdir -p certs && cd certs
openssl req -new -newkey rsa:2048 -nodes \
  -keyout monarcas.tc2007b.tec.mx.key -out monarcas.tc2007b.tec.mx.csr \
  -subj "/C=MX/ST=Nuevo Leon/L=Monterrey/O=Tecnologico de Monterrey/OU=TC2007B/CN=monarcas.tc2007b.tec.mx/emailAddress=a00840490@tec.mx" \
  -addext "subjectAltName=DNS:monarcas.tc2007b.tec.mx,IP:10.14.255.44"
```

- `monarcas.tc2007b.tec.mx.csr` is the file to send to the professor.
- `monarcas.tc2007b.tec.mx.key` is the private key. It never leaves the server and is never shared or committed.
- The professor's CA requires `emailAddress` in the subject; use the team contact email.
- If the server is reached through a different host name or IP, change `CN` and `subjectAltName`
  before generating the CSR. The apps must use a host that appears in `subjectAltName`.

Check the request before sending it:

```sh
openssl req -in monarcas.tc2007b.tec.mx.csr -noout -text | grep -A1 "Subject Alternative Name"
```

## 2. Install the signed certificate

Save the certificate the professor returns as `API/certs/monarcas.tc2007b.tec.mx.cer`. If they also send an
intermediate certificate, append it to the end of `monarcas.tc2007b.tec.mx.cer`. Python needs it in PEM format
(text starting with `-----BEGIN CERTIFICATE-----`). If `head -1` shows binary data instead, convert it:

```sh
openssl x509 -inform der -in monarcas.tc2007b.tec.mx.cer -out pem.tmp && mv pem.tmp monarcas.tc2007b.tec.mx.cer
```

Check that it matches the private key (both commands must print the same hash):

```sh
openssl x509 -noout -modulus -in monarcas.tc2007b.tec.mx.cer | openssl md5
openssl rsa  -noout -modulus -in monarcas.tc2007b.tec.mx.key | openssl md5
```

Then in `API/.env`:

```
SSL_CERT_FILE=certs/monarcas.tc2007b.tec.mx.cer
SSL_KEY_FILE=certs/monarcas.tc2007b.tec.mx.key
```

Restart the API. With `python3 server.py` it prints `Running SERVER API over HTTPS...`.
With Gunicorn, the `if __name__ == '__main__'` block in `server.py` does not run, so start it with
the config file in `API/`, which reads the same `.env`:

```sh
cd API && gunicorn -c gunicorn.conf.py server:app
```

The log must show `Listening at: https://0.0.0.0:10206`. Do not pass `-b`/`--bind` on the command line,
because it overrides the port from `.env`. Quick test from another machine:

```sh
curl --cacert profesor-ca.crt https://monarcas.tc2007b.tec.mx:10206/apidocs/
```

## 3. iOS apps

The apps already point to `https://`. iOS only accepts the certificate if it trusts the professor's CA:

- **Device:** install the CA certificate (AirDrop or email the `.crt`/`.cer`), then
  Settings > General > VPN & Device Management to install the profile, and
  Settings > General > About > Certificate Trust Settings to enable full trust.
- **Simulator:** drag the CA certificate onto the simulator window, or run
  `xcrun simctl keychain booted add-root-cert profesor-ca.crt`.
