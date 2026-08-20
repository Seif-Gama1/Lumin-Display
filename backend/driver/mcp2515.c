#include "mcp2515.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

// --- ANSI Escape Sequences for Visual Driver Logs ---
#define COLOR_RESET   "\033[0m"
#define COLOR_BOLD    "\033[1m"
#define COLOR_GREEN   "\033[32m"
#define COLOR_YELLOW  "\033[33m"
#define COLOR_CYAN    "\033[36m"
#define COLOR_MAGENTA "\033[35m"
#define COLOR_RED     "\033[31m"

// Ensure SPI commands are defined
#ifndef MCP_READ_RX0
#define MCP_READ_RX0 0x90
#endif
#ifndef MCP_READ_RX1
#define MCP_READ_RX1 0x94
#endif
#ifndef MCP_LOAD_TX0
#define MCP_LOAD_TX0 0x40
#endif
#ifndef MCP_RTS_TX0
#define MCP_RTS_TX0  0x81
#endif

int mcp2515_read_can_msg(unsigned int bus, unsigned int dev, uint32_t *can_id, uint8_t *dlc, uint8_t *data) {
    uint8_t intf = mcp2515_read_reg(bus, dev, MCP_CANINTF);

    uint8_t read_cmd = 0;
    uint8_t clear_bit = 0;
    const char *buf_tag = "";

    // Check which RX buffer caught the message
    if (intf & 0x01) {         // RX0IF (Buffer 0)
        read_cmd = MCP_READ_RX0;
        clear_bit = 0x01;
        buf_tag = COLOR_GREEN "[RXB0]" COLOR_RESET;
    } else if (intf & 0x02) {  // RX1IF (Buffer 1)
        read_cmd = MCP_READ_RX1;
        clear_bit = 0x02;
        buf_tag = COLOR_YELLOW "[RXB1]" COLOR_RESET;
    } else {
        return 0; // No message pending
    }

    uint8_t tx[13] = { read_cmd };
    uint8_t rx[13] = { 0 };

    if (rpi_spi_write_read_data(bus, dev, tx, rx, 13) != 0) {
        fprintf(stderr, COLOR_RED "[MCP2515 ERROR] SPI transfer failed on read!\n" COLOR_RESET);
        return -1;
    }

    // Extract Standard 11-bit CAN ID & DLC
    *can_id = ((uint32_t)rx[1] << 3) | (rx[2] >> 5);
    *dlc = rx[5] & 0x0F;
    if (*dlc > 8) *dlc = 8;

    memcpy(data, &rx[6], *dlc);

    // Fancy Visual Log
    printf("%s " COLOR_BOLD "ID: 0x%03X" COLOR_RESET " | DLC: %d | Data: [ ", buf_tag, *can_id, *dlc);
    for (int i = 0; i < *dlc; i++) {
        printf(COLOR_CYAN "%02X " COLOR_RESET, data[i]);
    }
    printf("]\n");

    // Clear specific interrupt flag so the buffer re-arms
    mcp2515_bit_modify(bus, dev, MCP_CANINTF, clear_bit, 0x00);

    return 1;
}

uint8_t mcp2515_read_reg(unsigned int bus, unsigned int dev, uint8_t reg) {
    uint8_t tx[3] = { MCP_READ, reg, 0x00 };
    uint8_t rx[3] = { 0 };

    if (rpi_spi_write_read_data(bus, dev, tx, rx, 3) != SPI_SUCCESS) {
        fprintf(stderr, COLOR_RED "[MCP2515 ERROR] Read reg 0x%02X failed\n" COLOR_RESET, reg);
        return 0;
    }

    return rx[2];
}

void mcp2515_write_reg(unsigned int bus, unsigned int dev, uint8_t reg, uint8_t val) {
    uint8_t tx[3] = { MCP_WRITE, reg, val };
    uint8_t rx[3] = { 0 };

    rpi_spi_write_read_data(bus, dev, tx, rx, 3);
}

static int mcp2515_reset(unsigned int bus, unsigned int dev) {
    uint8_t tx = MCP_RESET;
    uint8_t rx = 0;
    return rpi_spi_write_read_data(bus, dev, &tx, &rx, 1);
}

void mcp2515_bit_modify(unsigned int bus, unsigned int dev, uint8_t reg, uint8_t mask, uint8_t val) {
    uint8_t tx[4] = { MCP_BITMOD, reg, mask, val };
    uint8_t rx[4] = { 0 };
    rpi_spi_write_read_data(bus, dev, tx, rx, 4);
}

int mcp2515_init(unsigned int bus, unsigned int dev) {
    printf(COLOR_BOLD "==========================================\n");
    printf("   MCP2515 CAN Controller Initialization  \n");
    printf("==========================================\n" COLOR_RESET);

    uint8_t pre_stat = mcp2515_read_reg(bus, dev, 0x0E); // CANSTAT
    printf("[INIT] Pre-reset CANSTAT: " COLOR_YELLOW "0x%02X" COLOR_RESET " (Expected ~0x80)\n", pre_stat);

    printf("[INIT] Resetting chip...\n");
    if (mcp2515_reset(bus, dev) != SPI_SUCCESS) {
        fprintf(stderr, COLOR_RED "[INIT ERROR] Failed to send reset instruction over SPI!\n" COLOR_RESET);
        return -1;
    }
    usleep(50000); // 50ms settle time

    // Verify Config Mode (Top 3 bits: 100 -> 0x80)
    uint8_t stat = mcp2515_read_reg(bus, dev, 0x0E);
    if ((stat & 0xE0) != 0x80) {
        fprintf(stderr, COLOR_RED "[INIT ERROR] Failed Config Mode check! CANSTAT = 0x%02X\n" COLOR_RESET, stat);
        return -1;
    }
    printf("[INIT] Config Mode verified (" COLOR_GREEN "0x%02X" COLOR_RESET ")\n", stat);

    // Set Bit Timing for 500 kbps (8 MHz Crystal)
    mcp2515_write_reg(bus, dev, MCP_CNF1, 0x00);
    mcp2515_write_reg(bus, dev, MCP_CNF2, 0x90);
    mcp2515_write_reg(bus, dev, MCP_CNF3, 0x02);

    // Switch to Normal Operation Mode
    printf("[INIT] Transitioning to Normal Mode...\n");
    mcp2515_bit_modify(bus, dev, MCP_CANCTRL, 0xE0, MODE_NORMAL);

    usleep(10000);

    // Verify status mode
    uint8_t ctrl = mcp2515_read_reg(bus, dev, MCP_CANCTRL);
    if ((ctrl & 0xE0) != MODE_NORMAL) {
        fprintf(stderr, COLOR_RED "[INIT ERROR] Failed Normal Mode entry! CANCTRL = 0x%02X\n" COLOR_RESET, ctrl);
        return -1;
    }

    printf(COLOR_GREEN COLOR_BOLD "[INIT SUCCESS] MCP2515 Ready and Active.\n" COLOR_RESET);
    printf("------------------------------------------\n");
    return 0;
}

int mcp2515_send_can_msg(unsigned int bus, unsigned int dev, uint32_t can_id, uint8_t dlc, const uint8_t *data) {
    if (dlc > 8) dlc = 8;

    // Check if TXB0 is busy
    uint8_t tx_ctrl = mcp2515_read_reg(bus, dev, 0x30);
    if (tx_ctrl & 0x08) {
        return -1; // TXREQ set
    }

    uint8_t tx[14] = { 0 };
    uint8_t rx[14] = { 0 };

    tx[0] = MCP_LOAD_TX0;
    tx[1] = (uint8_t)(can_id >> 3);           // SIDH
    tx[2] = (uint8_t)((can_id & 0x07) << 5);  // SIDL
    tx[3] = 0x00;                             // EID8
    tx[4] = 0x00;                             // EID0
    tx[5] = dlc & 0x0F;                       // DLC

    if (data && dlc > 0) {
        memcpy(&tx[6], data, dlc);
    }

    if (rpi_spi_write_read_data(bus, dev, tx, rx, 6 + dlc) != SPI_SUCCESS) {
        fprintf(stderr, COLOR_RED "[MCP2515 ERROR] Failed to load TX buffer\n" COLOR_RESET);
        return -1;
    }

    // Request To Send
    uint8_t rts_cmd = MCP_RTS_TX0;
    uint8_t rts_rx = 0;
    if (rpi_spi_write_read_data(bus, dev, &rts_cmd, &rts_rx, 1) != SPI_SUCCESS) {
        fprintf(stderr, COLOR_RED "[MCP2515 ERROR] Failed to issue RTS command\n" COLOR_RESET);
        return -1;
    }

    // Fancy TX Log
    if (can_id != 0x311 && can_id != 0x310){
        printf(COLOR_MAGENTA "[TX  ] " COLOR_BOLD "ID: 0x%03X" COLOR_RESET " | DLC: %d | Data: [ ", can_id, dlc);
        for (int i = 0; i < dlc; i++) {
            printf(COLOR_CYAN "%02X " COLOR_RESET, data[i]);
        }
        printf("]\n");
    }
    return 0;
}
