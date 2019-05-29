#!/bin/bash
echo `date` >> /tmp/state
echo "$@" >> /tmp/state

case "$3" in
	OK)
		echo "$1 - $2 IS OK" >> /tmp/service.state
		;;
	WARNING)
		echo "$1 - $2 WARNING" >> /tmp/service.state
		;;
	UNKNOWN)
		;;
	CRITICAL)
		echo "$1 - $2 CRITICAL" >> /tmp/service.state
		case "$4" in
			SOFT)
				echo "  BUT SOFT" >> /tmp/service.state
				case "$5" in
					3)
						echo "$1 - $2 IS ALMOST HARD" >> /tmp/service.state
						;;
				esac
				;;
			HARD)
				echo "$1 - $2 METAPOED" >> /tmp/service.state
				echo "$1 - $2 DEPLOYING AWS" >> /tmp/service.state
				/Auto-Scaling/scripts/auto-scaling.sh >> /tmp/salida 2> /tmp/error
				;;
		esac
		;;
esac
exit 0
