#include <iostream>
#include <cstring>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include "CanFrame.h"

class QnxCanServer {
private:
    int server_fd = -1;
    int client_fd = -1;
    const uint16_t PORT = 5555;

public:
    bool start() {
        server_fd = socket(AF_INET, SOCK_STREAM, 0);
        if (server_fd < 0) {
            std::cerr << "[QNX Server] Failed to create socket\n";
            return false;
        }

        int opt = 1;
        setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

        sockaddr_in address{};
        address.sin_family = AF_INET;
        address.sin_addr.s_addr = INADDR_ANY; // Listens on all virtual network interfaces
        address.sin_port = htons(PORT);

        if (bind(server_fd, (struct sockaddr*)&address, sizeof(address)) < 0) {
            std::cerr << "[QNX Server] Bind failed on port " << PORT << "\n";
            return false;
        }

        if (listen(server_fd, 1) < 0) {
            std::cerr << "[QNX Server] Listen failed\n";
            return false;
        }

        std::cout << "[QNX Server] Listening on port " << PORT << " for Linux VM...\n";
        return true;
    }

    // Call this to accept incoming connection from Linux guest
    bool acceptClient() {
        sockaddr_in client_addr{};
        socklen_t addrlen = sizeof(client_addr);
        client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &addrlen);
        if (client_fd < 0) {
            std::cerr << "[QNX Server] Failed to accept Linux client\n";
            return false;
        }
        std::cout << "[QNX Server] Linux guest connected successfully!\n";
        return true;
    }

    // Call this inside your MCP2515 SPI receive callback/loop
    bool sendFrame(const CanFrame& frame) {
        if (client_fd < 0) return false;

        ssize_t bytes_sent = send(client_fd, &frame, sizeof(CanFrame), MSG_NOSIGNAL);
        if (bytes_sent <= 0) {
            std::cerr << "[QNX Server] Client disconnected\n";
            close(client_fd);
            client_fd = -1;
            return false;
        }
        return true;
    }

    ~QnxCanServer() {
        if (client_fd >= 0) close(client_fd);
        if (server_fd >= 0) close(server_fd);
    }
};

// --- Quick Test Usage ---
int main() {
    QnxCanServer server;
    if (!server.start()) return -1;

    server.acceptClient();

    // Example: Simulating frames coming from your MCP2515 driver
    CanFrame frame{};
    frame.can_id = 0x123;
    frame.can_dlc = 4;
    frame.data[0] = 0xDE;
    frame.data[1] = 0xAD;
    frame.data[2] = 0xBE;
    frame.data[3] = 0xEF;

    while (true) {
        server.sendFrame(frame);
        usleep(100000); // Send every 100ms
    }
    return 0;
}
