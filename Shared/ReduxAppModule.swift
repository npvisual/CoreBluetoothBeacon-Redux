//
//  ReduxAppModule.swift
//  CoreBluetoothBeacon-Redux
//
//  Created by Nicolas Philippe on 10/5/20.
//

import Foundation
import SwiftRex
import CombineRex
import CombineRextensions
import LoggerMiddleware
import CoreBluetooth
import CoreBluetoothMiddleware
import CoreLocation

enum AppAction {
    case bluetooth(CoreBluetoothAction)
}

enum CoreBluetoothAction {
    case startAdvertising
    case stopAdvertising
    case gotAdvertisingAck
    case gotManagerState(BTManagerType, CBManagerState)
    case gotSubscribedPeer(Bool, CBCentral, CBCharacteristic)
    case triggerError(Error)
}

struct AppState: Equatable {
    // TODO: replace with a configurable beacon
    // Note that the forced unwrapped is necessary here and will always be valid.
    // The UUID is taken from the Apple project in the Core Location documentation.
    static let beaconUUID = UUID.init(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0")!
    static let beaconIdentityConstraint: CLBeaconIdentityConstraint = CLBeaconIdentityConstraint(
        uuid: beaconUUID
    )
    static let beaconRegion: CLBeaconRegion =  CLBeaconRegion(
        beaconIdentityConstraint: beaconIdentityConstraint,
        identifier: "CoreLocation-Redux"
    )
    
    // MARK: - Static content
    
    // App related content
    let appTitle = "CoreBluetooth with Redux !"
    let appUsage = "Use the toggle switch to turn on/off the CoreBluetooth Beacon."
    
    let labelToggleBeacon = "Enable beacon"
    let labelBeaconInfo = "Broadcasting as : "
    let labelPeripheralManagerState = "State of peripheral manager : "
    let labelPeerConnection = "Peer connected : "
    let labelErrorInformation = "Error : "
    
    // MARK: - Application logic
    
    // Service status
    var peripheralManagerStatus: CBManagerState = .unknown
    var centralManagerStatus: CBManagerState = .unknown
    var connectedPeer: String = ""
    var isBeaconAdvertising: Bool = false
    
    // Error
    var error: String = ""
    
    static var empty: AppState {
        .init()
    }
    
    static var mock: AppState {
        .init()
    }}


// MARK: - STORE
class Store: ReduxStoreBase<AppAction, AppState> {
    private init() {
        super.init(
            subject: .combine(initialValue: .empty),
            reducer: Reducer.app,
            middleware: appMiddleware
        )
    }

    static let instance = Store()
}

// MARK: - WORLD
struct World {
    let store: () -> AnyStoreType<AppAction, AppState>
}

extension World {
    static let origin = World(
        store: { Store.instance.eraseToAnyStoreType() }
    )
}

// MARK: - MIDDLEWARE
let appMiddleware = LoggerMiddleware<IdentityMiddleware<AppAction, AppAction, AppState>>
    .default() <> CoreBluetoothMiddleware().lift(
        inputActionMap: { globalAction in
            switch globalAction {
            case .bluetooth(.startAdvertising):
                let peripheralData = AppState.beaconRegion.peripheralData(withMeasuredPower: nil)
                let advertisementData = peripheralData as! [String: Any]
                return BluetoothAction.request(.startAdvertising(advertisementData))
            default: return nil
            }
        },
        outputActionMap: { action in
            switch action {
            case .status(.gotAdvertisingAck): return AppAction.bluetooth(.gotAdvertisingAck)
            case let .status(.gotManagerState(type, status)): return AppAction.bluetooth(.gotManagerState(type, status))
            case let .status(.gotSubscribedAck(central, characteristic)): return AppAction.bluetooth(.gotSubscribedPeer(true, central, characteristic))
            case let .status(.gotUnsubscribed(central, characteristic)): return AppAction.bluetooth(.gotSubscribedPeer(false, central, characteristic))
            default: return .bluetooth(.stopAdvertising)
            }
        },
        stateMap: { globalState -> BluetoothState in
            return BluetoothState(
                statePeripheralManager: globalState.peripheralManagerStatus,
                stateCentralManager: globalState.centralManagerStatus
            )
        }
    )

// MARK: - REDUCERS
extension Reducer where ActionType == AppAction, StateType == AppState {
    static let app = Reducer<CoreBluetoothAction, AppState>.bluetooth.lift(
        action: \AppAction.bluetooth)
}

extension Reducer where ActionType == CoreBluetoothAction, StateType == AppState {
    static let bluetooth = Reducer { action, state in
        var state = state
        switch action {
        case .gotAdvertisingAck:
            state.isBeaconAdvertising = true
            state.error = ""
        case let .gotManagerState(type, status):
            switch type {
            case .peripheral:
                state.peripheralManagerStatus = status
            case .central:
                state.centralManagerStatus = status
            }
            state.error = ""
        case let .gotSubscribedPeer(status, central, characteristic):
            state.connectedPeer = ""
            if status {
                state.connectedPeer = central.identifier.uuidString + ":" + characteristic.description
            }
            state.error = ""
        case let .triggerError(error):
            state.error = error.localizedDescription
        case .startAdvertising,
             .stopAdvertising:
            state.error = ""
        }
        return state
    }
}

// MARK: - PROJECTIONS
extension ObservableViewModel where ViewAction == ContentView.ViewAction, ViewState == ContentView.ViewState {
    static func content<S: StoreType>(store: S) -> ObservableViewModel
    where S.ActionType == AppAction, S.StateType == AppState {
        return store
            .projection(action: Self.transform, state: Self.transform)
            .asObservableViewModel(initialState: .empty)
    }
    
    private static func transform(_ viewAction: ContentView.ViewAction) -> AppAction? {
        switch viewAction {
        case let .toggleBeacon(status):
            if status { return .bluetooth(.startAdvertising) }
            else { return .bluetooth(.stopAdvertising) }
        }
    }
    
    private static func transform(from state: AppState) -> ContentView.ViewState {
        
        return ContentView.ViewState(
            titleView: ContentView.ContentItem(
                title: state.appTitle,
                value: state.appUsage
            ),
            toggleBeacon: ContentView.ContentItem(
                title: state.labelToggleBeacon,
                value: state.isBeaconAdvertising
            ),
            beaconInfo: ContentView.ContentItem(
                title: state.labelBeaconInfo,
                value: AppState.beaconUUID.description
            ),
            statePeripheralManager: ContentView.ContentItem(
                title: state.labelPeripheralManagerState,
                value: state.peripheralManagerStatus.description
            ),
            peerConnection: ContentView.ContentItem(
                title: state.labelPeerConnection,
                value: state.connectedPeer
            ),
            errorInformation: ContentView.ContentItem(
                title: state.labelErrorInformation,
                value: state.error.description)
        )
    }
}

// MARK: - VIEW PRODUCERS
extension ViewProducer where Context == Void, ProducedView == ContentView {
    static func content<S: StoreType>(store: S) -> ViewProducer
    where S.ActionType == AppAction, S.StateType == AppState {
        ViewProducer {
            ContentView(
                viewModel: .content(store: store)
            )
        }
    }
}

// MARK: - PRISM
extension AppAction {
    public var bluetooth: CoreBluetoothAction? {
        get {
            guard case let .bluetooth(value) = self else { return nil }
            return value
        }
        set {
            guard case .bluetooth = self, let newValue = newValue else { return }
            self = .bluetooth(newValue)
        }
    }

    public var isBluetooth: Bool {
        self.bluetooth != nil
    }
}

extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self.rawValue {
        case 1: return "Resetting"
        case 2: return "Unsupported"
        case 3: return "Unauthorized"
        case 4: return "Powered Off"
        case 5: return "Powered On"
        default: return "Unknown"
        }
    }
}
