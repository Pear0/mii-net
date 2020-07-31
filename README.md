# mii-net

This is a basic Ethernet networking device using the MII (Media Independent Interface) to communicate with the two Marvell 88E1111 transceivers on an Altera DE2-115.

This is a toy project to communicate using the Marvell chips to a network so currently only ARP is supported (the FPGA will respond to ARP requests for a specific IP address). 

Future plans include hardware ICMP echo responses as well as using it to connect [TL-45](https://github.com/transfer-learning/tl45-softcore) to a network however this project is not under active development.
