//
//  MixingConsoleModels.swift
//  White Room Mixing Console
//
//  Data models for mixing console UI
//

import Foundation
import Combine

// MARK: - Bus Type

public enum BusType: String, CaseIterable, Identifiable {
    public var id: String { rawValue }

    case reverb = "Reverb"
    case delay = "Delay"
    case compressor = "Compressor"
    case eq = "EQ"
    case subgroup = "Subgroup"
    case master = "Master"
    case aux = "Aux"
    case fx = "FX"
}

// MARK: - Bus Channel Model

@MainActor
public class BusChannel: ObservableObject, Identifiable {
    public let id: String
    @Published public var name: String
    @Published public var type: BusType
    @Published public var channels: [String]

    // Bus-specific controls
    @Published public var volume: Double
    @Published public var pan: Double
    @Published public var isMuted: Bool

    // Metering
    @Published public var levelL: Double
    @Published public var levelR: Double
    @Published public var peakL: Double
    @Published public var peakR: Double

    // Sends to other buses
    @Published public var sends: [Send]

    // UI properties
    public let icon: String
    public let color: String

    public init(
        id: String,
        name: String,
        type: BusType,
        channels: [String] = [],
        volume: Double = 0.75,
        pan: Double = 0.0,
        isMuted: Bool = false,
        levelL: Double = -60.0,
        levelR: Double = -60.0,
        peakL: Double = -60.0,
        peakR: Double = -60.0,
        sends: [Send] = [],
        icon: String = "speaker.wave.2.fill",
        color: String = "#8B5CF6"
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.channels = channels
        self.volume = volume
        self.pan = pan
        self.isMuted = isMuted
        self.levelL = levelL
        self.levelR = levelR
        self.peakL = peakL
        self.peakR = peakR
        self.sends = sends
        self.icon = icon
        self.color = color
    }

    // Convert to dB for display
    public var volumeDB: Double {
        20 * log10(volume)
    }
}

// MARK: - Channel Strip Model

@MainActor
public class ChannelStrip: ObservableObject, Identifiable {
    public let id: String
    @Published public var name: String
    @Published public var type: ChannelType

    // Level controls
    @Published public var volume: Double
    @Published public var pan: Double

    // Mute/Solo
    @Published public var isMuted: Bool
    @Published public var isSolo: Bool

    // Metering
    @Published public var levelL: Double
    @Published public var levelR: Double
    @Published public var peakL: Double
    @Published public var peakR: Double

    // Effects
    @Published public var inserts: [InsertSlot]
    @Published public var sends: [Send]

    // Routing
    @Published public var outputBus: String

    public enum ChannelType: String, CaseIterable {
        case audio = "Audio"
        case midi = "MIDI"
        case bus = "Bus"
        case master = "Master"
    }

    public init(
        id: String,
        name: String,
        type: ChannelType = .audio,
        volume: Double = 0.8,
        pan: Double = 0.0,
        isMuted: Bool = false,
        isSolo: Bool = false,
        levelL: Double = -60.0,
        levelR: Double = -60.0,
        peakL: Double = -60.0,
        peakR: Double = -60.0,
        inserts: [InsertSlot] = [],
        sends: [Send] = [],
        outputBus: String = "master"
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.volume = volume
        self.pan = pan
        self.isMuted = isMuted
        self.isSolo = isSolo
        self.levelL = levelL
        self.levelR = levelR
        self.peakL = peakL
        self.peakR = peakR
        self.inserts = inserts
        self.sends = sends
        self.outputBus = outputBus
    }

    // Convert to dB for display
    public var volumeDB: Double {
        20 * log10(volume)
    }
}

// MARK: - Insert Slot Model

public struct InsertSlot: Identifiable, Equatable {
    public let id: String
    public var enabled: Bool
    public var plugin: String?
    public var effect: String?
    public var parameters: [String: Double]

    public init(
        id: String,
        enabled: Bool = true,
        plugin: String? = nil,
        effect: String? = nil,
        parameters: [String: Double] = [:]
    ) {
        self.id = id
        self.enabled = enabled
        self.plugin = plugin
        self.effect = effect
        self.parameters = parameters
    }
}

// MARK: - Send Model

public struct Send: Identifiable, Equatable {
    public let id: String
    public var bus: String
    public var amount: Double
    public var prePost: PrePostType

    public enum PrePostType: String, CaseIterable {
        case pre = "Pre"
        case post = "Post"
    }

    public init(
        id: String,
        bus: String,
        amount: Double = 0.0,
        prePost: PrePostType = .post
    ) {
        self.id = id
        self.bus = bus
        self.amount = amount
        self.prePost = prePost
    }
}

// MARK: - Mixing Console Model

@MainActor
public class MixingConsole: ObservableObject {
    @Published public var channels: [ChannelStrip]
    @Published public var buses: [BusChannel]
    @Published public var masterBus: ChannelStrip
    @Published public var selectedChannel: String?

    private var meterUpdateTimer: Timer?

    public init() {
        // Initialize with default channels
        self.masterBus = ChannelStrip(
            id: "master",
            name: "Master",
            type: .master,
            volume: 0.8,
            pan: 0.0
        )

        self.channels = [
            ChannelStrip(id: "1", name: "Kick", type: .audio),
            ChannelStrip(id: "2", name: "Snare", type: .audio),
            ChannelStrip(id: "3", name: "Hi-Hat", type: .audio),
            ChannelStrip(id: "4", name: "Bass", type: .audio),
            ChannelStrip(id: "5", name: "Synth 1", type: .audio),
            ChannelStrip(id: "6", name: "Synth 2", type: .audio),
            ChannelStrip(id: "7", name: "Vocals", type: .audio),
            ChannelStrip(id: "8", name: "FX", type: .audio)
        ]

        // Initialize default buses
        self.buses = [
            BusChannel(
                id: "bus-reverb-1",
                name: "Reverb 1",
                type: .reverb,
                volume: 0.75,
                icon: "waveform.path",
                color: "#8B5CF6"
            ),
            BusChannel(
                id: "bus-delay-1",
                name: "Delay 1",
                type: .delay,
                volume: 0.75,
                icon: "timelapse",
                color: "#EC4899"
            ),
            BusChannel(
                id: "bus-subgroup-drums",
                name: "Drums",
                type: .subgroup,
                volume: 0.8,
                icon: "speaker.wave.2",
                color: "#F59E0B"
            ),
            BusChannel(
                id: "bus-master",
                name: "Master",
                type: .master,
                volume: 1.0,
                icon: "speaker.wave.3",
                color: "#10B981"
            )
        ]

        startMeterUpdates()
    }

    // MARK: - Channel Management

    public func addChannel(_ channel: ChannelStrip) {
        channels.append(channel)
    }

    public func removeChannel(id: String) {
        // Remove from all buses
        for bus in buses {
            bus.channels.removeAll { $0 == id }
        }
        channels.removeAll { $0.id == id }
    }

    public func duplicateChannel(id: String) -> ChannelStrip? {
        guard let source = getChannel(id) else { return nil }

        let newId = "\(source.id)-copy-\(UUID().uuidString.prefix(8))"
        let duplicate = ChannelStrip(
            id: newId,
            name: "\(source.name) (copy)",
            type: source.type,
            volume: source.volume,
            pan: source.pan,
            isMuted: source.isMuted,
            isSolo: source.isSolo,
            levelL: source.levelL,
            levelR: source.levelR,
            peakL: source.peakL,
            peakR: source.peakR,
            inserts: source.inserts,
            sends: source.sends,
            outputBus: source.outputBus
        )

        channels.append(duplicate)
        return duplicate
    }

    public func getChannel(id: String) -> ChannelStrip? {
        if id == "master" { return masterBus }
        return channels.first { $0.id == id }
    }

    // MARK: - Bus Management

    public func addBus(_ bus: BusChannel) {
        buses.append(bus)
    }

    public func removeBus(id: String) {
        // Unroute all channels from this bus
        if let bus = buses.first(where: { $0.id == id }) {
            for channelId in bus.channels {
                unrouteChannelFromBus(channelId: channelId, busId: id)
            }
        }
        buses.removeAll { $0.id == id }
    }

    public func getBus(id: String) -> BusChannel? {
        buses.first { $0.id == id }
    }

    public func routeChannelToBus(channelId: String, busId: String) {
        guard let bus = buses.first(where: { $0.id == busId }) else { return }
        if !bus.channels.contains(channelId) {
            bus.channels.append(channelId)
        }
    }

    public func unrouteChannelFromBus(channelId: String, busId: String) {
        guard let bus = buses.first(where: { $0.id == busId }) else { return }
        bus.channels.removeAll { $0 == channelId }
    }

    public func addBusSend(fromBusId: String, toBusId: String, amount: Double) {
        guard let fromBus = buses.first(where: { $0.id == fromBusId }),
              buses.contains(where: { $0.id == toBusId }) else { return }

        if let existingSend = fromBus.sends.first(where: { $0.bus == toBusId }) {
            existingSend.amount = amount
        } else {
            fromBus.sends.append(Send(
                id: "send-\(fromBusId)-\(toBusId)-\(UUID().uuidString.prefix(8))",
                bus: toBusId,
                amount: amount,
                prePost: .post
            ))
        }
    }

    public func removeBusSend(fromBusId: String, toBusId: String) {
        guard let fromBus = buses.first(where: { $0.id == fromBusId }) else { return }
        fromBus.sends.removeAll { $0.bus == toBusId }
    }

    // MARK: - Level Controls

    public func setVolume(id: String, volume: Double) {
        guard let channel = getChannel(id) else { return }
        channel.volume = max(0.0, min(1.0, volume))
    }

    public func setPan(id: String, pan: Double) {
        guard let channel = getChannel(id) else { return }
        channel.pan = max(-1.0, min(1.0, pan))
    }

    public func setMute(id: String, muted: Bool) {
        guard let channel = getChannel(id) else { return }
        channel.isMuted = muted
    }

    public func setSolo(id: String, solo: Bool) {
        guard let channel = getChannel(id),
              channel.type != .master else { return }

        channel.isSolo = solo

        // Mute all non-soloed channels if any are soloed
        let hasSolo = channels.contains { $0.isSolo }
        channels.forEach { ch in
            if ch.id != id && ch.type != .master {
                ch.isMuted = hasSolo && !ch.isSolo
            }
        }
    }

    // MARK: - Metering

    private func startMeterUpdates() {
        meterUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateMeterLevels()
        }
    }

    private func updateMeterLevels() {
        // Simulate meter updates (in real app, this comes from audio backend)
        for channel in channels {
            if !channel.isMuted {
                let targetLevel = -60.0 + (channel.volume * 40.0)
                channel.levelL = targetLevel + Double.random(in: -2...2)
                channel.levelR = targetLevel + Double.random(in: -2...2)
                channel.peakL = max(channel.peakL - 1.0, channel.levelL)
                channel.peakR = max(channel.peakR - 1.0, channel.levelR)
            } else {
                channel.levelL = -60.0
                channel.levelR = -60.0
            }
        }

        // Update master meter
        let activeChannels = channels.filter { !$0.isMuted }
        if !activeChannels.isEmpty {
            let avgLevel = activeChannels.reduce(0.0) { $0 + $1.volume } / Double(activeChannels.count)
            masterBus.levelL = -60.0 + (avgLevel * 40.0)
            masterBus.levelR = -60.0 + (avgLevel * 40.0)
        }
    }

    deinit {
        meterUpdateTimer?.invalidate()
    }
}
