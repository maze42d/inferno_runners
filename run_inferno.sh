# shellcheck disable=SC2148
set -e

cd "$INFPATH/inferno"

cd alsa_pcm_inferno

# sink
pw-cli create-node adapter '{ object.linger=1 factory.name=api.alsa.pcm.sink node.name="Inferno sink" media.class=Audio/Sink api.alsa.path="inferno" session.suspend-timeout-seconds=0 node.pause-on-idle=false node.suspend-on-idle=false node.always-process=true api.alsa.headroom=128 api.alsa.pcm.card=999 }'

# source
pw-cli create-node adapter '{ object.linger=1 factory.name=api.alsa.pcm.source node.name="Inferno source" media.class=Audio/Source api.alsa.path="inferno" session.suspend-timeout-seconds=0 node.pause-on-idle=false node.suspend-on-idle=false node.always-process=true api.alsa.headroom=128 api.alsa.pcm.card=999 }'
