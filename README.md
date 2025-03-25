# wazo-webhookd-dedicated-exchange

Makes wazo-webhookd use a separate exchange than `wazo-headers`, to reduce load on RabbitMQ

## Installation

```sh
wazo-plugind-cli -c "install git https://github.com/wazo-communication/wazo-webhookd-dedicated-exchange"
```

`wazo-webhookd` will be restarted

## Uninstallation

```sh
wazo-plugind-cli -c "uninstall wazocommunication/wazo-webhookd-dedicated-exchange"
```
