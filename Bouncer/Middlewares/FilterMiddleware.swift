//
//  FilterMiddleware.swift
//  Bouncer
//

import Foundation
import Combine

enum FilterMiddlewareError {
    case loadError
    case addError
    case deleteError
    case unknown
}

func filterMiddleware(filterStore: FilterStore) -> Middleware<AppState, AppAction> {

    return { state, action in
        switch action {

            case .filter(action: .fetch):

                return filterStore.fetch()
                    .map { AppAction.filter(action: .fetchComplete(filters: $0 )) }
                    .catch { (error: FilterStoreError) -> Just<AppAction> in
                        switch(error) {
                        case .loadError:
                            return Just(AppAction.filter(action: .fetchError(error: FilterMiddlewareError.loadError)))

                        default:
                            return Just(AppAction.filter(action: .fetchError(error: FilterMiddlewareError.unknown)))
                        }
                    }
                    .eraseToAnyPublisher()

            case .filter(action: .add(let filter)):
                return filterStore.add(filter: filter)
                    .map { AppAction.filter(action: .fetch) }
                    .catch { (error: FilterStoreError) -> Just<AppAction> in
                        switch(error) {
                        case .addError:
                            return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.addError)))
                        default:
                            return Just(AppAction.filter(action: .addError(error: FilterMiddlewareError.unknown)))
                        }
                    }
                    .eraseToAnyPublisher()
                
            case .filter(action: .delete(let uuid)):
                return filterStore.remove(uuid: uuid)                    
                    .map { AppAction.filter(action: .fetch) }
                    .catch { (error: FilterStoreError) -> Just<AppAction> in
                        switch(error) {
                        case .addError:
                            return Just(AppAction.filter(action: .deleteError(error: FilterMiddlewareError.deleteError)))

                        default:
                            return Just(AppAction.filter(action: .deleteError(error: FilterMiddlewareError.unknown)))
                        }
                    }
                    .eraseToAnyPublisher()

            default:
                break
        }
        return Empty().eraseToAnyPublisher()
    }
}
