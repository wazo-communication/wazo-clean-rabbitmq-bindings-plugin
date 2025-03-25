# wazo-clean-rabbitmq-bindings

Remove unused configuration to reduce load on RabbitMQ

## Installation

```sh
wazo-plugind-cli -c "install git https://github.com/wazo-communication/wazo-clean-rabbitmq-bindings-plugin"
```

This plugin can be installed on a running instance without disruption, as it
does not restart any services.

Upon installation, the RabbitMQ configuration will be trimmed of unused
configuration. The operations are logged in
`/tmp/cleanup-push-notification-bindings.log`.

## Uninstallation

```sh
wazo-plugind-cli -c "uninstall wazocommunication/wazo-clean-rabbitmq-bindings"
```
