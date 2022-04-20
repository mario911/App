import Foundation
import NetworkExtension
import ClashKit

class PacketTunnelProvider: NEPacketTunnelProvider {
        
    override func startTunnel(options: [String : NSObject]? = nil) async throws {
        try self.setupClash()
        try self.setConfig()
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "254.1.1.1")
        settings.mtu = 1500
        settings.ipv4Settings = {
            let settings = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.255.0"])
            settings.includedRoutes = [NEIPv4Route.default()]
            return settings
        }()
        settings.dnsSettings = {
            let settings = NEDNSSettings(servers: ["114.114.114.114", "8.8.8.8"])
            return settings
        }()
        try await self.setTunnelNetworkSettings(settings)
    }
    
    override func stopTunnel(with reason: NEProviderStopReason) async {
        do {
            try await self.setTunnelNetworkSettings(nil)
        } catch {
            debugPrint(error)
        }
        self.receiveTraffic(0, down: 0)
    }
    
    override func handleAppMessage(_ messageData: Data) async -> Data? {
        guard let command = messageData.first.flatMap(Clash.Command.init(rawValue:)) else {
            return nil
        }
        switch command {
        case .setConfig:
            do {
                try self.setConfig()
            } catch {
                return error.localizedDescription.data(using: .utf8)
            }
        case .setTunnelMode:
            ClashSetTunnelMode(UserDefaults.shared.string(forKey: Clash.tunnelMode))
        case .setLogLevel:
            ClashSetLogLevel(UserDefaults.shared.string(forKey: Clash.logLevel))
        case .setSelectGroup:
            self.setSelectGroup()
        }
        return nil
    }
    
    private var tunnelFileDescriptor: Int32? {
        var buf = Array<CChar>(repeating: 0, count: Int(IFNAMSIZ))
        return (1...1024).first {
            var len = socklen_t(buf.count)
            return getsockopt($0, 2, 2, &buf, &len) == 0 && String(cString: buf).hasPrefix("utun")
        }
    }
}
