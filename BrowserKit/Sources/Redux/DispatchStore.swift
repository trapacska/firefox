// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Protocol that allows to subscribe to the store and receive dispatched actions to modify the store state
public protocol DispatchStore {
    func dispatch(_ action: Action)
}

public protocol DefaultDispatchStore: DispatchStore {
    associatedtype State: StateType
    /// `ActionCreators` allows  to perform a conditional dispatch to the store.
    /// An `ActionCreator` takes the current application state and a reference to a store then may return an optional `Action`
    associatedtype ActionCreator = (_ state: State, _ store: DefaultDispatchStore) -> Action?

    var state: State { get }

    func subscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State
    func subscribe<SubState, S: StoreSubscriber>(_ subscriber: S,
                                                 transform: ((Subscription<State>) -> Subscription<SubState>)?) where S.SubscriberStateType == SubState
    func unsubscribe<S: StoreSubscriber>(_ subscriber: S) where S.SubscriberStateType == State

    func dispatch(_ actionCreator: ActionCreator)
}
