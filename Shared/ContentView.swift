//
//  ContentView.swift
//  Shared
//
//  Created by Nicolas Philippe on 10/5/20.
//

import SwiftUI
import SwiftRex
import CombineRex
import CombineRextensions


struct ContentView: View {
    
    @ObservedObject var viewModel: ObservableViewModel<ViewAction, ViewState>

    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(viewModel.state.titleView.title)
                    .padding()
                    .font(.title)
                Text(viewModel.state.titleView.value)
                Toggle(
                    viewModel: viewModel,
                    state: \.toggleBeacon.value,
                    onToggle: { ViewAction.toggleBeacon($0) }) {
                    Text(viewModel.state.toggleBeacon.title)
                }
                Spacer()
                Text(viewModel.state.statePeripheralManager.title + viewModel.state.statePeripheralManager.value)
                Text(viewModel.state.peerConnection.title + viewModel.state.peerConnection.value)
                Text(viewModel.state.errorInformation.title + viewModel.state.errorInformation.value)
                Spacer()
                Text(viewModel.state.beaconInfo.title + viewModel.state.beaconInfo.value)
                    .multilineTextAlignment(.trailing)
            }
            .padding()
            Spacer()
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    
    static let mockState = AppState.mock
    static let mockStore = ObservableViewModel<AppAction, AppState>.mock(
        state: mockState,
        action: { action, _, state in
            state = Reducer.app.reduce(action, state)
        }
    )
    static let mockViewModel = ObservableViewModel.content(store: mockStore)
    
    static var previews: some View {
        ContentView(viewModel: mockViewModel)
    }
}

extension ContentView {
    enum ViewAction: Equatable {
        case toggleBeacon(Bool)
    }
    
    struct ViewState: Equatable {
        let titleView: ContentView.ContentItem<String>
        let toggleBeacon: ContentView.ContentItem<Bool>
        let beaconInfo: ContentView.ContentItem<String>
        let statePeripheralManager: ContentView.ContentItem<String>
        let peerConnection: ContentView.ContentItem<String>
        let errorInformation: ContentItem<String>
        
        static var empty: ViewState {
            .init(
                titleView: ContentView.ContentItem(title: "", value: ""),
                toggleBeacon: ContentView.ContentItem(title: "", value: false),
                beaconInfo: ContentView.ContentItem(title: "", value: ""),
                statePeripheralManager: ContentView.ContentItem(title: "", value: ""),
                peerConnection: ContentView.ContentItem(title: "", value: ""),
                errorInformation: ContentView.ContentItem(title: "", value: "")
            )
        }
    }
    
    struct ContentItem<T>: Equatable where T:Equatable {
        let title: String
        let value: T
        var action: ViewAction? = nil
    }
}
