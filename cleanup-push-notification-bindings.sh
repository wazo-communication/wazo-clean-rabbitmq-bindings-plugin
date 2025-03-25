#!/bin/bash

set -euo pipefail
QUEUE_NAME="$(rabbitmqctl -n rabbit@localhost list_queues name | grep 'wazo_webhookd\.')"

cat << EOF > /tmp/cleanup-push-notification-bindings.py
import json
import kombu
import logging
import sys

from argparse import ArgumentParser

logger = logging.getLogger(__name__)
logging.basicConfig(filename='/tmp/cleanup-push-notification-bindings.log', level=logging.INFO, format='%(asctime)s [%(process)d] (%(levelname)s) (%(name)s): %(message)s')
logger.info("*** Cleanup push notification bindings starting ***")

DEFAULT_CONFIG = {
    'username': 'guest',
    'password': 'guest',
    'host': 'localhost',
    'port': 5672,
    'vhost': '',
    'exchange_name': 'wazo-headers',
    'exchange_type': 'headers',
    'queue_name': '${QUEUE_NAME}',
}


def read_bindings(exchange):
    result = []
    i = 0
    for line in sys.stdin.readlines():
        i += 1
        tenant_uuid, user_uuid, subscription_uuid, name = line.strip().split('|')
        headers = {
            'x-subscription': subscription_uuid,
            'tenant_uuid': tenant_uuid,
            f'user_uuid:{user_uuid}': True,
            'name': name,
            'x-match': 'all',
        }
        binding = kombu.binding(exchange, None, headers, headers)
        logger.debug("Adding unused binding: %s - %s ", binding, binding.arguments)
        result.append(binding)
    logger.info("Found %d bindings to remove", i)
    return result

config = DEFAULT_CONFIG

exchange = kombu.Exchange(config['exchange_name'], type=config['exchange_type'])
bindings = read_bindings(exchange)

bus_url = 'amqp://{username}:{password}@{host}:{port}/{vhost}'.format(**config)
with kombu.Connection(bus_url) as connection:
    queue = kombu.Queue(config['queue_name'], auto_delete=True, durable=False)(connection.default_channel)
    logger.info("Found queue: %s with %d bindings", queue, len(bindings))
    for binding in bindings:
        logger.info("Unbinding binding: %s - %s", binding, binding.arguments)
        binding.unbind(queue)
logger.info("cleanup finished\n-------------------------------------------------------------------------")
EOF

sudo -u postgres psql asterisk -t -A -c "\
select owner_tenant_uuid, owner_user_uuid, webhookd_subscription.uuid, webhookd_subscription_event.event_name \
from webhookd_subscription join webhookd_subscription_event on webhookd_subscription.uuid = webhookd_subscription_event.subscription_uuid \
where owner_user_uuid not in (select uuid from userfeatures) and service = 'mobile';" \
| python3 /tmp/cleanup-push-notification-bindings.py
