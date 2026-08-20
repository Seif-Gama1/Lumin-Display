#ifndef CAN_FRAME_H
#define CAN_FRAME_H

#include <cstdint>

#pragma pack(push, 1) // Ensure no struct padding across target compilers
struct CanFrame {
    uint32_t can_id;  // CAN ID (e.g., 0x0A2, 0x0A3)
    uint8_t  can_dlc; // Length (0-8)
    uint8_t  data[8]; // Raw payload
};
#pragma pack(pop)

#endif // CAN_FRAME_H
