#ifndef MCP2515_H
#define MCP2515_H

#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include "rpi_spi.h"

#define MCP_CANCTRL     0x0F
#define MCP_CNF3        0x28
#define MCP_CNF2        0x29
#define MCP_CNF1        0x2A
#define MODE_NORMAL     0x00

/* MCP2515 Command Instructions */
#define MCP_RESET       0xC0
#define MCP_READ        0x03
#define MCP_WRITE       0x02
#define MCP_BITMOD      0x05 

#define MCP_READ_RX0    0x90
#define MCP_RXB0CTRL    0x60
#define MCP_CANINTF     0x2C

#ifndef MCP_LOAD_TX0
#define MCP_LOAD_TX0 0x40
#endif

#ifndef MCP_RXB1CTRL
// MCP2515 RXB1 Register Definitions
#define MCP_RXB1CTRL    0x70
#define MCP_RXB1SIDH    0x71
#define MCP_RXB1SIDL    0x72
#define MCP_RXB1DLC     0x75
#define MCP_RXB1D0      0x76
#endif

#ifndef MCP_RTS_TX0
#define MCP_RTS_TX0  0x81
#endif

#define MCP_READ_RX0    0x90    // Read RX Buffer 0 starting at RXB0D0
#define MCP_READ_RX1    0x94    // Read RX Buffer 1 starting at RXB1D0

#ifdef __cplusplus
extern "C" {
#endif

// Only expose what the outside world actually needs to call
int mcp2515_init(unsigned int bus, unsigned int dev);
uint8_t mcp2515_read_reg(unsigned int bus, unsigned int dev, uint8_t reg);
void mcp2515_write_reg(unsigned int bus, unsigned int dev, uint8_t reg, uint8_t val);
void mcp2515_bit_modify(unsigned int bus, unsigned int dev, uint8_t reg, uint8_t mask, uint8_t val);
int mcp2515_read_can_msg(unsigned int bus, unsigned int dev, uint32_t *can_id, uint8_t *dlc, uint8_t *data);
int mcp2515_send_can_msg(unsigned int bus, unsigned int dev, uint32_t can_id, uint8_t dlc, const uint8_t *data);

#ifdef __cplusplus
}
#endif

#endif // MCP2515_H
