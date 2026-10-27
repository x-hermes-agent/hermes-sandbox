#!/bin/sh
set -e
mkdir -p /etc/ssh/keys /run/sshd
[ -f /etc/ssh/keys/ssh_host_ed25519_key ] || ssh-keygen -q -t ed25519 -N "" -f /etc/ssh/keys/ssh_host_ed25519_key
install -d -m 700 -o agent -g agent /home/agent/.ssh
chown agent:agent /home/agent/sandbox-to-hermes
printf '%s\n' "$AUTHORIZED_KEY" > /home/agent/.ssh/authorized_keys
chown agent:agent /home/agent/.ssh/authorized_keys
chmod 600 /home/agent/.ssh/authorized_keys
exec /usr/sbin/sshd -D -e
